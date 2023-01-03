 vlog microcode.sv +define+MARCH12_XS
 vlog mbist_tb.sv  +define+MARCH12_XS

#vlog microcode.sv +define+GALPAT_YS
#vlog mbist_tb.sv  +define+GALPAT_YS

#vsim work.mbist_tb
#source wave.tb.do

 restart -f
 run -all
