vlog microcode.sv +define+TEST_U_CODE +define+MARCH12_XS
#vsim work.microcode_container
restart -f
#source wave.do
run 20000ps
