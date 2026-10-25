library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ABCU_Package.all;

entity AXI_To_Tx_Bridge is
    Port ( 
        clk             : in  std_logic;
        reset           : in  std_logic; 
        m_axis_tdata    : in  std_logic_vector(31 downto 0);
        m_axis_tvalid   : in  std_logic;
        m_axis_tready   : out std_logic;
        m_axis_tlast    : in  std_logic;
        mode_data       : out std_logic_vector(7 downto 0);
        main_red_data   : out std_logic_vector(7 downto 0);
        azimuth_fp32    : out std_logic_vector(31 downto 0);
        elevation_fp32  : out std_logic_vector(31 downto 0);
        freq1           : out std_logic_vector(7 downto 0);
        freq2           : out std_logic_vector(7 downto 0);
        freq3           : out std_logic_vector(7 downto 0);
        freq4           : out std_logic_vector(7 downto 0);
        Pa_LSB          : out std_logic_vector(7 downto 0);
        Pa_MSB          : out std_logic_vector(7 downto 0);
        Pb_MSB          : out std_logic_vector(7 downto 0);
        Pb_LSB          : out std_logic_vector(7 downto 0);
        RFIF_CTRL_SW    : out std_logic;
        RFIF_CAL_IN      : out std_logic;
        otrm01_32ch     : out data_array;
        otrm23_32ch     : out data_array;
        otrm45_32ch     : out data_array;
        otrm67_32ch     : out data_array;
        otrm89_32ch     : out data_array;
        otrm1011_32ch   : out data_array;
        otrm1213_32ch   : out data_array;
        otrm1415_32ch   : out data_array
    );
end AXI_To_Tx_Bridge;

architecture Behavioral of AXI_To_Tx_Bridge is
    type state_type is (INIT_STABILIZE, CAPTURE_HEADER, GC_WORD_A, GC_WORD_B, GC_WORD_C);
signal state : state_type := INIT_STABILIZE;

    signal word_counter   : integer range 0 to 255 := 0;
    signal startup_timer  : integer range 0 to 1023 := 0;
    signal rfif_ctrl_reg, rfif_cal_reg  : std_logic := '0';
    signal bridge_ready   : std_logic := '0'; 

    type header_buffer_type is array (0 to 13) of std_logic_vector(31 downto 0);
    signal header_buffer  : header_buffer_type := (others => (others => '0'));

    signal main_red       : std_logic_vector(7 downto 0) := (others => '0');
    signal p_mode         : std_logic_vector(7 downto 0) := (others => '0');
    signal p_azimuth      : std_logic_vector(31 downto 0) := (others => '0');
    signal p_elevation    : std_logic_vector(31 downto 0) := (others => '0');
    signal p_frequency    : std_logic_vector(31 downto 0) := (others => '0');

    signal active_gc_id   : integer range 0 to 255 := 0;
    signal saved_word_b   : std_logic_vector(31 downto 0) := (others => '0');

    signal reg_otrm01     : data_array := (others => (others => '0'));
    signal reg_otrm23     : data_array := (others => (others => '0'));
    signal reg_otrm45     : data_array := (others => (others => '0'));
    signal reg_otrm67     : data_array := (others => (others => '0'));
    signal reg_otrm89     : data_array := (others => (others => '0'));
    signal reg_otrm1011   : data_array := (others => (others => '0'));
    signal reg_otrm1213   : data_array := (others => (others => '0'));
    signal reg_otrm1415   : data_array := (others => (others => '0'));

    -- --- FLAT TRACE ALIASES FOR THE AUTOMATED WIZARD ---
    -- We extract Channel 1 (index 0) into flat vectors so the wizard can hook onto them
    signal ch1_debug_otrm01   : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm23   : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm45   : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm67   : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm89   : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm1011 : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm1213 : std_logic_vector(7 downto 0);
    signal ch1_debug_otrm1415 : std_logic_vector(7 downto 0);

    -- =========================================================================
    -- --- AUTOMATED SET UP DEBUG ATTRIBUTES FIREWALL ---
    -- =========================================================================
    attribute mark_debug : string;
    attribute dont_touch : string;

    -- Protect core data parameters from being optimized or dissolved
    attribute mark_debug of p_azimuth      : signal is "true";
    attribute dont_touch of p_azimuth      : signal is "true";
    attribute mark_debug of p_elevation    : signal is "true";
    attribute dont_touch of p_elevation    : signal is "true";
    attribute mark_debug of rfif_ctrl_reg  : signal is "true";
    attribute dont_touch of rfif_ctrl_reg  : signal is "true";

    -- Protect our flat array slice nodes so the wizard can scan them cleanly
    attribute mark_debug of ch1_debug_otrm01   : signal is "true";
    attribute dont_touch of ch1_debug_otrm01   : signal is "true";
    attribute mark_debug of ch1_debug_otrm23   : signal is "true";
    attribute dont_touch of ch1_debug_otrm23   : signal is "true";
    attribute mark_debug of ch1_debug_otrm45   : signal is "true";
    attribute dont_touch of ch1_debug_otrm45   : signal is "true";
    attribute mark_debug of ch1_debug_otrm67   : signal is "true";
    attribute dont_touch of ch1_debug_otrm67   : signal is "true";
    attribute mark_debug of ch1_debug_otrm89   : signal is "true";
    attribute dont_touch of ch1_debug_otrm89   : signal is "true";
    attribute mark_debug of ch1_debug_otrm1011 : signal is "true";
    attribute dont_touch of ch1_debug_otrm1011 : signal is "true";
    attribute mark_debug of ch1_debug_otrm1213 : signal is "true";
    attribute dont_touch of ch1_debug_otrm1213 : signal is "true";
    attribute mark_debug of ch1_debug_otrm1415 : signal is "true";
    attribute dont_touch of ch1_debug_otrm1415 : signal is "true";

    -- Helpful sideband signals to use as trigger triggers in Hardware Manager
    attribute mark_debug of state          : signal is "true";
    attribute mark_debug of m_axis_tlast   : signal is "true";
-- Add these internal signal registers inside your architecture declarations space:
    signal history_Pa : std_logic_vector(31 downto 0) := (others => '0');
    signal history_Pb : std_logic_vector(31 downto 0) := (others => '0');
 -- Add this single signal to your architecture declarations space:
 -- Add this single signal register inside your architecture declarations space:
 signal session_locked : std_logic := '0';
 
 begin
 
     -- Keep m_axis_tready open and tracking bridge_ready continuously as specified
  m_axis_tready <= bridge_ready;
    
     process(clk)
         variable v_gc_idx : integer range 0 to 31 := 0;
     begin
         if reset = '0' then
             state          <= INIT_STABILIZE;
             word_counter   <= 0; startup_timer  <= 0; bridge_ready   <= '0'; rfif_ctrl_reg  <= '0';
             main_red       <= (others => '0'); p_mode <= (others => '0');
             p_azimuth      <= (others => '0'); p_elevation <= (others => '0'); p_frequency <= (others => '0');
             saved_word_b   <= (others => '0'); active_gc_id   <= 0;
             reg_otrm01     <= (others => (others => '0')); reg_otrm23     <= (others => (others => '0'));
             reg_otrm45     <= (others => (others => '0')); reg_otrm67     <= (others => (others => '0'));
             reg_otrm89     <= (others => (others => '0')); reg_otrm1011   <= (others => (others => '0'));
             reg_otrm1213   <= (others => (others => '0')); reg_otrm1415   <= (others => (others => '0'));
             history_Pa     <= (others => '0'); history_Pb     <= (others => '0');
             session_locked <= '0';
             rfif_cal_reg   <= '0'; 
             
         elsif rising_edge(clk) then
             if startup_timer < 100 then
                 startup_timer <= startup_timer + 1; bridge_ready  <= '0'; state <= INIT_STABILIZE;
             else
                 bridge_ready  <= '1';
                 if state = INIT_STABILIZE then state <= CAPTURE_HEADER; word_counter <= 0; end if;
             end if;
    
             if bridge_ready = '1' and m_axis_tvalid = '1' then
                 case state is
                     when INIT_STABILIZE =>
                         state        <= CAPTURE_HEADER; word_counter <= 0;
    
                     when CAPTURE_HEADER =>
                         -- Catch early TLAST if a short control packet terminates early
                         if m_axis_tlast = '1' then
                             state        <= CAPTURE_HEADER;
                             word_counter <= 0;
                         else
                             if word_counter <= 9 then
                                 null;
                                 
                             elsif word_counter = 10 then
                                 -- IDENTIFIER CHECK
                                 if (m_axis_tdata(31 downto 16) = x"AAA1") then
                                     session_locked <= '1'; 
                                 else
                                     session_locked <= '0'; 
                                 end if;
                             
                             elsif word_counter = 11 then
                                 if session_locked = '1' then
                                     main_red <= m_axis_tdata(31 downto 24);
                                     p_mode   <= m_axis_tdata(23 downto 16);
                                     
                                     
                                     
                                     if (m_axis_tdata(31 downto 24) = x"01") then 
                                         rfif_ctrl_reg <= '1';
                                     else
                                         rfif_ctrl_reg <= '0';
                                     end if;
                                 end if;
    
                             elsif word_counter = 12 then
                                 if session_locked = '1' then 
                                     history_Pa <= m_axis_tdata; 
                                 end if;
                             
                             elsif word_counter = 13 then
                                 if session_locked = '1' then 
                                     history_Pb <= m_axis_tdata; 
                                 end if;
                                 
                             elsif word_counter = 14 then
                                 if session_locked = '1' then 
                                     p_frequency <= m_axis_tdata; 
                                     p_azimuth   <= history_Pa;
                                     p_elevation <= history_Pb;
                                 end if;
                             end if;
    
                             -- Word iteration sequencing logic
                             if word_counter < 14 then
                                 word_counter <= word_counter + 1;
                             else
                                 word_counter <= 0; 
                                 state        <= GC_WORD_A; -- FIXED: Go to data states unconditionally so OTRM data always processes!
                             end if;
                         end if;
    
                     when GC_WORD_A =>
                         active_gc_id <= to_integer(unsigned(m_axis_tdata(7 downto 0)));
                         
                         if m_axis_tlast = '1' then 
                             state          <= CAPTURE_HEADER; 
                             word_counter   <= 0; 
                         else 
                             state          <= GC_WORD_B; 
                         end if;
    
                     when GC_WORD_B =>
                         saved_word_b <= m_axis_tdata;
                         
                         if m_axis_tlast = '1' then 
                             state          <= CAPTURE_HEADER; 
                             word_counter   <= 0; 
                         else 
                             state          <= GC_WORD_C; 
                         end if;
    
                     when GC_WORD_C =>
                         if active_gc_id >= 1 and active_gc_id <= 32 then
                             v_gc_idx := active_gc_id - 1; 
                             reg_otrm01(v_gc_idx)   <= saved_word_b(7 downto 0);     
                             reg_otrm23(v_gc_idx)   <= saved_word_b(15 downto 8);
                             reg_otrm45(v_gc_idx)   <= saved_word_b(23 downto 16);    
                             reg_otrm67(v_gc_idx)   <= saved_word_b(31 downto 24);
                             reg_otrm89(v_gc_idx)   <= m_axis_tdata(7 downto 0);     
                             reg_otrm1011(v_gc_idx) <= m_axis_tdata(15 downto 8);
                             reg_otrm1213(v_gc_idx) <= m_axis_tdata(23 downto 16);    
                             reg_otrm1415(v_gc_idx) <= m_axis_tdata(31 downto 24);
                         end if;
                         
                         if m_axis_tlast = '1' then 
                             state          <= CAPTURE_HEADER;  
                             word_counter   <= 0; 
                         else 
                             state          <= GC_WORD_A; 
                         end if;
    
                     when others => 
                         state          <= CAPTURE_HEADER; 
                         word_counter   <= 0;
                 end case;
             end if;
         end if;
     end process;
     
     RFIF_CAL_IN <= rfif_cal_reg;



 RFIF_CTRL_SW <= rfif_ctrl_reg; main_red_data <= main_red; mode_data <= p_mode; azimuth_fp32 <= p_azimuth; elevation_fp32 <= p_elevation;
    Pa_MSB <= p_azimuth(23 downto 16);   Pa_LSB <= p_azimuth(7 downto 0);
    Pb_MSB <= p_elevation(23 downto 16); Pb_LSB <= p_elevation(7 downto 0);
    freq1 <= p_frequency(31 downto 24);  freq2 <= p_frequency(23 downto 16); freq3 <= p_frequency(15 downto 8); freq4 <= p_frequency(7 downto 0);
    otrm01_32ch <= reg_otrm01; otrm23_32ch <= reg_otrm23; otrm45_32ch <= reg_otrm45; otrm67_32ch <= reg_otrm67;
    otrm89_32ch <= reg_otrm89; otrm1011_32ch <= reg_otrm1011; otrm1213_32ch <= reg_otrm1213; otrm1415_32ch <= reg_otrm1415;
    -- Continuous trace connections (Maps Matrix Index 0 -> Channel 1 data lanes)
    ch1_debug_otrm01   <= reg_otrm01(0);   ch1_debug_otrm23   <= reg_otrm23(0);
    ch1_debug_otrm45   <= reg_otrm45(0);   ch1_debug_otrm67   <= reg_otrm67(0);
    ch1_debug_otrm89   <= reg_otrm89(0);   ch1_debug_otrm1011 <= reg_otrm1011(0);
    ch1_debug_otrm1213 <= reg_otrm1213(0); ch1_debug_otrm1415 <= reg_otrm1415(0);
    end Behavioral;
