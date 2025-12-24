library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity pingpong is
    port(
           i_clk            : in STD_LOGIC;
           i_rst            : in STD_LOGIC;
           i_left_button    : in STD_LOGIC; 
           i_right_button   : in STD_LOGIC;
           i_speed_switch   : in STD_LOGIC;
           o_count          : out STD_LOGIC_VECTOR(7 downto 0)     
        );   
end pingpong;

architecture Behavioral of pingpong is
signal count            : STD_LOGIC_VECTOR(7 downto 0);
signal right_score      : STD_LOGIC_VECTOR(3 downto 0);
signal left_score       : STD_LOGIC_VECTOR(3 downto 0);
signal divclk           : STD_LOGIC_VECTOR(26 downto 0);
signal led_clk          : STD_LOGIC;
signal left_button_reg  : STD_LOGIC;
signal right_button_reg : STD_LOGIC;

signal random           : STD_LOGIC_VECTOR(4 downto 0) := "10101";
signal rang_dice        : STD_LOGIC_VECTOR(1 downto 0);
signal clk_ball_random  : STD_LOGIC;
signal slow_clk         : STD_LOGIC;

-- 新增時鐘同步相關變數
signal led_clk_sync     : STD_LOGIC;

-- ? 定義多檔速度（分頻時鐘）
signal clk_speed_0      : STD_LOGIC;
signal clk_speed_1      : STD_LOGIC;
signal clk_speed_2      : STD_LOGIC;
signal clk_speed_3      : STD_LOGIC;

signal score_timer      : integer range 0 to 100000000 := 0;
constant SCORE_DISPLAY_TIME : integer := 100000000;
signal score_updated    : STD_LOGIC := '0';

type counter_state is (reserve, counter_is_counting_left, counter_is_counting_right, 
                       left_win, right_win, left_ready_serve, right_ready_serve);
signal counter_move_state: counter_state;
signal prestate: counter_state;

begin

o_count <= count;

-- ? 預設的四個速度檔位（基於分頻時鐘）
clk_speed_0 <= divclk(23);
clk_speed_1 <= divclk(24);
clk_speed_2 <= divclk(25);
clk_speed_3 <= divclk(26);

-- 預設為正常速度
slow_clk <= divclk(24);

-- 隨機骰子
rang_dice <= random(1 downto 0);

-- ? 用選擇邏輯穩定時脈輸出
process(i_clk, i_rst)
begin
    if i_rst = '0' then
        led_clk <= '0';
    elsif rising_edge(i_clk) then
        if i_speed_switch = '0' then
            -- 使用隨機時脈
            case rang_dice is
                when "00" => led_clk <= clk_speed_0;
                when "01" => led_clk <= clk_speed_1;
                when "10" => led_clk <= clk_speed_2;
                when others => led_clk <= clk_speed_3;
            end case;
        else
            -- 使用預設正常速度
            led_clk <= slow_clk;
        end if;
    end if;
end process;

-- 時鐘同步：避免時脈切換的毛刺
led_clk_sync <= led_clk when rising_edge(i_clk);

-- 隨機數生成器 (LFSR)：同步控制
random_gen: process(slow_clk, i_rst)
begin
    if i_rst = '0' then
        random <= "10101";
    elsif rising_edge(slow_clk) then
        random <= random(3 downto 0) & (random(4) xor random(1));
    end if;
end process;

-- 主狀態機
led_move_state: process(i_clk, i_rst)
begin
    if i_rst = '0' then
        counter_move_state <= reserve;
        prestate <= reserve;
        left_button_reg <= '0';
        right_button_reg <= '0';
        score_timer <= 0;
        score_updated <= '0';
    elsif rising_edge(i_clk) then
        left_button_reg <= i_left_button;
        right_button_reg <= i_right_button;
        
        case counter_move_state is 
            when counter_is_counting_left =>
                prestate <= counter_is_counting_left;
                score_timer <= 0;
                score_updated <= '0';
                
                if (count = "10000000") and (i_left_button = '1') then 
                    counter_move_state <= counter_is_counting_right;             
                elsif (count = "00000000") or (count < "10000000" and i_left_button = '1') then 
                    counter_move_state <= right_win;
                end if;
                
            when counter_is_counting_right =>
                prestate <= counter_is_counting_right;
                score_timer <= 0;
                score_updated <= '0';
                
                if (count = "00000001") and (i_right_button = '1') then
                    counter_move_state <= counter_is_counting_left;
                elsif (count = "00000000") or (i_right_button = '1' and count > "00000001") then 
                    counter_move_state <= left_win;
                end if;
                
            when right_win =>
                if score_updated = '0' then
                    score_updated <= '1';
                    score_timer <= 0;
                elsif score_timer < SCORE_DISPLAY_TIME then
                    score_timer <= score_timer + 1;
                else
                    counter_move_state <= reserve;
                    prestate <= right_win;
                    score_timer <= 0;
                    score_updated <= '0';
                end if;
                
            when left_win =>
                if score_updated = '0' then
                    score_updated <= '1';
                    score_timer <= 0;
                elsif score_timer < SCORE_DISPLAY_TIME then
                    score_timer <= score_timer + 1;
                else
                    counter_move_state <= reserve;
                    prestate <= left_win;
                    score_timer <= 0;
                    score_updated <= '0';
                end if;
                
            when left_ready_serve =>
                score_timer <= 0;
                score_updated <= '0';
                if count = "10000000" then
                    counter_move_state <= counter_is_counting_right;
                    prestate <= left_ready_serve;
                end if;
                
            when right_ready_serve =>
                score_timer <= 0;
                score_updated <= '0';
                if count = "00000001" then 
                    counter_move_state <= counter_is_counting_left;
                    prestate <= right_ready_serve;
                end if;
                
            when reserve =>
                score_timer <= 0;
                score_updated <= '0';
                if i_left_button = '1' and left_button_reg = '0' then
                    counter_move_state <= left_ready_serve;
                    prestate <= reserve;
                elsif i_right_button = '1' and right_button_reg = '0' then 
                    counter_move_state <= right_ready_serve;
                    prestate <= reserve;
                end if;
                
            when others =>
                counter_move_state <= reserve;
        end case;
    end if;
end process;

-- LED/計數器控制
counter: process(led_clk_sync, i_rst)
begin
    if i_rst = '0' then
        count <= "00000000";
    elsif rising_edge(led_clk_sync) then
        case counter_move_state is 
            when counter_is_counting_left =>
                count <= count(6 downto 0) & '0'; 
                
            when counter_is_counting_right =>
                count <= '0' & count(7 downto 1); 
                
            when right_win =>
                count <= left_score & right_score;
                
            when left_win =>    
                count <= left_score & right_score;
                
            when left_ready_serve =>
                count <= "10000000";
                
            when right_ready_serve =>
                count <= "00000001";
                
            when reserve =>
                count <= left_score & right_score;
                
            when others =>
                null;
        end case;
    end if;                
end process;

-- 分數計算
count_score: process(i_clk, i_rst)
begin
    if i_rst = '0' then
        right_score <= "0000"; 
        left_score  <= "0000"; 
    elsif rising_edge(i_clk) then
        if counter_move_state = right_win and score_updated = '0' and prestate = counter_is_counting_left then
            right_score <= right_score + 1;
        elsif counter_move_state = left_win and score_updated = '0' and prestate = counter_is_counting_right then
            left_score <= left_score + 1;
        end if;
    end if;
end process;

-- 時鐘分頻
fd: process(i_clk, i_rst)
begin
    if i_rst = '0' then 
        divclk <= (others => '0');
    elsif rising_edge(i_clk) then
        divclk <= divclk + 1;
    end if;
end process;

end Behavioral;
