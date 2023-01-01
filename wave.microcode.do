onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /microcode_container/clk
add wave -noupdate /microcode_container/rstn
add wave -noupdate /microcode_container/i_shift_mode
add wave -noupdate /microcode_container/i_jmp_to_inst
add wave -noupdate /microcode_container/i_jmp_en
add wave -noupdate /microcode_container/o_op_cmd
add wave -noupdate /microcode_container/o_data
add wave -noupdate -radix hexadecimal /microcode_container/o_addr_x
add wave -noupdate -radix hexadecimal /microcode_container/o_addr_y
add wave -noupdate -group INS_FETCH /microcode_container/bg_data_type
add wave -noupdate -group INS_FETCH /microcode_container/bg_data_inv
add wave -noupdate -group INS_FETCH /microcode_container/addr_x_cmd
add wave -noupdate -group INS_FETCH /microcode_container/addr_y_cmd
add wave -noupdate -group INS_FETCH /microcode_container/apply_addr_reg
add wave -noupdate -group INS_FETCH /microcode_container/no_last_addr_count
add wave -noupdate -group INS_FETCH /microcode_container/rpt_cntr_cmd
add wave -noupdate -group INS_FETCH /microcode_container/next_inst_cond_x
add wave -noupdate -group INS_FETCH /microcode_container/next_inst_cond_y
add wave -noupdate -group INS_FETCH /microcode_container/next_inst_cond_rc
add wave -noupdate -group INS_FETCH /microcode_container/loop_en
add wave -noupdate -group INS_FETCH /microcode_container/inv_bg_data
add wave -noupdate -group INS_FETCH /microcode_container/inv_addr_seq
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /microcode_container/r_addr_ax_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /microcode_container/r_addr_ay_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /microcode_container/r_addr_bx_reg
add wave -noupdate -expand -group {addr regs} -radix hexadecimal /microcode_container/r_addr_by_reg
add wave -noupdate -expand -group flowCTRL /microcode_container/next_loop_reg
add wave -noupdate -expand -group flowCTRL /microcode_container/r_loop_reg
add wave -noupdate -expand -group flowCTRL /microcode_container/next_inst_cond_mask
add wave -noupdate -expand -group flowCTRL /microcode_container/next_inst_cond_sastified
add wave -noupdate -expand -group flowCTRL /microcode_container/jmp_en
add wave -noupdate -expand -group flowCTRL -radix hexadecimal /microcode_container/r_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /microcode_container/jmp_to_inst
add wave -noupdate -expand -group uCode -radix hexadecimal /microcode_container/next_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /microcode_container/r_inst_ptr
add wave -noupdate -expand -group uCode -radix hexadecimal /microcode_container/microcode
add wave -noupdate -expand -group uCode -radix hexadecimal /microcode_container/curr_inst
add wave -noupdate -expand -group DatGen /microcode_container/bg_data_inv
add wave -noupdate -expand -group DatGen /microcode_container/bg_data_inv_af_loop
add wave -noupdate -expand -group DatGen /microcode_container/next_data_reg
add wave -noupdate -expand -group DatGen /microcode_container/r_data_reg
add wave -noupdate /microcode_container/r_addr_x_max
add wave -noupdate /microcode_container/r_addr_x_min
add wave -noupdate -radix hexadecimal /microcode_container/r_addr_ax_reg
add wave -noupdate -radix hexadecimal /microcode_container/r_addr_bx_reg
add wave -noupdate -radix hexadecimal /microcode_container/r_addr_ay_reg
add wave -noupdate -radix hexadecimal /microcode_container/r_addr_by_reg
add wave -noupdate /microcode_container/next_addr_ax_reg
add wave -noupdate /microcode_container/next_addr_bx_reg
add wave -noupdate /microcode_container/next_addr_x_reg
add wave -noupdate /microcode_container/addr_x_op
add wave -noupdate /microcode_container/addr_x_op_p1
add wave -noupdate /microcode_container/addr_x_op_m1
add wave -noupdate /microcode_container/out_addr_x
add wave -noupdate /microcode_container/addr_x_max_carry
add wave -noupdate /microcode_container/addr_x_min_carry
add wave -noupdate /microcode_container/r_addr_y_max
add wave -noupdate /microcode_container/r_addr_y_min
add wave -noupdate /microcode_container/next_addr_ay_reg
add wave -noupdate /microcode_container/next_addr_by_reg
add wave -noupdate /microcode_container/next_addr_y_reg
add wave -noupdate /microcode_container/addr_y_op
add wave -noupdate /microcode_container/addr_y_op_p1
add wave -noupdate /microcode_container/addr_y_op_m1
add wave -noupdate /microcode_container/out_addr_y
add wave -noupdate /microcode_container/addr_y_max_carry
add wave -noupdate /microcode_container/addr_y_min_carry
add wave -noupdate /microcode_container/r_rpt_cntr_reg
add wave -noupdate /microcode_container/next_rpt_cntr_reg
add wave -noupdate /microcode_container/r_rc_max
add wave -noupdate /microcode_container/rc_carry
add wave -noupdate /microcode_container/addr_x_carry
add wave -noupdate /microcode_container/addr_y_carry
add wave -noupdate /microcode_container/addr_x_cmd_af_loop
add wave -noupdate /microcode_container/addr_y_cmd_af_loop
add wave -noupdate /microcode_container/r_inv_addr_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28692 ps} 1} {{Cursor 2} {28590 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 300
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
WaveRestoreZoom {0 ps} {3736 ps}
