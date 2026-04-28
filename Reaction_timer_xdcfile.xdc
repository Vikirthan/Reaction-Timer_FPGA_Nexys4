## reactionTimer - Nexys 4 XDC Constraints
## Clock: 100 MHz on pin E3

set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Buttons (active HIGH on Nexys 4 except BTNRES)
## Using: BTNC = clear, BTNU = start, BTND = stop

set_property PACKAGE_PIN E16 [get_ports clear]
set_property IOSTANDARD LVCMOS33 [get_ports clear]

set_property PACKAGE_PIN F15 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]

set_property PACKAGE_PIN V10 [get_ports stop]
set_property IOSTANDARD LVCMOS33 [get_ports stop]

## LED (LD0)
set_property PACKAGE_PIN T8 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]

## 7-Segment Display - Anode signals (AN0..AN3 of right 4-digit group)
## AN0..AN7 all exist on Nexys 4; we use lower 4 (AN0-AN3)
set_property PACKAGE_PIN N6  [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]

set_property PACKAGE_PIN M6  [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]

set_property PACKAGE_PIN M3  [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]

set_property PACKAGE_PIN N5  [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

## 7-Segment Display - Cathode signals (sseg[7]=DP, sseg[6]=CA ... sseg[0]=CG)
## CA=sseg[6], CB=sseg[5], CC=sseg[4], CD=sseg[3], CE=sseg[2], CF=sseg[1], CG=sseg[0], DP=sseg[7]

set_property PACKAGE_PIN L3  [get_ports {sseg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[6]}]

set_property PACKAGE_PIN N1  [get_ports {sseg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[5]}]

set_property PACKAGE_PIN L5  [get_ports {sseg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[4]}]

set_property PACKAGE_PIN L4  [get_ports {sseg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[3]}]

set_property PACKAGE_PIN K3  [get_ports {sseg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[2]}]

set_property PACKAGE_PIN M2  [get_ports {sseg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[1]}]

set_property PACKAGE_PIN L6  [get_ports {sseg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[0]}]

set_property PACKAGE_PIN M4  [get_ports {sseg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg[7]}]
