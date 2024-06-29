//-----------------------------------------------------------------------------
//
// Title       : FPUadder_tb
// Design      : FPUadderModulated
// Author      : Mohammad
// Company     : comp
//
//-----------------------------------------------------------------------------
//
// File        : c:/My_Designs/FPUadderModulated/FPUadderModulated/src/FPUadder_tb.v
// Generated   : Sat Jun 29 01:56:37 2024
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
    
    FPU uut 
    ( 
	.F1 (F1),
	.F2 (F2),
	.F3 (F3)
    
    );
    

    
    initial begin

        $dumpfile("dump.vcd");
      $dumpvars(1);
    end
    
    initial begin	

		F1 <= 0;
		F2 <= 0; 
		#500;
		//sum (normalize right)
		F1 <= 32'h3f400000;
		F2 <= 32'h3ee00000;
		//F3 should be: 0x3f980000;
		#500;
		//sum (normalize left)
		F1 <= 32'h3D99999A;
		F2 <= 32'h3BF5C28F;
		//F3 should be: 0x3DA8F5C3;
		#500;
		//subtraction case 1
		F1 <= 32'h3F000000;
		F2 <= 32'hBEE00000;
		//F3 should be: 0x3D800000;
		#500;
		//subtraction case 2
		F1 <= 32'hBF000000;
		F2 <= 32'h3EE00000;
		//F3 should be: 0xBD800000;
		#500;
		//rounding last shifted digit case 
		//will round -0.4927368 to -0.49274 (final result) 
		F1 <= 32'hBF000000;
		F2 <= 32'h3BEE0000;
		//F3 should be: 0xBEFC4800;	
		#500;
		//sum 0.999999 with 0.5 should round and produce 1.5
		F1 <= 32'h3F7FFFFF;
		F2 <= 32'h3F000000;
		#500;
		//same exponent case
		F1 <= 32'h3FFFFFFF;
		F2 <= 32'h40000000;
		#500;
		//infinity case
		F1 <= 32'h7F800000;//infinity case
		F2 <= 32'h7F000000;
		#500;
		//very large number + very small number = very large number
		F1 <= 32'hFF7FFFFF;
		F2 <= 32'h3FC51EB8;
		#500;
		//NaN + num = NaN
		F1 <= 32'hFFFFFFFF;//NaN
		F2 <= 32'h3FC51EB8;
		#500;
		//0 + num = num
		F1 <= 32'h00000000;//0 case
		F2 <= 32'h40A00000;
		#500;
		//NaN + inf = NaN
		F1 <= 32'hFFFFFFFF;
		F2 <= 32'h7F800000;
		#500;
		//very large + very large = inf (overflow detection)
		F1 <= 32'h7F000003;
		F2 <= 32'h7F000003;
		#500;
		//-very large - very large = -inf (underflow detection)
		F1 <= 32'hFF000003;
		F2 <= 32'hFF000003;
		#700;	
		$finish;
    end	


    endmodule
