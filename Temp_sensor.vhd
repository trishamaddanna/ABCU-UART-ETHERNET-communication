library IEEE;
Library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.vcomponents.all;

entity Temp_sensor is
    Port (
        clk_200m   : in  STD_LOGIC;
--        clk_200n   : in  STD_LOGIC;	   -- 200 MHz Artix-7 Clock
        reset_spi  : out STD_LOGIC:='1'; 
        reset      : in  STD_LOGIC;
        din        : out STD_LOGIC;         -- Connected to AD7814 DIN
        sclk       : out STD_LOGIC;         -- Connected to AD7814 SCLK
        dout       : in  STD_LOGIC;         -- Connected to AD7814 DOUT
        -- Readable Outputs
        temp_sign  : out STD_LOGIC;                    -- '1' if negative
        --temp_int   : out integer range 0 to 128;       -- Integer part
        --temp_frac  : out integer range 0 to 75;        -- Fraction (.00, .25, .50, .75)
        --data_vld   : out STD_LOGIC          -- Pulses when data is updated
         raw_10  : out STD_LOGIC_VECTOR(9 downto 0);
           ila_temp_int  : out std_logic_vector(7 downto 0); -- 0 to 128 fits in 8 bits
           ila_temp_frac : out std_logic_vector(6 downto 0) -- 0 to 75 fits in 7 bits
    );
end Temp_sensor;

architecture Behavioral of Temp_sensor is
    -- SPI Timing Constants
    constant CLK_DIV_VAL  : integer := 100;    -- 1MHz SCLK
    constant SAMPLE_LIMIT : integer := 200000; -- 1ms between samples

    type state_type is (IDLE, READ_DATA, CONVERT, WAIT_NEXT);
    signal state      : state_type := IDLE;
    signal sclk_reg   : STD_LOGIC := '1';
    signal clk_cnt    : integer range 0 to CLK_DIV_VAL := 0;
    signal bit_cnt    : integer range 0 to 16 := 0;
    signal sample_cnt : integer range 0 to SAMPLE_LIMIT := 0;
    signal shift_reg  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal raw_10bit  : STD_LOGIC_VECTOR(9 downto 0);
--    signal temp_sign  : STD_LOGIC;                    -- '1' if negative
    signal temp_int   : integer range 0 to 128;       -- Integer part
    signal temp_frac  : integer range 0 to 75;        -- Fraction (.00, .25, .50, .75)
    signal data_vld   : STD_LOGIC;                     -- Pulses when data is updated

  
  
--    COMPONENT ila_0

--PORT (
--	clk : IN STD_LOGIC;
--	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe1 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
--	probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--	probe4 : IN STD_LOGIC_VECTOR(6 DOWNTO 0)
--);
--END COMPONENT  ;

begin

ila_temp_int  <= std_logic_vector(to_unsigned(temp_int, 8));
ila_temp_frac <= std_logic_vector(to_unsigned(temp_frac, 7));

raw_10 <= raw_10bit; 
-- IBUFDS_inst : IBUFDS
--   generic map (
--      DIFF_TERM => FALSE, -- Differential Termination 
--      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
--      IOSTANDARD => "DEFAULT")
--   port map (
--      O => clk_200m,  -- Buffer output
--      I => clk_200p,  -- Diff_p buffer input (connect directly to top-level port)
--      IB => clk_200n -- Diff_n buffer input (connect directly to top-level port)
--       );
       
--       ILA : ila_0
--PORT MAP (
--	clk => clk_200m,
--	probe0(0) => dout, 
--	probe1 => raw_10bit, 
--	probe2(0) => temp_sign, 
--	probe3 => ila_temp_int,
--	probe4 => ila_temp_frac
--);
    sclk <= sclk_reg;

    process(clk_200m, reset)
        variable signed_raw : signed(9 downto 0);
        variable abs_val    : unsigned(9 downto 0);
    begin
        if reset = '0' then
            state <= IDLE;
            sclk_reg <= '1';
            data_vld <= '0';
            sample_cnt <= 0;
        elsif rising_edge(clk_200m) then
            case state is
                
                when IDLE =>
                    data_vld <= '0';
                    if sample_cnt >= SAMPLE_LIMIT then
                        sample_cnt <= 0;
                        bit_cnt <= 16;
                        state <= READ_DATA;
                    else
                        sample_cnt <= sample_cnt + 1;
                    end if;

                when READ_DATA =>
		  -- Drive DIN Low for normal operation
                        din <= '0';
                    if clk_cnt = CLK_DIV_VAL - 1 then
                        clk_cnt <= 0;
                        sclk_reg <= not sclk_reg;
                        
                        -- Falling edge: Sample data from DOUT
                        if sclk_reg = '1' then 
                            shift_reg <= shift_reg(14 downto 0) & dout;
                        -- Rising edge: Check if 16 bits are done
                        else
                            if bit_cnt = 1 then
                                raw_10bit <= shift_reg(14 downto 5); -- Bits 15-6 are data
                                state <= CONVERT;
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when CONVERT =>
                    -- Process Two's Complement to readable format
                    signed_raw := signed(raw_10bit);
                    
                    if signed_raw < 0 then
                        temp_sign <= '1';
                        abs_val := unsigned(abs(signed_raw));
                    else
                        temp_sign <= '0';
                        abs_val := unsigned(signed_raw);
                    end if;

                    temp_int <= to_integer(abs_val / 4);
                    
                    case abs_val(1 downto 0) is
                        when "00"   => temp_frac <= 0;
                        when "01"   => temp_frac <= 25;
                        when "10"   => temp_frac <= 50;
                        when "11"   => temp_frac <= 75;
                        when others => temp_frac <= 0;
                    end case;
                    
                    data_vld <= '1';
                    state <= WAIT_NEXT;

                when WAIT_NEXT =>
                    sclk_reg <= '1';
                    data_vld <= '0';
                    state <= IDLE;
                    
            end case;
        end if;
    end process;
end Behavioral;
