#vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS
vlog microcode.sv +define+TEST_U_CODE +define+GALPAT_YS
#vsim work.microcode_container
restart -f
#source wave.microcode.do
run -all
