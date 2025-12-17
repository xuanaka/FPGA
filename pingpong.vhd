library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity pingpong is
    Port (
        i_clk : in  STD_LOGIC;
        i_rst : in  STD_LOGIC;        -- 低態有效非同步重置
        i_swL : in  STD_LOGIC;        -- 左側按鍵
        i_swR : in  STD_LOGIC;        -- 右側按鍵
        o_led : out STD_LOGIC_VECTOR (7 downto 0)
    );
end pingpong;

architecture Behavioral of pingpong is
    -- 狀態
    type STATE_TYPE is (MovingL, MovingR, Lwin, Rwin);
    signal state      : STATE_TYPE;
    signal prev_state : STATE_TYPE;   -- 前一拍狀態（判斷剛進入/離開）

    -- LED 與分數
    signal led_r  : STD_LOGIC_VECTOR (7 downto 0);
    signal scoreL : unsigned(3 downto 0);
    signal scoreR : unsigned(3 downto 0);

    -- 分數顯示當拍加 1 的偵測（用於 LED 顯示避免舊值閃爍）
    signal enter_Lwin : std_logic;
    signal enter_Rwin : std_logic;

    -- 變速控制：可變節拍（move_tick）產生
    constant DIV_WIDTH      : integer := 24;  -- 除頻器位寬（足夠覆蓋實機需求）
    -- 模擬用：數十個時脈就移動一次（Vivado/Modelsim 看波形方便）
    constant MIN_DIV_SIM    : integer := 5;
    constant MAX_DIV_SIM    : integer := 40;
    -- 實機用（舉例 100MHz 時脈）：每 20ms ~ 300ms 移動一次
    constant MIN_DIV_HW     : integer := 2_000_000;  -- 20ms @100MHz
    constant MAX_DIV_HW     : integer := 30_000_000; -- 300ms @100MHz

    -- 選用哪組參數（預設用模擬；燒板時改成 HW 那組）
    constant MIN_DIV        : integer := MIN_DIV_SIM;
    constant MAX_DIV        : integer := MAX_DIV_SIM;

    signal div_counter : unsigned(DIV_WIDTH-1 downto 0);
    signal div_target  : unsigned(DIV_WIDTH-1 downto 0);
    signal move_tick   : std_logic;  -- = '1' 時才移動一格

    -- 簡單 16-bit LFSR 做擬隨機數
    signal lfsr : std_logic_vector(15 downto 0);

    -- 進入移動狀態（用來在「反彈或發球」時抽新速度）
    signal enter_MovingR : std_logic;
    signal enter_MovingL : std_logic;
begin
    o_led <= led_r;

    -- 剛進入分數狀態（供 LED 顯示當拍+1 使用）
    enter_Lwin <= '1' when (state = Lwin and prev_state /= Lwin) else '0';
    enter_Rwin <= '1' when (state = Rwin and prev_state /= Rwin) else '0';

    -- 剛進入移動狀態（反彈或從分數畫面發球）
    enter_MovingR <= '1' when (state = MovingR and prev_state /= MovingR) else '0';
    enter_MovingL <= '1' when (state = MovingL and prev_state /= MovingL) else '0';

    --------------------------------------------------------------------
    -- 狀態機：控制球移動與勝負判斷
    --------------------------------------------------------------------
    FSM: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            state      <= MovingR;
            prev_state <= MovingR;
        elsif rising_edge(i_clk) then
            prev_state <= state;

            case state is
                when MovingR =>
                    if (led_r(0) = '1') and (i_swR = '1') then
                        state <= MovingL;            -- 右邊界正確接到，往左
                    elsif (led_r(0) = '1') and (i_swR = '0') then
                        state <= Lwin;               -- 沒接到，左方得分
                    elsif (led_r(0) = '0') and (i_swR = '1') then
                        state <= Lwin;               -- 過早按，左方得分
                    end if;

                when MovingL =>
                    if (led_r(7) = '1') and (i_swL = '1') then
                        state <= MovingR;            -- 左邊界正確接到，往右
                    elsif (led_r(7) = '1') and (i_swL = '0') then
                        state <= Rwin;               -- 沒接到，右方得分
                    elsif (led_r(7) = '0') and (i_swL = '1') then
                        state <= Rwin;               -- 過早按，右方得分
                    end if;

                when Lwin =>
                    -- 顯示分數期間，按左鍵繼續，改為往右發球
                    if i_swL = '1' then
                        state <= MovingR;
                    end if;

                when Rwin =>
                    -- 顯示分數期間，按右鍵繼續，改為往左發球
                    if i_swR = '1' then
                        state <= MovingL;
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 變速節拍產生器：move_tick
    -- - LFSR 每拍更新；在「反彈或發球」時抽新 div_target
    -- - 在 MovingL/MovingR 狀態累計 div_counter；達標送出 move_tick
    --------------------------------------------------------------------
    SPEED_P: process(i_clk, i_rst)
        variable feedback : std_logic;
        variable rnd8     : integer;
        variable span     : integer;
        variable val      : integer;
    begin
        if i_rst = '0' then
            lfsr        <= x"ACE1"; -- 任意非 0 初值
            div_counter <= (others => '0');
            -- 初始速度
            div_target  <= to_unsigned(MIN_DIV, DIV_WIDTH);
            move_tick   <= '0';
        elsif rising_edge(i_clk) then
            -- LFSR free-run
            feedback := lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10);
            lfsr     <= lfsr(14 downto 0) & feedback;

            if (state = MovingR) or (state = MovingL) then
                -- 反彈或剛發球：抽新速度，並清計數
                if (enter_MovingR = '1') or (enter_MovingL = '1') then
                    rnd8 := to_integer(unsigned(lfsr(7 downto 0)));
                    span := MAX_DIV - MIN_DIV + 1;
                    val  := MIN_DIV + (rnd8 mod span);
                    div_target  <= to_unsigned(val, DIV_WIDTH);
                    div_counter <= (others => '0');
                    move_tick   <= '0';
                else
                    -- 依 div_target 節拍送出 move_tick
                    if div_counter >= div_target then
                        div_counter <= (others => '0');
                        move_tick   <= '1';
                    else
                        div_counter <= div_counter + 1;
                        move_tick   <= '0';
                    end if;
                end if;
            else
                -- 非移動狀態不送 tick，並歸零計數器
                div_counter <= (others => '0');
                move_tick   <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- LED 顯示與球位置更新（受 move_tick 節拍控制）
    --------------------------------------------------------------------
    LED_P: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            led_r <= "10000000"; -- 初始在最左邊
        elsif rising_edge(i_clk) then
            case state is
                when MovingR =>
                    -- 剛從 Lwin 離開：從最左端重新發球（本拍僅定位，不移動）
                    if prev_state = Lwin then
                        led_r <= "10000000";
                    -- 節拍到且尚未碰最右端才右移
                    elsif (move_tick = '1') and (led_r(0) = '0') then
                        led_r(7)           <= '0';
                        led_r(6 downto 0)  <= led_r(7 downto 1);
                    end if;

                when MovingL =>
                    -- 剛從 Rwin 離開：從最右端重新發球（本拍僅定位，不移動）
                    if prev_state = Rwin then
                        led_r <= "00000001";
                    -- 節拍到且尚未碰最左端才左移
                    elsif (move_tick = '1') and (led_r(7) = '0') then
                        led_r(7 downto 1) <= led_r(6 downto 0);
                        led_r(0)          <= '0';
                    end if;

                when Lwin =>
                    -- 顯示左方分數於高 4 bit
                    -- 若本拍「剛進入 Lwin」，則顯示 scoreL+1（與實際加分同拍呈現）
                    if (enter_Lwin = '1') and (scoreL < to_unsigned(15, 4)) then
                        led_r <= std_logic_vector(scoreL + 1) & "0000";
                    else
                        led_r <= std_logic_vector(scoreL) & "0000";
                    end if;

                when Rwin =>
                    -- 顯示右方分數於低 4 bit
                    -- 若本拍「剛進入 Rwin」，則顯示 scoreR+1（與實際加分同拍呈現）
                    if (enter_Rwin = '1') and (scoreR < to_unsigned(15, 4)) then
                        led_r <= "0000" & std_logic_vector(scoreR + 1);
                    else
                        led_r <= "0000" & std_logic_vector(scoreR);
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- 分數累加（僅在剛進入得分狀態的那一拍 +1，上限 15）
    --------------------------------------------------------------------
    score_L_p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            scoreL <= (others => '0');
        elsif rising_edge(i_clk) then
            if (state = Lwin) and (prev_state /= Lwin) and (scoreL < to_unsigned(15, 4)) then
                scoreL <= scoreL + 1;
            end if;
        end if;
    end process;

    score_R_p: process(i_clk, i_rst)
    begin
        if i_rst = '0' then
            scoreR <= (others => '0');
        elsif rising_edge(i_clk) then
            if (state = Rwin) and (prev_state /= Rwin) and (scoreR < to_unsigned(15, 4)) then
                scoreR <= scoreR + 1;
            end if;
        end if;
    end process;

end Behavioral;