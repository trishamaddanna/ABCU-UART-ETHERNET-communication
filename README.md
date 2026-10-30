# Antenna Beam Control Unit (ABCU) Communication Core

**Description:** FPGA-based bidirectional communication subsystem for an Antenna Beam Control Unit (ABCU). Integrates a MicroBlaze-based 1G Ethernet interface with 32-channel UART-over-LVDS transmit and receive networks for communication with 32 Group Controllers (GCs).

---

Developed and synthesized using **Xilinx Vivado**, the architecture establishes a bidirectional data gateway between a **MicroBlaze-based 1G Ethernet infrastructure** and custom **32-channel UART-over-LVDS transmit and receive interfaces**.

The Artix-7-based ABCU provides **32 transmit and 32 receive channels**, distributed across eight physical connectors, each carrying four TX and four RX channel connections. These interfaces connect to **32 Virtex-7-based Group Controllers (GCs)**, with each GC interfacing with 16 OTRMs. The subsystem supports command distribution, OTRM power control, operational mode configuration, and telemetry collection.

---

## 🛠️ Toolchain Infrastructure & Verification Environment

The development and validation process used the following EDA and software tools:

*   **FPGA Synthesis & Block Design:** Developed using **Xilinx Vivado System Edition** targeting the Artix-7-based ABCU and Virtex-7-based Group Controllers. The design combines custom VHDL modules with Xilinx IP Integrator components interconnected through an AXI4-based infrastructure.
*   **Embedded Software Development:** Programmed within the **Xilinx Software Development Kit (XSDK)** to compile the C-based standalone Ethernet stacks and network bridge management applications executing on the MicroBlaze soft processor core.
*   **Graphical User Interface (GUI) App:** Developed using **Qt Creator (C++ / Qt5)** to design an asynchronous multi-threaded system control dashboard. The GUI features a dedicated worker thread (`receive.cpp`) managing UDP sockets to prevent interface freezes during high-volume telemetry processing.
* **Hardware Debugging and Validation:** Used **Xilinx Vivado Hardware Manager and Integrated Logic Analyzer (ILA)** to capture and analyze internal FPGA signals, AXI bus handshakes, communication transactions, and temperature telemetry during hardware validation.
  
---

## 📐 System Architecture & Hardware Components

The system operates as a bidirectional Ethernet-to-UART communication bridge, with command transmission and telemetry reception handled by dedicated hardware and software subsystems.

### 1. MicroBlaze Ethernet Subsystem Components
The Ethernet communications hub is constructed by interfacing dedicated soft IP components with external memory modules over the system crossbar fabric:
*   **Xilinx AXI 1G Ethernet Core:** Provides the Ethernet interface through RGMII and transfers received network frames to the MicroBlaze-based embedded system for UDP packet processing.
*   **AXI DMA Engine:** Transfers data between AXI streaming interfaces and DDR3 memory using Simple Transfer mode.
*   **MicroBlaze Soft Core Processor:** Executes the embedded lwIP network stack, processes incoming GUI commands, and manages communication between the Ethernet subsystem and FPGA-based UART interfaces.
  
### 2. Data Synchronizer Components (`AXI_To_Tx_Bridge.vhd`)
Implements the downward command-processing interface, transferring decoded command data from the AXI-Stream interface to the transmit-channel logic.
*   **AXI-Stream Interface:** Receives and captures 32-bit streaming data words from the processor-side AXI data path.
*   **Protocol Parsing FSM:** Implements an FSM to capture AXI-Stream data, identify packet boundaries, validate the header (x"AAA1"), decode control information, and extract command payloads. It also monitors m_axis_tlast to handle stream termination.
*   **Array Payload Demultiplexer:** Distributes decoded command data into parallel channel structures (data_array) for subsequent processing by the transmit modules.

### 3. VHDL UART Components over LVDS
Implements 32 parallel UART transmit channels and 32 parallel UART receive channels over LVDS physical interfaces, enabling simultaneous communication with the 32 Group Controllers.
**Physical Interface:** The ABCU exposes eight physical connectors, each carrying four TX and four RX channel connections. These connectors provide the LVDS communication interfaces to the 32 Group Controllers.
*   **32-Channel Transmit Network (`Tx_Channel.vhd`):** Implements 32 parallel UART transmit channels operating with a 10 MHz TX clock and a 10 Mbps UART bit rate. Supports OTRM power-control, normal/dwell, and calibration packet structures (pkt_otrm_data, pkt_phase_data, and pkt_mode02_data). The mode tracking signal (mode_data_out) selects the appropriate packet for transmission.
*   **32-Channel Receive Network (`Rx_GC_To_ABCU.vhd`):** Implements 32 parallel UART receive channels using a 200 MHz sampling clock to receive 10 Mbps serial data. Each UART bit period is sampled 20 times. The receiver evaluates the central samples (samples 5–15, inclusive) using majority voting to determine the received logic level, improving noise tolerance during LVDS communication.
  
### 4. Upward Telemetry Bridge Components (`Rx_To_Axi_Bridge.vhd`)
Coordinates the real-time aggregation and uplink packaging of return status variables:
*   **Input Strobe Synchronization Logic:** Detects valid-data transitions using rx_pkt2_valid and rx_pkt2_valid_reg to trigger synchronous telemetry capture.
*   **Hardware Snapshot Register Banks:** Capture temperature measurements from the SPI-driven AD7814 Temp_sensor block, together with system-status signals such as RFIF_FWD_PWR_STS and RFIF_TEMP_STS.
*   **AXI-Stream Master Assembler:** Organizes the captured telemetry and status registers into a 7-word AXI-Stream data frame and asserts m_axis_tvalid to transfer the data to the Ethernet subsystem.
---

## ⚡ Bidirectional Communication Flow Mechanics

Information streams through the ABCU core over two independent, concurrent processing pipelines:

### 1. Downward Control Path (GUI ➔ Ethernet ➔ UART ➔ GC)
1.  **GUI Assertion:** The operator configures target radar parameters (Azimuth, Elevation, Frequency) and toggles calibration states on the Qt dashboard. The GUI packs these variables into a raw payload and transmits it over UDP.
2.  **Ethernet Reception:** The Xilinx Ethernet block receives the packet and passes it to the MicroBlaze processor, which acts as the **Ethernet-to-UART Bridge**.
3.  **Bridge Decoding:** The downward hardware bridge receives data over an AXI-Stream interface. Its protocol parsing FSM identifies packet boundaries, validates the framing identifier (x"AAA1"), extracts hardware control information (RFIF_CTRL_SW), and distributes the decoded parameters into parallel channel structures (data_array).
4.  **Multi-Mode Packet Transmission:** Upon receiving the external Start of Beam trigger (sob_in), the transmit channels capture the required register values and serialize the command packets according to the selected operating mode. The communication sequence supports the following packet types:
    *   *OTRM Power Control Packet:* Transmits power-on and power-off commands for individual OTRM elements using the 15-byte power-control packet format.
    *   *Normal/Dwell Mode Packet (x"01"):* Transmits the phase-gradient parameters (Pa_LSB/MSB, Pb_LSB/MSB) required for normal and dwell operation.
    *   *Calibration Mode Packet (x"02"):* Transmits calibration alignment parameters using the corresponding function identifier.
    *   *Packet Timing:* Implements a hardware-controlled 50 µs interval between applicable packet transmissions to maintain the required communication timing.

### 2. Upward Telemetry Path (GC ➔ UART ➔ Ethernet ➔ GUI)
1. **Header-Based Packet Classification:** Incoming serial data from the 32 Group Controllers is captured by the 200 MHz receiver logic. The received packet headers are decoded to identify packet types based on their function identifiers:
   - **OTRM Packet** (`temp_pkt(2) = x"14"`): Routes received OTRM status data to the OTRM Packet 1 registers.
   - **Normal/Dwell Packet** (`temp_pkt(2) = x"01"`): Routes received phase and parameter data to the Phase/Parameter Packet 2 registers.
   - **Calibration Packet** (`temp_pkt(2) = x"02"`): Identifies and routes received calibration-related data to the corresponding calibration registers.
   CRC-8 validation is performed on received packets before accepting the corresponding data.
2.  **Telemetry Bridging:** The upward bridge block aggregates valid receiver signals, snapshots real-time telemetry and status parameters (including an SPI-driven AD7814 temperature sensor running over a 1 MHz clock), and generates a 7-word burst stream.
3.  **Ethernet Upload:** The AXI DMA engine triggers a simple transfer, moving the telemetry burst into memory. The embedded server encapsulates this 29-byte frame block into a structured UDP packet and transmits it back to the ground PC to update the Message Monitor dashboard in real-time.

---

## 💻 Integrated Applications & Firmware Stack

The operational stack maps across three separate firmware and software application layers:

### 1. Bootloader Application (`bootloader.c`)
Resides in primary non-volatile Quad-SPI (QSPI) Flash memory. Upon a power-on-reset (POR) or hardware reset condition, it initializes the QSPI Flash interface, locates the SREC image starting at flash base address `0x01000000`, copies the binary application sections into DDR3 RAM, and transfers execution to the loaded application.

### 2. Ethernet Application (`echo.c` / `main.c`)
An embedded standalone application executing on the MicroBlaze processor core using the **lwIP (Lightweight IP) protocol stack**. It establishes network interface bindings, initializes UDP protocol control blocks, and continuously polls xemacif_input() to process incoming Ethernet frames. The application invokes transfer_data() to manage the associated DMA data transfers.

### 3. Qt Graphical User Interface Dashboard
A cross-platform desktop control dashboard designed in C++ utilizing Qt5 frameworks. 
*   **Main Interface Thread:** Manages the graphical panels, maps parameter choices to hex strings, and calculates spatial phase equations (\(P_a\), \(P_b\)).
*   **Worker Thread Interface:** Implements an asynchronous worker block (`receive.cpp`) moved onto an independent `QThread`. This thread processes low-level socket connections, intercepts incoming packets, extracts the 29 bytes of incoming telemetry datagrams using Datagram.left(29) and forwards the resulting data to the GUI thread.

---

## 📂 Repository Layout & Project Artifacts

Because the core RTL blocks contain sensitive aerospace IP, this repository catalogs all architectural verification layout diagrams, timing waveforms, embedded codebases, and script assets used to validate the system:

### 💻 Hardware Design & Simulation Codebases
*   `ABCU.vhd` — Top-level synthesizable structural block integrating the 32-channel TX and RX communication networks with the Ethernet and external LVDS interfaces.
*   `ABCU_Package.vhd` — Shared VHDL package defining custom data types and array structures, including data_array and temp_pkt_type.
*   `AXI_To_Tx_Bridge.vhd` — Downward AXI-Stream command parser implementing header decoding, frame validation, and payload distribution.
*   `Tx_Channel.vhd` — 32-channel UART transmit logic operating with a 10 MHz TX clock, supporting OTRM power-control, normal/dwell, and calibration packets, with CRC-8 frame processing and a hardware-controlled 50 µs packet-timing interval.
*   `Rx_GC_To_ABCU.vhd` — 32-channel UART receive logic operating with a 200 MHz sampling clock, incorporating input synchronization, oversampling, majority voting, and CRC-8 validation.
*   `Rx_To_AXI_Bridge.vhd` — Upward bridge manager bundling telemetry snapshot frames into AXI-Stream bursts.
*   `Temp_sensor.vhd` — Synthesizable SPI controller reading real-time digital temperatures from an external AD7814 chip over a 1 MHz SPI clock.
*   `coverage_pulse_gen.vhd` — VHDL timing core generating dual-edge synchronized protect envelopes around active radar pulses.

### 🔌 Embedded C Firmware & Software Applications
*   `bootloader.c` — Simple SREC bootloader firmware running on MicroBlaze to initialize QSPI flash memory configurations and load memory images starting at flash base address `0x01000000`.
*   `echo.c` / `main.c` — Standalone lwIP embedded C server handling network bindings, UDP protocol control blocks, and AXI DMA Simple Transfer tracking cycles.

### 🖥️ Graphical User Interface (GUI) App Codebases
*   `main.cpp` — Qt application entry point responsible for initializing the application and launching the main window.
*   `mainwindow.cpp` / `mainwindow.h` — Real-time control dashboard layout handling math parameter conversions (\(P_a\), \(P_b\)), calibration toggles, and memory binary uploads.
*   `receive.cpp` / `receive.h` — Asynchronous worker-thread implementation handling UDP socket reception and extraction of telemetry data for delivery to the GUI.
  
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
*   `calibration_pkt.png` — Architectural reference layout defining the 15-byte **Calibration Mode Message Format**, outlining the phase and attenuation coefficients, frequency IDs, and array table designations.

### 📊 Real-Time Hardware Logic Waveforms
*   `txrx_waveform_calibpkt.png` — Single-channel handshake timing trace verifying exact transaction-level byte execution (`ac 0f 02`) during an active Calibration Mode command sweep, physical `SDO`/`SDI` LVDS pins, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `txrx_waveform_normalphasepkt.png` — Single-channel handshake timing trace verifying exact transaction-level byte execution (`ac 32 01`) during an active Normal/Dwell Mode command sweep, physical `SDO`/`SDI` LVDS pins, and hardware interlock status assertions (`RFIF_CAL_IN`, `RFIF_CTRL_SW`).
*   `txrx_waveform_otrmpowerpkt.png` — Serial timing trace tracking serial line decoding and OTRM header matching loops (`ac 0f 14`).
*   `txmultichan_waveform_calibpkt.png` — Multi-channel simulation waveform demonstrating simultaneous parallel bus data output across channels (`tx_data_8_2` to `tx_data_8_20`) under a Calibration Mode layout.
*   `txmultichan_waveform_normalphasepkt.png` — Multi-channel simulation waveform demonstrating simultaneous parallel bus data output across channels (`tx_data_8_2` to `tx_data_8_20`) under a Normal/Dwell Mode layout.
*   `README.md` — Main technical documentation page.
