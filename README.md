# Antenna Beam Control Unit (ABCU) Communication Core

**Description:** High-speed SoC and FPGA communications subsystem for an airborne Antenna Beam Control Unit (ABCU). Bridges a MicroBlaze 1G Ethernet topology with a custom 32-channel asynchronous UART-over-LVDS matrix interface.

---

A safety-critical, high-speed **SoC and FPGA-based communications subsystem** for an airborne **Antenna Beam Control Unit (ABCU)**. Modeled and synthesized using **Xilinx Vivado**, this architecture establishes a bidirectional data gateway bridging a **MicroBlaze-based 1G Ethernet infrastructure** with a custom **32-channel high-speed UART over Low-Voltage Differential Signaling (LVDS)** interface. 

The core facilitates high-speed board-to-board control and telemetry distribution between an **Artix-7-based 8-channel ABCU** module and a centralized **Virtex-7-based 32-channel Group Controller (GC)** system.

---

## 🛠️ Toolchain Infrastructure & Verification Environment

To meet stringent reliability and safety requirements, professional, industry-standard electronic design automation (EDA) tools were utilized throughout the development and validation lifecycle:

*   **FPGA Synthesis & Block Design:** Developed inside **Xilinx Vivado System Edition** targeting a unified hardware netlist on Artix-7 and Virtex-7 architectures. It leverages custom VHDL modules alongside Xilinx IP integrator cores hooked onto an AXI4 interconnect fabric.
*   **Embedded Software Development:** Programmed within the **Xilinx Software Development Kit (XSDK) / Vitis** to compile the C-based standalone Ethernet stacks and network bridge management applications executing on the MicroBlaze soft processor core.
*   **Graphical User Interface (GUI) App:** Developed using **Qt Creator (C++ / Qt5)** to design an asynchronous multi-threaded system control dashboard. The GUI features a dedicated worker thread (`receive.cpp`) managing raw UDP sockets to prevent interface freezes during high-volume telemetry processing.
*   **Hardware-in-the-Loop Emulation:** Validated using the **Xilinx Vivado Hardware Manager Integrated Logic Analyzer (ILA)** to capture live bus handshakes and temperature telemetry profiles without signal optimization loss.

---

## 📐 System Architecture & Hardware Components

The system functions simultaneously as an Ethernet-to-UART bridge, splitting communication and processing logic across independent specialized subsystems:

### 1. MicroBlaze Ethernet Subsystem Components
The Ethernet communications hub is constructed by interfacing dedicated soft IP components with external memory modules over the system crossbar fabric:
*   **Xilinx AXI 1G/2.5G Ethernet Core:** Automatically manages physical layer RGMII signaling states and extracts structured TCP/IP or UDP command packets from the raw network line.
*   **AXI DMA Engine:** Configured in standard Simple Transfer mode to bypass software overhead. The DMA automates direct scatter-gather-free memory copies, dumping captured Ethernet payloads or telemetry streams into dedicated DDR3 address spaces.
*   **MicroBlaze Soft Core Processor:** Serves as the primary system controller. It arbitrates communication boundaries, executes network stack protocols, and hosts the application tracking state matrices.

### 2. Data Synchronizer Components (`AXI_To_Tx_Bridge.vhd`)
Acts as the downward command parsing buffer that transitions data between high-frequency processor buses and physical output pins:
*   **AXI-Stream Interface Bus:** Latches 32-bit streaming data blocks directly from the processor's memory queues.
*   **8-State Protocol FSM:** Runs through an algorithmic tracking loop (`INIT_STABILIZE` → `CAPTURE_HEADER` → `GC_WORD_A` → `GC_WORD_B` → `GC_WORD_C`) to parse multi-byte header boundaries. It locks frames on an identifier tag (`x"AAA1"`), isolates global status registers (`RFIF_CTRL_SW`), and buffers spatial phase matrix tracking words into localized register arrays.
*   **Array Payload Demultiplexer:** Splits the 32-bit streaming data back into multi-channel parallel structures (`data_array`) distributing specialized command vectors to individual channel modules.

### 3. VHDL UART Components over LVDS
The serialization network bypasses traditional processor bottlenecks by implementing parallel hardware modules mapped directly onto Low-Voltage Differential Signaling pairs:
*   **32-Channel Transmit Network (`Tx_Channel.vhd`):** Spans 32 parallel transmit channels operating on a synchronous low-frequency clock domain (f = 10 MHz). It features a mid-sampling data collection grid that updates output ports bit-by-bit to maintain stable transmission lines.
*   **32-Channel Receive Network (`Rx_GC_To_ABCU.vhd`):** Spans 32 parallel receive channels operating on a high-speed clock domain (f = 200 MHz). It uses an oversampling majority-voting architecture to accurately capture in-sync bytes over noisy differential physical lines.

### 4. Upward Telemetry Bridge Components (`Rx_To_AXI_Bridge.vhd`)
Coordinates the real-time aggregation and uplink packaging of return status variables:
*   **Input Strobe Synchronization Logic:** Evaluates low-to-high transition edges (`rx_pkt2_valid` and `rx_pkt2_valid_reg`) across incoming telemetry channels to securely trigger synchronous capture frames without data tearing.
*   **Hardware Snapshot Register Banks:** Instantly freezes real-time analog parameters (including an SPI-driven AD7814 `Temp_sensor` block mapping structural temperatures) alongside system-wide physical health rails (`RFIF_FWD_PWR_STS`, `RFIF_TEMP_STS`).
*   **AXI-Stream Master Assembler:** Bundles the frozen parameter registers into an upstream 7-Word AXI-Stream data frame, triggering active `m_axis_tvalid` flags to route the diagnostic data directly back through the Ethernet subsystem.

---

## ⚡ Bidirectional Communication Flow Mechanics

Information streams through the ABCU core over two independent, concurrent processing pipelines:

### 1. Downward Control Path (GUI ➔ Ethernet ➔ UART ➔ GC)
1.  **GUI Assertion:** The operator configures target radar parameters (Azimuth, Elevation, Frequency) and toggles calibration states on the Qt dashboard. The GUI packs these variables into a raw payload and fires it over UDP.
2.  **Ethernet Reception:** The Xilinx Ethernet block catches the packet and passes it to the MicroBlaze processor, which acts as the **Ethernet-to-UART Bridge**.
3.  **Bridge Decoding:** The downward hardware bridge monitors the data over an AXI-Stream bus. An internal **8-state protocol FSM** parses frame boundaries, validates a framing identifier tag (`x"AAA1"`), isolates hardware control lines (`RFIF_CTRL_SW`), and decouples the parameters into a localized parallel matrix (`data_array`).
4.  **Serialized Transmission:** Upon receiving an external Start of Beam trigger (`sob_in`), the transmit channels freeze current register snapshots in flip-flops and serialize the parameters into **two distinct 15-byte packets**:
    *   *Packet 1 (OTRM Data):* Contains hardware configuration metrics marked by function code `x"0F"`.
    *   *Packet 2 (Phase/Parameter Data):* Contains calculated phase gradients marked by function code `x"32"`.
    A mandatory **50 µs delay hardware loop** is inserted between the two packets to prevent data overlapping at the destination Group Controller.

### 2. Upward Telemetry Path (GC ➔ UART ➔ Ethernet ➔ GUI)
1.  **Telemetry Sampling:** Returning serial streams from the 32 Group Controller modules are captured by the 200 MHz receiver block, checked against a CRC-8 polynomial, and written to storage.
2.  **Telemetry Bridging:** The upward bridge block aggregates valid receiver signals, snapshots real-time analog parameters (including an SPI-driven AD7814 temperature sensor running over a 1 MHz clock), and generates a 7-word burst stream.
3.  **Ethernet Upload:** The AXI DMA engine triggers a simple transfer, moving the telemetry burst into memory. The embedded server encapsulates this 29-byte frame block into a structured UDP packet and transmits it back to the ground PC to update the Message Monitor dashboard in real-time.

---

## 💻 Integrated Applications & Firmware Stack

The operational stack maps across three separate firmware and software application layers:

### 1. Bootloader Application (`bootloader.c`)
Resides in primary non-volatile Quad-SPI (QSPI) Flash memory. Upon a power-on-reset (POR) or hardware reset condition, it mounts the SPI flash lines, locates the SREC image starting at flash base address `0x01000000`, copies the binary application sections into DDR3 RAM, and branches execution to the main application address.

### 2. Ethernet Application (`echo.c` / `main.c`)
An embedded standalone application executing on the MicroBlaze processor core utilizing the **lwIP (Lightweight IP) protocol stack**. It establishes network interface bindings, mounts raw UDP PCBs, and loops indefinitely to monitor `xemacif_input()` network lines while checking `transfer_data()` hooks to handle DMA transfers.

### 3. Qt Graphical User Interface Dashboard
A cross-platform desktop control dashboard designed in C++ utilizing Qt5 frameworks. 
*   **Main Interface Thread:** Manages the graphical panels, maps parameter choices to hex strings, and calculates spatial phase equations (\(P_a\), \(P_b\)).
*   **Worker Thread Interface:** Implements an asynchronous worker block (`receive.cpp`) moved onto an independent `QThread`. This thread processes low-level socket connections, prevents interface stuttering during peak telemetry loads, and transmits command buffers down to the ABCU network.

---

## 📂 Repository Layout & Project Artifacts

Because the core RTL blocks contain sensitive aerospace IP, this repository catalogs all architectural verification layout diagrams, timing waveforms, embedded codebases, and script assets used to validate the system:

### 💻 Hardware Design & Simulation Codebases
*   `ABCU.vhd` — Top-level synthesizable structural block mapping internal modules to physical external LVDS I/O lines.
*   `ABCU_Package.vhd` — Shared package configuration file declaring custom array array parameters (data_array, temp_pkt_type).
*   `AXI_To_Tx_Bridge.vhd` — Downward AXI-Stream interface command parser implementing the 8-state header decoding and frame-locking FSM.
*   `Tx_Channel.vhd` — Asynchronous 10 MHz serialization core driving real-time CRC-8 frame calculations and the 50 µs packet spacing delay loop.
*   `Rx_GC_To_ABCU.vhd` — Oversampled 200 MHz serial line receiver featuring input synchronization, majority-voting bit noise sampling, and packet CRC verification.
*   `Rx_To_AXI_Bridge.vhd` — Upward bridge manager bundling telemetry snapshot frames into AXI-Stream bursts.
*   `Temp_sensor.vhd` — Synthesizable SPI controller reading real-time digital temperatures from an external AD7814 chip over a 1 MHz serial clock tree.
*   `coverage_pulse_gen.vhd` — VHDL timing core generating dual-edge synchronized protect envelopes around active radar pulses.

### 🔌 Embedded C Firmware & Software Applications
*   `bootloader.c` — Simple SREC bootloader firmware running on MicroBlaze to initialize QSPI flash memory configurations and load memory images starting at flash base address `0x01000000`.
*   `echo.c` / `main.c` — Standalone lwIP embedded C server handling network bindings, raw UDP PCBs, and AXI DMA Simple Transfer tracking cycles.

### 🖥️ Graphical User Interface (GUI) App Codebases
*   `main.cpp` — Desktop application initialization routine registering string thread metadata definitions.
*   `mainwindow.cpp` / `mainwindow.h` — Real-time control dashboard layout handling math parameter conversions (\(P_a\), \(P_b\)), calibration toggles, and memory binary uploads.
*   `receive.cpp` / `receive.h` — Asynchronous multi-threaded worker thread managing underlying raw UDP sockets and safe 29-byte telemetry array filtering.

### 🗺️ System Layout Block Blueprints
*   `abcu_block_diagram.jpg` — Block diagram illustrating the unified system architecture (`Top_System`) across data synchronizers, 32-channel Tx/Rx paths, and the AXI telemetries.
*   `ethernet_uart_bridge.jpg` — Detailed hardware netlist block diagram exported from Vivado tracking MicroBlaze connections, AXI interconnect lines, peripheral cores, and 32-channel pin assignments.
*   `gui_group_controller_unit.jpg` — Interface screenshot of the Qt user dashboard tracking status indicators for all 32 independent channels (GC 01 to GC 32).
*   `gui_gc1_dialog_box.jpg` — Modular pop-up panel detailing binary ON/OFF control selections and error diagnostics for the 16 localized elements on channel GC 1.
*   `gui_rfif_cal_unit.jpg` — Dedicated RF front-end diagnostics panel showing real-time voltage profiles, temperature status loops, and calibration flags (RFIF_CAL_IN).
*   `gui_message_monitor.jpg` — Telemetry window logging explicit hex string payload text captures for incoming (Rx) and outgoing (Tx) UDP packet streams.

### 📜 Protocol Frame Structures & Message Formats
*   `otrm_power_pkt.png` — Structural byte map mapping the 15-byte **Power Control Packet** layout, showcasing bit toggling allocations per OTRM element and the multi-state power definitions (Default, Power_on, Power_off).
*   `dwell_phase_pkt.png` — Architectural reference layout defining the 15-byte **Dwell Mode Message Format**, outlining the explicit positioning of phase gradients (\(P_A, P_B\)), frequency IDs, and array table designations.

### 📊 Real-Time Hardware Logic Waveforms
*   `tx_waveform_packet1_otrm.jpg` — Simulation timing trace tracking multi-channel `tx_data_8_x` data registers outputting Packet 1 frames marked by the `x"0F"` OTRM identifier.
*   `tx_waveform_packet2_phase.jpg` — Simulation timing trace tracking multi-channel `tx_data_8_x` data registers outputting Packet 2 phase parameters marked by the `x"32"` function code.
*   `rx_waveform_abcu_interface_otrm.jpg` — Vivado logic analyzer trace verifying incoming `rx_data_8_1` bytes, physical `SDO`/`SDI` LVDS pin matrix states outputting Packet 1 frames marked by the `x"0F"` OTRM identifier, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `rx_waveform_abcu_interface_phase.jpg` — Vivado logic analyzer trace verifying incoming `rx_data_8_1` bytes, physical `SDO`/`SDI` LVDS pin matrix states outputting Packet 2 phase parameters marked by the `x"32"` function code, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `README.md` — Main technical documentation page.


