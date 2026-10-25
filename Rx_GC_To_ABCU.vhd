library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ABCU_Package.all;

entity Rx_GC_To_ABCU is
    Port (
        clk_200            : in  std_logic;
        reset              : in  std_logic;
        rx_in              : in  std_logic;
        byte_cntrx         : inout integer range 0 to 8191;
        error_cnt          : inout integer range 0 to 8191;
        rx_data_out        : out std_logic_vector(7 downto 0);
        
        -- FIXED: Separated validation pulses prevent overlapping down the line
        pkt1_valid_pulse   : out std_logic; -- Fires on valid OTRM Packet
        pkt2_valid_pulse   : out std_logic; -- Fires on valid Phase/Parameter Packet
        
        -- FIXED: Separated data buses preserve integrity across the 50us delay window
        pkt1_data_out      : out temp_pkt_type;
        pkt2_data_out      : out temp_pkt_type
    );
end Rx_GC_To_ABCU;

architecture Behavioral of Rx_GC_To_ABCU is
    type rx_packet_mem is array (0 to 31, 0 to 14) of std_logic_vector(7 downto 0);
    signal gc_storage : rx_packet_mem := (others => (others => x"00"));

    type state_type is (IDLE, START_B, DATA_B, STOP_B, VALIDATE);
    signal state : state_type := IDLE;

    signal clk_cnt     : integer range 0 to 31 := 0; 
    signal bit_idx     : integer range 0 to 7  := 0;
    signal byte_idx    : integer range 0 to 14 := 0;
    signal rx_byte     : std_logic_vector(7 downto 0);
    signal rx_sync     : std_logic_vector(1 downto 0) := "11";
    signal sampled_bit : std_logic;
    signal sample_acc  : integer range 0 to 11 := 0; 
    
    -- Dedicated internal registered output holding lanes
    signal reg_pkt1    : temp_pkt_type := (others => x"00");
    signal reg_pkt2    : temp_pkt_type := (others => x"00");
    
    signal temp_pkt    : temp_pkt_type := (others => x"00");
    signal storage_ptr : integer range 0 to 31 := 0;

begin
    process(clk_200) begin
        if rising_edge(clk_200) then rx_sync <= rx_sync(0) & rx_in; end if;
    end process;

    process(clk_200, reset)
         variable v_crc8 : unsigned(7 downto 0);
    begin
        if reset = '0' then
            state <= IDLE; byte_cntrx <= 0; error_cnt <= 0; byte_idx <= 0;
            rx_data_out <= (others => '0'); sample_acc <= 0;
            pkt1_valid_pulse <= '0'; pkt2_valid_pulse <= '0';
            reg_pkt1 <= (others => x"00"); reg_pkt2 <= (others => x"00");
            storage_ptr <= 0;
        elsif rising_edge(clk_200) then
            -- Default assignment: Pulse lines must cleanly drop back to low state
            pkt1_valid_pulse <= '0';
            pkt2_valid_pulse <= '0';

            case state is
                when IDLE =>
                    clk_cnt <= 0; sample_acc <= 0;
                    if rx_sync = "10" then state <= START_B; end if;

                when START_B =>
                    if clk_cnt = 18 then state <= DATA_B; clk_cnt <= 0; bit_idx <= 0; sample_acc <= 0;
                    else clk_cnt <= clk_cnt + 1; end if;

                when DATA_B =>
                    if clk_cnt = 0 then sample_acc <= 0; end if;
                    if clk_cnt >= 5 and clk_cnt <= 15 then
                        if rx_sync(1) = '1' then sample_acc <= sample_acc + 1; end if;
                    end if;
                    if clk_cnt = 16 then
                        if sample_acc > 5 then sampled_bit <= '1'; else sampled_bit <= '0'; end if;
                    end if;
                    if clk_cnt = 19 then
                        rx_byte(bit_idx) <= sampled_bit; clk_cnt <= 0;
                        if bit_idx = 7 then state <= STOP_B; else bit_idx <= bit_idx + 1; end if;
                    else clk_cnt <= clk_cnt + 1; end if;
                    
                when STOP_B =>
                     if clk_cnt = 19 then
                        temp_pkt(byte_idx) <= rx_byte; rx_data_out <= rx_byte;
                        if byte_idx = 14 then state <= VALIDATE;
                        else byte_idx <= byte_idx + 1; state <= IDLE; clk_cnt <= 0; end if;
                    else clk_cnt <= clk_cnt + 1; end if;         

                when VALIDATE =>
                    v_crc8 := x"00";
                    for i in 0 to 13 loop 
                        v_crc8 := v_crc8 xor unsigned(temp_pkt(i));
                        for j in 0 to 7 loop
                            if (v_crc8(7) = '1') then v_crc8 := (v_crc8 sll 1) xor x"07";
                            else v_crc8 := (v_crc8 sll 1); end if;
                        end loop;
                    end loop;

                    if (temp_pkt(0) = x"AC")  and (temp_pkt(14) = std_logic_vector(v_crc8)) then
                        for k in 0 to 14 loop 
                        gc_storage(storage_ptr, k) <= temp_pkt(k); 
                        end loop;
                        byte_cntrx <= byte_cntrx + 1;
                        
                        -- --- CRITICAL DISCRIMINATOR ROUTING ENGINE ---
                        if temp_pkt(2) = x"14" then
                            -- Securely map payload data into Packet 1 Registers
                            reg_pkt1 <= temp_pkt;
                            pkt1_valid_pulse <= '1'; -- Safely alerts upward bridge
                            
                        elsif temp_pkt(2) = x"01" then
                            -- Securely map payload data into Packet 2 Registers
                            reg_pkt2 <= temp_pkt;
                            pkt2_valid_pulse <= '1'; -- Safely alerts upward bridge
                        end if;
                        
                        if storage_ptr = 31 then storage_ptr <= 0; else storage_ptr <= storage_ptr + 1; end if;
                    else    
                        error_cnt <= error_cnt + 1; 
                    end if;
                    byte_idx <= 0; state <= IDLE;
            end case;
        end if;
    end process;

    -- Drive external top mapping wiring rails persistently
    pkt1_data_out <= reg_pkt1;
    pkt2_data_out <= reg_pkt2;

end Behavioral;
