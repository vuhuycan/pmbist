 vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS
#vlog microcode.sv +define+TEST_U_CODE +define+GALPAT_YS
#vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS_TESTLOOP
 vlog virtual_netlist.sv +define+TEST

 vsim work.virtual_netlist
#source wave.virtualnet.do

 restart -f
 run -all
