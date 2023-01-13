module virtual_netlist
(
    fclk//, 
	 //rstn,
    //
    //select,
    //capture_en,
    //shift_en,
    //update_en,
    //si, so,
    
);

	 input logic fclk;//, rstn;

    logic tck;

    logic select, capture_en, shift_en, update_en, si;
    logic so, dummy_tdr_so, mbist_so;
	 logic[3:0] dummy_tdr_dataout;
    
    import pmbist::*;
    //parameter BG_DATA = 2;
    //parameter ADDR_X  = 3;
    //parameter ADDR_Y  = 4;
    
    logic [BG_DATA-1:0] data;
    logic [ADDR_X-1:0]  addr_x;
    logic [ADDR_Y-1:0]  addr_y;
    
    logic cs, we, re, oe, odd_bwe, even_bwe, comp_en;
    

    logic so_from_mem;
    logic si_to_mem;
    logic shift_result;
    logic mbist_run;
    
	 logic clk_sel;
    logic[MEM_NUM-1:0] fail_flags;
    logic m0_fail_flag;
    assign fail_flags = m0_fail_flag;

	virtual_jtag u_vjtag (
		.virtual_jtag_0_jtag_tdi                (si),                // virtual_jtag_0_jtag.tdi
		.virtual_jtag_0_jtag_tdo                (so),                //                    .tdo
		.virtual_jtag_0_jtag_ir_in              (select),              //                    .ir_in
		.virtual_jtag_0_jtag_ir_out             (),             //                    .ir_out
		.virtual_jtag_0_jtag_virtual_state_cdr  (capture_en),  //                    .virtual_state_cdr
		.virtual_jtag_0_jtag_virtual_state_sdr  (shift_en),  //                    .virtual_state_sdr
		.virtual_jtag_0_jtag_virtual_state_e1dr (), //                    .virtual_state_e1dr
		.virtual_jtag_0_jtag_virtual_state_pdr  (),  //                    .virtual_state_pdr
		.virtual_jtag_0_jtag_virtual_state_e2dr (), //                    .virtual_state_e2dr
		.virtual_jtag_0_jtag_virtual_state_udr  (update_en),  //                    .virtual_state_udr
		.virtual_jtag_0_jtag_virtual_state_cir  (),  //                    .virtual_state_cir
		.virtual_jtag_0_jtag_virtual_state_uir  (),  //                    .virtual_state_uir
		.virtual_jtag_0_tck_clk                 (tck)                  //  virtual_jtag_0_tck.clk
	);
	
tdr #(4) dummy_tdr (
    tck         
  , 1'b0//~rstn       
  , ~select      
  , capture_en   
  , shift_en     
  , update_en    
  , si      
  , dummy_tdr_dataout      
  , dummy_tdr_so     
  , dummy_tdr_dataout   
  ) ; 
  
  assign so = select? mbist_so : dummy_tdr_so;
    
pmbist_top ins_pmbist_top
(
    tck,fclk, clk_sel,
	 1'b1,//rstn, FPGA doesn't need this pin
    
    select,
    capture_en,
    shift_en,
    update_en,
    si, mbist_so,
    
    addr_x,
    addr_y,
    data,
    
    cs,
    we,
    re,
    oe,
    odd_bwe,
    even_bwe,
    comp_en,
    
    mbist_run,
    fail_flags,
    shift_result,
    si_to_mem,
    so_from_mem,
);    

    parameter MEM0_ADR_Y = 2;
    parameter MEM0_ADR_X = 2;
    parameter MEM0_DATA  = 7;
    logic [MEM0_ADR_Y+MEM0_ADR_X-1:0] tomem_addr;
    logic [MEM0_DATA-1:0] tomem_data;
    logic [MEM0_DATA-1:0] frommem_q;     
    
    logic tomem_cs, tomem_we, tomem_re, tomem_oe, tomem_odd_bwe, tomem_even_bwe;

mem_interface #(.MEM_ADR_X(MEM0_ADR_X),.MEM_ADR_Y(MEM0_ADR_Y),.MEM_DATA(MEM0_DATA)) mem0_intf
(
    tck,fclk, clk_sel,
	 1'b1,//rstn, FPGA doesn't need this pin
	 tomem_clk,
    
    addr_x,
    addr_y,
    data,
    
    cs,
    we,
    re,
    oe,
    odd_bwe,
    even_bwe,
    comp_en,
    
    mbist_run,
    //i_mem_test_en,
    //o_compared_data,
    m0_fail_flag,
    
    shift_result, si_to_mem, so_from_mem,
    
    //connect to memory:
    //tomem_addr_x,
    //tomem_addr_y,
    tomem_addr,
    tomem_data,
    
    tomem_cs,
    tomem_we,
    tomem_re,
    tomem_oe,
    tomem_odd_bwe,
    tomem_even_bwe,

    frommem_q,
);

ram_sp_sr_sw #(.DATA_WIDTH(MEM0_DATA),.ADDR_WIDTH(MEM0_ADR_Y+MEM0_ADR_X)) mut_m0 (
    tomem_clk,
    tomem_addr,
    tomem_data,
    tomem_cs,
    tomem_we,
    //tomem_oe,
    frommem_q
);




    //just for test
    `ifdef TEST
    
    task pulse_clk;
    begin
        #50 force clk = 1;
        #50 force clk = 0;
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
       //force mut_m0.oe = 1;
    end
    `endif

endmodule

module ram_sp_sr_sw (

  clk         , // Clock Input
  address     , // Address Input
  data        , // Data input
  cs          , // chip select
  we          , // Write Enable/Read Enable
  //oe          , // Output Enable
  data_output   // Data output
  );
  parameter DATA_WIDTH = 8 ;
  parameter ADDR_WIDTH = 8 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  //--------------Input Ports-----------------------
  input                  clk         ;
  input [ADDR_WIDTH-1:0] address     ;
  input                  cs          ;
  input                  we          ;
  //input                  oe          ;

  //--------------Inout Ports-----------------------
  input [DATA_WIDTH-1:0]  data       ;
  output[DATA_WIDTH-1:0]  data_output;

  //--------------Internal variables----------------
  reg [DATA_WIDTH-1:0] data_out ;
  reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];


  //--------------Code Starts Here------------------

  // Tri-State Buffer control
  // output : When we = 0, oe = 1, cs = 1
  //assign data = (cs && oe &&  ! we) ? data_out : 8'bz;
  //assign data_output = (cs && oe &&  ! we) ? data_out : 8'bz;
  
  assign data_output = data_out;
  //assign data_output = ( address==10 )? '1 : data_out; 

  // Memory Write Block
  // Write Operation : When we = 1, cs = 1
  always @ (posedge clk)
  begin : MEM_WRITE
    if ( cs && we )
    begin
       mem[address] = data;
    end
  end

  // Memory Read Block
  // Read Operation : When we = 0, oe = 1, cs = 1
  always @ (posedge clk)
  begin : MEM_READ
    if (cs &&  ! we ) //&& oe)
    begin
      data_out = mem[address];
    end
    else ;
  end
endmodule 

module single_clk_ram( 
    output reg [7:0] q,
    input [7:0] d,
    input [4:0] write_address, read_address,
    input we, clk
);
    reg [7:0] mem [31:0];

    always @ (posedge clk) begin
        if (we)
            mem[write_address] <= d;
        q <= mem[read_address]; // q doesn't get d in this clock cycle
    end
endmodule