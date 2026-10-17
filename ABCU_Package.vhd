library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package ABCU_Package is
    type data_array is array (0 to 31) of std_logic_vector(7 downto 0);
    type temp_pkt_type is array (0 to 14) of std_logic_vector(7 downto 0);
end package;
