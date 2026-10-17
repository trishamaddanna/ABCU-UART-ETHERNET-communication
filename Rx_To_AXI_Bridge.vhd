library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ABCU_Package.all;

entity Rx_To_AXI_Bridge is
    Port (
        clk              : in  std_logic; 
        reset            : in  std_logic; -- Active-low global hardware reset
        
        -- Sideband inputs matched perfectly to the Dual-Pulse Receiver rails
        rx_pkt1_valid    : in  std_logic;      -- Channel 0 OTRM (Packet 1) Strobe
        rx_pkt2_valid    : in  std_logic;      -- Channel 0 Phase (Packet 2) Strobe
        ch9_pkt1_valid   : in  std_logic;      -- Channel 9 OTRM (Packet 1) Strobe
        ch9_pkt2_valid   : in  std_logic;      -- Channel 9 Phase (Packet 2) Strobe
        
        rx_pkt1_data     : in  temp_pkt_type;  -- Channel 0 Packet 1 Array Content
        rx_pkt2_data     : in  temp_pkt_type;  -- Channel 0 Packet 2 Array Content
        ch9_pkt1_data    : in  temp_pkt_type;  -- Channel 9 Packet 1 Array Content
        ch9_pkt2_data    : in  temp_pkt_type;  -- Channel 9 Packet 2 Array Content

        -- AXI-Stream Master Interface (7-Word Burst Output)
        m_axis_tdata     : out std_logic_vector(31 downto 0);
        m_axis_tvalid    : out std_logic;
        m_axis_tready    : in  std_logic;
        m_axis_tlast     : out std_logic;

        -- Persistent Top-Level Wire Parameter Rails
        Pa_LSB_out       : out std_logic_vector(7 downto 0);
        Pa_MSB_out       : out std_logic_vector(7 downto 0);
        Pb_LSB_out       : out std_logic_vector(7 downto 0);
        Pb_MSB_out       : out std_logic_vector(7 downto 0);
        byte12_out       : out std_logic_vector(7 downto 0);
        byte13_out       : out std_logic_vector(7 downto 0);
        byte12_9         : out std_logic_vector(7 downto 0);
        byte13_9         : out std_logic_vector(7 downto 0);

        -- Inward Real-time Status Lines
        RFIF_FWD_PWR_STS : in  std_logic;
        RFIF_SLB_OUT_STS : in  std_logic;
        RFIF_TEMP_STS    : in  std_logic;
        RFIF_AMP_CAL_STS : in  std_logic;
        RFIF_PATH_CAL_STS: in  std_logic
    );
end Rx_To_AXI_Bridge;

architecture Behavioral of Rx_To_AXI_Bridge is
    type bridge_state_type is (IDLE, STREAM_W1, STREAM_W2, STREAM_W3, STREAM_W4, STREAM_W5, STREAM_W6, STREAM_W7);
    signal state : bridge_state_type := IDLE;

    -- FIXED: Registered edge-tracking delayed signal
    signal rx_pkt2_valid_reg : std_logic := '0';

    signal buffered_ch9_12, buffered_ch9_13 : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_Pa_LSB, reg_Pa_MSB, reg_Pb_LSB, reg_Pb_MSB, reg_b12, reg_b13 : std_logic_vector(7 downto 0) := (others => '0');
    signal ch0_otrm01, ch0_otrm23, ch0_otrm45, ch0_otrm67, ch0_otrm89, ch0_otrm1011, ch0_otrm1213, ch0_otrm1415 : std_logic_vector(7 downto 0) := (others => '0');
    signal ch9_otrm01, ch9_otrm23, ch9_otrm45, ch9_otrm67, ch9_otrm89, ch9_otrm1011, ch9_otrm1213, ch9_otrm1415 : std_logic_vector(7 downto 0) := (others => '0');
    signal reg_fwd_pwr, reg_slb_out, reg_temp_sts, reg_amp_cal, reg_path_cal : std_logic := '0';

    -- SNAPSHOT STRUCTURES
    signal snap_Pa_LSB, snap_Pa_MSB, snap_Pb_LSB, snap_Pb_MSB, snap_b12, snap_b13, snap_ch9_12, snap_ch9_13 : std_logic_vector(7 downto 0) := (others => '0');
    signal snap_ch0_otrm01, snap_ch0_otrm23, snap_ch0_otrm45, snap_ch0_otrm67, snap_ch0_otrm89, snap_ch0_otrm1011, snap_ch0_otrm1213, snap_ch0_otrm1415 : std_logic_vector(7 downto 0) := (others => '0');
    signal snap_ch9_otrm01, snap_ch9_otrm23, snap_ch9_otrm45, snap_ch9_otrm67, snap_ch9_otrm89, snap_ch9_otrm1011, snap_ch9_otrm1213, snap_ch9_otrm1415 : std_logic_vector(7 downto 0) := (others => '0');
    signal snap_fwd_pwr, snap_slb_out, snap_temp_sts, snap_amp_cal, snap_path_cal : std_logic := '0';
begin

    process(clk, reset)
    begin
        if reset = '0' then
            state <= IDLE; reg_Pa_LSB <= (others => '0'); reg_Pa_MSB <= (others => '0'); reg_Pb_LSB <= (others => '0'); reg_Pb_MSB <= (others => '0');
            reg_b12 <= (others => '0'); reg_b13 <= (others => '0'); buffered_ch9_12 <= (others => '0'); buffered_ch9_13 <= (others => '0');
            ch0_otrm01 <= (others => '0'); ch0_otrm23 <= (others => '0'); ch0_otrm45 <= (others => '0'); ch0_otrm67 <= (others => '0');
            ch0_otrm89 <= (others => '0'); ch0_otrm1011 <= (others => '0'); ch0_otrm1213 <= (others => '0'); ch0_otrm1415 <= (others => '0');
            ch9_otrm01 <= (others => '0'); ch9_otrm23 <= (others => '0'); ch9_otrm45 <= (others => '0'); ch9_otrm67 <= (others => '0');
            ch9_otrm89 <= (others => '0'); ch9_otrm1011 <= (others => '0'); ch9_otrm1213 <= (others => '0'); ch9_otrm1415 <= (others => '0');
            reg_fwd_pwr <= '0'; reg_slb_out <= '0'; reg_temp_sts <= '0'; reg_amp_cal <= '0'; reg_path_cal <= '0';
            
            snap_Pa_LSB <= (others => '0'); snap_Pa_MSB <= (others => '0'); snap_Pb_LSB <= (others => '0'); snap_Pb_MSB <= (others => '0');
            snap_b12 <= (others => '0'); snap_b13 <= (others => '0'); snap_ch9_12 <= (others => '0'); snap_ch9_13 <= (others => '0');
            snap_ch0_otrm01 <= (others => '0'); snap_ch0_otrm23 <= (others => '0'); snap_ch0_otrm45 <= (others => '0'); snap_ch0_otrm67 <= (others => '0');
            snap_ch0_otrm89 <= (others => '0'); snap_ch0_otrm1011 <= (others => '0'); snap_ch0_otrm1213 <= (others => '0'); snap_ch0_otrm1415 <= (others => '0');
            snap_ch9_otrm01 <= (others => '0'); snap_ch9_otrm23 <= (others => '0'); snap_ch9_otrm45 <= (others => '0'); snap_ch9_otrm67 <= (others => '0');
            snap_ch9_otrm89 <= (others => '0'); snap_ch9_otrm1011 <= (others => '0'); snap_ch9_otrm1213 <= (others => '0'); snap_ch9_otrm1415 <= (others => '0');
            snap_fwd_pwr <= '0'; snap_slb_out <= '0'; snap_temp_sts <= '0'; snap_amp_cal <= '0'; snap_path_cal <= '0';
            rx_pkt2_valid_reg <= '0';
        elsif rising_edge(clk) then
            -- Register strobe history to calculate true edges
            rx_pkt2_valid_reg <= rx_pkt2_valid;

            if ch9_pkt1_valid = '1' then
                ch9_otrm01 <= ch9_pkt1_data(3); ch9_otrm23 <= ch9_pkt1_data(4); ch9_otrm45 <= ch9_pkt1_data(5); ch9_otrm67 <= ch9_pkt1_data(6);
                ch9_otrm89 <= ch9_pkt1_data(7); ch9_otrm1011 <= ch9_pkt1_data(8); ch9_otrm1213 <= ch9_pkt1_data(9); ch9_otrm1415 <= ch9_pkt1_data(10);
            end if;
            if ch9_pkt2_valid = '1' then buffered_ch9_12 <= ch9_pkt2_data(12); buffered_ch9_13 <= ch9_pkt2_data(13); end if;
            if rx_pkt1_valid = '1' then
                ch0_otrm01 <= rx_pkt1_data(3); ch0_otrm23 <= rx_pkt1_data(4); ch0_otrm45 <= rx_pkt1_data(5); ch0_otrm67 <= rx_pkt1_data(6);
                ch0_otrm89 <= rx_pkt1_data(7); ch0_otrm1011 <= rx_pkt1_data(8); ch0_otrm1213 <= rx_pkt1_data(9); ch0_otrm1415 <= rx_pkt1_data(10);
            end if;
            
            if rx_pkt2_valid = '1' then
                reg_Pa_LSB <= rx_pkt2_data(7);   reg_Pa_MSB <= rx_pkt2_data(8);   reg_Pb_LSB <= rx_pkt2_data(9);   reg_Pb_MSB <= rx_pkt2_data(10);  
                reg_b12    <= rx_pkt2_data(12);  reg_b13    <= rx_pkt2_data(13);
                reg_fwd_pwr <= RFIF_FWD_PWR_STS; reg_slb_out <= RFIF_SLB_OUT_STS; reg_temp_sts <= RFIF_TEMP_STS; reg_amp_cal <= RFIF_AMP_CAL_STS; reg_path_cal <= RFIF_PATH_CAL_STS;
            end if;

            -- FIXED SHIELD STROBE: Triggers snapshots only on the absolute low-to-high transition edge
            if rx_pkt2_valid = '1'  and rx_pkt2_valid_reg = '0'  and state = IDLE then
                snap_Pa_LSB <= rx_pkt2_data(7);   snap_Pa_MSB <= rx_pkt2_data(8);   
                snap_Pb_LSB <= rx_pkt2_data(9);   snap_Pb_MSB <= rx_pkt2_data(10);  
                snap_b12    <= rx_pkt2_data(12);  snap_b13    <= rx_pkt2_data(13);  
                snap_ch9_12 <= ch9_pkt2_data(12); snap_ch9_13 <= ch9_pkt2_data(13);
                
                snap_ch0_otrm01 <= ch0_otrm01; snap_ch0_otrm23 <= ch0_otrm23; 
                snap_ch0_otrm45 <= ch0_otrm45; snap_ch0_otrm67 <= ch0_otrm67;
                snap_ch0_otrm89 <= ch0_otrm89; snap_ch0_otrm1011 <= ch0_otrm1011; 
                snap_ch0_otrm1213 <= ch0_otrm1213; snap_ch0_otrm1415 <= ch0_otrm1415;
                
                snap_ch9_otrm01 <= ch9_otrm01; snap_ch9_otrm23 <= ch9_otrm23; 
                snap_ch9_otrm45 <= ch9_otrm45; snap_ch9_otrm67 <= ch9_otrm67;
                snap_ch9_otrm89 <= ch9_otrm89; snap_ch9_otrm1011 <= ch9_otrm1011; 
                snap_ch9_otrm1213 <= ch9_otrm1213; snap_ch9_otrm1415 <= ch9_otrm1415;
                
                snap_fwd_pwr <= RFIF_FWD_PWR_STS; snap_slb_out <= RFIF_SLB_OUT_STS; 
                snap_temp_sts <= RFIF_TEMP_STS; snap_amp_cal <= RFIF_AMP_CAL_STS; snap_path_cal <= RFIF_PATH_CAL_STS;
            end if;

            case state is
                when IDLE => 
                    -- FIXED EDGE TRIGGER: Requires a true rising edge pulse to exit IDLE
                    if rx_pkt2_valid = '1'  and rx_pkt2_valid_reg = '0' then 
                        state <= STREAM_W1; 
                    end if;
                when STREAM_W1 => if m_axis_tready = '1' then state <= STREAM_W2; end if;
                when STREAM_W2 => if m_axis_tready = '1' then state <= STREAM_W3; end if;
                when STREAM_W3 => if m_axis_tready = '1' then state <= STREAM_W4; end if;
                when STREAM_W4 => if m_axis_tready = '1' then state <= STREAM_W5; end if;
                when STREAM_W5 => if m_axis_tready = '1' then state <= STREAM_W6; end if;
                when STREAM_W6 => if m_axis_tready = '1' then state <= STREAM_W7; end if; 
                when STREAM_W7 => 
                    if m_axis_tready = '1' then 
                        state <= IDLE; -- Safely cycles out; blocked from double-triggering by edge-reg
                    end if;
                when others => state <= IDLE;
            end case;
        end if;
    end process;




    process(state, snap_Pa_LSB, snap_Pa_MSB, snap_Pb_LSB, snap_Pb_MSB, snap_b12, snap_b13, snap_ch9_12, snap_ch9_13,
            snap_ch0_otrm01, snap_ch0_otrm23, snap_ch0_otrm45, snap_ch0_otrm67, snap_ch0_otrm89, snap_ch0_otrm1011, snap_ch0_otrm1213, snap_ch0_otrm1415,
            snap_ch9_otrm01, snap_ch9_otrm23, snap_ch9_otrm45, snap_ch9_otrm67, snap_ch9_otrm89, snap_ch9_otrm1011, snap_ch9_otrm1213, snap_ch9_otrm1415,
            snap_fwd_pwr, snap_slb_out, snap_temp_sts, snap_amp_cal, snap_path_cal)
    begin
        case state is
            when IDLE => m_axis_tdata <= (others => '0'); m_axis_tvalid <= '0'; m_axis_tlast <= '0';
            when STREAM_W1 => m_axis_tdata <= snap_Pb_MSB & snap_Pb_LSB & snap_Pa_MSB & snap_Pa_LSB; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W2 => m_axis_tdata <= snap_ch9_13 & snap_ch9_12 & snap_b13 & snap_b12; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W3 => m_axis_tdata <= snap_ch0_otrm67 & snap_ch0_otrm45 & snap_ch0_otrm23 & snap_ch0_otrm01; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W4 => m_axis_tdata <= snap_ch0_otrm1415 & snap_ch0_otrm1213 & snap_ch0_otrm1011 & snap_ch0_otrm89; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W5 => m_axis_tdata <= snap_ch9_otrm67 & snap_ch9_otrm45 & snap_ch9_otrm23 & snap_ch9_otrm01; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W6 => m_axis_tdata <= snap_ch9_otrm1415 & snap_ch9_otrm1213 & snap_ch9_otrm1011 & snap_ch9_otrm89; m_axis_tvalid <= '1'; m_axis_tlast <= '0';
            when STREAM_W7 =>
               m_axis_tdata(31 downto 5) <= (others => '0'); m_axis_tdata(4) <= snap_amp_cal; m_axis_tdata(3) <= snap_path_cal;
               m_axis_tdata(2) <= snap_temp_sts; m_axis_tdata(1) <= snap_slb_out; m_axis_tdata(0) <= snap_fwd_pwr;
               m_axis_tvalid <= '1'; m_axis_tlast <= '1'; 
        end case;
    end process;

    byte12_9 <= buffered_ch9_12; byte13_9 <= buffered_ch9_13; Pa_LSB_out <= reg_Pa_LSB; Pa_MSB_out <= reg_Pa_MSB; Pb_LSB_out <= reg_Pb_LSB; Pb_MSB_out <= reg_Pb_MSB; byte12_out <= reg_b12; byte13_out <= reg_b13;
end Behavioral;
