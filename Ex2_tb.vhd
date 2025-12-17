library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity breath_tb is
end entity breath_tb;

architecture Behavioral of breath_tb is
    signal i_clk  : std_logic := '0';
    signal i_rst  : std_logic := '0';
    signal o_led1: std_logic := '0';
    signal o_led2: std_logic := '0';
    component breath_dual
        Port ( i_clk  : in STD_LOGIC;
                  i_rst     : in STD_LOGIC;
                  o_led1 : out STD_LOGIC;
                  o_led2 : out STD_LOGIC);
    end component;  
begin

       dut: breath_dual
    Port map( 
           i_clk => i_clk,
           i_rst => i_rst,
           o_led1 => o_led1,
           o_led2 => o_led2);
           
    clock_process : process
    begin
        i_clk <= '0';
        wait for 10 ns;
        i_clk <= '1';
        wait for 10 ns;
    end process;

    stim_process: process
    begin
        i_rst <= '0';
        wait for 20 ns;
        i_rst <= '1'; 
        wait;
    end process;

end Behavioral;