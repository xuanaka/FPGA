library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA is
    generic(
        H_RES     : INTEGER  := 800;
        H_FP      : INTEGER  := 56;
        H_SYNC    : INTEGER  := 120;
        H_BP      : INTEGER  := 64;
        H_POL     : STD_LOGIC := '1';
        
        V_RES     : INTEGER  := 600;
        V_FP      : INTEGER  := 37;
        V_SYNC    : INTEGER  := 6;
        V_BP      : INTEGER  := 23;
        V_POL     : STD_LOGIC := '1'
    );
    port (
        i_clk        : IN STD_LOGIC;
        i_rst        : IN STD_LOGIC; -- Active High Reset
        
        -- Pixel Color Input
        i_pixel_data : IN STD_LOGIC_VECTOR(11 downto 0); 
        
        -- Position Feedback
        o_h_pos      : OUT INTEGER; 
        o_v_pos      : OUT INTEGER;
        o_video_on   : OUT STD_LOGIC;

        -- Hardware Output
        o_red        : OUT STD_LOGIC_VECTOR(3 downto 0);
        o_green      : OUT STD_LOGIC_VECTOR(3 downto 0);
        o_blue       : OUT STD_LOGIC_VECTOR(3 downto 0);
        o_h_sync     : OUT STD_LOGIC;
        o_v_sync     : OUT STD_LOGIC
    );
end VGA;

architecture Behavior of VGA is
    constant H_TOTAL : INTEGER := H_RES + H_FP + H_SYNC + H_BP;
    constant V_TOTAL : INTEGER := V_RES + V_FP + V_SYNC + V_BP;

    signal h_count   : INTEGER range 0 to H_TOTAL - 1 := 0;
    signal v_count   : INTEGER range 0 to V_TOTAL - 1 := 0;
    
    signal pixel_clk : STD_LOGIC := '0';
    signal clk_div   : STD_LOGIC := '0';
    signal video_on  : STD_LOGIC := '0';

begin

    o_h_pos    <= h_count;
    o_v_pos    <= v_count;
    o_video_on <= video_on;

    -- Clock Divider (100MHz -> 50MHz)
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

    -- Horizontal Counter
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

    -- Vertical Counter
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

    -- H-Sync Generator
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

    -- V-Sync Generator
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

    -- Video On Signal
    video_on <= '1' when (h_count < H_RES) and (v_count < V_RES) else '0';

    -- RGB Output Logic
    process (pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if video_on = '1' then
                o_red   <= i_pixel_data(11 downto 8);
                o_green <= i_pixel_data(7 downto 4);
                o_blue  <= i_pixel_data(3 downto 0);
            else
                o_red   <= (others => '0');
                o_green <= (others => '0');
                o_blue  <= (others => '0');
            end if;
        end if;
    end process;

end Behavior;