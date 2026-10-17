library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

-- Include UNISIM library for FPGA differential output primitives 
library UNISIM; 
use UNISIM.vcomponents.all; 

entity coverage_pulse_gen is 
    Port ( 
        clk_200     : in  STD_LOGIC; -- 200MHz System Clock (5ns period)
        reset       : in  STD_LOGIC; -- System Reset (Active Low)
        sob_in      : in  STD_LOGIC; -- Internal SOB signal (single-ended)
        prt_in      : in  STD_LOGIC; -- Internal PRT signal (single-ended)
        cov_pulse_i : out STD_LOGIC;  -- Drives RFIF_COV_PUL 
        RFIF_CAL    : OUT STD_LOGIC:='0'
    ); 
end coverage_pulse_gen; 

architecture Behavioral of coverage_pulse_gen is 
    -- Synchronizers / Edge Detector registers to prevent metastability
    signal sob_reg       : std_logic_vector(2 downto 0) := (others => '0'); 
    signal prt_reg       : std_logic_vector(2 downto 0) := (others => '0');
  
    signal sob_fall_edge : std_logic := '0'; 
    signal prt_rise_edge : std_logic := '0';

    -- Counter & State Management (50us period @ 200MHz = 10,000 clock cycles) 
    signal cycle_cnt     : integer range 0 to 9999 := 0; 
    signal pulse_cnt     : integer range 0 to 37 := 0; 
    signal is_active     : boolean := false; 
    
begin 

    ------------------------------------------------------------------------- 
    -- Input Synchronization & Edge Detection
    ------------------------------------------------------------------------- 
    process(clk_200, reset) 
    begin 
        if reset = '0' then 
            sob_reg       <= (others => '0'); 
            prt_reg       <= (others => '0');
            sob_fall_edge <= '0';
            prt_rise_edge <= '0';
        elsif rising_edge(clk_200) then 
            -- Double-register inputs to safely capture edge crossings
            sob_reg <= sob_reg(1 downto 0) & sob_in; 
            prt_reg <= prt_reg(1 downto 0) & prt_in; 
            
            -- Detect Falling Edge of SOB ('1' to '0') 
            if sob_reg(2) = '1' and sob_reg(1) = '0' then 
                sob_fall_edge <= '1'; 
            else 
                sob_fall_edge <= '0'; 
            end if; 
            
            -- Detect Rising Edge of PRT ('0' to '1')
            if prt_reg(2) = '0' and prt_reg(1) = '1' then 
                prt_rise_edge <= '1';
            else 
                prt_rise_edge <= '0';
            end if;
        end if; 
    end process; 

    ------------------------------------------------------------------------- 
    -- Timing & Pulse Generation State Machine 
    ------------------------------------------------------------------------- 
    process(clk_200, reset) 
    begin 
        if reset = '0' then 
            cycle_cnt   <= 0; 
            pulse_cnt   <= 0; 
            is_active   <= false; 
            cov_pulse_i <= '0'; 
        elsif rising_edge(clk_200) then 
            
            -- Trigger sequence start on SOB falling edge
            if sob_fall_edge = '1' then 
                cycle_cnt   <= 0; 
                pulse_cnt   <= 0; 
                is_active   <= true; 
                cov_pulse_i <= '0'; 
                
            elsif is_active then 
                
                -- Track and increment pulse count on every detected PRT rising edge
                if prt_rise_edge = '1' then
                    pulse_cnt <= pulse_cnt + 1;
                    -- Reset cycle counter on subsequent pulses to align with the active PRT grid
                    if pulse_cnt > 0 then
                        cycle_cnt <= 0; 
                    end if;
                else
                    -- Keep incrementing the free-running grid timer
                    if cycle_cnt < 9999 then
                        cycle_cnt <= cycle_cnt + 1;
                    else
                        cycle_cnt <= 0;
                    end if;
                end if;

                -----------------------------------------------------------------
                -- Output Window Generation Logic
                -----------------------------------------------------------------
                if pulse_cnt = 0 then 
                    -- FIRST PULSE: Starts 4.5us (900 cycles) after SOB falling edge.
                    -- Closes at 15.5us (3,100 cycles) giving 0.5us pre and post protection 
                    -- around the 10us wide PRT pulse (which arrives at 5us).
                    if cycle_cnt >= 900 and cycle_cnt < 3100 then 
                        cov_pulse_i <= '1'; 
                    else 
                        cov_pulse_i <= '0'; 
                    end if; 
                    
                elsif pulse_cnt < 37 then 
                    -- SUBSEQUENT 36 PULSES: 
                    -- Opens 0.5us (100 cycles) before the expected 50us period grid (at cycle 9900)
                    -- Closes 0.5us (100 cycles) after the 10us PRT falling edge (at cycle 2100)
                    if cycle_cnt >= 9900 or cycle_cnt < 2100 then 
                        cov_pulse_i <= '1'; 
                    else 
                        cov_pulse_i <= '0'; 
                    end if; 
                    
                else 
                    -- Sequence complete after 37 pulses have been generated
                    cov_pulse_i <= '0'; 
                    is_active   <= false; 
                end if; 
                
            else 
                cov_pulse_i <= '0'; 
            end if; 
        end if; 
    end process; 

end Behavioral;
