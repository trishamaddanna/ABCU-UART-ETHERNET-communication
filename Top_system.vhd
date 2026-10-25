library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use work.ABCU_Package.all;

entity Top_system is
    Port (
        clk_10          : in  std_logic; 
        clk_200         : in  std_logic; 
        reset           : in  std_logic; 
        
        TX_OUT_32       : out std_logic_vector(31 downto 0);
        RX_IN_32        : in  std_logic_vector(31 downto 0);
        
        rx_data_32      : out data_array;
        tx_data_32      : out data_array;
        sob_in          : in  std_logic; 
        
        s_axis_tdata    : in  std_logic_vector(31 downto 0);
        s_axis_tvalid   : in  std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tlast    : in  std_logic;
        
        m_axis_tdata    : out std_logic_vector(31 downto 0);
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in  std_logic;
        m_axis_tlast    : out std_logic;

        RFIF_CTRL_SW    : out std_logic;
        RFIF_CAL_IN     :  out STD_LOGIC;
         RFIF_FWD_PWR_STS: in  std_logic;
         RFIF_SLB_OUT_STS: in  std_logic;
         RFIF_TEMP_STS   : in  std_logic;
         RFIF_AMP_CAL_STS   : in  std_logic;
         RFIF_PATH_CAL_STS   : in  std_logic;
        mode_data_out   : out std_logic_vector(7 downto 0);
        main_red_out    : out std_logic_vector(7 downto 0);
        
        Pa_LSB_out      : out std_logic_vector(7 downto 0);
        Pa_MSB_out      : out std_logic_vector(7 downto 0);
        Pb_LSB_out      : out std_logic_vector(7 downto 0);
        Pb_MSB_out      : out std_logic_vector(7 downto 0);
        
        byte12_out      : out std_logic_vector(7 downto 0);
        byte13_out      : out std_logic_vector(7 downto 0);
        byte12_9        : out std_logic_vector(7 downto 0);
        byte13_9        : out std_logic_vector(7 downto 0)
    );
end Top_system;

architecture Structural of Top_system is
    type counter_array is array (0 to 31) of integer range 0 to 8191;
    signal rx_bytes_total   : counter_array;
    signal rx_errors_total  : counter_array;
   
    -- Channel 0 split interconnect signals
    signal ch0_pkt1_valid   : std_logic;
    signal ch0_pkt2_valid   : std_logic;
    signal ch0_pkt1_data    : temp_pkt_type;
    signal ch0_pkt2_data    : temp_pkt_type;

    -- Channel 9 split interconnect signals (Index 8)
    signal ch9_pkt1_valid   : std_logic;
    signal ch9_pkt2_valid   : std_logic;
    signal ch9_pkt1_data    : temp_pkt_type;
    signal ch9_pkt2_data    : temp_pkt_type;

    signal local_Pa_LSB     : std_logic_vector(7 downto 0);
    signal local_Pa_MSB     : std_logic_vector(7 downto 0);
    signal local_Pb_LSB     : std_logic_vector(7 downto 0);
    signal local_Pb_MSB     : std_logic_vector(7 downto 0);
    signal local_mode_data  : std_logic_vector(7 downto 0);
    
    signal ch32_otrm01      : data_array;
    signal ch32_otrm23      : data_array;
    signal ch32_otrm45      : data_array;
    signal ch32_otrm67      : data_array;
    signal ch32_otrm89      : data_array;
    signal ch32_otrm1011    : data_array;
    signal ch32_otrm1213    : data_array;
    signal ch32_otrm1415    : data_array;
   
begin

    -- DOWNWARD BRIDGE ENGINE
    AXI_TO_TX_BRIDGE_INST: entity work.AXI_To_Tx_Bridge
        port map (
            clk             => clk_10, reset => reset,
            m_axis_tdata    => s_axis_tdata, m_axis_tvalid => s_axis_tvalid,
            m_axis_tready   => s_axis_tready, m_axis_tlast => s_axis_tlast,
            mode_data       => local_mode_data, main_red_data => main_red_out,
            azimuth_fp32    => open, elevation_fp32 => open,
            freq1 => open, freq2 => open, freq3 => open, freq4 => open,
            RFIF_CTRL_SW    => RFIF_CTRL_SW, RFIF_CAL_IN => RFIF_CAL_IN, 
            Pa_LSB          => local_Pa_LSB, Pa_MSB => local_Pa_MSB,
            Pb_LSB          => local_Pb_LSB, Pb_MSB => local_Pb_MSB,
            otrm01_32ch => ch32_otrm01, otrm23_32ch => ch32_otrm23,
            otrm45_32ch => ch32_otrm45, otrm67_32ch => ch32_otrm67,
            otrm89_32ch => ch32_otrm89, otrm1011_32ch => ch32_otrm1011,
            otrm1213_32ch => ch32_otrm1213, otrm1415_32ch => ch32_otrm1415
        );

    ---------------------------------------------------------------------------
    -- CHANNEL 0: Explicit Structural Routing (Maps to Channel ID 1)
    ---------------------------------------------------------------------------
    TX_INST_CH0: entity work.Tx_Channel
        port map (
            clk_10 => clk_10, reset => reset, channel_id => 1, 
            tx_out => TX_OUT_32(0), tx_done => open, sob_in => sob_in, 
            curr_byte_out => tx_data_32(0), mode_data_out       => local_mode_data, 
            OTRM01 => ch32_otrm01(0), OTRM23 => ch32_otrm23(0), OTRM45 => ch32_otrm45(0), OTRM67 => ch32_otrm67(0),
            OTRM89 => ch32_otrm89(0), OTRM1011 => ch32_otrm1011(0), OTRM1213 => ch32_otrm1213(0), OTRM1415 => ch32_otrm1415(0),
            Pa_LSB1 => local_Pa_LSB, Pa_MSB1 => local_Pa_MSB, Pb_LSB1 => local_Pb_LSB, Pb_MSB1 => local_Pb_MSB
        );

    RX_INST_CH0: entity work.Rx_GC_To_ABCU
        port map (
            clk_200 => clk_200, reset => reset, rx_in => RX_IN_32(0),
            byte_cntrx => rx_bytes_total(0), error_cnt => rx_errors_total(0), rx_data_out => rx_data_32(0),
            pkt1_valid_pulse => ch0_pkt1_valid,
            pkt2_valid_pulse => ch0_pkt2_valid,
            pkt1_data_out    => ch0_pkt1_data,
            pkt2_data_out    => ch0_pkt2_data
        );

    ---------------------------------------------------------------------------
    -- CHANNEL 9: Explicit Structural Routing (Array Index 8 maps to Channel ID 9)
    ---------------------------------------------------------------------------
    TX_INST_CH8: entity work.Tx_Channel
        port map (
            clk_10 => clk_10, reset => reset, channel_id => 9, 
            tx_out => TX_OUT_32(8), tx_done => open, sob_in => sob_in, 
            curr_byte_out => tx_data_32(8), mode_data_out       => local_mode_data,
            OTRM01 => ch32_otrm01(8), OTRM23 => ch32_otrm23(8), OTRM45 => ch32_otrm45(8), OTRM67 => ch32_otrm67(8),
            OTRM89 => ch32_otrm89(8), OTRM1011 => ch32_otrm1011(8), OTRM1213 => ch32_otrm1213(8), OTRM1415 => ch32_otrm1415(8),
            Pa_LSB1 => local_Pa_LSB, Pa_MSB1 => local_Pa_MSB, Pb_LSB1 => local_Pb_LSB, Pb_MSB1 => local_Pb_MSB
        );

    RX_INST_CH8: entity work.Rx_GC_To_ABCU
        port map (
            clk_200 => clk_200, reset => reset, rx_in => RX_IN_32(8),
            byte_cntrx => rx_bytes_total(8), error_cnt => rx_errors_total(8), rx_data_out => rx_data_32(8),
            pkt1_valid_pulse => ch9_pkt1_valid,
            pkt2_valid_pulse => ch9_pkt2_valid,
            pkt1_data_out    => ch9_pkt1_data,
            pkt2_data_out    => ch9_pkt2_data
        );

    ---------------------------------------------------------------------------
    -- UPWARD TELEMETRY BRIDGE ENGINE: Streams diagnostic data back up to the PC
    ---------------------------------------------------------------------------
        ---------------------------------------------------------------------------
    -- UPWARD TELEMETRY BRIDGE ENGINE: Streams diagnostic data back up to the PC
    ---------------------------------------------------------------------------
    RX_BRIDGE_INST: entity work.Rx_To_AXI_Bridge
        port map (
            clk              => clk_200,
            reset            => reset,
            
            -- Pass the updated split-signal networks into your telemetry system ports
            rx_pkt1_valid    => ch0_pkt1_valid, 
            rx_pkt2_valid    => ch0_pkt2_valid,
            ch9_pkt1_valid   => ch9_pkt1_valid,  
            ch9_pkt2_valid   => ch9_pkt2_valid,
            
            rx_pkt1_data     => ch0_pkt1_data,
            rx_pkt2_data     => ch0_pkt2_data,
            ch9_pkt1_data    => ch9_pkt1_data,
            ch9_pkt2_data    => ch9_pkt2_data, 
            
            m_axis_tdata     => m_axis_tdata,
            m_axis_tvalid    => m_axis_tvalid,
            m_axis_tready    => m_axis_tready,
            m_axis_tlast     => m_axis_tlast,
            
            Pa_LSB_out       => Pa_LSB_out,
            Pa_MSB_out       => Pa_MSB_out,
            Pb_LSB_out       => Pb_LSB_out,
            Pb_MSB_out       => Pb_MSB_out,
            byte12_out       => byte12_out,
            byte13_out       => byte13_out,
            byte12_9         => byte12_9,
            byte13_9         => byte13_9,
             RFIF_FWD_PWR_STS => RFIF_FWD_PWR_STS,
             RFIF_SLB_OUT_STS => RFIF_SLB_OUT_STS,
             RFIF_TEMP_STS  => RFIF_TEMP_STS,
             RFIF_AMP_CAL_STS  => RFIF_AMP_CAL_STS,
             RFIF_PATH_CAL_STS   => RFIF_PATH_CAL_STS
        );


    ---------------------------------------------------------------------------
    -- CHANNELS 1 to 31: Parallel Structural Compiler (Skips Index 0 and Index 8)
    ---------------------------------------------------------------------------
    GEN_CHANNELS: for i in 1 to 31 generate
        GEN_SKIP_CH9: if i /= 8 generate
            TX_INST: entity work.Tx_Channel
                port map (
                    clk_10 => clk_10, reset => reset, channel_id => (i + 1),  mode_data_out       => local_mode_data,
                    tx_out => TX_OUT_32(i), tx_done => open, sob_in => sob_in, curr_byte_out => tx_data_32(i),
                    OTRM01 => ch32_otrm01(i), OTRM23 => ch32_otrm23(i), OTRM45 => ch32_otrm45(i), OTRM67 => ch32_otrm67(i),
                    OTRM89 => ch32_otrm89(i), OTRM1011 => ch32_otrm1011(i), OTRM1213 => ch32_otrm1213(i), OTRM1415 => ch32_otrm1415(i),
                    Pa_LSB1 => local_Pa_LSB, Pa_MSB1 => local_Pa_MSB, Pb_LSB1 => local_Pb_LSB, Pb_MSB1 => local_Pb_MSB
                );

            RX_INST: entity work.Rx_GC_To_ABCU
                port map (
                    clk_200 => clk_200, reset => reset, rx_in => RX_IN_32(i),
                    byte_cntrx => rx_bytes_total(i), error_cnt => rx_errors_total(i), rx_data_out => rx_data_32(i),
                    pkt1_valid_pulse => open, pkt2_valid_pulse => open,
                    pkt1_data_out => open, pkt2_data_out => open
                );
        end generate;
    end generate;
    mode_data_out <= local_mode_data; 

end Structural;
