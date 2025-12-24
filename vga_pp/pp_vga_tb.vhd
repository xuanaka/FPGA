library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_Top_PingPong_VGA is
-- Testbench has no ports
end tb_Top_PingPong_VGA;

architecture Behavioral of tb_Top_PingPong_VGA is

    component Top_PingPong_VGA
        Port ( 
            CLK_100MHZ : in  STD_LOGIC;
            RESET      : in  STD_LOGIC;
            BTN_L      : in  STD_LOGIC;
            BTN_R      : in  STD_LOGIC;
            SW_SPEED   : in  STD_LOGIC;
            VGA_HS     : out STD_LOGIC;
            VGA_VS     : out STD_LOGIC;
            VGA_R      : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_G      : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_B      : out STD_LOGIC_VECTOR(3 downto 0);
            LED_OUT    : out STD_LOGIC_VECTOR(7 downto 0) 
        );
    end component;

    -- Inputs
    signal CLK_100MHZ : std_logic := '0';
    signal RESET      : std_logic := '0';
    signal BTN_L      : std_logic := '0';
    signal BTN_R      : std_logic := '0';
    signal SW_SPEED   : std_logic := '0';

    -- Outputs
    signal VGA_HS     : std_logic;
    signal VGA_VS     : std_logic;
    signal VGA_R      : std_logic_vector(3 downto 0);
    signal VGA_G      : std_logic_vector(3 downto 0);
    signal VGA_B      : std_logic_vector(3 downto 0);
    signal LED_OUT    : std_logic_vector(7 downto 0);

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns; -- 100MHz

begin

    uut: Top_PingPong_VGA PORT MAP (
        CLK_100MHZ => CLK_100MHZ,
        RESET      => RESET,
        BTN_L      => BTN_L,
        BTN_R      => BTN_R,
        SW_SPEED   => SW_SPEED,
        VGA_HS     => VGA_HS,
        VGA_VS     => VGA_VS,
        VGA_R      => VGA_R,
        VGA_G      => VGA_G,
        VGA_B      => VGA_B,
        LED_OUT    => LED_OUT
    );

    -- Clock process
    clk_process :process
    begin
        CLK_100MHZ <= '0';
        wait for CLK_PERIOD/2;
        CLK_100MHZ <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin		
        -- 1. Hold Reset (Active Low, so hold '0')
        RESET <= '0';
        wait for 100 ns;	
        
        -- 2. Release Reset (Set to '1')
        RESET <= '1'; 
        wait for 100 ns;

        -- 3. Simulate Button Press (Left Serve)
        wait for 1 ms;
        BTN_L <= '1';
        wait for 100 ms; -- Long press
        BTN_L <= '0';
        
        wait; -- Let simulation run
    end process;

end Behavioral;