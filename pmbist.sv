package pmbist;

    parameter OP_CMD = 2;
    parameter INST_NUM = 16; //the last inst is always NOP, used for stopping the program.
    parameter INST_NUM_W = $clog2(INST_NUM);
    parameter BG_DT_TYPE = 2;
    parameter BG_DT_INV  = 1;
    parameter ADR_CMD   = 2;
    parameter APPL_ADR_CMD = 3;
    parameter NO_LAST_ADR_CNT = 1;
    parameter RC_CMD = 1;
    parameter NEXT_INST_COND = 1;
    parameter LOOP_MODE = 2;
    parameter INV_ADR_SEQ = 1;
    parameter INV_DAT_BG = 1;
    parameter LOOP_NUM  = 4; //INST_NUM/2 is optimal?;
    parameter LOOP_NUM_W = $clog2(LOOP_NUM);
    parameter INST = OP_CMD + BG_DT_TYPE + BG_DT_INV + ADR_CMD*2 + APPL_ADR_CMD + NO_LAST_ADR_CNT + RC_CMD + NEXT_INST_COND*3 + LOOP_MODE + LOOP_NUM_W + INV_ADR_SEQ + INV_DAT_BG + INST_NUM_W;
    
    parameter BG_DATA = 2;
    parameter ADDR_X  = 2;
    parameter ADDR_Y  = 2;
    parameter ADDR_X_MAX = (2**ADDR_X)-1;
    parameter ADDR_X_MIN = 0;
    parameter ADDR_Y_MAX = (2**ADDR_Y)-1;
    parameter ADDR_Y_MIN = 0;
    parameter RPT_CNTR = ADDR_X + ADDR_Y;
    parameter RC_MAX   = (2**RPT_CNTR) -1;
    
    parameter MEM_NUM  = 1;


//LABEL: OP   , BgDataType, BgDataInv , AddrX_CMD, AddrY_CMD, ApplyAddrReg, NoLastAdrCnt, RC_CMD , NextInstrCondition, LoopMode  , Loop modification   , LoopReg, JmpTo
//       nop  , _ (AL)    , _ (DFLT)  , _        , _        , _ (A)       , _              , _   , _                 , _           _                   , _      , _    
//       read , CS        , inv BgData, inc x    , inc y    , B           , NoLastAdrCnt, inc RC , AX end            , Jump        inv BgData          , n      , LABEL
//       write, RS        ,           , dcr x    , drc y    , selAcptoB                          , AY end            , repeat    , inv AddrSeq
//       rmw  , CB        ,           , chg x @y , chg y @x , selBcptoA                          , RC end              start_loop, inv BgData & AddrSeq
//       ...  ,                                             , selArlB                            , AX-AY-RC end
//            ,                                             , selBrlA                              use 3b for 3 conds
//            ,                                             , AxorB
//            ,                                             , selBrrA

    typedef enum logic[OP_CMD-1:0] {
        NOP = '0,
        WRITE,
        READ
        //RMW
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
        CHG,
        INC,
        DEC
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
        LAST_ADDR_CNT_ON = '0,
        LAST_ADDR_CNT_OFF
    } t_no_last_addr_count;
    
    typedef enum logic {
        RC_KEEP = '0,
        RC_INC
    } t_rpt_cntr_cmd;
    typedef enum logic {
        NO_COND = '0,
        END_CNT
    } t_next_inst_cond;
    typedef enum logic[1:0] {
        NO_LOOP = '0,
        JUMP,        //jump to LABEL every time, until NextInstCond is true
	//TODO rename REPEAT to END_LOOP?
        REPEAT,      //repeat from LABEL to current Inst once, when NextInstCond is true
        //NESTED_LOOP, //same as REPEAT, but jump over other Inst(s), create nested loops.
	START_LOOP
    } t_loop_mode;
    
endpackage

module pmbist_top
import pmbist::*;
(
    tck, f_clk,
    o_clk_sel, 
    rstn,
    
    select,
    capture_en,
    shift_en,
    update_en,
    si, so,
    
    o_addr_x,
    o_addr_y,
    o_data,
    
    o_cs,
    o_we,
    o_re,
    o_oe,
    o_odd_bwe,
    o_even_bwe,
    o_comp_en,
    
    o_mbist_run,
    i_fail_flags,
    o_shift_result,
    si_to_mem,
    so_from_mem,
);    
    
    input logic tck, f_clk, rstn;
          logic clk;
    output logic o_clk_sel;
	        logic clk_sel;
    
    output logic [BG_DATA-1:0] o_data;
    output logic [ADDR_X-1:0]  o_addr_x;
    output logic [ADDR_Y-1:0]  o_addr_y;
    
    output logic o_cs, o_we, o_re, o_oe, o_odd_bwe, o_even_bwe, o_comp_en;    
    
    t_op_cmd op_cmd;
    
    output logic o_mbist_run;
    
    input logic[MEM_NUM-1:0] i_fail_flags;
    logic fail_flag;
    assign fail_flag    = | i_fail_flags;
    input logic so_from_mem;
    output logic si_to_mem;
    
    input  logic select, capture_en, shift_en, update_en, si;
    output logic so;
    logic mbist_start, mbist_run, mbist_done, shift_setup, shift_result, end_of_prog;
    output logic o_shift_result;
    assign o_shift_result = shift_result;
    
    logic[4:0] tdr_dataout;
    logic tdr_so;
    logic setup_chain_si, setup_chain_so, tdr_setup_so;
    
    assign o_mbist_run = mbist_run;
    
    
    tdr #(5) i_ctl_tdr (
    tck         
  , ~rstn       
  , select      
  , capture_en   
  , shift_en     
  , update_en    
  , si      
  , {3'b0          ,~mbist_done,fail_flag}
  , tdr_so     
  , tdr_dataout   
  ) ; 
    assign mbist_start  = tdr_dataout[1]; //TODO mbist_start can be metastable
    assign clk_sel      = tdr_dataout[2];
    assign shift_setup  = tdr_dataout[3] & shift_en; //when on functional clk, toggle shift_setup/result might cause metastable
    assign shift_result = tdr_dataout[4] & shift_en;
    
    assign setup_chain_si = tdr_so;
    assign tdr_setup_so = shift_setup? setup_chain_so : tdr_so;
    
    assign si_to_mem = tdr_setup_so;
    assign so = shift_result? so_from_mem : tdr_setup_so;
    
    clock_mux #(2) i_clkmux ({f_clk,tck},clk_sel? 2'b01:2'b10,clk);
    assign o_clk_sel = clk_sel;

    enum logic[1:0] {
        IDLE = '0,
        //SETUP,
        RUN,
        DONE
    } r_state, next_stage;    
    always @(*) begin
        case(r_state)
        IDLE : begin
            mbist_done = '0;
            if (mbist_start) begin
                next_stage = RUN;
                mbist_run  = '1;
            end else begin
                next_stage = IDLE;
                mbist_run  = '0;
            end
        end
        RUN  : begin
            mbist_done = '0;
	    if (end_of_prog) begin
                next_stage = DONE;//IDLE;
                mbist_run  = '0;
            end else begin
                next_stage = RUN;
                mbist_run  = '1;
            end
        end    
        DONE : begin
            mbist_done = '1;
            //if (shift_setup | shift_result) begin
            if (capture_en) begin
                next_stage = DONE;//IDLE;
                mbist_run  = '0;
            end else begin
                next_stage = DONE;
                mbist_run  = '0;
            end
        end
        endcase
    end    
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_state <= IDLE;
        end else begin
            r_state <= next_stage;
        end
    end     
        
        
    microcode_container i_ucode
    (
    clk, rstn,
    
    shift_setup,setup_chain_si,setup_chain_so,//si, so,
    end_of_prog,
    mbist_run,
    
    op_cmd,
    o_addr_x,
    o_addr_y,
    o_data,
    );
    
    ctrl_sigs_gen ins_ctrl_sigs_gen
    (
    clk, rstn,
    
    op_cmd,
    
    o_cs,
    o_we,
    o_re,
    o_oe,
    o_odd_bwe,
    o_even_bwe,
    o_comp_en,
    );
    
    //for FPGA
    initial begin
        r_state = IDLE;
    end
    
    //just for test
    `ifdef TEST_TOP_PMBIST
    
    task pulse_clk;
    begin
        #50 force tck = 1;
        #50 force tck = 0;
    end
    endtask
    
    task setup;
    begin
        force select = 1;
        force capture_en = 1;
        force shift_en = 0;
        force update_en = 0;
        force si = 1;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 1;
        force update_en = 0;
        pulse_clk;
        pulse_clk;
        pulse_clk;
        force si = 0;
        pulse_clk;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 0;
        force update_en = 1;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 0;
        force update_en = 0;
    end
    endtask
    task result;
    begin
        force select = 1;
        force capture_en = 1;
        force shift_en = 0;
        force update_en = 0;
        force si = 0;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 1;
        force update_en = 0;
        pulse_clk;
        pulse_clk;
        pulse_clk;
        pulse_clk;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 0;
        force update_en = 1;
        pulse_clk;
        force capture_en = 0;
        force shift_en = 0;
        force update_en = 0;
    end
    endtask    
    initial begin
        pulse_clk;
        setup;
        for (int i=0; i <210; i =i+1) pulse_clk;
        result;
        for (int i=0; i <3; i =i+1) pulse_clk;
        setup;
        for (int i=0; i <100; i =i+1) pulse_clk;
        result;
        for (int i=0; i <110; i =i+1) pulse_clk;
        result;
        forever pulse_clk;
    end

    initial begin
       force rstn = 1;
       //force shift_setup = 0;
       //force shift_result = 0;
    end
    `endif
    
endmodule





 
module tdr (
    TCK         // i
  , Reset       // i
  , Select      // i
  , CaptureEn   // i
  , ShiftEn     // i
  , UpdateEn    // i
  , ScanIn      // i
  , DataIn      // i
  , ScanOut     // o
  , DataOut     // o
  ) ;

  parameter DLEN = 8 ;

  input                TCK ;         // i
  input                Reset ;       // i
  input                Select ;      // i
  input                CaptureEn ;   // i
  input                ShiftEn ;     // i
  input                UpdateEn ;    // i
  input                ScanIn ;      // i
  input   [DLEN-1:0]   DataIn ;      // i
  output               ScanOut ;     // o
  output  [DLEN-1:0]   DataOut ;     // o

  reg     [DLEN-1:0]   ShiftData ;
  reg     [DLEN-1:0]   UpdateData ;

  assign ScanOut = ShiftData[0] ;
  assign DataOut = UpdateData ;

  // Shift Registers
  always @(posedge TCK or posedge Reset) begin
    if (Reset)
       ShiftData <= {DLEN{1'b0}} ;
    else if (Select & CaptureEn)
       ShiftData <= DataIn ;
    else if (Select & ShiftEn)
       ShiftData <= {ScanIn, ShiftData[DLEN-1:1]} ;
    else
       ShiftData <= ShiftData ;
  end

  // Update Registers
  always @(negedge TCK or posedge Reset) begin
    if (Reset)
       UpdateData <= {DLEN{1'b0}};
    else if (Select & UpdateEn)
       UpdateData <= ShiftData ;
    else
       UpdateData <= UpdateData ;
  end

endmodule

module clock_mux (clk,clk_select,clk_out);

	parameter num_clocks = 4;

	input [num_clocks-1:0] clk;
	input [num_clocks-1:0] clk_select; // one hot
	output clk_out;

	genvar i;

	reg [num_clocks-1:0] ena_r0;
	reg [num_clocks-1:0] ena_r1;
	reg [num_clocks-1:0] ena_r2;
	wire [num_clocks-1:0] qualified_sel;

	// A look-up-table (LUT) can glitch when multiple inputs
	// change simultaneously. Use the keep attribute to
	// insert a hard logic cell buffer and prevent
	// the unrelated clocks from appearing on the same LUT.

	wire [num_clocks-1:0] gated_clks /* synthesis keep */;

	initial begin
		ena_r0 = 0;
		ena_r1 = 0;
		ena_r2 = 0;
	end

	generate
		for (i=0; i<num_clocks; i=i+1)
		begin : lp0
			wire [num_clocks-1:0] tmp_mask;
			assign tmp_mask = {num_clocks{1'b1}} ^ (1 << i);

			assign qualified_sel[i] = clk_select[i] & (~|(ena_r2 & tmp_mask));

			always @(posedge clk[i]) begin
				ena_r0[i] <= qualified_sel[i];
				ena_r1[i] <= ena_r0[i];
			end

			always @(negedge clk[i]) begin
				ena_r2[i] <= ena_r1[i];
			end

			assign gated_clks[i] = clk[i] & ena_r2[i];
		end
	endgenerate

	// These will not exhibit simultaneous toggle by construction
	assign clk_out = |gated_clks;

endmodule
