package pmbist;

    parameter OP_CMD = 2;
    parameter INST_NUM = 16;
    parameter INST_NUM_W = $clog2(INST_NUM);
    parameter INST = OP_CMD + INST_NUM_W + 18;
    
    parameter BG_DATA = 2;
    parameter ADDR_X  = 2;
    parameter ADDR_Y  = 2;
    parameter ADDR_X_MAX = (2**ADDR_X)-1;
    parameter ADDR_X_MIN = 0;
    parameter ADDR_Y_MAX = (2**ADDR_Y)-1;
    parameter ADDR_Y_MIN = 0;
    parameter RPT_CNTR = ADDR_X + ADDR_Y;
    parameter RC_MAX   = (2**RPT_CNTR) -1;

//LABEL: OP   , BgDataType , BgDataInv , AddrX_CMD, AddrY_CMD, ApplyAddrReg, NoLastAddrCount, RC_CMD   , NextInstrCondition, LoopMode                       , JmpTo
//       nop  , _          , _         , _        , _        , _ (A)       , _              , _        , _                 , _                              , _
//       read , CB         , inv BgData, inc x    , inc y    , B           , NoLastAddrCount, inc RC   , AX end            , Loop                           , LABEL
//       write, CS         ,           , dcr x    , drc y    , AxorB                                   , AY end            , Loop - inv BgData - inv AddrSeq
//       rmw  , RS         ,           , chg x @y , chg y @x , AtoB                                    , RC end              (use 3b for 3 conds) 
//       ...  ,                                              , ArlB                                    , AX-AY-RC end
//            ,                                              , BrlA                                     (use 3b for 3 conds)
//            ,                                              , ArrB
//            ,                                              , BrrA    
    typedef enum logic[OP_CMD-1:0] {
        NOP = '0,
        WRITE,
        READ,
        RMW
    } t_op_cmd;
    typedef enum logic[1:0] {
        AL = '0,
        CB,
        CS,
        RS
    } t_bg_data_type;
    typedef enum logic {
        DFLT = '0,
        INV
    } t_dflt_inv;
    
    typedef enum logic[1:0] {
        KEEP = '0,
        INC,
        DEC,
        CHG
    } t_addr_cmd;
    typedef enum logic[2:0] {
        A = '0,
        B,
        selAcptoB,
        selBcptoA,
        selArlB,
        selBrlA,
        AxorB,
        selBrrA
    } t_apply_addr_reg;
    typedef enum logic {
        LAST_ADDR_COUNT = '0,
        NO_LAST_ADDR_COUNT
    } t_no_last_addr_count;
    
    typedef enum logic {
        RC_KEEP = '0,
        RC_INC
    } t_rpt_cntr_cmd;
    typedef enum logic {
        NO_COND = '0,
        END_COUNT
    } t_next_inst_cond;
    typedef enum logic {
        NO_LOOP = '0,
        LOOP
    } t_loop_mode;
    
endpackage

module microcode_container
import pmbist::*;
(
    clk, rstn,
    
    i_shift_mode,
    
    i_jmp_to_inst,
    i_jmp_en,
    
    o_op_cmd,
    o_addr_x,
    o_addr_y,
    o_data,
    //o_bg_data_type,
    //o_bg_data_inv
);

    input logic clk, rstn;
    
    input logic i_shift_mode;
    
    input logic[INST_NUM-1:0] i_jmp_to_inst;
    input logic i_jmp_en;
    
    //output logic [OP_CMD-1:0] o_op_cmd;
    output t_op_cmd o_op_cmd;
    output logic [BG_DATA-1:0] o_data;
    output logic [ADDR_X-1:0]  o_addr_x;
    output logic [ADDR_Y-1:0]  o_addr_y;

    t_bg_data_type bg_data_type;
    t_dflt_inv bg_data_inv;
    t_addr_cmd addr_x_cmd, addr_y_cmd;
    t_apply_addr_reg apply_addr_reg;
    t_no_last_addr_count no_last_addr_count;
    t_rpt_cntr_cmd rpt_cntr_cmd;
    t_next_inst_cond next_inst_cond_x, next_inst_cond_y, next_inst_cond_rc;    
    t_loop_mode loop_en;
    t_dflt_inv loop_bg_data, loop_addr_seq;
    logic [INST_NUM_W-1:0] jmp_to_inst;
    
    logic [INST-1:0] microcode [0:INST_NUM-1];
    logic [INST-1:0] curr_inst;
    logic [INST_NUM_W-1:0] r_inst_ptr, next_inst_ptr;
    logic jmp_en;
    logic inst_ptr_so,inst_ptr_si;

    logic next_inst_cond_sastified;
    logic[INST_NUM-1:0] r_loop_reg, next_loop_reg;

    assign jmp_en = loop_en & next_inst_cond_sastified & ~r_loop_reg[r_inst_ptr];
    assign inst_ptr_si = '0;//just for test
    assign next_inst_ptr = jmp_en? jmp_to_inst : (next_inst_cond_sastified)? r_inst_ptr +1 : r_inst_ptr;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_inst_ptr <= '0;
        end
        else if (i_shift_mode) begin
            r_inst_ptr <= {r_inst_ptr[INST_NUM_W-2:0],inst_ptr_si};
        end else begin
            r_inst_ptr <= next_inst_ptr;
        end
    end 
    assign inst_ptr_so = r_inst_ptr[INST_NUM_W-1];
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i =0; i <INST_NUM; i =i +1) begin
                microcode[i] <= 'b10;
            end
        end
        else if (i_shift_mode) begin
            microcode[0] <= {microcode[0][INST-2:0],inst_ptr_so};
            for (int i =1; i <INST_NUM; i =i +1) begin
                microcode[i] <= {microcode[i][INST-2:0],microcode[i-1][INST-1]};
            end
        end
    end    

    
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
    assign loop_en            =          t_loop_mode'(curr_inst[OP_CMD+15]);
    assign loop_bg_data       =           t_dflt_inv'(curr_inst[OP_CMD+16]);
    assign loop_addr_seq      =           t_dflt_inv'(curr_inst[OP_CMD+17]);
    assign jmp_to_inst        =                       curr_inst[INST-1:OP_CMD+18];
    
    logic [BG_DATA-1:0] r_data_reg, next_data_reg, next_data_reg_dflt;

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
    logic                 rc_carry;

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_addr_y_max <= ADDR_Y_MAX;
            r_addr_x_max <= ADDR_X_MAX;
            r_addr_y_min <= ADDR_Y_MIN;
            r_addr_x_min <= ADDR_X_MIN;
        end
    end 

    assign o_addr_x = out_addr_x;
    assign o_addr_y = out_addr_y;

    //---------------------------
    //-- Data generator
    //---------------------------
    //in: out_addr_x/y, bg_data_type, bg_data_inv
    always @(*) begin
        case(bg_data_type)
        AL: next_data_reg_dflt = r_data_reg;
        CS: next_data_reg_dflt = out_addr_y[0]? ~r_data_reg : r_data_reg; 
        RS: next_data_reg_dflt = out_addr_x[0]? ~r_data_reg : r_data_reg;
        CB: next_data_reg_dflt = (out_addr_x[0] ^ out_addr_y[0])? ~r_data_reg : r_data_reg;
        default: next_data_reg_dflt = r_data_reg;
        endcase
    end
    always @(*) begin
        case(bg_data_inv)
        DFLT: next_data_reg =  next_data_reg_dflt;
        INV : next_data_reg = ~next_data_reg_dflt;
        default: next_data_reg =  next_data_reg_dflt;
        endcase
    end
    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_data_reg <= '0;
        end else begin
            r_data_reg <= next_data_reg;
        end
    end 
    assign o_data = r_data_reg;
    
    
    //---------------------------
    //-- Address x generator
    //---------------------------
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
    assign addr_x_op_p1 = (no_last_addr_count&next_inst_cond_sastified)? addr_x_op : addr_x_op +1;
    assign addr_x_op_m1 = (no_last_addr_count&next_inst_cond_sastified)? addr_x_op : addr_x_op -1;
    always @(*) begin
        case(addr_x_cmd)
        KEEP: next_addr_x_reg =  addr_x_op;
        INC : next_addr_x_reg =  addr_x_op_p1;
        DEC : next_addr_x_reg =  addr_x_op_m1;
        CHG : begin
            case(addr_y_cmd)
            INC: next_addr_x_reg = addr_y_max_carry? addr_x_op_p1 : addr_x_op; 
            DEC: next_addr_x_reg = addr_y_min_carry? addr_x_op_m1 : addr_x_op; 
            default: next_addr_x_reg =  addr_x_op;
            endcase
        end
        default: next_addr_x_reg =  addr_x_op;
        endcase
    end

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

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_addr_ax_reg <= '0;
            r_addr_bx_reg <= '0;
        end else begin
            r_addr_ax_reg <= next_addr_ax_reg;
            r_addr_bx_reg <= next_addr_bx_reg;
        end
    end 

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
    //assign addr_y_op_p1 = addr_y_op +1;
    //assign addr_y_op_m1 = addr_y_op -1;
    assign addr_y_op_p1 = (no_last_addr_count&next_inst_cond_sastified)? addr_y_op : addr_y_op +1;
    assign addr_y_op_m1 = (no_last_addr_count&next_inst_cond_sastified)? addr_y_op : addr_y_op -1;
    always @(*) begin
        case(addr_y_cmd)
        KEEP: next_addr_y_reg =  addr_y_op;
        INC : next_addr_y_reg =  addr_y_op_p1;
        DEC : next_addr_y_reg =  addr_y_op_m1;
        CHG : begin
            case(addr_x_cmd)
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
        end else begin
            r_addr_ay_reg <= next_addr_ay_reg;
            r_addr_by_reg <= next_addr_by_reg;
        end
    end 

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
        end else begin
            r_rpt_cntr_reg <= next_rpt_cntr_reg;
        end
    end 
    assign rc_carry = r_rpt_cntr_reg == r_rc_max;


    //---------------------------
    //-- Loop Control block
    //---------------------------
    logic addr_x_carry, addr_y_carry;
    logic[2:0] next_inst_cond_mask;

    always @(*) begin
        case(addr_x_cmd)
        KEEP: addr_x_carry = '0;
        INC : addr_x_carry = addr_x_max_carry;
        DEC : addr_x_carry = addr_x_min_carry;
        CHG : begin
            case(addr_y_cmd)
            INC: addr_x_carry = addr_x_max_carry;
            DEC: addr_x_carry = addr_x_min_carry;
            default: addr_x_carry = '0;
            endcase
        end
        default: addr_x_carry = '0;
        endcase
    end
    always @(*) begin
        case(addr_y_cmd)
        KEEP: addr_y_carry = '0;
        INC : addr_y_carry = addr_y_max_carry;
        DEC : addr_y_carry = addr_y_min_carry;
        CHG : begin
            case(addr_x_cmd)
            INC: addr_y_carry = addr_y_max_carry;
            DEC: addr_y_carry = addr_y_min_carry;
            default: addr_y_carry = '0;
            endcase
        end
        default: addr_y_carry = '0;
        endcase
    end
    assign next_inst_cond_mask = ~{next_inst_cond_x,next_inst_cond_y,next_inst_cond_rc};
    assign next_inst_cond_sastified = &( next_inst_cond_mask | {addr_x_carry,addr_y_carry,rc_carry} );

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            for (int i =0; i <INST_NUM; i =i+1) begin
            r_loop_reg[i] <= '0;
            end
        end else begin
            for (int i =0; i <INST_NUM; i =i+1) begin
            r_loop_reg[i] <= next_loop_reg[i];
            end
        end
    end 

    always @(*) begin
        for (int i =0; i <INST_NUM; i =i+1) begin
            if ( i < r_inst_ptr ) begin
            next_loop_reg[i] = '0;
            end
            else begin 
            next_loop_reg[i] = r_loop_reg[i];
            end
            if ( ~next_loop_reg[r_inst_ptr] ) begin
            next_loop_reg[r_inst_ptr] = (loop_en)? next_inst_cond_sastified : r_loop_reg[r_inst_ptr];
            end
        end
    end
                                
    //TODO invert data, addr registers when enter loop
            

    //for FPGA
    initial begin
        r_inst_ptr = '0;
        microcode[0] = {4'd0 ,2'd0, 1'd0, 3'd0  ,1'd0,1'd0      , 3'd0 , 2'd0, 2'd1, 1'd0   ,2'd0, 2'd1};
        //              i0   ,_   ,nLoop, next: ,kpRC,lstAdCntOn, A    ,keepY,incX , bgDat  ,AL  , write

        microcode[1] = {4'd0 ,2'd3, 1'd1, 3'd0  ,1'd0,1'd0      , 3'd1, 2'd0 , 2'd1, 1'd0   ,2'd3, 2'd2 };
        //              i0   ,d+a , Loop, next: ,kpRC,lstAdCntOn, B    ,keepY,incX ,invBgDat,CB  , read

        microcode[2] = {4'd0 ,2'd3, 1'd1, 3'd1  ,1'd0,1'd0      , 3'd1, 2'd0 , 2'd1, 1'd0   ,2'd3, 2'd3 };
        //              i0   ,d+a , Loop, nx:x  ,kpRC,lstAdCntOn, B    ,keepY,incX ,invBgDat,CB  , rmw

        r_data_reg = 2'b10;
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

        r_loop_reg = '0;

    end

    //just for test
    `ifdef TEST
    initial begin
        force clk = 0;
        forever #50 force clk = ~clk;
    end

    initial begin
       force rstn = 1;
       force i_shift_mode = 0;
    end
    `endif

endmodule
