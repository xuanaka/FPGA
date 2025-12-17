library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity breath_dual is
    Port (
        i_clk : in STD_LOGIC;
        i_rst : in STD_LOGIC;
        o_led1 : out STD_LOGIC;
        o_led2 : out STD_LOGIC
    );
end breath_dual;

architecture Behavioral of breath_dual is

    component hw1_2cnters 
        Port (
            i_clk        : in STD_LOGIC;
            i_rst        : in STD_LOGIC;
            i_upperBound1: in STD_LOGIC_VECTOR (7 downto 0);
            i_upperBound2: in STD_LOGIC_VECTOR (7 downto 0);
            o_state      : out STD_LOGIC
        );           
    end component;

    type STATE2TYPE is (gettingBright, gettingDark);

    signal upbnd1 : STD_LOGIC_VECTOR (7 downto 0) ;
    signal upbnd2 : STD_LOGIC_VECTOR (7 downto 0) ;
    signal state1, state2 : STATE2TYPE;
    signal alreadyP_PWM_cycles : STD_LOGIC := '0';
    signal pwmCnt : STD_LOGIC_VECTOR (7 downto 0) ;
    constant P : STD_LOGIC_VECTOR (7 downto 0) := "11111111"; -- 255
    signal pwm_pedge : STD_LOGIC := '0';
    signal pwm1, pwm2 : STD_LOGIC;
    signal pwm_old : STD_LOGIC := '0';

begin

    -- LED1 PWM
    hw1_led1: hw1_2cnters 
        port map (
            i_clk         => i_clk,
            i_rst         => i_rst,
            i_upperBound1 => upbnd1,
            i_upperBound2 => upbnd2,
            o_state       => pwm1
        );

    -- LED2 PWM
    hw1_led2: hw1_2cnters 
        port map (
            i_clk         => i_clk,
            i_rst         => i_rst,
            i_upperBound1 => upbnd2,
            i_upperBound2 => upbnd1,
            o_state       => pwm2
        );

    o_led1 <= pwm1;
    o_led2 <= pwm2;

    -- LED1 呼吸狀態機
    FSM1: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            state1 <= gettingBright;
        elsif rising_edge(i_clk) then
            case state1 is
                when gettingBright =>
                    if upbnd1 = "11111111" then
                        state1 <= gettingDark;
                    end if;
                when gettingDark =>
                    if upbnd1 ="00000000" then
                        state1 <= gettingBright;
                    end if;
                when others => null;
            end case;
        end if;        
    end process;

    -- LED2 呼吸狀態機（反向）
    FSM2: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            state2 <= gettingDark;
        elsif rising_edge(i_clk) then
            case state2 is
                when gettingBright =>
                    if upbnd2 = "11111111" then
                        state2 <= gettingDark;
                    end if;
                when gettingDark =>
                    if upbnd2 = "00000000" then
                        state2 <= gettingBright;
                    end if;
                when others => null;
            end case;
        end if;        
    end process;

    -- upbnd1, upbnd2 亮度調整
    upbnd1p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            upbnd1 <= "00000000";
        elsif rising_edge(i_clk) then
            if alreadyP_PWM_cycles = '1' then
                case state1 is
                    when gettingBright =>
                        if upbnd1 < "11111111" then
                            upbnd1 <= upbnd1 + 1;
                        end if;
                    when gettingDark =>
                        if upbnd1 > "00000000" then
                            upbnd1 <=upbnd1 - 1;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process upbnd1p;

    upbnd2p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            upbnd2 <= "11111111";
        elsif rising_edge(i_clk) then
            if alreadyP_PWM_cycles = '1' then
                case state2 is
                    when gettingBright =>
                        if upbnd2 < "11111111" then
                            upbnd2 <=upbnd2 + 1;
                        end if;
                    when gettingDark =>
                        if upbnd2 > "00000000" then
                            upbnd2 <= upbnd2 - 1;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process upbnd2p;

    -- 累積 P 個 PWM 週期後觸發亮度變化
    P_PWM_cycles: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            pwmCnt <= "00000000";
            alreadyP_PWM_cycles <= '0';
        elsif rising_edge(i_clk) then        
            if pwm_pedge = '1' then
                if pwmCnt = P then
                    pwmCnt <= (others => '0');
                    alreadyP_PWM_cycles <= '1';
                else
                    pwmCnt <= pwmCnt + 1;
                    alreadyP_PWM_cycles <= '0';
                end if;
            else
                alreadyP_PWM_cycles <= '0';
            end if;
        end if;
    end process P_PWM_cycles;

    -- 偵測 PWM1 上升沿
    detect_PWM_edge: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            pwm_pedge <= '0';
            pwm_old <= '0';
        elsif rising_edge(i_clk) then    
            pwm_old <= pwm1;
            if pwm_old = '0' and pwm1 = '1' then
                pwm_pedge <= '1';
            else
                pwm_pedge <= '0';
            end if;
        end if;
    end process;
end Behavioral;