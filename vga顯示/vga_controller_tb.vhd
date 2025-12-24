LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY vga_controller_tb IS
END vga_controller_tb;

ARCHITECTURE behavior OF vga_controller_tb IS
  -- 測試用時鐘與重置
  SIGNAL i_clk    : STD_LOGIC := '0';  -- 100MHz 輸入時鐘（下方用 10ns 週期模擬）
  SIGNAL i_rst    : STD_LOGIC := '1';  -- 同步/非同步重置（依 VGA.vhd 的用法）

  -- VGA 介面訊號
  SIGNAL o_h_sync : STD_LOGIC;
  SIGNAL o_v_sync : STD_LOGIC;
  SIGNAL o_red    : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL o_green  : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL o_blue   : STD_LOGIC_VECTOR(3 DOWNTO 0);

  -- 直接例化 VGA（注意：entity 名稱是 VGA）
  COMPONENT VGA IS
    GENERIC(
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
    PORT (
      i_clk      : IN STD_LOGIC;
      i_rst      : IN STD_LOGIC;
      o_red      : OUT STD_LOGIC_VECTOR(3 downto 0);
      o_green    : OUT STD_LOGIC_VECTOR(3 downto 0);
      o_blue     : OUT STD_LOGIC_VECTOR(3 downto 0);
      o_h_sync   : OUT STD_LOGIC;
      o_v_sync   : OUT STD_LOGIC
    );
  END COMPONENT;

BEGIN
  -- UUT 例化
  uut: VGA
    PORT MAP(
      i_clk    => i_clk,
      i_rst    => i_rst,
      o_red    => o_red,
      o_green  => o_green,
      o_blue   => o_blue,
      o_h_sync => o_h_sync,
      o_v_sync => o_v_sync
    );

  -- 100MHz 時鐘：10ns 週期（50% 佔空比）
  CLOCK_PROC: PROCESS
  BEGIN
    i_clk <= '0';
    WAIT FOR 5 ns;
    i_clk <= '1';
    WAIT FOR 5 ns;
  END PROCESS;

  -- 重置程序：先保持重置，稍後解除
  RESET_PROC: PROCESS
  BEGIN
    i_rst <= '1';
    WAIT FOR 50 ns;     -- 保持重置一段時間
    i_rst <= '0';       -- 解除重置
    WAIT FOR 10 ms;     -- 模擬一段時間
    WAIT;
  END PROCESS;

END behavior;