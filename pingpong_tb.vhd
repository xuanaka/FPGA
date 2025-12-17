library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pingpong_tb is
end pingpong_tb;

architecture tb of pingpong_tb is
    -- DUT ports
    signal i_clk : std_logic := '0';
    signal i_rst : std_logic := '1';    -- ?C?A????
    signal i_swL : std_logic := '0';
    signal i_swR : std_logic := '0';
    signal o_led : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- ?N std_logic_vector ?? "0101..." ?r??]???? VHDL-2008?^
    function slv_to_string(slv: std_logic_vector) return string is
        variable res : string(1 to slv'length);
        variable k   : integer := 1;
    begin
        for i in slv'range loop
            case slv(i) is
                when '0' => res(k) := '0';
                when '1' => res(k) := '1';
                when others => res(k) := 'X';
            end case;
            k := k + 1;
        end loop;
        return res;
    end function;

begin
    -- Clock generator
    i_clk <= not i_clk after CLK_PERIOD/2;

    -- Device Under Test
    dut: entity work.pingpong
        port map (
            i_clk => i_clk,
            i_rst => i_rst,
            i_swL => i_swL,
            i_swR => i_swR,
            o_led => o_led
        );

    stim: process
        -- ?p?u??G???? N ????
        procedure wait_cycles(n: natural) is
        begin
            for k in 1 to n loop
                wait for CLK_PERIOD;
            end loop;
        end procedure;

        -- ?p?u??G???k??@??
        procedure tap_R is
        begin
            i_swR <= '1';
            wait_cycles(1);
            i_swR <= '0';
        end procedure;

        -- ?p?u??G??????@??
        procedure tap_L is
        begin
            i_swL <= '1';
            wait_cycles(1);
            i_swL <= '0';
        end procedure;

        -- ??d???U
        procedure expect_led(constant expect: std_logic_vector) is
        begin
            assert o_led = expect
                report "???? o_led=" & slv_to_string(expect) & "?A???? " & slv_to_string(o_led)
                severity error;
        end procedure;

    begin
        ----------------------------------------------------------------
        -- ?u?b?}?Y reset ?@??
        ----------------------------------------------------------------
        i_rst <= '0';
        wait_cycles(3);
        i_rst <= '1';
        i_swL <= '0';
        i_swR <= '0';
        wait_cycles(2);

        ----------------------------------------------------------------
        -- TEST 1: ???`??u?@???]?k??????u???A?A??????^?k?^
        ----------------------------------------------------------------
        report "TEST 1: ???`??u?@??" severity note;
        wait until o_led = "00000001";  -- ??k??
        tap_R;                          -- ?k??b?????T???y -> ????
        wait until o_led = "10000000";  -- ????
        tap_L;                          -- ????b?????T???y -> ???k
        wait_cycles(2);
        report "TEST 1 ????" severity note;

        ----------------------------------------------------------------
        -- TEST 2: ?k??S????y -> ????o???]??? 1 ?? 4bit?^
        ----------------------------------------------------------------
        report "TEST 2: ?k??S????y -> ????o??" severity note;
        wait until o_led = "00000001";  -- ???y?A??k??
        -- ?????k??A??????A?i?J Lwin ???s???
        wait_cycles(3);
        expect_led("00010000");
        report "TEST 2 ?????]???????=1?^" severity note;
         wait_cycles(20);
        ----------------------------------------------------------------
        -- TEST 3: ?k???????y -> ????A?o???]??p=2?^
        ----------------------------------------------------------------
        report "TEST 3: ?k???????y -> ????A?o??" severity note;
        tap_L;                -- ?q Lwin ???}?A???k?o?y?]?y?q?????????m?}?l????^
        wait_cycles(2);
        -- ??@????~??m?]?D?k??^?A??p bit2 ?G??
        wait until o_led = "00000100";
        tap_R;                -- ?L???? -> Lwin
        wait_cycles(3);
        expect_led("00100000");
        report "TEST 3 ?????]???????=2?^" severity note;
        wait_cycles(10);
        ----------------------------------------------------------------
        -- TEST 4: ????S????y -> ?k??o???]??? 1 ??C 4bit?^
        ----------------------------------------------------------------
        report "TEST 4: ????S????y -> ?k??o??" severity note;
        tap_L;                          -- ?q Lwin ???}?A???k?o?y
        wait until o_led = "00000001";  -- ??k??
        tap_R;                          -- ?k??b?????y -> ????
        wait until o_led = "10000000";  -- ????
        -- ????????A???k??o??
        wait_cycles(3);
        expect_led("00000001");
        report "TEST 4 ?????]?k?????=1?^" severity note;

        ----------------------------------------------------------------
        -- TEST 5: ?????????y -> ?k??A?o???]??p=2?^
        ----------------------------------------------------------------
        report "TEST 5: ?????????y -> ?k??A?o??" severity note;
        tap_R;                -- ?q Rwin ???}?A?????o?y
        wait_cycles(2);
        -- ??@????~??m?]?D????^?A??p bit5 ?G??
        wait until o_led = "00100000";
        tap_L;                -- ?L???? -> Rwin
        wait_cycles(3);
        expect_led("00000010");
        report "TEST 5 ?????]?k?????=2?^" severity note;

        report "???????????]???{?u?b?}?Y reset ?@???^" severity note;
        wait;
    end process;

end tb;