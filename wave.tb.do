onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mbist_tb/pass
add wave -noupdate /mbist_tb/DUT/clk
add wave -noupdate /mbist_tb/DUT/rstn
add wave -noupdate /mbist_tb/DUT/i_shift_mode
add wave -noupdate /mbist_tb/DUT/si
add wave -noupdate /mbist_tb/DUT/so
add wave -noupdate /mbist_tb/DUT/o_end_of_prog
add wave -noupdate /mbist_tb/DUT/i_mbist_run
add wave -noupdate /mbist_tb/DUT/o_op_cmd
add wave -noupdate /mbist_tb/DUT/o_data
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/o_addr_x
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/o_addr_y
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/bg_data_type
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/bg_data_inv
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/addr_x_cmd
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/addr_y_cmd
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/apply_addr_reg
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/no_last_addr_count
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/rpt_cntr_cmd
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/next_inst_cond_x
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/next_inst_cond_y
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/next_inst_cond_rc
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/loop_mode
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/inv_bg_data
add wave -noupdate -group INS_FETCH /mbist_tb/DUT/inv_addr_seq
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /mbist_tb/DUT/r_addr_ax_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /mbist_tb/DUT/r_addr_ay_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /mbist_tb/DUT/r_addr_bx_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /mbist_tb/DUT/r_addr_by_reg
add wave -noupdate -expand -group flowCTRL -radix hexadecimal /mbist_tb/DUT/next_loop_reg
add wave -noupdate -expand -group flowCTRL -radix hexadecimal /mbist_tb/DUT/r_loop_reg
add wave -noupdate -expand -group flowCTRL /mbist_tb/DUT/next_inst_cond_mask
add wave -noupdate -expand -group flowCTRL /mbist_tb/DUT/next_inst_cond_sastified
add wave -noupdate -expand -group flowCTRL /mbist_tb/DUT/jmp_en
add wave -noupdate -expand -group flowCTRL -radix hexadecimal /mbist_tb/DUT/r_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /mbist_tb/DUT/jmp_to_inst
add wave -noupdate -expand -group uCode -radix hexadecimal /mbist_tb/DUT/next_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /mbist_tb/DUT/r_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /mbist_tb/DUT/microcode
add wave -noupdate -expand -group uCode -radix hexadecimal /mbist_tb/DUT/curr_inst
add wave -noupdate -expand -group DatGen /mbist_tb/DUT/bg_data_inv
add wave -noupdate -expand -group DatGen /mbist_tb/DUT/next_data_reg
add wave -noupdate -expand -group DatGen /mbist_tb/DUT/r_data_reg
add wave -noupdate /mbist_tb/DUT/r_addr_x_max
add wave -noupdate /mbist_tb/DUT/r_addr_x_min
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/r_addr_ax_reg
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/r_addr_bx_reg
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/r_addr_ay_reg
add wave -noupdate -radix hexadecimal /mbist_tb/DUT/r_addr_by_reg
add wave -noupdate /mbist_tb/DUT/next_addr_ax_reg
add wave -noupdate /mbist_tb/DUT/next_addr_bx_reg
add wave -noupdate /mbist_tb/DUT/next_addr_x_reg
add wave -noupdate /mbist_tb/DUT/addr_x_op
add wave -noupdate /mbist_tb/DUT/addr_x_op_p1
add wave -noupdate /mbist_tb/DUT/addr_x_op_m1
add wave -noupdate /mbist_tb/DUT/out_addr_x
add wave -noupdate /mbist_tb/DUT/addr_x_max_carry
add wave -noupdate /mbist_tb/DUT/addr_x_min_carry
add wave -noupdate /mbist_tb/DUT/r_addr_y_max
add wave -noupdate /mbist_tb/DUT/r_addr_y_min
add wave -noupdate /mbist_tb/DUT/next_addr_ay_reg
add wave -noupdate /mbist_tb/DUT/next_addr_by_reg
add wave -noupdate /mbist_tb/DUT/next_addr_y_reg
add wave -noupdate /mbist_tb/DUT/addr_y_op
add wave -noupdate /mbist_tb/DUT/addr_y_op_p1
add wave -noupdate /mbist_tb/DUT/addr_y_op_m1
add wave -noupdate /mbist_tb/DUT/out_addr_y
add wave -noupdate /mbist_tb/DUT/addr_y_max_carry
add wave -noupdate /mbist_tb/DUT/addr_y_min_carry
add wave -noupdate /mbist_tb/DUT/r_rpt_cntr_reg
add wave -noupdate /mbist_tb/DUT/next_rpt_cntr_reg
add wave -noupdate /mbist_tb/DUT/r_rc_max
add wave -noupdate /mbist_tb/DUT/rc_carry
add wave -noupdate /mbist_tb/DUT/addr_x_carry
add wave -noupdate /mbist_tb/DUT/addr_y_carry
add wave -noupdate /mbist_tb/DUT/addr_x_cmd_af_loop
add wave -noupdate /mbist_tb/DUT/addr_y_cmd_af_loop
add wave -noupdate /mbist_tb/DUT/r_inv_addr_en
add wave -noupdate /mbist_tb/DUT/loop_reg_id
add wave -noupdate /mbist_tb/DUT/repeat_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {158890 ps} 0} {{Cursor 2} {76892 ps} 1}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2163 ns}
