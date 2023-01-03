`timescale 1ns/1ns
//`define DEBUG
`define MONITOR

module mbist_tb;

parameter HALF_CYCLE = 5;
parameter A_WIDTH = 4;
parameter AX_WIDTH = 2;
parameter AY_WIDTH = 2;
parameter D_WIDTH = 2;



reg clk;
reg [D_WIDTH-1:0] d;
wire [D_WIDTH-1:0] d_out;
reg wr_en, rd_en, out_en;
reg [A_WIDTH-1:0] a;
//reg [AX_WIDTH:0] ax;
integer ax;
//reg [AY_WIDTH:0] ay;
integer ay;
//logic[1:0] axA, ayA;
wire [AX_WIDTH-1:0] AX = ax;
wire [AY_WIDTH-1:0] AY = ay;
parameter ax_max = (2**AX_WIDTH) - 1;
parameter ay_max = (2**AY_WIDTH) - 1;
reg [D_WIDTH-1:0] q;
integer data_invert;
reg mismatch;
integer i;

//--- hook up the memory ---
//SYNC_1RW_16x8 memory_inst (.CLK(clk), .D(d), .Q(d_out), .WE(wr_en), .RE(rd_en),
//.OE(out_en), .A({AX,AY}) );
microcode_container DUT(clk,1'b1,1'b0,,,,1'b1, , ,,,);

`ifdef MARCH12_XS
initial begin
    clk = 0;

    //force DUT.microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd1 , 2'd2, 1'd0   ,2'd0, 2'd1};
    //          //              i0   ,_   ,nLoop, nxt:xy,kpRC,lstAdCntOn, A    ,chgY ,incX , bgDat  ,AL  , write
    //force DUT.microcode[1] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd0, 2'd0 , 2'd0, 1'd0   ,2'd0, 2'd2 };
    //          //              i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, A    ,keepY,keepX,   BgDat,AL  , read
    //force DUT.microcode[2] = {4'd1 ,2'd0, 2'd2, 3'd3  ,1'd0,1'd1      , 3'd0, 2'd1 , 2'd2, 1'd1   ,2'd0, 2'd1 };
    //          //              i1   ,    , jump, nxt:xy,kpRC,lstAdCntOf, A    ,chgY ,incX ,invBgDat,AL  , write
    //force DUT.microcode[3] = {4'd1 ,2'd3, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd0};
    //          //              i1   ,iA+D, Loop, nxt:  ,kpRC,lstAdCntOn, A    ,     ,      , bgDat  ,AL  , nop
    //force DUT.microcode[4] = {4'd0 ,2'd1, 2'd1, 3'd3  ,1'd0,1'd0      , 3'd0, 2'd1 , 2'd2, 1'd0   ,2'd0, 2'd2 };
    //          //              i0   ,  d , Loop, nxt:xy,kpRC,lstAdCntOn, A    ,chgY ,incX ,   BgDat,AL  , read

    memory_test_MARCH_XSCAN_SP(1);
    $display("PASS = %0d",pass);
    #100 $stop;
end
`endif

`ifdef GALPAT_YS
initial begin    
    clk = 0;
    //    force DUT.microcode[0] = {4'd0 ,2'd0, 2'd0, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
    //    //              i0   ,_   ,nLoop, nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write
	//
	//
    //    force DUT.microcode[1] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd1,1'd0      , 3'd2 ,2'd2 , 2'd1, 1'd1   ,2'd0, 2'd1};
    //    //                        i0   ,_   ,nLoop, nxt:  ,inRC,lstAdCntOn, sAtoB,incY , chgX ,inBgDat,AL  , write
	//
    //    force DUT.microcode[2] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd1 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd2};
    //    //                        i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, B                , bgDat  ,AL  , read
    //    force DUT.microcode[3] = {4'd0 ,2'd0, 2'd0, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd1   ,2'd0, 2'd2};
    //    //                        i0   ,_   ,nLoop, nxt:  ,kpRC,lstAdCntOn, A                ,invBgDat,AL  , read
    //    force DUT.microcode[4] = {4'd2 ,2'd0, 2'd2, 3'd4  ,1'd1,1'd0      , 3'd1 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd0};
    //    //                        i2   ,_   , jmp , nxt:rc,inRC,lstAdCntOn, B    ,incY , chgX , bgDat  ,AL  , nop
	//
    //    force DUT.microcode[5] = {4'd1 ,2'd0, 2'd2, 3'd3  ,1'd0,1'd0      , 3'd0 ,2'd2 , 2'd1, 1'd0   ,2'd0, 2'd1};
    //    //              i1   ,_   , jmp , nxt:xy,kpRC,lstAdCntOn, A    ,incY , chgX , bgDat  ,AL  , write
	//
    //    force DUT.microcode[6] = {4'd0 ,2'd1, 2'd1, 3'd0  ,1'd0,1'd0      , 3'd0 ,2'd0 , 2'd0, 1'd0   ,2'd0, 2'd0};
    //    //              i0   ,invD, Loop, nxt:  ,kpRC,lstAdCntOn, A    ,     ,      , bgDat  ,AL  , nop
    
    memory_test_GALPAT_YSCAN_SP(1);
    $display("PASS = %0d",pass);
    #100 $stop;

end
`endif



import pmbist::*;
t_op_cmd ref_op_cmd;
integer pass = 1;

task monitor;
begin
    if ( ref_op_cmd == DUT.o_op_cmd &
    ax == DUT.o_addr_x &
    ay == DUT.o_addr_y &
    d  == DUT.o_data ) begin
    end
    else begin
        pass = 0;// ax=&0d.%0d ay=&0d.%0d ax=&0d.%0d 
        $display("fail:");
    end
    $display("op=%s.%s ax=%0d.%0d ay=%0d.%0d d=%0d.%0d",ref_op_cmd,DUT.o_op_cmd,ax,DUT.o_addr_x,ay,DUT.o_addr_y,d,DUT.o_data);
    //end
end
endtask
task monitorRead;
begin
    if ( ref_op_cmd == DUT.o_op_cmd &
    ax == DUT.o_addr_x &
    ay == DUT.o_addr_y &
    q  == DUT.o_data ) begin
    end
    else begin
        pass = 0;// ax=&0d.%0d ay=&0d.%0d ax=&0d.%0d 
        $display("fail:");
    end
    $display("op=%s.%s ax=%0d.%0d ay=%0d.%0d d=%0d.%0d",ref_op_cmd,DUT.o_op_cmd,ax,DUT.o_addr_x,ay,DUT.o_addr_y,q,DUT.o_data);
    //end
end
endtask
task memory_sp_WRITE;
//input [A_WIDTH-1:0] a;
//input [D_WIDTH-1:0] d;
begin
    `ifdef DEBUG
    $display("memory_sp_WRITE,ax= %0d,ay= %0d,d= %0d\n",ax,ay,d);
    `endif
    wr_en = 1;
    rd_en = 0;
    out_en = 1;
    //strobe = 0;
    #HALF_CYCLE clk = 1;
    #HALF_CYCLE clk = 0;
    `ifdef MONITOR
    ref_op_cmd = WRITE;
    monitor;
    `endif
end
endtask

task memory_sp_READ;
begin
    `ifdef DEBUG
    $display("memory_sp_READ ,ax= %0d,ay= %0d,q= %0d\n",ax,ay,q);
    `endif
    wr_en = 0;
    rd_en = 1;
    out_en = 1;
    //strobe = 1;
    #HALF_CYCLE clk = 1;
    #HALF_CYCLE clk = 0;
    if ( q == d_out ) mismatch = 0; else mismatch = 1;
    `ifdef MONITOR
    ref_op_cmd = READ;
    monitorRead;
    `endif
end
endtask
//task memory_sp_READ_away;
//begin
//    `ifdef DEBUG
//    $display("memory_sp_READ ,ax= %0d,ay= %0d,d= %0d\n",ax,ay,d);
//    `endif
//    wr_en = 0;
//    rd_en = 1;
//    out_en = 1;
//    //strobe = 1;
//    #HALF_CYCLE clk = 1;
//    #HALF_CYCLE clk = 0;
//    if ( q == d_out ) mismatch = 0; else mismatch = 1;
//    `ifdef MONITOR
//    ref_op_cmd = READ;
//    if ( ref_op_cmd == DUT.o_op_cmd &
//    axA == DUT.o_addr_x &
//    ayA == DUT.o_addr_y &
//    q  == DUT.o_data ) begin
//    end
//    else begin
//        pass = 0;// ax=&0d.%0d ay=&0d.%0d ax=&0d.%0d
//$display("fail:");        
//    end
//    $display("op=%s.%s ax=%0d.%0d ay=%0d.%0d d=%0d.%0d",ref_op_cmd,DUT.o_op_cmd,axA,DUT.o_addr_x,ayA,DUT.o_addr_y,q,DUT.o_data);
//    //end
//    `endif
//end
//endtask

task memory_sp_NOP;
begin
    `ifdef DEBUG
    $display("memory_sp_NOP  ,ax= %0d,ay= %0d,d= %0d\n",ax,ay,d);
    `endif
    wr_en = 0;
    rd_en = 0;
    out_en = 1;
    //strobe = 1;
    #HALF_CYCLE clk = 1;
    #HALF_CYCLE clk = 0;
    `ifdef MONITOR
    ref_op_cmd = NOP;
    //monitor;
    `endif
end
endtask

function [D_WIDTH-1:0] address_function;
input ax; //[AX_WIDTH:0] ax;
input ay; //[AY_WIDTH:0] ay;
input data_pattern;
input data_invert;
begin
    if (~data_invert) begin
        address_function = 1024'b0;
    end else begin
        address_function = {1024{1'b1}};
    end
    //$display("addr func = %d\n",address_function);
end
endfunction

//Refer MARCH_XSCAN sheet, LLWEB-10019592_Memory_test_pattern_algorithms_for_only_MINORI_T7_draft_20200214B.xlsm                                            
//SPRAM
task memory_test_MARCH_XSCAN_SP;

input data_pattern;
begin
    for (data_invert=0 ; data_invert <= 1; data_invert=data_invert+1) begin
        for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin    
            for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin
                a={ax,ay};
                d=address_function(ax,ay,data_pattern,data_invert);
                memory_sp_WRITE;
            end
        end
        for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin 
            for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin
                a={ax,ay};
                q=address_function(ax,ay,data_pattern,data_invert);
                memory_sp_READ;
                d=~address_function(ax,ay,data_pattern,data_invert);
                memory_sp_WRITE;
            end
        end     
        memory_sp_NOP; //just for pmbist DUT
        for (ay=ay_max ; ay >= 0 ; ay= ay-1 ) begin 
            for ( ax=ax_max ; ax >= 0 ; ax=ax-1) begin
                a={ax,ay};
                q=~address_function(ax,ay,data_pattern,data_invert);
                memory_sp_READ;
                d=address_function(ax,ay,data_pattern,data_invert);
                memory_sp_WRITE;
            end
        end     
        memory_sp_NOP; //just for pmbist DUT
        for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin 
            for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin
                a={ax,ay};
                q=address_function(ax,ay,data_pattern,data_invert);
                memory_sp_READ;
            end
        end 
    end
end
endtask

task memory_test_MARCH_YSCAN_SP;                    
                    
input data_pattern;                    
begin                    
    for (data_invert=0 ; data_invert <= 1; data_invert=data_invert+1) begin                
        for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin            
            for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin        
                a={ax,ay};    
                d=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;    
            end        
        end            
        for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin            
            for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin        
                a={ax,ay};    
                q=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_READ;    
                d=~address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;    
            end        
        end            
        for ( ax=ax_max ; ax >= 0 ; ax=ax-1) begin            
            for (ay=ay_max ; ay >= 0 ; ay= ay-1 ) begin        
                a={ax,ay};    
                q=~address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_READ;    
                d=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;    
            end        
        end            
        for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin            
            for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin        
                a={ax,ay};    
                q=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_READ;    
            end        
        end            
    end                
end                    
endtask                    

task GRAY_CODE_1C_SP;                                    
input data_pattern;        // data_pattern=ALL                            
begin                                    
data_invert=0;                                    
ay=0;        
                            
                                    
    for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin                    
        a={ax,ay};                             
        d=address_function(ax,ay,data_pattern,data_invert);                            
        memory_sp_WRITE;                             
    end        
                                    
    for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin    
        memory_sp_NOP;
        memory_sp_NOP;
        memory_sp_NOP;
        memory_sp_NOP;
        for ( i=0 ; i <= AY_WIDTH-1 ; i=i+1) begin //N Column address pin number                            
            for (data_invert=0 ; data_invert <= 1; data_invert=data_invert+1) begin                        
                                    
                a={ax,ay};                
                d=~address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_WRITE;                    
                memory_sp_WRITE;   //redundant operation                    
                                    
                ax[i] = ~ax[i];        
                a={ax,ay};                    
                d=address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_WRITE;                
                memory_sp_NOP;
                d=address_function(ax,ay,data_pattern,data_invert);                    
                q=address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_READ;                    
                memory_sp_WRITE;            
                                    
                ax[i] = ~ax[i];            
                a={ax,ay};                    
                q=~address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_READ;                    
                memory_sp_READ;  //redundant operation                
                                    
                ax[i] = ~ax[i];            
                a={ax,ay};                    
                q=address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_READ;                    
                memory_sp_READ;  //redundant operation                
                                    
                ax[i] = ~ax[i];            
                a={ax,ay};                    
                d=address_function(ax,ay,data_pattern,data_invert);                    
                q=address_function(ax,ay,data_pattern,data_invert);                    
                memory_sp_WRITE;                    
                memory_sp_READ;                    
                                    
            end                    
                                    
            ax[i] = ~ax[i];                
            a={ax,ay};                        
            d=address_function(ax,ay,data_pattern,data_invert);                        
            memory_sp_WRITE;
            memory_sp_NOP;
            ax[i] = ~ax[i];
            a={ax,ay};
            memory_sp_NOP;
            memory_sp_NOP;        
        end                    
        memory_sp_NOP;
        memory_sp_NOP;
    end                                
end                                    
endtask                                    

task memory_test_GALPAT_YSCAN_SP;                    
                    
input data_pattern;  
logic[1:0] r_axA, r_ayA;                  
logic[3:0] r_aA;                  
begin                    
    for (data_invert=0 ; data_invert <= 1; data_invert=data_invert+1) begin                
        for ( ax=0 ; ax <= ax_max ; ax=ax+1) begin            
            for (ay=0 ; ay <= ay_max ; ay= ay+1 ) begin        
                a={ax,ay};    
                d=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;    
            end        
        end
            
        for (int axH=0 ; axH <= ax_max ; axH=axH+1) begin            
            for (int ayH=0 ; ayH <= ay_max ; ayH= ayH+1 ) begin        
                ax = axH; ay =ayH;
                a={ax,ay};    
                d=~address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;
                //r_axA = ax-1; r_ayA = ay-1;
                r_aA = (axH<<2)+ayH;
                //for (int axA=0; axA <=ax_max ; axA =axA+1) begin   
                //    r_axA = r_axA+1;         
                //    for (int ayA=0; ayA <=ay_max ; ayA= ayA+1 ) begin  
                //        //$display("enterLoop");      
                //        //ax = axH +axA; ay =ayH +ayA;
                //        r_ayA =r_ayA+1;
                //        if (axH==r_axA & ayH==r_ayA) begin $display("skip");continue;end
                //        ax = r_axA; ay =r_ayA;
                for (int aA=0; aA <=((ax_max<<2)+ay_max) ; aA =aA+1) begin   
                        r_aA = r_aA+1;
                        if (r_aA==((axH<<2)+ayH)) continue;
                        ax = r_aA>>2; r_ayA =r_aA; ay =r_ayA;
                        a={ax,ay};    
                        q=address_function(ax,ay,data_pattern,data_invert);    
                        memory_sp_READ; 
                        ax = axH; ay =ayH;
                        a={ax,ay};    
                        q=~address_function(ax,ay,data_pattern,data_invert);    
                        memory_sp_READ;
                        memory_sp_NOP; //just for pmbist DUT                        
                //    end
                end
                ax = axH; ay =ayH;
                a={ax,ay};
                d=address_function(ax,ay,data_pattern,data_invert);    
                memory_sp_WRITE;    
            end        
        end    
        memory_sp_NOP; //just for pmbist DUT  
    end                
end                    
endtask                    



endmodule
