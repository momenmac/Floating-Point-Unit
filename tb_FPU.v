//-----------------------------------------------------------------------------
//
// Title       : FPU_tb
// Design      : FPUdesign
// Author      : Mohammad
// Company     : comp
//
//-----------------------------------------------------------------------------
//
// File        : C:/My_Designs/FPunitTest/FPUdesign/src/FPU_tb.v
// Generated   : Wed Jun 26 16:18:08 2024
// From        : Interface description file
// By          : ItfToHdl ver. 1.0
//
//-----------------------------------------------------------------------------
//
// Description : 
//
//-----------------------------------------------------------------------------
`timescale 1ns / 1ns

module tb_FPU;
	reg [31:0] F1;
    reg [31:0] F2;
    wire[31:0] F3;
	reg clk;
    
    FPU uut 
    ( 
	.clk (clk),
	.F1 (F1),
	.F2 (F2),
	.F3 (F3)
    
    );
    

    
    initial begin

        $dumpfile("dump.vcd");
      $dumpvars(1);
    end
    
    initial begin	
		clk <= 0;
		#20;
		F1 <= 32'h3f400000;
		F2 <= 32'h3ee00000;	 
		#300;
		F1 <= 32'h3D99999A;
		F2 <= 32'h3BF5C28F;
		//F3 should be: 0x3f980000;
		#6000 $finish;
    end

  initial begin
    forever begin
      #300 clk <= ~clk; 
    end
  end
    endmodule


