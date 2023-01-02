`timescale 1ps/1ps

module ctrl_sigs_gen
import pmbist::*;
(
    clk, rstn,
    
    i_op_cmd,
    
    o_cs,
    o_we,
    o_re,
    o_oe,
    o_odd_bwe,
    o_even_bwe,
    o_comp_en,
);

    input logic clk, rstn;
    
    input t_op_cmd i_op_cmd;
    output logic o_cs, o_we, o_re, o_oe, o_odd_bwe, o_even_bwe, o_comp_en;
    
    logic [6:0] out;
    
    always @(*) begin
        case(i_op_cmd)
        //                CS WE RE OE ODD EVEN COMP
        NOP    : out = 'b_0__0__0__0__0___0___0;
        WRITE  : out = 'b_1__1__0__0__1___1___0;
        READ   : out = 'b_1__0__1__1__0___0___1;
        default: out = 'b_0__0__0__0__0___0___0;
        endcase
    end
    
    assign o_cs       = out[6];
    assign o_we       = out[5];
    assign o_re       = out[4];
    assign o_oe       = out[3];
    assign o_odd_bwe  = out[2];
    assign o_even_bwe = out[1];
    assign o_comp_en  = out[0];
    
endmodule


module mem_interface
import pmbist::*;
(
    clk, rstn,
    
    i_addr_x,
    i_addr_y,
    i_data,
    
    i_cs,
    i_we,
    i_re,
    i_oe,
    i_odd_bwe,
    i_even_bwe,
    i_comp_en,
    
    i_mbist_run,
    //i_mem_test_en,
    //o_compared_data,
    o_fail_flag,
    
    i_shift_mode, si, so,
    
    //connect to memory:
    //o_addr_x,
    //o_addr_y,
    o_addr,
    o_data,
    
    o_cs,
    o_we,
    o_re,
    o_oe,
    o_odd_bwe,
    o_even_bwe,

    i_q,
);

    parameter MEM_ADR_X = 2;
    parameter MEM_ADR_Y = 2;
    parameter MEM_DATA  = 7;
    parameter MEM_ADR_X_MAX = (2**MEM_ADR_X)-1;
    parameter MEM_ADR_X_MIN = 0;
    parameter MEM_ADR_Y_MAX = (2**MEM_ADR_Y)-1;
    parameter MEM_ADR_Y_MIN = 0;
    parameter MEM_DTdivBG_DT = MEM_DATA/BG_DATA;
    parameter MEM_DTmodBG_DT = MEM_DATA%BG_DATA;

    input logic clk, rstn;
    
    input  logic [ADDR_X-1:0]  i_addr_x;
    input  logic [ADDR_Y-1:0]  i_addr_y;
    input  logic [BG_DATA-1:0] i_data;
    //output logic [MEM_ADR_X-1:0]  o_addr_x;
    //output logic [MEM_ADR_Y-1:0]  o_addr_y;
    output logic [MEM_ADR_Y+MEM_ADR_X-1:0] o_addr;
    output logic [MEM_DATA-1:0] o_data;
    input  logic [MEM_DATA-1:0] i_q;     
    
    input  logic i_cs, i_we, i_re, i_oe, i_odd_bwe, i_even_bwe, i_comp_en;    
    output logic o_cs, o_we, o_re, o_oe, o_odd_bwe, o_even_bwe;
    
    input  logic i_mbist_run;
    //input  logic i_mem_test_en;
    //output logic[MEM_DATA-1:0] o_compared_data;
    output logic o_fail_flag;
    
    input  logic i_shift_mode, si;
    output logic so;
    
    logic  ax_max_mask;
    logic  ay_max_mask;
    logic  mem_test_en;
    
    generate if (MEM_ADR_X_MAX < ADDR_X_MAX) 
        assign ax_max_mask = ~( i_addr_x > MEM_ADR_X_MAX );
    else 
        assign ax_max_mask = '1;
    endgenerate    
    generate if (MEM_ADR_Y_MAX < ADDR_Y_MAX) 
        assign ay_max_mask = ~( i_addr_y > MEM_ADR_Y_MAX );
    else 
        assign ay_max_mask = '1;
    endgenerate 
    assign mem_test_en = i_mbist_run & ax_max_mask & ay_max_mask;
    
    //assign o_cs = i_cs & mem_test_en;
    //assign o_we = i_we & mem_test_en;
    //assign o_re = i_re & mem_test_en;
    //assign o_oe = i_oe & mem_test_en;
    always @(*) begin 
        o_cs = #1 i_cs & mem_test_en;
        o_we = #1 i_we & mem_test_en;
        o_re = #1 i_re & mem_test_en;
        o_oe = #1 i_oe & mem_test_en;
    end
    
    //assign o_addr_x = i_addr_x;
    //assign o_addr_y = i_addr_y;
    //assign o_addr = {i_addr_y[MEM_ADR_Y-1:0],i_addr_x[MEM_ADR_X-1:0]};
    always @(*) o_addr = #1 {i_addr_x[MEM_ADR_X-1:0],i_addr_y[MEM_ADR_Y-1:0]};
    
    //assign o_data[BG_DATA*MEM_DTdivBG_DT-1:0] = {MEM_DTdivBG_DT{i_data}};
    always @(*) o_data[BG_DATA*MEM_DTdivBG_DT-1:0] = #1 {MEM_DTdivBG_DT{i_data}};
    generate if (MEM_DTmodBG_DT) 
        //assign o_data[MEM_DATA:BG_DATA*MEM_DTdivBG_DT] = i_data[MEM_DTmodBG_DT-1:0];
        always @(*) o_data[MEM_DATA-1:BG_DATA*MEM_DTdivBG_DT] = #1 i_data[MEM_DTmodBG_DT-1:0];
    endgenerate
    
    //TODO gen BWE signals: generate for (int i 
    
    logic r_comp_en;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_comp_en <= '0;
        end else begin
            r_comp_en <= i_comp_en & mem_test_en;
        end
    end 
    
    logic [BG_DATA-1:0] r_expect_data;
    logic [MEM_DATA-1:0]  expect_data;
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_expect_data <= '0;
        end else begin
            r_expect_data <= i_data;
        end
    end 
    assign expect_data[BG_DATA*MEM_DTdivBG_DT-1:0] = {MEM_DTdivBG_DT{r_expect_data}};
    generate if (MEM_DTmodBG_DT) 
        assign expect_data[MEM_DATA-1:BG_DATA*MEM_DTdivBG_DT] = r_expect_data[MEM_DTmodBG_DT-1:0];
    endgenerate
    
    logic [MEM_DATA-1:0] r_compared_data, next_compared_data;
    
    assign next_compared_data = r_compared_data | ( {MEM_DATA{r_comp_en}} & (i_q^expect_data) );
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            r_compared_data <= '0;
        end
        else if (i_shift_mode) begin
            r_compared_data <= {r_compared_data[MEM_DATA-2:0],si};
        end else begin
            r_compared_data <=  next_compared_data;
        end
    end 
    assign so = r_compared_data[MEM_DATA-1];
    
    //assign o_compared_data = r_compared_data;
    assign o_fail_flag = |r_compared_data;

    //for FPGA
    initial begin
        r_compared_data = '0;
        r_comp_en = '0;
        r_expect_data = '0;
    end

endmodule





