set_property IOSTANDARD LVCMOS25 [get_ports CLK_100MHZ]
set_property PACKAGE_PIN Y9 [get_ports CLK_100MHZ]

# ----------------------------------------------------------------------------
# Input Controls (Buttons & Switch)
# ----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS25} [get_ports {RESET}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS25} [get_ports {BTN_L}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS25} [get_ports {BTN_R}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS25} [get_ports {SW_SPEED}]

# LED ¿é¥X (¹ïÀ³ LED_OUT)
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[7]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[6]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[5]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[4]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[3]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[2]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[1]}]
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS25} [get_ports {LED_OUT[0]}]


set_property -dict {PACKAGE_PIN V4   IOSTANDARD LVCMOS25}  [get_ports {VGA_HS}]
set_property -dict {PACKAGE_PIN U6   IOSTANDARD LVCMOS25}  [get_ports {VGA_VS}]

set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS25} [get_ports {VGA_R[3]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS25} [get_ports {VGA_R[2]}]
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS25} [get_ports {VGA_R[1]}]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD LVCMOS25} [get_ports {VGA_R[0]}]

set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS25} [get_ports {VGA_G[3]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS25} [get_ports {VGA_G[2]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS25} [get_ports {VGA_G[1]}]
set_property -dict {PACKAGE_PIN AA7 IOSTANDARD LVCMOS25} [get_ports {VGA_G[0]}]

set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS25} [get_ports {VGA_B[3]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS25} [get_ports {VGA_B[2]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS25} [get_ports {VGA_B[1]}]
set_property -dict {PACKAGE_PIN AB4 IOSTANDARD LVCMOS25} [get_ports {VGA_B[0]}]
