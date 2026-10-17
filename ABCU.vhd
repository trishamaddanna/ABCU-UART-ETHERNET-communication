----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.03.2026 09:17:11
-- Design Name: 
-- Module Name: ABCU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
Library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ABCU is
 Port (
--        system_200MHz_OUT_P      : in  std_logic;
--        system_200MHz_OUT_N      : in  std_logic;
--        FPGA_POR                 : in  std_logic;
        EXRX_RST_FPGA            :in  std_logic;
        EXRX_PRT_FPGA            :in  std_logic;
        EXRX_SOB_FPGA            :in  std_logic;
        
        RST_PLANK1_FPGA  : out  std_logic;
        RST_PLANK2_FPGA  : out  std_logic;
        RST_PLANK3_FPGA  : out  std_logic;
        RST_PLANK4_FPGA  : out  std_logic;
        
        PRT_PLANK1_FPGA  : out  std_logic;
        PRT_PLANK2_FPGA  : out  std_logic;
        PRT_PLANK3_FPGA  : out  std_logic;
        PRT_PLANK4_FPGA  : out  std_logic;
        
        SOB_PLANK1_FPGA  :out  std_logic;
        SOB_PLANK2_FPGA  :out  std_logic;
        SOB_PLANK3_FPGA  :out  std_logic;
        SOB_PLANK4_FPGA  :out  std_logic;
        
         -- Port 1 physical pins
        SDO_PLANK1_FPGA   : in  std_logic;
        SDI_PLANK1_FPGA   : out std_logic;
        
         -- Port 2 physical pins
        SDO_PLANK2_FPGA   : in  std_logic;
        SDI_PLANK2_FPGA   : out std_logic;
        
         -- Port 3 physical pins
        SDO_PLANK3_FPGA   : in  std_logic;
        SDI_PLANK3_FPGA   : out std_logic;
        
         -- Port 4 physical pins
        SDO_PLANK4_FPGA   : in  std_logic;
        SDI_PLANK4_FPGA   : out std_logic;
        
         -- Port 5 physical pins
        SDO_PLANK5_FPGA   : in  std_logic;
        SDI_PLANK5_FPGA   : out std_logic;
        
         -- Port 6 physical pins
        SDO_PLANK6_FPGA   : in  std_logic;
        SDI_PLANK6_FPGA   : out std_logic;
         -- Port 7 physical pins
        SDO_PLANK7_FPGA   : in  std_logic;
        SDI_PLANK7_FPGA   : out std_logic;
         -- Port 8 physical pins
        SDO_PLANK8_FPGA   : in  std_logic;
        SDI_PLANK8_FPGA   : out std_logic;
         -- Port 9 physical pins
        SDO_PLANK9_FPGA   : in  std_logic;
        SDI_PLANK9_FPGA   : out std_logic;
         -- Port 10 physical pins
        SDO_PLANK10_FPGA   : in  std_logic;
        SDI_PLANK10_FPGA   : out std_logic;
         -- Port 11 physical pins
        SDO_PLANK11_FPGA   : in  std_logic;
        SDI_PLANK11_FPGA   : out std_logic;
         -- Port 12 physical pins
        SDO_PLANK12_FPGA   : in  std_logic;
        SDI_PLANK12_FPGA   : out std_logic;    
         -- Port 13 physical pins
        SDO_PLANK13_FPGA   : in  std_logic;
        SDI_PLANK13_FPGA   : out std_logic;
         -- Port 14 physical pins
        SDO_PLANK14_FPGA   : in  std_logic;
        SDI_PLANK14_FPGA   : out std_logic;
         -- Port 15 physical pins
        SDO_PLANK15_FPGA   : in  std_logic;
        SDI_PLANK15_FPGA   : out std_logic;
         -- Port 16 physical pins
        SDO_PLANK16_FPGA   : in  std_logic;
        SDI_PLANK16_FPGA   : out std_logic;
         -- Port 17 physical pins
        SDO_PLANK17_FPGA   : in  std_logic;
        SDI_PLANK17_FPGA   : out std_logic;
         -- Port 18 physical pins
        SDO_PLANK18_FPGA   : in  std_logic;
        SDI_PLANK18_FPGA   : out std_logic;        
         -- Port 19 physical pins
        SDO_PLANK19_FPGA   : in  std_logic;
        SDI_PLANK19_FPGA   : out std_logic;
         -- Port 20 physical pins
        SDO_PLANK20_FPGA   : in  std_logic;
        SDI_PLANK20_FPGA   : out std_logic;
         -- Port 21 physical pins
        SDO_PLANK21_FPGA   : in  std_logic;
        SDI_PLANK21_FPGA   : out std_logic;
         -- Port 22 physical pins
        SDO_PLANK22_FPGA   : in  std_logic;
        SDI_PLANK22_FPGA   : out std_logic;
         -- Port 23 physical pins
        SDO_PLANK23_FPGA   : in  std_logic;
        SDI_PLANK23_FPGA   : out std_logic;
         -- Port 24 physical pins
        SDO_PLANK24_FPGA   : in  std_logic;
        SDI_PLANK24_FPGA   : out std_logic;
         -- Port 25 physical pins
        SDO_PLANK25_FPGA   : in  std_logic;
        SDI_PLANK25_FPGA   : out std_logic;
         -- Port 26 physical pins
        SDO_PLANK26_FPGA   : in  std_logic;
        SDI_PLANK26_FPGA   : out std_logic;        
         -- Port 27 physical pins
        SDO_PLANK27_FPGA   : in  std_logic;
        SDI_PLANK27_FPGA   : out std_logic;
         -- Port 28 physical pins
        SDO_PLANK28_FPGA   : in  std_logic;
        SDI_PLANK28_FPGA   : out std_logic;
         -- Port 29 physical pins
        SDO_PLANK29_FPGA   : in  std_logic;
        SDI_PLANK29_FPGA   : out std_logic;
         -- Port 30 physical pins
        SDO_PLANK30_FPGA   : in  std_logic;
        SDI_PLANK30_FPGA   : out std_logic;
         -- Port 31 physical pins
        SDO_PLANK31_FPGA   : in  std_logic;
        SDI_PLANK31_FPGA   : out std_logic;
         -- Port 32 physical pins
        SDO_PLANK32_FPGA   : in  std_logic;
        SDI_PLANK32_FPGA   : out std_logic;
--         p0                : in std_logic_vector(7 downto 0);
--         p1                : in std_logic_vector(7 downto 0);
--         frequency1  : in std_logic_vector(7 downto 0);
--         frequency2  : in std_logic_vector(7 downto 0);
--         frequency3  : in std_logic_vector(7 downto 0);
--         frequency4  : in std_logic_vector(7 downto 0);
--        Pa_LSB          : in std_logic_vector(7 downto 0);
--        Pa_MSB          : in std_logic_vector(7 downto 0);
--        Pb_MSB          : in std_logic_vector(7 downto 0);
--        Pb_LSB          : in std_logic_vector(7 downto 0);
--        main_red_data   : in std_logic_vector(7 downto 0);
          reset            : in std_logic;
          clk_10M        : in std_logic; 
          clk_200M       : in std_logic;
           clk_100M       : in std_logic;
            rx_data_8_1, rx_data_8_2, rx_data_8_3, rx_data_8_4, rx_data_8_5,rx_data_8_6,rx_data_8_7,rx_data_8_8,rx_data_8_9,rx_data_8_10: out std_logic_vector(7 downto 0);
             rx_data_8_11, rx_data_8_12, rx_data_8_13, rx_data_8_14, rx_data_8_15,rx_data_8_16,rx_data_8_17,rx_data_8_18,rx_data_8_19,rx_data_8_20: out std_logic_vector(7 downto 0);
             rx_data_8_21, rx_data_8_22, rx_data_8_23, rx_data_8_24, rx_data_8_25,rx_data_8_26,rx_data_8_27,rx_data_8_28,rx_data_8_29,rx_data_8_30: out std_logic_vector(7 downto 0);
             rx_data_8_31, rx_data_8_32 : out std_logic_vector(7 downto 0);
              tx_data_8_1, tx_data_8_2,tx_data_8_3, tx_data_8_4, tx_data_8_5,tx_data_8_6,tx_data_8_7,tx_data_8_8,tx_data_8_9,tx_data_8_10: out std_logic_vector(7 downto 0);
              tx_data_8_11,tx_data_8_12,tx_data_8_13,tx_data_8_14, tx_data_8_15,tx_data_8_16,tx_data_8_17,tx_data_8_18,tx_data_8_19,tx_data_8_20: out std_logic_vector(7 downto 0);
              tx_data_8_21,tx_data_8_22,tx_data_8_23,tx_data_8_24, tx_data_8_25,tx_data_8_26,tx_data_8_27,tx_data_8_28,tx_data_8_29,tx_data_8_30: out std_logic_vector(7 downto 0);
              tx_data_8_31,tx_data_8_32 : out std_logic_vector(7 downto 0);
              RFIF_COV_PUL  : out STD_LOGIC;

              m_axis_tdata    : out std_logic_vector(31 downto 0);
              m_axis_tvalid   : out std_logic;
              m_axis_tready   : in  std_logic;
              m_axis_tlast    : out std_logic;
              s_axis_tdata    : in  std_logic_vector(31 downto 0);
                      s_axis_tvalid   : in  std_logic;
                      s_axis_tready   : out std_logic;
                      s_axis_tlast    : in  std_logic;
              mode_data_out   : out std_logic_vector(7 downto 0);
              main_red_out    : out std_logic_vector(7 downto 0);
              Pa_LSB_out      : out std_logic_vector(7 downto 0);
              Pa_MSB_out      : out std_logic_vector(7 downto 0);
              Pb_LSB_out      : out std_logic_vector(7 downto 0);
              Pb_MSB_out      : out std_logic_vector(7 downto 0);
              byte12_out      : out std_logic_vector(7 downto 0);
              byte13_out      : out std_logic_vector(7 downto 0);
              RFIF_FWD_PWR_STS: in  std_logic;
              RFIF_SLB_OUT_STS: in  std_logic;
              RFIF_TEMP_STS   : in  std_logic;
              RFIF_AMP_CAL_STS   : in  std_logic;
              RFIF_PATH_CAL_STS   : in  std_logic;
              RFIF_CAL_IN     : out STD_LOGIC;
              RFIF_CTRL_SW    : out STD_LOGIC;
               byte12_9        : out std_logic_vector(7 downto 0);
               byte13_9        : out std_logic_vector(7 downto 0)
                       --main_red_data   : out std_logic_vector(7 downto 0);
--                       RFIF_CTRL_SW    : out std_logic
  );
end ABCU;

architecture Structural of ABCU is

--signal main_red : std_logic_vector(7 downto 0); 
signal tx_out :std_logic;
signal rx_in :std_logic;
signal sdo_in,sdi_out,sob_int,prt_int,rst_int  : std_logic;

begin

   COVERAGE_GEN_INST :  entity work.coverage_pulse_gen
    port map (
        clk_200     => clk_200M, 
        reset       => reset,
        sob_in      => sob_int, -- Single-ended internal signal
        prt_in      => prt_int, -- Single-ended internal signal
        
        -- Connect directly to your top-level ports matching your schematic
        cov_pulse_i => RFIF_COV_PUL

    );


    -- First UART Port Instance
    UART_PORT: entity work.Top_system
        port map (
            clk_10        => clk_10M,
            clk_200       => clk_200M,
            reset         => reset,
            sob_in        => EXRX_SOB_FPGA,
            RFIF_CAL_IN   => RFIF_CAL_IN, 
             RFIF_FWD_PWR_STS => RFIF_FWD_PWR_STS,
             RFIF_SLB_OUT_STS => RFIF_SLB_OUT_STS,
             RFIF_TEMP_STS  => RFIF_TEMP_STS,
             RFIF_AMP_CAL_STS  => RFIF_AMP_CAL_STS,
             RFIF_PATH_CAL_STS   => RFIF_PATH_CAL_STS,
--            p0            => p0, 
--            p1            => p1, 
--            frequency1 => frequency1, 
--            frequency2 => frequency2, 
--            frequency3 => frequency3, 
--            frequency4 => frequency4,
--            Pa_LSB_in       => Pa_LSB, 
--            Pa_MSB_in       => Pa_MSB, 
--            Pb_LSB_in       => Pb_LSB,
--            Pb_MSB_in       => Pb_MSB,
            tx_data_32(0) => tx_data_8_1,
            tx_data_32(1) => tx_data_8_2,
            tx_data_32(2) => tx_data_8_3,
            tx_data_32(3) => tx_data_8_4,
            tx_data_32(4) => tx_data_8_5,
            tx_data_32(5) => tx_data_8_6,
            tx_data_32(6) => tx_data_8_7,
            tx_data_32(7) => tx_data_8_8,  
            tx_data_32(8) => tx_data_8_9,
            tx_data_32(9) => tx_data_8_10,
            tx_data_32(10) => tx_data_8_11,
            tx_data_32(11) => tx_data_8_12,  
            tx_data_32(12) => tx_data_8_13,
            tx_data_32(13) => tx_data_8_14,
            tx_data_32(14) => tx_data_8_15,
            tx_data_32(15) => tx_data_8_16,
            tx_data_32(16) => tx_data_8_17,
            tx_data_32(17) => tx_data_8_18,  
            tx_data_32(18) => tx_data_8_19,
            tx_data_32(19) => tx_data_8_20,
            tx_data_32(20) => tx_data_8_21,
            tx_data_32(21) => tx_data_8_22,
            tx_data_32(22) => tx_data_8_23,
            tx_data_32(23) => tx_data_8_24, 
            tx_data_32(24) => tx_data_8_25,
            tx_data_32(25) => tx_data_8_26,
            tx_data_32(26) => tx_data_8_27,
            tx_data_32(27) => tx_data_8_28, 
            tx_data_32(28) => tx_data_8_29,
            tx_data_32(29) => tx_data_8_30,
            tx_data_32(30) => tx_data_8_31,
            tx_data_32(31) => tx_data_8_32,
                       
             
            rx_data_32(0) => rx_data_8_1,
            rx_data_32(1) => rx_data_8_2,
            rx_data_32(2) => rx_data_8_3, 
            rx_data_32(3) => rx_data_8_4, 
            rx_data_32(4) => rx_data_8_5, 
            rx_data_32(5) => rx_data_8_6,  
            rx_data_32(6) => rx_data_8_7,
            rx_data_32(7) => rx_data_8_8,
            rx_data_32(8) => rx_data_8_9,
            rx_data_32(9) => rx_data_8_10,
            rx_data_32(10) => rx_data_8_11,
            rx_data_32(11) => rx_data_8_12,
            rx_data_32(12) => rx_data_8_13,
            rx_data_32(13) => rx_data_8_14,
            rx_data_32(14) => rx_data_8_15,
            rx_data_32(15) => rx_data_8_16,
            rx_data_32(16) => rx_data_8_17,
            rx_data_32(17) => rx_data_8_18,
            rx_data_32(18) => rx_data_8_19,
            rx_data_32(19) => rx_data_8_20,
            rx_data_32(20) => rx_data_8_21,
            rx_data_32(21) => rx_data_8_22,
            rx_data_32(22) => rx_data_8_23,
            rx_data_32(23) => rx_data_8_24,
            rx_data_32(24) => rx_data_8_25,
            rx_data_32(25) => rx_data_8_26,
            rx_data_32(26) => rx_data_8_27,
            rx_data_32(27) => rx_data_8_28,
            rx_data_32(28) => rx_data_8_29,
            rx_data_32(29) => rx_data_8_30,
            rx_data_32(30) => rx_data_8_31,
            rx_data_32(31) => rx_data_8_32, 
            
            RX_IN_32(0)   => SDO_PLANK1_FPGA,  
            RX_IN_32(1)   => SDO_PLANK2_FPGA, 
            RX_IN_32(2)   => SDO_PLANK3_FPGA,  
            RX_IN_32(3)   => SDO_PLANK4_FPGA,  
            RX_IN_32(4)   => SDO_PLANK5_FPGA, 
            RX_IN_32(5)   => SDO_PLANK6_FPGA, 
            RX_IN_32(6)   => SDO_PLANK7_FPGA, 
            RX_IN_32(7)   => SDO_PLANK8_FPGA,  
            RX_IN_32(8)   => SDO_PLANK9_FPGA,  
            RX_IN_32(9)  => SDO_PLANK10_FPGA,
            RX_IN_32(10)   => SDO_PLANK11_FPGA,  
            RX_IN_32(11)   => SDO_PLANK12_FPGA, 
            RX_IN_32(12)   => SDO_PLANK13_FPGA,
            RX_IN_32(13)   => SDO_PLANK14_FPGA,
            RX_IN_32(14)   => SDO_PLANK15_FPGA, 
            RX_IN_32(15)   => SDO_PLANK16_FPGA,
            RX_IN_32(16)   => SDO_PLANK17_FPGA, 
            RX_IN_32(17)   => SDO_PLANK18_FPGA,
            RX_IN_32(18)   => SDO_PLANK19_FPGA,  
            RX_IN_32(19)   => SDO_PLANK20_FPGA,  
            RX_IN_32(20)   => SDO_PLANK21_FPGA,  
            RX_IN_32(21)   => SDO_PLANK22_FPGA, 
            RX_IN_32(22)   => SDO_PLANK23_FPGA,  
            RX_IN_32(23)   => SDO_PLANK24_FPGA,  
            RX_IN_32(24)   => SDO_PLANK25_FPGA,   
            RX_IN_32(25)   => SDO_PLANK26_FPGA,
            RX_IN_32(26)   => SDO_PLANK27_FPGA,  
            RX_IN_32(27)   => SDO_PLANK28_FPGA,  
            RX_IN_32(28)   => SDO_PLANK29_FPGA,  
            RX_IN_32(29)   => SDO_PLANK30_FPGA,
            RX_IN_32(30)   => SDO_PLANK31_FPGA,  
            RX_IN_32(31)   => SDO_PLANK32_FPGA,
                   
--            TX_OUT_32(0)  => SDI_PLANK1_FPGA,
            TX_OUT_32(0)  =>SDI_PLANK1_FPGA,
            TX_OUT_32(1)  => SDI_PLANK2_FPGA,
            TX_OUT_32(2)  => SDI_PLANK3_FPGA,
            TX_OUT_32(3)  => SDI_PLANK4_FPGA,
            TX_OUT_32(4)  => SDI_PLANK5_FPGA,
            TX_OUT_32(5)  => SDI_PLANK6_FPGA,
            TX_OUT_32(6)  => SDI_PLANK7_FPGA,
            TX_OUT_32(7)  => SDI_PLANK8_FPGA,
            TX_OUT_32(8)  => SDI_PLANK9_FPGA,
            TX_OUT_32(9)  => SDI_PLANK10_FPGA,
            TX_OUT_32(10)  => SDI_PLANK11_FPGA,
            TX_OUT_32(11)  => SDI_PLANK12_FPGA,
            TX_OUT_32(12)  => SDI_PLANK13_FPGA,
            TX_OUT_32(13)  => SDI_PLANK14_FPGA,
            TX_OUT_32(14)  => SDI_PLANK15_FPGA,
            TX_OUT_32(15)  => SDI_PLANK16_FPGA,
            TX_OUT_32(16)  => SDI_PLANK17_FPGA,
            TX_OUT_32(17)  => SDI_PLANK18_FPGA,
            TX_OUT_32(18)  => SDI_PLANK19_FPGA,
            TX_OUT_32(19)  => SDI_PLANK20_FPGA,
            TX_OUT_32(20)  => SDI_PLANK21_FPGA,
            TX_OUT_32(21)  => SDI_PLANK22_FPGA,
            TX_OUT_32(22)  => SDI_PLANK23_FPGA,
            TX_OUT_32(23)  => SDI_PLANK24_FPGA,
            TX_OUT_32(24)  => SDI_PLANK25_FPGA,
            TX_OUT_32(25)  => SDI_PLANK26_FPGA,
            TX_OUT_32(26)  => SDI_PLANK27_FPGA,
            TX_OUT_32(27)  => SDI_PLANK28_FPGA,
            TX_OUT_32(28)  => SDI_PLANK29_FPGA,
            TX_OUT_32(29)  => SDI_PLANK30_FPGA, 
            TX_OUT_32(30)  => SDI_PLANK31_FPGA,
            TX_OUT_32(31)  => SDI_PLANK32_FPGA,
            m_axis_tdata  => m_axis_tdata,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tready => m_axis_tready,
            m_axis_tlast  => m_axis_tlast,
            s_axis_tdata    => s_axis_tdata,
            s_axis_tvalid   => s_axis_tvalid,
            s_axis_tready   => s_axis_tready,
            s_axis_tlast    => s_axis_tlast,
            RFIF_CTRL_SW    => RFIF_CTRL_SW,
            mode_data_out   => mode_data_out,
            main_red_out   => main_red_out,
            Pa_LSB_out    => Pa_LSB_out,
            Pa_MSB_out    => Pa_MSB_out,
            Pb_LSB_out    => Pb_LSB_out,
            Pb_MSB_out    => Pb_MSB_out,
            byte12_out    => byte12_out,
            byte13_out    => byte13_out,
            byte12_9         => byte12_9,
            byte13_9         => byte13_9
                    
        );
        

--    SDI_PLANK1_FPGA <= sdi_out;
    sdo_in  <= SDO_PLANK1_FPGA;
    sob_int <= EXRX_SOB_FPGA;
    prt_int <= EXRX_PRT_FPGA;
    rst_int <= EXRX_RST_FPGA; 
                   
--  PRT  & RST from Exciter Receiver TO Group control Units
   RST_PLANK1_FPGA  <= rst_int; 
   RST_PLANK2_FPGA  <= rst_int;
   RST_PLANK3_FPGA  <= rst_int;
   RST_PLANK4_FPGA  <= rst_int;  
   
   PRT_PLANK1_FPGA  <= prt_int;
   PRT_PLANK2_FPGA  <= prt_int;
   PRT_PLANK3_FPGA  <= prt_int;
   PRT_PLANK4_FPGA  <= prt_int;
   
   SOB_PLANK1_FPGA  <= sob_int;
   SOB_PLANK2_FPGA  <= sob_int;
   SOB_PLANK3_FPGA  <= sob_int; 
   SOB_PLANK4_FPGA  <= sob_int; 
           
end Structural;
