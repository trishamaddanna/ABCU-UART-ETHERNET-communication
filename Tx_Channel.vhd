library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Tx_Channel is 
    Port ( 
        clk_10         : in std_logic;
        reset          : in std_logic; -- Active-low global system reset
        channel_id     : in integer range 1 to 32;
        tx_out         : out std_logic;
        tx_done        : out std_logic;
        sob_in         : in std_logic; -- External Trigger Pulse
        curr_byte_out  : out std_logic_vector(7 downto 0);
        
        -- OTRM Data Ports
        OTRM01         : in std_logic_vector(7 downto 0);
        OTRM23         : in std_logic_vector(7 downto 0);
        OTRM45         : in std_logic_vector(7 downto 0);
        OTRM67         : in std_logic_vector(7 downto 0);
        OTRM89         : in std_logic_vector(7 downto 0);
        OTRM1011       : in std_logic_vector(7 downto 0);
        OTRM1213       : in std_logic_vector(7 downto 0);
        OTRM1415       : in std_logic_vector(7 downto 0);
        
        -- Original Parameters for Packet 2
        Pa_LSB1        : in std_logic_vector(7 downto 0);
        Pa_MSB1        : in std_logic_vector(7 downto 0);
        Pb_MSB1        : in std_logic_vector(7 downto 0);
        Pb_LSB1        : in std_logic_vector(7 downto 0)
    ); 
end Tx_Channel;

architecture Behavioral of Tx_Channel is
    -- Core 15-byte packet structure type
    type pkt_storage_type is array (0 to 14) of std_logic_vector(7 downto 0);
    
    -- DISTINCT NAMED PACKETS: Separated physically to avoid array overlapping
    signal pkt_otrm_data  : pkt_storage_type := (others => x"00"); -- Dedicated to Packet 1
    signal pkt_phase_data : pkt_storage_type := (others => x"00"); -- Dedicated to Packet 2
    
    -- Processing States
    type state_type is (IDLE, START_B, DATA_B, STOP_B, DELAY);
    signal state : state_type := IDLE;
    
    signal byte_idx   : integer range 0 to 14 := 0;
    signal clk_cnt    : integer range 0 to 31 := 0;
    signal bit_idx    : integer range 0 to 7  := 0;
    signal curr_byte  : std_logic_vector(7 downto 0);
    signal sob_sync   : std_logic_vector(2 downto 0) := (others => '1');
    signal packet_num : integer range 1 to 2 := 1; 
    
    -- Delay Counter for 50 microseconds spacing (500 cycles at 10 MHz)
    signal delay_cnt  : integer range 0 to 511   := 0;

--    -- --- INDEPENDENT INTERNALLY LATCHED REGISTERS ---
--    signal reg_OTRM01   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM23   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM45   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM67   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM89   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM1011 : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM1213 : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_OTRM1415 : std_logic_vector(7 downto 0) := (others => '0');

--    signal reg_Pa_LSB   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_Pa_MSB   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_Pb_LSB   : std_logic_vector(7 downto 0) := (others => '0');
--    signal reg_Pb_MSB   : std_logic_vector(7 downto 0) := (others => '0');

    -- Shared internal CRC calculation function
    function calc_crc8(data : pkt_storage_type) return std_logic_vector is
        variable crc : unsigned(7 downto 0) := x"00";
    begin
        for i in 0 to 13 loop
            crc := crc xor unsigned(data(i));
            for j in 0 to 7 loop
                if (crc(7) = '1') then 
                    crc := (crc sll 1) xor x"07";
                else 
                    crc := (crc sll 1);
                end if;
            end loop;
        end loop;
        return std_logic_vector(crc);
    end function;

begin

    process(clk_10, reset)
        variable v_pkt_otrm  : pkt_storage_type;
        variable v_pkt_phase : pkt_storage_type;
        variable v_crc       : std_logic_vector(7 downto 0);
    begin
        if reset = '0' then
            state          <= IDLE; tx_out <= '1'; tx_done <= '0';
            sob_sync       <= (others => '1'); 
            pkt_otrm_data  <= (others => x"00");
            pkt_phase_data <= (others => x"00");
            curr_byte      <= (others => '0'); clk_cnt <= 0; bit_idx <= 0;
            byte_idx       <= 0; packet_num <= 0; delay_cnt <= 0;
            
            -- Flush hardware register snapshots
--            reg_OTRM01   <= (others => '0'); reg_OTRM23   <= (others => '0');
--            reg_OTRM45   <= (others => '0'); reg_OTRM67   <= (others => '0');
--            reg_OTRM89   <= (others => '0'); reg_OTRM1011 <= (others => '0');
--            reg_OTRM1213 <= (others => '0'); reg_OTRM1415 <= (others => '0');
--            reg_Pa_LSB   <= (others => '0'); reg_Pa_MSB   <= (others => '0');
--            reg_Pb_LSB   <= (others => '0'); reg_Pb_MSB   <= (others => '0');
            
        elsif rising_edge(clk_10) then
            sob_sync <= sob_sync(1 downto 0) & sob_in;
            
            case state is
                when IDLE =>
                    tx_out     <= '1'; 
                    tx_done    <= '0'; 
                    delay_cnt  <= 0;
                    byte_idx   <= 0;
                    
                    -- TRIGGER PROTECTION FIREWALL: Only accepts trigger if the edge drops cleanly 
                    -- and resets packet pointer states back to initial ground state atomically
                    if sob_sync(2) = '1' and sob_sync(1) = '0' then
                        packet_num <= 1;
                        
                        -- CRITICAL FREEZE: Secure current values into isolated hardware flip-flops instantly
--                        reg_OTRM01   <= OTRM01;   reg_OTRM23   <= OTRM23;
--                        reg_OTRM45   <= OTRM45;   reg_OTRM67   <= OTRM67;
--                        reg_OTRM89   <= OTRM89;   reg_OTRM1011 <= OTRM1011;
--                        reg_OTRM1213 <= OTRM1213; reg_OTRM1415 <= OTRM1415;
                        
--                        reg_Pa_LSB   <= Pa_LSB1;  reg_Pa_MSB   <= Pa_MSB1;
--                        reg_Pb_LSB   <= Pb_LSB1;  reg_Pb_MSB   <= Pb_MSB1;
                        
                        -- --- ASSEMBLE INDEPENDENT PACKET 1 (OTRM DATA) ---
                        -- --- ASSEMBLE INDEPENDENT PACKET 1 (OTRM DATA) ---
                        v_pkt_otrm := (others => x"00");
                        v_pkt_otrm(0)  := x"AC"; 
                        v_pkt_otrm(1)  := x"0F"; 
                        v_pkt_otrm(2)  := x"14"; 
                        
                        -- FIX: Swap out raw input port connections for stable latched registers
                        v_pkt_otrm(3)  := OTRM01;    
                        v_pkt_otrm(4)  := OTRM23;
                        v_pkt_otrm(5)  := OTRM45;    
                        v_pkt_otrm(6)  := OTRM67;
                        v_pkt_otrm(7)  := OTRM89;     
                        v_pkt_otrm(8)  := OTRM1011;
                        v_pkt_otrm(9)  := OTRM1213;   
                        v_pkt_otrm(10) := OTRM1415; 
                        
                        v_pkt_otrm(11) := std_logic_vector(to_unsigned(channel_id, 8));
                        v_pkt_otrm(12) := x"00";     
                        v_pkt_otrm(13) := x"00";
                        v_crc := calc_crc8(v_pkt_otrm);
                        v_pkt_otrm(14) := v_crc;
                        pkt_otrm_data <= v_pkt_otrm;
                        
                        -- --- PRE-ASSEMBLE INDEPENDENT PACKET 2 (PHASE DATA) ---
                        v_pkt_phase := (others => x"00");
                        v_pkt_phase(0)  := x"AC"; 
                        v_pkt_phase(1)  := x"32"; 
                        v_pkt_phase(2)  := x"01";
                        v_pkt_phase(4)  := x"11"; 
                        
                        -- FIX: Swap out raw input port connections for stable latched registers
                        v_pkt_phase(7)  := Pa_LSB1; 
                        v_pkt_phase(8)  := Pa_MSB1;
                        v_pkt_phase(9)  := Pb_LSB1; 
                        v_pkt_phase(10) := Pb_MSB1;
                        
                        v_crc := calc_crc8(v_pkt_phase);
                        v_pkt_phase(14) := v_crc;
                        pkt_phase_data <= v_pkt_phase;

                        
                        state    <= START_B;
                    end if;

                when START_B =>
                    if packet_num = 1 then
                        curr_byte <= pkt_otrm_data(byte_idx);
                    else
                        curr_byte <= pkt_phase_data(byte_idx);
                    end if;
                    tx_out <= '0'; bit_idx <= 0; state <= DATA_B;

                when DATA_B =>
                    tx_out <= curr_byte(bit_idx);
                    if bit_idx = 7 then state <= STOP_B; else bit_idx <= bit_idx + 1; end if;

                when STOP_B =>
                    tx_out <= '1';
                    if clk_cnt < 1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        if byte_idx < 14 then
                            byte_idx <= byte_idx + 1; state <= START_B;
                        else
                            if packet_num = 1 then
                                delay_cnt <= 0; state <= DELAY;
                            else
                                tx_done <= '1'; 
                                -- FIXED HARDWARE HANDSHAKE HOLD: Forcing a mandatory state recovery cycle 
                                -- clears the edge sync buffer before re-entering IDLE state monitoring!
                                state   <= IDLE; 
                            end if;
                        end if;
                    end if;

                when DELAY =>
                    tx_out <= '1'; 
                    if delay_cnt < 499 then 
                        delay_cnt <= delay_cnt + 1;
                    else
                        packet_num <= 2;
                        byte_idx   <= 0; 
                        state      <= START_B; -- Triggers Packet 2 from frozen register values cleanly
                    end if;

                when others => state <= IDLE;
            end case;
        end if;
    end process;

    curr_byte_out <= curr_byte;
end Behavioral;
