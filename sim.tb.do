vlog mbist_tb.sv +define+MARCH12_XS
#vlog mbist_tb.sv +define+GALPAT_YS
#vsim work.mbist_tb
restart -f
#source wave.tb.do
run -all
