`define MARCH12_XS
`timescale 1ps/1ps

module microcode_container
import pmbist::*;
(
    clk, rstn,
    
    i_shift_mode, si, so,
    o_end_of_prog,
    i_mbist_run,
    
    //i_jmp_to_inst,
    //i_jmp_en,
    
    o_op_cmd,
    o_addr_x,
    o_addr_y,
    o_data,
    //o_bg_data_type,
    //o_bg_data_inv
);

    input  logic clk, rstn;
    
    input  logic i_shift_mode, si;
    output logic so;
    output logic o_end_of_prog;
    input  logic i_mbist_run;
    
    //input logic[INST_NUM-1:0] i_jmp_to_inst;
    //input logic i_jmp_en;
    
    output t_op_cmd o_op_cmd;
    output logic [BG_DATA-1:0] o_data;
    output logic [ADDR_X-1:0]  o_addr_x;
    output logic [ADDR_Y-1:0]  o_addr_y;

    t_bg_data_type bg_data_type;
    t_dflt_inv bg_data_inv;
    t_addr_cmd addr_x_cmd, addr_y_cmd;
    t_addr_cmd addr_x_cmd_af_loop, addr_y_cmd_af_loop;
    t_apply_addr_reg apply_addr_reg;
    t_no_last_addr_count no_last_addr_count;
    t_rpt_cntr_cmd rpt_cntr_cmd;
    t_next_inst_cond next_inst_cond_x, next_inst_cond_y, next_inst_cond_rc;    
    t_loop_mode loop_mode;
    t_dflt_inv inv_bg_data, inv_addr_seq;
    logic [INST_NUM_W-1:0] jmp_to_inst;
    
    logic [INST-1:0] microcode [0:INST_NUM-1];
    logic [INST-1:0] curr_inst;
    logic [INST_NUM_W-1:0] r_inst_ptr, next_inst_ptr;
    logic jmp_en;
    logic inst_ptr_so,inst_ptr_si;

    logic next_inst_cond_sastified;
    logic[INST_NUM-1:0] r_loop_reg, next_loop_reg;





    assign inst_ptr_si = si;
    
    //---------------------------
    //-- Instruction Pointer:
    //---------------------------
    assign o_end_of_prog = r_inst_ptr==(INST_NUM-1) & next_inst_cond_sastified;
    assign jmp_en = ((loop_mode==REPEAT) & next_inst_cond_sastified & ~r_loop_reg[r_inst_ptr]) | (loop_mode==JUMP & ~next_inst_cond_sastified);

    assign next_inst_ptr =  //o_end_of_prog             ? r_inst_ptr    :
                            //~i_mbist_run              ? r_inst_ptr    :
                            jmp_en                    ? jmp_to_inst   : 
                            (i_mbist_run & next_inst_cond_sastified)? r_inst_ptr +1 : 
                                                        r_inst_ptr;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_inst_ptr <= 'hf;
        end else if (i_shift_mode) begin
            r_inst_ptr <= {r_inst_ptr[INST_NUM_W-2:0],inst_ptr_si};
        end else begin
            r_inst_ptr <= next_inst_ptr;
        end
    end 
    assign inst_ptr_so = r_inst_ptr[INST_NUM_W-1];
    
    

    //---------------------------
    //-- MicroCode:
    //---------------------------
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i =0; i <INST_NUM; i =i +1) begin
                microcode[i] <= '0;
            end
        end
        else if (i_shift_mode) begin
            microcode[0] <= {microcode[0][INST-2:0],inst_ptr_so};
            for (int i =1; i <INST_NUM; i =i +1) begin
                microcode[i] <= {microcode[i][INST-2:0],microcode[i-1][INST-1]};
            end
        end
    end    
    logic microcode_so;
    assign microcode_so = microcode[INST_NUM-1][INST-1];
    

    //---------------------------
    //-- Fetch current Instruction from MicroCode:
    //---------------------------
    assign curr_inst          = microcode[r_inst_ptr];

    assign o_op_cmd           =             t_op_cmd'(curr_inst[OP_CMD-1:0]);
    assign bg_data_type       =       t_bg_data_type'(curr_inst[OP_CMD+1:OP_CMD]);
    assign bg_data_inv        =           t_dflt_inv'(curr_inst[OP_CMD+2]);
    assign addr_x_cmd         =           t_addr_cmd'(curr_inst[OP_CMD+4:OP_CMD+3]);
    assign addr_y_cmd         =           t_addr_cmd'(curr_inst[OP_CMD+6:OP_CMD+5]);
    assign apply_addr_reg     =     t_apply_addr_reg'(curr_inst[OP_CMD+9:OP_CMD+7]);
    assign no_last_addr_count = t_no_last_addr_count'(curr_inst[OP_CMD+10]);
    assign rpt_cntr_cmd       =       t_rpt_cntr_cmd'(curr_inst[OP_CMD+11]);
    assign next_inst_cond_x   =     t_next_inst_cond'(curr_inst[OP_CMD+12]);
    assign next_inst_cond_y   =     t_next_inst_cond'(curr_inst[OP_CMD+13]);
    assign next_inst_cond_rc  =     t_next_inst_cond'(curr_inst[OP_CMD+14]);
    assign loop_mode            =          t_loop_mode'(curr_inst[OP_CMD+16:OP_CMD+15]);
    assign inv_bg_data        =           t_dflt_inv'(curr_inst[OP_CMD+17]);
    assign inv_addr_seq       =           t_dflt_inv'(curr_inst[OP_CMD+18]);
    assign jmp_to_inst        =                       curr_inst[INST-1:OP_CMD+19];
    




    //---------------------------
    //-- Declare signals for Addr Generators:
    //---------------------------
    logic [ADDR_X-1:0]  r_addr_x_max, r_addr_x_min;
    logic [ADDR_X-1:0]  r_addr_ax_reg, r_addr_bx_reg;
    logic [ADDR_X-1:0]  next_addr_ax_reg, next_addr_bx_reg, next_addr_x_reg;
    logic [ADDR_X-1:0]  addr_x_op, addr_x_op_p1, addr_x_op_m1;
    logic [ADDR_X-1:0]  out_addr_x;
    logic               addr_x_max_carry, addr_x_min_carry;

    logic [ADDR_Y-1:0]  r_addr_y_max, r_addr_y_min;
    logic [ADDR_Y-1:0]  r_addr_ay_reg, r_addr_by_reg;
    logic [ADDR_Y-1:0]  next_addr_ay_reg, next_addr_by_reg, next_addr_y_reg;
    logic [ADDR_Y-1:0]  addr_y_op, addr_y_op_p1, addr_y_op_m1;
    logic [ADDR_Y-1:0]  out_addr_y;
    logic               addr_y_max_carry, addr_y_min_carry;

    logic [RPT_CNTR-1:0]  r_rpt_cntr_reg, next_rpt_cntr_reg, r_rc_max;

    logic addr_x_carry, addr_y_carry, rc_carry;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_addr_y_max <= ADDR_Y_MAX;
            r_addr_x_max <= ADDR_X_MAX;
            r_addr_y_min <= ADDR_Y_MIN;
            r_addr_x_min <= ADDR_X_MIN;
        end else if (i_shift_mode) begin
            r_addr_y_max <= {r_addr_y_max[ADDR_Y-2:0],microcode_so};
            r_addr_y_min <= {r_addr_y_min[ADDR_Y-2:0],r_addr_y_max[ADDR_Y-1]}; 
            r_addr_x_max <= {r_addr_x_max[ADDR_X-2:0],r_addr_y_min[ADDR_Y-1]};
            r_addr_x_min <= {r_addr_x_min[ADDR_X-2:0],r_addr_x_max[ADDR_X-1]};
        end
    end 
    logic r_addr_x_min_so;
    assign r_addr_x_min_so = r_addr_x_min[ADDR_X-1];

    assign o_addr_x = out_addr_x;
    assign o_addr_y = out_addr_y;

    logic r_inv_addr_en;
    //always @(posedge clk or negedge rstn) begin
    always @(posedge clk) begin
        if (~rstn) begin
            r_inv_addr_en <= '0;
        end else 
        if (jmp_en & inv_addr_seq) begin
            r_inv_addr_en <= ~r_inv_addr_en;
            //r_inv_addr_en <= '1;
        end else 
        if (next_inst_cond_sastified & loop_mode==REPEAT & inv_addr_seq) begin
            //r_inv_addr_en <= '0;
            r_inv_addr_en <= ~r_inv_addr_en;
        end else begin
            r_inv_addr_en <= r_inv_addr_en;
        end
    end    
    
    //convert INC to DEC and DEC to INC:
    // before b1 b0 | b1 b0 after
    // KEEP   0  0  | 0  0  KEEP
    // CHG    0  1  | 0  1  CHG
    // INC    1  0  | 1  1  DEC
    // DEC    1  1  | 1  0  INC
    assign addr_x_cmd_af_loop = (r_inv_addr_en)? t_addr_cmd'({addr_x_cmd[1],addr_x_cmd[0]^addr_x_cmd[1]}) : addr_x_cmd;
    assign addr_y_cmd_af_loop = (r_inv_addr_en)? t_addr_cmd'({addr_y_cmd[1],addr_y_cmd[0]^addr_y_cmd[1]}) : addr_y_cmd;



    //---------------------------
    //-- Address X generator
    //---------------------------
    //select AX or BX for address operation:
    always @(*) begin
        case(apply_addr_reg)
        A         : addr_x_op = r_addr_ax_reg;
        B         : addr_x_op = r_addr_bx_reg;
        selAcptoB : addr_x_op = r_addr_ax_reg;
        selBcptoA : addr_x_op = r_addr_bx_reg;
        selArlB   : addr_x_op = r_addr_ax_reg;
        selBrlA   : addr_x_op = r_addr_bx_reg;
        AxorB     : addr_x_op = r_addr_ax_reg;
        selBrrA   : addr_x_op = r_addr_bx_reg;
        default   : addr_x_op = r_addr_ax_reg;
        endcase
    end

    assign addr_x_max_carry = (addr_x_op == r_addr_x_max);
    assign addr_x_min_carry = (addr_x_op == r_addr_x_min);
    always @(*) begin
        case(addr_x_cmd_af_loop)
        KEEP: addr_x_carry = '0;
        INC : addr_x_carry = addr_x_max_carry;
        DEC : addr_x_carry = addr_x_min_carry;
        CHG : begin
            case(addr_y_cmd_af_loop)
            INC: addr_x_carry = addr_x_max_carry;
            DEC: addr_x_carry = addr_x_min_carry;
            default: addr_x_carry = '0;
            endcase
        end
        default: addr_x_carry = '0;
        endcase
    end

    //address X operation:
    assign addr_x_op_p1 = (no_last_addr_count&next_inst_cond_sastified)? addr_x_op : addr_x_op +1;
    assign addr_x_op_m1 = (no_last_addr_count&next_inst_cond_sastified)? addr_x_op : addr_x_op -1;
    always @(*) begin
        case(addr_x_cmd_af_loop)
        KEEP: next_addr_x_reg =  addr_x_op;
        INC : next_addr_x_reg =  addr_x_op_p1;
        DEC : next_addr_x_reg =  addr_x_op_m1;
        CHG : begin
            case(addr_y_cmd_af_loop)
            INC: next_addr_x_reg = addr_y_max_carry? addr_x_op_p1 : addr_x_op; 
            DEC: next_addr_x_reg = addr_y_min_carry? addr_x_op_m1 : addr_x_op; 
            default: next_addr_x_reg =  addr_x_op;
            endcase
        end
        default: next_addr_x_reg =  addr_x_op;
        endcase
    end

    //write back address X operation to AX or BX register:
    always @(*) begin
        case(apply_addr_reg)
        A         : next_addr_ax_reg = next_addr_x_reg;
        B         : next_addr_ax_reg =   r_addr_ax_reg;
        selAcptoB : next_addr_ax_reg =   r_addr_ax_reg;
        selBcptoA : next_addr_ax_reg = next_addr_x_reg;
        selArlB   : next_addr_ax_reg =   r_addr_ax_reg;
        selBrlA   : next_addr_ax_reg = {next_addr_x_reg[ADDR_X-2:0],next_addr_x_reg[ADDR_X-1]};
        AxorB     : next_addr_ax_reg = next_addr_x_reg;
        selBrrA   : next_addr_ax_reg = {next_addr_x_reg[0],next_addr_x_reg[ADDR_X-1:1]};
        default   : next_addr_ax_reg = next_addr_x_reg;
        endcase
    end
    always @(*) begin
        case(apply_addr_reg)
        A         : next_addr_bx_reg = r_addr_bx_reg;
        B         : next_addr_bx_reg = next_addr_x_reg;
        selAcptoB : next_addr_bx_reg = next_addr_x_reg;
        selBcptoA : next_addr_bx_reg = r_addr_bx_reg;
        selArlB   : next_addr_bx_reg = {next_addr_x_reg[ADDR_X-2:0],next_addr_x_reg[ADDR_X-1]};
        selBrlA   : next_addr_bx_reg = r_addr_bx_reg;
        AxorB     : next_addr_bx_reg = r_addr_bx_reg;
        selBrrA   : next_addr_bx_reg = r_addr_bx_reg;
        default   : next_addr_bx_reg = r_addr_bx_reg;
        endcase
    end

    //AX and BX registers:
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_addr_ax_reg <= '0;
            r_addr_bx_reg <= '0;
        end else if (i_shift_mode) begin
            r_addr_ax_reg <= {r_addr_ax_reg[ADDR_X-2:0],r_addr_x_min_so};
            r_addr_bx_reg <= {r_addr_bx_reg[ADDR_X-2:0],r_addr_ax_reg[ADDR_X-1]};
        end else begin
            r_addr_ax_reg <= next_addr_ax_reg;
            r_addr_bx_reg <= next_addr_bx_reg;
        end
    end 
    logic r_addr_bx_reg_so;
    assign r_addr_bx_reg_so = r_addr_bx_reg[ADDR_X-1];

    //Apply AX or BX to memories:
    always @(*) begin
        case(apply_addr_reg)
        A         : out_addr_x = r_addr_ax_reg;
        B         : out_addr_x = r_addr_bx_reg;
        selAcptoB : out_addr_x = r_addr_ax_reg;
        selBcptoA : out_addr_x = r_addr_bx_reg;
        selArlB   : out_addr_x = r_addr_ax_reg;
        selBrlA   : out_addr_x = r_addr_bx_reg;
        AxorB     : out_addr_x = r_addr_bx_reg ^ r_addr_bx_reg;
        selBrrA   : out_addr_x = r_addr_bx_reg;
        default   : out_addr_x = r_addr_ax_reg;
        endcase
    end



    //---------------------------
    //-- Address y generator
    //---------------------------
    always @(*) begin
        case(apply_addr_reg)
        A         : addr_y_op = r_addr_ay_reg;
        B         : addr_y_op = r_addr_by_reg;
        selAcptoB : addr_y_op = r_addr_ay_reg;
        selBcptoA : addr_y_op = r_addr_by_reg;
        selArlB   : addr_y_op = r_addr_ay_reg;
        selBrlA   : addr_y_op = r_addr_by_reg;
        AxorB     : addr_y_op = r_addr_ay_reg;
        selBrrA   : addr_y_op = r_addr_by_reg;
        default   : addr_y_op = r_addr_ay_reg;
        endcase
    end

    assign addr_y_max_carry = (addr_y_op == r_addr_y_max);
    assign addr_y_min_carry = (addr_y_op == r_addr_y_min);
    always @(*) begin
        case(addr_y_cmd_af_loop)
        KEEP: addr_y_carry = '0;
        INC : addr_y_carry = addr_y_max_carry;
        DEC : addr_y_carry = addr_y_min_carry;
        CHG : begin
            case(addr_x_cmd_af_loop)
            INC: addr_y_carry = addr_y_max_carry;
            DEC: addr_y_carry = addr_y_min_carry;
            default: addr_y_carry = '0;
            endcase
        end
        default: addr_y_carry = '0;
        endcase
    end

    assign addr_y_op_p1 = (no_last_addr_count&next_inst_cond_sastified)? addr_y_op : addr_y_op +1;
    assign addr_y_op_m1 = (no_last_addr_count&next_inst_cond_sastified)? addr_y_op : addr_y_op -1;
    always @(*) begin
        case(addr_y_cmd_af_loop)
        KEEP: next_addr_y_reg =  addr_y_op;
        INC : next_addr_y_reg =  addr_y_op_p1;
        DEC : next_addr_y_reg =  addr_y_op_m1;
        CHG : begin
            case(addr_x_cmd_af_loop)
            INC: next_addr_y_reg = addr_x_max_carry? addr_y_op_p1 : addr_y_op; 
            DEC: next_addr_y_reg = addr_x_min_carry? addr_y_op_m1 : addr_y_op; 
            default: next_addr_y_reg =  addr_y_op;
            endcase
        end
        default: next_addr_y_reg =  addr_y_op;
        endcase
    end

    always @(*) begin
        case(apply_addr_reg)
        A         : next_addr_ay_reg =  next_addr_y_reg;
        B         : next_addr_ay_reg =    r_addr_ay_reg;
        selAcptoB : next_addr_ay_reg =    r_addr_ay_reg;
        selBcptoA : next_addr_ay_reg =  next_addr_y_reg;
        selArlB   : next_addr_ay_reg =    r_addr_ay_reg;
        selBrlA   : next_addr_ay_reg = {next_addr_y_reg[ADDR_X-2:0],next_addr_y_reg[ADDR_X-1]};
        AxorB     : next_addr_ay_reg =  next_addr_y_reg;
        selBrrA   : next_addr_ay_reg = {next_addr_y_reg[0],next_addr_y_reg[ADDR_X-1:1]};
        default   : next_addr_ay_reg =  next_addr_y_reg;
        endcase
    end
    always @(*) begin
        case(apply_addr_reg)
        A         : next_addr_by_reg =    r_addr_by_reg;
        B         : next_addr_by_reg =  next_addr_y_reg;
        selAcptoB : next_addr_by_reg =  next_addr_y_reg;
        selBcptoA : next_addr_by_reg =    r_addr_by_reg;
        selArlB   : next_addr_by_reg = {next_addr_y_reg[ADDR_X-2:0],next_addr_y_reg[ADDR_X-1]};
        selBrlA   : next_addr_by_reg =    r_addr_by_reg;
        AxorB     : next_addr_by_reg =    r_addr_by_reg;
        selBrrA   : next_addr_by_reg =    r_addr_by_reg;
        default   : next_addr_by_reg =    r_addr_by_reg;
        endcase
    end

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_addr_ay_reg <= '0;
            r_addr_by_reg <= '0;
        end else if (i_shift_mode) begin
            r_addr_ay_reg <= {r_addr_ay_reg[ADDR_Y-2:0],r_addr_bx_reg_so};
            r_addr_by_reg <= {r_addr_by_reg[ADDR_Y-2:0],r_addr_ay_reg[ADDR_Y-1]};
        end else begin
            r_addr_ay_reg <= next_addr_ay_reg;
            r_addr_by_reg <= next_addr_by_reg;
        end
    end 
    logic r_addr_by_reg_so;
    assign r_addr_by_reg_so = r_addr_by_reg[ADDR_Y-1];

    always @(*) begin
        case(apply_addr_reg)
        A         : out_addr_y = r_addr_ay_reg;
        B         : out_addr_y = r_addr_by_reg;
        selAcptoB : out_addr_y = r_addr_ay_reg;
        selBcptoA : out_addr_y = r_addr_by_reg;
        selArlB   : out_addr_y = r_addr_ay_reg;
        selBrlA   : out_addr_y = r_addr_by_reg;
        AxorB     : out_addr_y = r_addr_by_reg ^ r_addr_by_reg;
        selBrrA   : out_addr_y = r_addr_by_reg;
        default   : out_addr_y = r_addr_ay_reg;
        endcase
    end

    //---------------------------
    //-- Loop Control block
    //---------------------------
    logic[2:0] next_inst_cond_mask;

    assign next_inst_cond_mask = ~{next_inst_cond_x,next_inst_cond_y,next_inst_cond_rc};
    assign next_inst_cond_sastified = &( next_inst_cond_mask | {addr_x_carry,addr_y_carry,rc_carry} );

    always @(*) begin
        for (int i =0; i <INST_NUM; i =i+1) begin
            if ( i < r_inst_ptr ) begin
            next_loop_reg[i] = '0;
            end
            else begin 
            next_loop_reg[i] = r_loop_reg[i];
            end
            if ( ~next_loop_reg[r_inst_ptr] ) begin
            next_loop_reg[r_inst_ptr] = (loop_mode==REPEAT)? next_inst_cond_sastified : r_loop_reg[r_inst_ptr];
            end
        end
    end
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_loop_reg <= '0;
        end else if (i_shift_mode) begin
            r_loop_reg <= {r_loop_reg[INST_NUM-2:0],r_addr_by_reg_so};
        end else begin
            r_loop_reg <= next_loop_reg;
        end
    end 
    logic r_loop_reg_so;
    assign r_loop_reg_so = r_loop_reg[INST_NUM-1];

    

    //---------------------------
    //-- Data Generator
    //---------------------------
    //in: out_addr_x/y, bg_data_type, bg_data_inv
    logic [BG_DATA-1:0] r_data_reg, next_data_reg;
    //t_dflt_inv bg_data_inv_af_loop;

    //assign bg_data_inv_af_loop = (inv_bg_data&r_loop_reg[r_inst_ptr])? ~bg_data_inv : bg_data_inv;
    //assign bg_data_inv_af_loop =t_dflt_inv'( (inv_bg_data&r_loop_reg[r_inst_ptr]) ^ bg_data_inv );

    //assign bg_data_inv_af_loop =t_dflt_inv'( (jmp_en) ^ bg_data_inv );

    always @(*) begin
        case(bg_data_type)
        AL     : next_data_reg = r_data_reg;
        CS     : next_data_reg = out_addr_y[0]? ~r_data_reg : r_data_reg; 
        RS     : next_data_reg = out_addr_x[0]? ~r_data_reg : r_data_reg;
        CB     : next_data_reg = (out_addr_x[0] ^ out_addr_y[0])? ~r_data_reg : r_data_reg;
        default: next_data_reg = r_data_reg;
        endcase
    end
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_data_reg <= '0;
        end else if ( jmp_en & inv_bg_data ) begin
            r_data_reg <= ~next_data_reg;
        end else if (next_inst_cond_sastified & loop_mode==REPEAT & inv_bg_data) begin
            r_data_reg <= ~next_data_reg;
        end else if (i_shift_mode) begin
            r_data_reg <= {r_data_reg[BG_DATA-2:0],r_loop_reg_so};
        end else begin
            r_data_reg <= next_data_reg;
        end
    end 
    logic r_data_reg_so;
    assign r_data_reg_so    = r_data_reg[BG_DATA-1];

    //output data to memories:
    always @(*) begin
        case(bg_data_inv)//_af_loop)
        DFLT   : o_data =  r_data_reg;
        INV    : o_data = ~r_data_reg;
        default: o_data =  r_data_reg;
        endcase
    end
    
    //---------------------------
    //-- Repeat Counter
    //---------------------------
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_rc_max <= RC_MAX;
        end
    end 

    always @(*) begin
        case(rpt_cntr_cmd)
        RC_KEEP: next_rpt_cntr_reg = r_rpt_cntr_reg;
        RC_INC : next_rpt_cntr_reg = r_rpt_cntr_reg +1;
        default: next_rpt_cntr_reg = r_rpt_cntr_reg;
        endcase
    end
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_rpt_cntr_reg <= '0;
        end else if (i_shift_mode) begin
            r_rpt_cntr_reg <= {r_rpt_cntr_reg[RPT_CNTR-2:0],r_data_reg_so};
        end else begin
            r_rpt_cntr_reg <= next_rpt_cntr_reg;
        end
    end 
    logic r_rpt_cntr_reg_so;
    assign r_rpt_cntr_reg_so    = r_rpt_cntr_reg[RPT_CNTR-1];
    
    assign rc_carry = r_rpt_cntr_reg == r_rc_max;

    



    assign so = r_rpt_cntr_reg_so;
    
    //---------------------------
    //-- For FPGA
    //---------------------------
    initial begin
        r_inst_ptr = 'hf;
        
        for (int i =0; i <INST_NUM; i =i+1) microcode[i] = '0;
        
        r_data_reg = 2'b0;
        r_addr_ax_reg = '0;
        r_addr_bx_reg = '0;
        r_addr_ay_reg = '0;
        r_addr_by_reg = '0;
        r_rpt_cntr_reg = '0;

        r_addr_y_max = ADDR_Y_MAX;
        r_addr_x_max = ADDR_X_MAX;
        r_addr_y_min = ADDR_Y_MIN;
        r_addr_x_min = ADDR_X_MIN;
        r_rc_max = RC_MAX;

        r_inv_addr_en = '0;
        r_loop_reg = '0;
    end



    initial #1 begin
    `ifdef PROG1
        microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd0 , 2'd0, 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, next: ,kpRC,lstAdCntOn, A    ,keepY,incX , bgDat  ,AL  , write

        microcode[1] = {4'd0 ,2'd3, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd1, 2'd0 , 2'd1, 1'd1   ,2'd3, 2'd2 };
        //              i0   ,d+a , Loop, next: ,kpRC,lstAdCntOn, B    ,keepY,incX ,invBgDat,CB  , read

        microcode[2] = {4'd0 ,2'd3, 2'd1, 3'd1  ,1'd0,1'd0      , 3'd1, 2'd0 , 2'd1, 1'd0   ,2'd3, 2'd3 };
        //              i0   ,d+a , Loop, nx:x  ,kpRC,lstAdCntOn, B    ,keepY,incX ,   BgDat,CB  , rmw
    `elsif PROG2 //compact MARCH12
        microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, nxt:xy,kpRC,lstAdCntOn, A    ,incY ,chgX , bgDat  ,AL  , write

        microcode[1] = {4'd1 ,2'd3, 2'd1, 3'd3  ,1'd0,1'd1      , 3'd0, 2'd2 , 2'd1, 1'd0   ,2'd0, 2'd3 };
        //              i1   ,d+a , Loop, nxt:xy,kpRC,lstAdCntOf, A    ,incY ,chgX ,   BgDat,AL  , rmw

        microcode[2] = {4'd0 ,2'd1, 2'd1, 3'd3  ,1'd0,1'd0      , 3'd0, 2'd2 , 2'd1, 1'd0   ,2'd0, 2'd2 };
        //              i0   ,  d , Loop, nxt:xy,kpRC,lstAdCntOn, A    ,incY ,chgX ,   BgDat,AL  , read
    `elsif MARCH12_XS
        microcode[0] = {4'd0,DFLT,DFLT,NO_LOOP,NO_COND,END_CNT,END_CNT,RC_KEEP,LAST_ADDR_CNT_ON ,   A   ,CHG,INC,DFLT,AL,WRITE};
        //              i0   ,_  ,    ,nLoop  ,                 nxt:xy,kpRC   ,lstAdCntOn       ,   A  ,chgY,incX,bgDat,AL,write

        microcode[1] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd0, 2'd0 , 2'd0, 1'd0   ,2'd0, 2'd2 };
        //              i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, A    ,keepY,keepX,   BgDat,AL  , read
        microcode[2] = {4'd1 ,2'd0, 2'd2, 3'd3  ,1'd0,1'd1      , 3'd0, 2'd1 , 2'd2, 1'd1   ,2'd0, 2'd1 };
        //              i1   ,    , jump, nxt:xy,kpRC,lstAdCntOf, A    ,chgY ,incX ,invBgDat,AL  , write
        microcode[3] = {4'd1 ,2'd3, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd0};
        //              i1   ,iA+D, Loop, nxt:  ,kpRC,lstAdCntOn, A    ,     ,      , bgDat  ,AL  , nop

        microcode[4] = {4'd0 ,2'd1, 2'd1, 3'd3  ,1'd0,1'd0      , 3'd0, 2'd1 , 2'd2, 1'd0   ,2'd0, 2'd2 };
        //              i0   ,  d , Loop, nxt:xy,kpRC,lstAdCntOn, A    ,chgY ,incX ,   BgDat,AL  , read
    `elsif PROG4 //compact GALPAT
        microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write

        microcode[1] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd1,1'd0      , 3'd2 ,2'd2 , 2'd1, 1'd1   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, nxt:  ,inRC,lstAdCntOn, sAtoB,incY , chgX ,inBgDat,AL  , write
        microcode[2] = {4'd0 ,2'd0, 2'd0, 3'd4  ,1'd1,1'd0      , 3'd1 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd3};
        //              i0   ,_   ,nLoop, nxt:rc,inRC,lstAdCntOn, B    ,incY , chgX , bgDat  ,AL  , rmw - not actually rmw, should be readB0-readA1
        microcode[3] = {4'd1 ,2'd0, 2'd2, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i1   ,_   , jmp , nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write

        microcode[4] = {4'd0 ,2'd1, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd0};
        //              i0   ,invD, Loop, nxt:  ,kpRC,lstAdCntOn, A    ,     ,      , bgDat  ,AL  , nop

    `elsif PROG5 //GALPAT
        microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write


        microcode[1] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd1,1'd0      , 3'd2 ,2'd2 , 2'd1, 1'd1   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, nxt:  ,inRC,lstAdCntOn, sAtoB,incY , chgX ,inBgDat,AL  , write

        microcode[2] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd1 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd2};
        //              i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, B                 , bgDat  ,AL  , read
        microcode[3] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd1 ,2'd0 , 2'd0, 1'd1   ,2'd0, 2'd2};
        //              i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, A                 ,invBgDat,AL  , read
        microcode[4] = {4'd2 ,2'd0, 2'd2, 3'd4  ,1'd1,1'd0      , 3'd1 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd0};
        //              i2   ,_   , jmp , nxt:rc,inRC,lstAdCntOn, B    ,incY , chgX , bgDat  ,AL  , nop

        microcode[5] = {4'd1 ,2'd0, 2'd2, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i1   ,_   , jmp , nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write

        microcode[6] = {4'd0 ,2'd1, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd0};
        //              i0   ,invD, Loop, nxt:  ,kpRC,lstAdCntOn, A    ,     ,      , bgDat  ,AL  , nop
    `endif
    end

    //just for test
    `ifdef TEST_U_CODE
    initial begin
        force clk = 0;
        forever #50 force clk = ~clk;
    end

    initial begin
       force rstn = 1;
       force i_shift_mode = 0;
       force i_mbist_run  = 1;
    end
    
    always @(*) 
        if (o_end_of_prog) force i_mbist_run = 0;
    
    `endif



endmodule
