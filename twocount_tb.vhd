library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity tb_twocount is
end tb_twocount;

architecture Behavioral of tb_twocount is
    -- Component declaration
    component twocount is
        Port ( i_clk : in STD_LOGIC;
               i_rst : in STD_LOGIC;
               o_count1 : out STD_LOGIC_VECTOR (7 downto 0);
               o_count2 : out STD_LOGIC_VECTOR (7 downto 0);
               o_count3 : out STD_LOGIC_VECTOR (7 downto 0)
               );
    end component;
    
    -- Test signals
    signal i_clk : STD_LOGIC := '0';
    signal i_rst : STD_LOGIC := '0';
    signal o_count1 : STD_LOGIC_VECTOR (7 downto 0);
    signal o_count2 : STD_LOGIC_VECTOR (7 downto 0);
    signal o_count3 : STD_LOGIC_VECTOR (7 downto 0);
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Helper function to convert std_logic_vector to integer for display
    function slv_to_int(slv : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(slv));
    end function;
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: twocount 
        Port map (
            i_clk => i_clk,
            i_rst => i_rst,
            o_count1 => o_count1,
            o_count2 => o_count2,
            o_count3 => o_count3
        );
    
    -- Clock process
    clk_process: process
    begin
        i_clk <= '0';
        wait for clk_period/2;
        i_clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Test reset functionality
        report "=== Starting testbench for three-counter FSM module ===";
        
        -- Apply reset
        i_rst <= '0';
        wait for 20 ns;
        
        report "Reset applied - Initial values:";
        report "count1 = " & integer'image(slv_to_int(o_count1)) & 
               " (expected: 0)";
        report "count2 = " & integer'image(slv_to_int(o_count2)) & 
               " (expected: 253)";
        report "count3 = " & integer'image(slv_to_int(o_count3)) & 
               " (expected: 11)";
        
        -- Release reset
        --i_rst <= '1';
        --wait for 20 ns;
        
        -- Test State s0: count1 increments from 0 to 8
        report "=== Testing State s0 - count1 incrementing ===";
        for i in 0 to 15 loop
            wait for clk_period;
            report "Cycle " & integer'image(i) & 
                   ": count1=" & integer'image(slv_to_int(o_count1)) &
                   ", count2=" & integer'image(slv_to_int(o_count2)) &
                   ", count3=" & integer'image(slv_to_int(o_count3));
            
            -- Check if count1 reaches 8 (0000_1000)
            if o_count1 = "00001000" then
                report ">>> count1 reached 8, transitioning s0->s3->s1";
                exit;
            end if;
        end loop;
        
        -- State s3: count1 resets, then goes to s1
        wait for clk_period;
        report "After s3 transition: count1=" & integer'image(slv_to_int(o_count1));
        
        -- Test State s1: count2 decrements from 253 to 80
        report "=== Testing State s1 - count2 decrementing ===";
        for i in 0 to 200 loop
            wait for clk_period;
            if i mod 20 = 0 then  -- Report every 20 cycles
                report "Cycle " & integer'image(i) & 
                       ": count1=" & integer'image(slv_to_int(o_count1)) &
                       ", count2=" & integer'image(slv_to_int(o_count2)) &
                       ", count3=" & integer'image(slv_to_int(o_count3));
            end if;
            
            -- Check if count2 reaches 80 (0101_0000)
            if o_count2 = "01010000" then
                report ">>> count2 reached 80, transitioning s1->s4->s2";
                exit;
            end if;
        end loop;
        
        -- State s4: count2 resets, then goes to s2
        wait for clk_period;
        report "After s4 transition: count2=" & integer'image(slv_to_int(o_count2));
        
        -- Test State s2: count3 increments from 11 to 20
        report "=== Testing State s2 - count3 incrementing ===";
        for i in 0 to 15 loop
            wait for clk_period;
            report "Cycle " & integer'image(i) & 
                   ": count1=" & integer'image(slv_to_int(o_count1)) &
                   ", count2=" & integer'image(slv_to_int(o_count2)) &
                   ", count3=" & integer'image(slv_to_int(o_count3));
            
            -- Check if count3 reaches 20 (0001_0100)
            if o_count3 = "00010100" then
                report ">>> count3 reached 20, transitioning s2->s5->s0";
                exit;
            end if;
        end loop;
        
        -- State s5: count3 resets, then goes back to s0
        wait for clk_period;
        report "After s5 transition: count3=" & integer'image(slv_to_int(o_count3));
        
        -- Test another complete cycle
        report "=== Testing second complete FSM cycle ===";
        for i in 0 to 50 loop
            wait for clk_period;
            if i mod 10 = 0 then
                report "Cycle " & integer'image(i) & 
                       ": count1=" & integer'image(slv_to_int(o_count1)) &
                       ", count2=" & integer'image(slv_to_int(o_count2)) &
                       ", count3=" & integer'image(slv_to_int(o_count3));
            end if;
            
            -- Break early if we complete another cycle
            if o_count1 = "00001000" then
                report ">>> Completed second cycle - count1 reached 8 again";
                exit;
            end if;
        end loop;
        
        -- Test reset during operation
        report "=== Testing reset during operation ===";
        wait for 50 ns;
        i_rst <= '0';
        wait for 20 ns;
        report "During reset: count1=" & integer'image(slv_to_int(o_count1)) &
               ", count2=" & integer'image(slv_to_int(o_count2)) &
               ", count3=" & integer'image(slv_to_int(o_count3));
        
        i_rst <= '1';
        wait for 50 ns;
        report "After reset release: count1=" & integer'image(slv_to_int(o_count1)) &
               ", count2=" & integer'image(slv_to_int(o_count2)) &
               ", count3=" & integer'image(slv_to_int(o_count3));
        
        report "=== Testbench completed successfully ===";
        wait;
    end process;
    
    -- State transition monitor
    state_monitor: process(i_clk)
        variable prev_count1 : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        variable prev_count2 : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        variable prev_count3 : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        variable cycle_count : integer := 0;
    begin
        if rising_edge(i_clk) and i_rst = '1' then
            cycle_count := cycle_count + 1;
            
            -- Detect state transitions based on counter behavior
            if o_count1 = "00000000" and prev_count1 = "00001000" then
                report "*** STATE TRANSITION DETECTED: s0->s3->s1 (count1 reset from 8 to 0) at cycle " & integer'image(cycle_count);
            elsif o_count2 = "11111101" and prev_count2 = "01010000" then
                report "*** STATE TRANSITION DETECTED: s1->s4->s2 (count2 reset from 80 to 253) at cycle " & integer'image(cycle_count);
            elsif o_count3 = "00001011" and prev_count3 = "00010100" then
                report "*** STATE TRANSITION DETECTED: s2->s5->s0 (count3 reset from 20 to 11) at cycle " & integer'image(cycle_count);
            end if;
            
            -- Check for unexpected counter changes
            if (o_count1 /= prev_count1 and o_count1 /= prev_count1 + 1 and o_count1 /= "00000000") then
                report "WARNING: Unexpected count1 change from " & integer'image(slv_to_int(prev_count1)) & 
                       " to " & integer'image(slv_to_int(o_count1));
            end if;
            
            if (o_count2 /= prev_count2 and o_count2 /= prev_count2 - 1 and o_count2 /= "11111101") then
                report "WARNING: Unexpected count2 change from " & integer'image(slv_to_int(prev_count2)) & 
                       " to " & integer'image(slv_to_int(o_count2));
            end if;
            
            if (o_count3 /= prev_count3 and o_count3 /= prev_count3 + 1 and o_count3 /= "00001011") then
                report "WARNING: Unexpected count3 change from " & integer'image(slv_to_int(prev_count3)) & 
                       " to " & integer'image(slv_to_int(o_count3));
            end if;
            
            prev_count1 := o_count1;
            prev_count2 := o_count2;
            prev_count3 := o_count3;
        end if;
    end process;
    
    -- Assertion checks for critical values
    assertion_checks: process(i_clk)
    begin
        if rising_edge(i_clk) and i_rst = '1' then
            -- Check initial values after reset release
            if i_rst'event and i_rst = '1' then
                assert o_count1 = "00000000" 
                    report "ERROR: count1 should be 0 after reset" 
                    severity error;
                assert o_count2 = "11111101" 
                    report "ERROR: count2 should be 253 after reset" 
                    severity error;
                assert o_count3 = "00001011" 
                    report "ERROR: count3 should be 11 after reset" 
                    severity error;
            end if;
        end if;
    end process;

end Behavioral;