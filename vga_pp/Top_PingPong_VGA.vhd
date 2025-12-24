library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_PingPong_VGA is
    port (
        CLK_100MHZ : in  STD_LOGIC;              -- System Clock
        RESET      : in  STD_LOGIC;              -- System Reset (Active Low: 0 = Reset)
        BTN_L      : in  STD_LOGIC;              -- Left Button
        BTN_R      : in  STD_LOGIC;              -- Right Button
        SW_SPEED   : in  STD_LOGIC;              -- Speed Switch
        
        -- VGA Interface
        VGA_HS     : out STD_LOGIC;
        VGA_VS     : out STD_LOGIC;
        VGA_R      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B      : out STD_LOGIC_VECTOR(3 downto 0);
        
        -- LED Output (Optional, for debugging)
        LED_OUT    : out STD_LOGIC_VECTOR(7 downto 0) 
    );
end Top_PingPong_VGA;

architecture Behavioral of Top_PingPong_VGA is

    -- Internal Signals
    signal led_state : STD_LOGIC_VECTOR(7 downto 0); -- LED status from pingpong game
    
    -- VGA Coordinate Signals
    signal h_pos     : INTEGER range 0 to 2000; 
    signal v_pos     : INTEGER range 0 to 2000;
    signal video_on  : STD_LOGIC;
    
    -- RGB Color Signal
    signal rgb_out   : STD_LOGIC_VECTOR(11 downto 0);
    
    -- Reset Signal for VGA (Inverted because VGA uses Active High reset)
    signal vga_reset : STD_LOGIC;

    -- Drawing Constants
    constant BOX_W   : integer := 60;  -- LED Box Width
    constant BOX_H   : integer := 40;  -- LED Box Height
    constant GAP     : integer := 20;  -- Gap between boxes
    constant START_X : integer := 100; -- Starting X coordinate
    constant START_Y : integer := 280; -- Starting Y coordinate

begin

    -- Reset Logic Fix:
    -- Pingpong uses '0' for reset (Active Low).
    -- VGA uses '1' for reset (Active High).
    -- We assume input RESET is Active Low (like pingpong).
    vga_reset <= not RESET; 

    -- 1. Instantiate PingPong Game Logic
    inst_pingpong: entity work.pingpong
        port map (
            i_clk          => CLK_100MHZ,
            i_rst          => RESET,       -- Active Low
            i_left_button  => BTN_L,
            i_right_button => BTN_R,
            i_speed_switch => SW_SPEED,
            o_count        => led_state
        );
        
    LED_OUT <= led_state;

    -- 2. Instantiate VGA Controller
    inst_vga: entity work.VGA
        port map (
            i_clk        => CLK_100MHZ,
            i_rst        => vga_reset,   -- Active High (Inverted)
            
            -- Pixel Data & Coordinates
            i_pixel_data => rgb_out,     -- Color input from Top
            o_h_pos      => h_pos,       -- Current X position
            o_v_pos      => v_pos,       -- Current Y position
            o_video_on   => video_on,    -- Visible area flag
            
            -- Hardware Outputs
            o_red        => VGA_R,
            o_green      => VGA_G,
            o_blue       => VGA_B,
            o_h_sync     => VGA_HS,
            o_v_sync     => VGA_VS
        );

    -- 3. Graphics Generation Logic
    process(h_pos, v_pos, video_on, led_state)
        variable box_idx : integer;
    begin
        -- Default Background Color (Black)
        rgb_out <= "000000000000"; 
        
        if video_on = '1' then
            
            -- Check Y range for the row of boxes
            if (v_pos >= START_Y) and (v_pos < START_Y + BOX_H) then
                -- Check X range for the whole group of boxes
                if (h_pos >= START_X) and (h_pos < START_X + (BOX_W + GAP) * 8) then
                    
                    -- Calculate which box we are currently drawing
                    -- We use 'mod' to find position within a box+gap cycle
                    if ((h_pos - START_X) mod (BOX_W + GAP)) < BOX_W then
                        -- Calculate Box Index (0 to 7)
                        -- Note: LED vector is 7 downto 0, visual layout is Left(7)..Right(0) or Left(0)..Right(7)?
                        -- Adjust formula based on your visual preference. 
                        -- Here: Leftmost on screen corresponds to led_state(7).
                        box_idx := 7 - ((h_pos - START_X) / (BOX_W + GAP)); 
                        
                        -- Safety check for index bounds
                        if box_idx >= 0 and box_idx <= 7 then
                            -- Default Box Color (Dim Gray Frame)
                            rgb_out <= "001100110011"; 
                            
                            -- If the LED bit is '1', light it up!
                            if led_state(box_idx) = '1' then
                                if box_idx >= 4 then
                                    rgb_out <= "111100000000"; -- Red for Left side
                                else
                                    rgb_out <= "000011110000"; -- Green for Right side
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            -- Draw a simple floor line
            if v_pos = START_Y + BOX_H + 10 then
                if h_pos > START_X - 20 and h_pos < START_X + (BOX_W + GAP) * 8 + 20 then
                    rgb_out <= "111111111111"; -- White Line
                end if;
            end if;
            
        else
            rgb_out <= (others => '0'); -- Blanking interval
        end if;
    end process;

end Behavioral;