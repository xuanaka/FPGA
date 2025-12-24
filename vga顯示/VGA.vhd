library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA is
    generic(
        H_RES     : INTEGER  := 800;      -- H_RES  : 可見像素數（每行顯示的像素寬度）
        H_FP      : INTEGER  := 56;       -- H_FP   : 前沿空白（可見像素之後、HSYNC之前的空白）
        H_SYNC    : INTEGER  := 120;      -- H_SYNC : 水平同步脈衝寬度（通知一行結束）
        H_BP      : INTEGER  := 64;       -- H_BP   : 後沿空白（HSYNC之後、下一行可見像素之前的空白）
        H_POL     : STD_LOGIC := '1';     -- H_POL  : 水平同步脈衝極性（'1' 正脈衝、'0' 負脈衝）
        V_RES     : INTEGER  := 600;      -- V_RES  : 可見行數（每幀顯示的高度）
        V_FP      : INTEGER  := 37;       -- V_FP   : 前沿空白（可見行之後、VSYNC之前的空白行）
        V_SYNC    : INTEGER  := 6;        -- V_SYNC : 垂直同步脈衝寬度（通知一幀結束）
        V_BP      : INTEGER  := 23;       -- V_BP   : 後沿空白（VSYNC之後、下一幀可見行之前的空白）
        V_POL     : STD_LOGIC := '1'      -- V_POL  : 垂直同步脈衝極性（'1' 正脈衝、'0' 負脈衝）
    );
    port (
        i_clk      : IN STD_LOGIC;                           -- 100MHz 輸入時鐘
        i_rst      : IN STD_LOGIC;                           -- 同步/非同步重置
        o_red      : OUT STD_LOGIC_VECTOR(3 downto 0);       -- 4-bit R
        o_green    : OUT STD_LOGIC_VECTOR(3 downto 0);       -- 4-bit G
        o_blue     : OUT STD_LOGIC_VECTOR(3 downto 0);       -- 4-bit B
        o_h_sync   : OUT STD_LOGIC;                          -- 水平同步
        o_v_sync   : OUT STD_LOGIC                           -- 垂直同步
    );
end VGA;

architecture Behavior of VGA is
    constant H_TOTAL : INTEGER := H_RES + H_FP + H_SYNC + H_BP;
    constant V_TOTAL : INTEGER := V_RES + V_FP + V_SYNC + V_BP;

    signal h_count   : INTEGER range 0 to H_TOTAL - 1 := 0;
    signal v_count   : INTEGER range 0 to V_TOTAL - 1 := 0;

    signal pixel_clk : STD_LOGIC := '0';     -- 50MHz 像素時鐘
    signal clk_div   : STD_LOGIC := '0';

    -- 形狀參數（可自行調整）
    constant Cx      : INTEGER := 200;   -- 圓心 X
    constant Cy      : INTEGER := 150;   -- 圓心 Y
    constant Cr      : INTEGER := 80;    -- 圓半徑

    constant SQ_X0   : INTEGER := 350;   -- 正方形左上 X
    constant SQ_Y0   : INTEGER := 100;   -- 正方形左上 Y
    constant SQ_SIZE : INTEGER := 120;   -- 正方形邊長

    constant RT_X0   : INTEGER := 550;   -- 長方形左上 X
    constant RT_Y0   : INTEGER := 80;    -- 長方形左上 Y
    constant RT_W    : INTEGER := 180;   -- 長方形寬
    constant RT_H    : INTEGER := 100;   -- 長方形高

    -- 三角形（等腰三角形）頂點座標
    constant T_X0    : INTEGER := 250;   -- 頂點 A (X)
    constant T_Y0    : INTEGER := 400;   -- 頂點 A (Y)
    constant T_X1    : INTEGER := 450;   -- 頂點 B (X)
    constant T_Y1    : INTEGER := 500;   -- 頂點 B (Y)
    constant T_X2    : INTEGER := 150;   -- 頂點 C (X)
    constant T_Y2    : INTEGER := 500;   -- 頂點 C (Y)

    -- 可見區檢查
    signal visible   : STD_LOGIC := '0';
begin

    -- 100MHz 轉 50MHz 像素時鐘
    process (i_clk, i_rst)
    begin
        if i_rst = '1' then
            clk_div   <= '0';
            pixel_clk <= '0';
        elsif rising_edge(i_clk) then
            clk_div   <= not clk_div;
            pixel_clk <= clk_div;
        end if;
    end process;

    -- 水平計數
    process (pixel_clk, i_rst)
    begin
        if i_rst = '1' then
            h_count <= 0;
        elsif rising_edge(pixel_clk) then
            if h_count < H_TOTAL - 1 then
                h_count <= h_count + 1;
            else
                h_count <= 0;
            end if;
        end if;
    end process;

    -- 垂直計數
    process (pixel_clk, i_rst)
    begin
        if i_rst = '1' then
            v_count <= 0;
        elsif rising_edge(pixel_clk) then
            if h_count = H_TOTAL - 1 then
                if v_count < V_TOTAL - 1 then
                    v_count <= v_count + 1;
                else
                    v_count <= 0;
                end if;
            end if;
        end if;
    end process;

    -- HSYNC 產生
    process (h_count, i_rst)
    begin
        if i_rst = '1' then
            o_h_sync <= NOT H_POL;
        elsif h_count < H_RES + H_FP or h_count >= H_RES + H_FP + H_SYNC then
            o_h_sync <= NOT H_POL;
        else
            o_h_sync <= H_POL;
        end if;
    end process;

    -- VSYNC 產生
    process (v_count, i_rst)
    begin
        if i_rst = '1' then
            o_v_sync <= NOT V_POL;
        elsif v_count < V_RES + V_FP or v_count >= V_RES + V_FP + V_SYNC then
            o_v_sync <= NOT V_POL;
        else
            o_v_sync <= V_POL;
        end if;
    end process;

    -- 可見區域旗標
    process(h_count, v_count)
    begin
        if (h_count < H_RES) and (v_count < V_RES) then
            visible <= '1';
        else
            visible <= '0';
        end if;
    end process;

    -- RGB 輸出：圖形合成
    process (h_count, v_count, visible, i_rst)
        -- 三角形點在三角形內的判斷（藉由重心座標/向量叉積法）
        variable px, py   : integer;
        variable v0x, v0y : integer;
        variable v1x, v1y : integer;
        variable v2x, v2y : integer;
        variable c1, c2, c3 : integer;
        variable tri_inside : boolean;

        -- 圓形判斷
        variable dx, dy : integer;
        variable r2     : integer;

        -- 顏色暫存
        variable r, g, b : std_logic_vector(3 downto 0);
    begin
        if i_rst = '1' then
            o_red   <= "0000";
            o_green <= "0000";
            o_blue  <= "0000";
        else
            -- 預設背景黑
            r := "0000";
            g := "0000";
            b := "0000";

            if visible = '1' then
                px := h_count;
                py := v_count;

                -- 1) 圓形：青色
                dx := px - Cx;
                dy := py - Cy;
                r2 := Cr * Cr;
                if (dx*dx + dy*dy) <= r2 then
                    r := "0000";  -- R
                    g := "1111";  -- G
                    b := "1111";  -- B
                end if;

                -- 2) 正方形：紅色
                if (px >= SQ_X0) and (px < SQ_X0 + SQ_SIZE) and
                   (py >= SQ_Y0) and (py < SQ_Y0 + SQ_SIZE) then
                    r := "1111";
                    g := "0000";
                    b := "0000";
                end if;

                -- 3) 長方形：綠色
                if (px >= RT_X0) and (px < RT_X0 + RT_W) and
                   (py >= RT_Y0) and (py < RT_Y0 + RT_H) then
                    r := "0000";
                    g := "1111";
                    b := "0000";
                end if;

                -- 4) 三角形：藍色（使用向量叉積判斷同向）
                v0x := T_X2 - T_X0;
                v0y := T_Y2 - T_Y0;
                v1x := T_X1 - T_X0;
                v1y := T_Y1 - T_Y0;
                v2x := px   - T_X0;
                v2y := py   - T_Y0;

                -- 以三邊的方向一致性來判斷是否在三角形內
                -- 對每條邊做叉積符號一致性檢查
                -- 邊 AB 與點 P
                c1 := (T_X1 - T_X0) * (py - T_Y0) - (T_Y1 - T_Y0) * (px - T_X0);
                -- 邊 BC 與點 P
                c2 := (T_X2 - T_X1) * (py - T_Y1) - (T_Y2 - T_Y1) * (px - T_X1);
                -- 邊 CA 與點 P
                c3 := (T_X0 - T_X2) * (py - T_Y2) - (T_Y0 - T_Y2) * (px - T_X2);

                tri_inside := ((c1 >= 0) and (c2 >= 0) and (c3 >= 0)) or
                              ((c1 <= 0) and (c2 <= 0) and (c3 <= 0));

                if tri_inside then
                    r := "0000";
                    g := "0000";
                    b := "1111";
                end if;

                -- 若圖形重疊，後面條件會覆蓋前面顏色；可依需要改成混色或優先順序
            end if;

            o_red   <= r;
            o_green <= g;
            o_blue  <= b;
        end if;
    end process;

end Behavior;