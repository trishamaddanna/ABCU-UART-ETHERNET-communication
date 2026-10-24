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
*   **8-State Protocol FSM:** Runs through an algorithmic tracking loop (`INIT_STABILIZE` → `CAPTURE_HEADER` → `GC_WORD_A` → `GC_WORD_B` → `GC_WORD_C`) to parse multi-byte header boundaries. It actively checks for early stream terminations (`m_axis_tlast = '1'`), locks valid frames on an identifier tag (`x"AAA1"`), isolates hardware control switches (`RFIF_CTRL_SW`), and transitions directly to data processing states unconditionally upon header validation to guarantee continuous OTRM updates.
*   **Array Payload Demultiplexer:** Splits the 32-bit streaming data back into multi-channel parallel structures (`data_array`) distributing specialized command vectors to individual channel modules.

### 3. VHDL UART Components over LVDS
The serialization network bypasses traditional processor bottlenecks by implementing parallel hardware modules mapped directly onto Low-Voltage Differential Signaling pairs:
*   **32-Channel Transmit Network (`Tx_Channel.vhd`):** Spans 32 parallel transmit channels operating on a synchronous low-frequency clock domain (f = 10 MHz). Features a mid-sampling data collection architecture that compiles three independent physical packet structures (`pkt_otrm_data`, `pkt_phase_data`, and `pkt_mode02_data`). It uses a dynamic mode tracking port (`mode_data_out`) to conditionally branch output streams on the second packet window based on the active GUI layout command.
*   **32-Channel Receive Network (`Rx_GC_To_ABCU.vhd`):** Spans 32 parallel receive channels operating on a high-speed clock domain (f = 200 MHz). It uses an oversampling majority-voting architecture to accurately capture in-sync bytes over noisy differential physical lines.

### 4. Upward Telemetry Bridge Components (`Rx_To_Axi_Bridge.vhd`)
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
4.  **Multi-Mode Serialized Transmission:** Upon receiving an external Start of Beam trigger (`sob_in`), the transmit channels freeze current register snapshots in flip-flops and parse the transmission sequence dynamically across separate 15-byte packet blocks based on the latched `mode_data_out` parameter:
    *   *Packet 1 (All Modes):* Always transmits the core structural configuration block containing OTRM data parameters.
    *   *Packet 2 (Normal / Dwell Mode - `x"01"`):* Transmits the active phase gradient template array (`Pa_LSB/MSB`, `Pb_LSB/MSB`) using function identifier `x"01"`.
    *   *Packet 2 (Calibration Mode - `x"02"`):* Bypasses phase computations to transmit alternative hardware calibration alignment parameters marked by identifier code `x"02"`.
    An automated **50 µs delay hardware loop** is maintained between Packet 1 and Packet 2 boundaries to avoid bus overlap states at the destination Group Controller.

### 2. Upward Telemetry Path (GC ➔ UART ➔ Ethernet ➔ GUI)
1.  **Discriminator Telemetry Sampling:** Returning serial streams from the 32 Group Controller modules are captured by the 200 MHz receiver block. An internal **Discriminator Routing Engine** parses incoming headers. If the structural function byte matches byte position **`temp_pkt(2) = x"14"`**, the data is routed into OTRM Packet 1 registers; if it matches **`temp_pkt(2) = x"01"`**, it maps directly into Phase/Parameter Packet 2 register channels, preserving data lane boundaries over the shared physical line before executing CRC-8 checks.
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
*   **Worker Thread Interface:** Implements an asynchronous worker block (`receive.cpp`) moved onto an independent `QThread`. This thread processes low-level socket connections, intercepts incoming packets, extracts exactly 29-byte telemetry segments via a dedicated buffer mask (`Datagram.left(29)`), and transmits thread-stable data buffers up to the UI layout.

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
*   `abcu_block_diagram.png` — Block diagram illustrating the unified system architecture (`Top_System`) across data synchronizers, 32-channel Tx/Rx paths, and the AXI telemetries.
*   `ethernet_uart_bridge.png` — Detailed hardware netlist block diagram exported from Vivado tracking MicroBlaze connections, AXI interconnect lines, peripheral cores, and 32-channel pin assignments.

### 🖥️ Qt User Interface Dashboard Captures
*   `gui_calibration.png` — Main dashboard view set to **Calibration Mode**, showcasing real-time hexadecimal transmission codes (`Tx`/`Rx`) within the Message Monitor layout.
*   `gui_normal.png` — Main dashboard view set to **Normal Mode**, illustrating independent standalone phase tracking setups and telemetry verification.
*   `gui_array_geometry.png` — Active panel representation displaying the real-time **Array Geometry** interface configured for a dynamic 16x8 matrix array block selection layout.
*   `gui_group_controller_unit.png` — Interface screenshot of the Qt user dashboard tracking status indicators for all 32 independent channels (GC 01 to GC 32).
*   `gui_gc1_dialog_box.png` — Modular pop-up panel detailing binary ON/OFF control selections and error diagnostics for the 16 localized elements on channel GC 1.
*   `gui_rfif_cal_unit.png` — Dedicated RF front-end diagnostics panel showing real-time voltage profiles, temperature status loops, and calibration flags (RFIF_CAL_IN).

### 📜 Protocol Frame Structures & Message Formats
*   `otrm_power_pkt.png` — Structural byte map mapping the 15-byte **Power Control Packet** layout, showcasing bit toggling allocations per OTRM element and the multi-state power definitions (Default, Power_on, Power_off).
*   `dwell_phase_pkt.png` — Architectural reference layout defining the 15-byte **Dwell Mode Message Format**, outlining the explicit positioning of phase gradients (\(P_A, P_B\)), frequency IDs, and array table designations.

### 📊 Real-Time Hardware Logic Waveforms
*   `txrx_waveform_calibpkt.png` — Single-channel handshake timing trace verifying exact transaction-level byte execution (`ac 0f 02`) during an active Calibration Mode command sweep, physical `SDO`/`SDI` LVDS pins, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `txrx_waveform_normalphasepkt.png` — Single-channel handshake timing trace verifying exact transaction-level byte execution (`ac 32 01`) during an active Normal/Dwell Mode command sweep, physical `SDO`/`SDI` LVDS pins, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `txrx_waveform_otrmpowerpkt.png` — Serial timing trace tracking single-ended baseline line decodes and OTRM header matching loops (`ac 0f 14`).
*   `txmultichan_waveform_calibpkt.png` — Multi-channel simulation waveform demonstrating simultaneous parallel bus data output across channels (`tx_data_8_2` to `tx_data_8_20`) under a Calibration Mode layout.
*   `txmultichan_waveform_normalphasepkt.png` — Multi-channel simulation waveform demonstrating simultaneous parallel bus data output across channels (`tx_data_8_2` to `tx_data_8_20`) under a Normal/Dwell Mode layout.
*   `README.md` — Main technical documentation page.
