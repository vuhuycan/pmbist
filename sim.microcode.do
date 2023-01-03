#vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS
#vlog microcode.sv +define+TEST_U_CODE +define+GALPAT_YS
 vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS_TESTLOOP

#vsim work.microcode_container
#source wave.microcode.do

 restart -f
 run -all
