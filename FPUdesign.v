module FPU (
    input clk,
    input [31:0] F1,
    input [31:0] F2,
    output [31:0] F3
);

    // Wires for splitting 
    wire sign1, sign2;
    wire [7:0] exp1, exp2;
    wire [22:0] frac1, frac2;
    
    assign sign1 = F1[31];
    assign exp1 = F1[30:23];
    assign frac1 = F1[22:0];

    assign sign2 = F2[31];
    assign exp2 = F2[30:23];
    assign frac2 = F2[22:0];
    
    reg sign_res;
    reg [7:0] exp_res;
    reg [24:0] frac_res;
    
    reg [31:0] adder_in1;
    reg [31:0] adder_in2;
    wire [31:0] adder_out;

    assign F3[31] = sign_res;
    assign F3[30:23] = exp_res;
    assign F3[22:0] = frac_res[22:0];

    adder Add (
        .f1add(adder_in1),
        .f2add(adder_in2),
        .out(adder_out)
    );
    
    always @(posedge clk) begin
        // If F1 is NaN or F2 is zero, return F1
        if ((exp1 == 8'hFF && frac1 != 0) || (exp2 == 8'h00 && frac2 == 0)) begin
            sign_res = sign1;
            exp_res = exp1;
            frac_res = frac1;
        end
        // If F2 is NaN or F1 is zero, return F2
        else if ((exp2 == 8'hFF && frac2 != 0) || (exp1 == 8'h00 && frac1 == 0)) begin
            sign_res = sign2;
            exp_res = exp2;
            frac_res = frac2;
        end
        // If either operand is infinity, result is infinity
        else if (exp1 == 8'hFF || exp2 == 8'hFF) begin
            sign_res = sign1 & sign2;
            exp_res = 8'hFF;
            frac_res = 0;
        end
        // Perform addition
        else begin
            adder_in1 = F1;
            adder_in2 = F2;
            sign_res = adder_out[31];
            exp_res = adder_out[30:23];
            frac_res = {1'b0, adder_out[22:0]};
        end
    end    
endmodule

module adder (
    input [31:0] f1add,
    input [31:0] f2add,
    output [31:0] out
);
    // For the inputs
    reg sign1;
    reg sign2;
	reg [31:0]out_temp;
    reg [7:0] exp1;
    reg [7:0] exp2;
    reg [23:0] frac1;
    reg [23:0] frac2;
    reg [23:0] smallest;
    reg [23:0] largest;
    reg [5:0] shmt;
	reg [23:0] smallest_shifted;
	reg [23:0] shifted_bits;
	reg sign_small;
    reg sign_large;
    // For the outputs
    reg sign_res;
    reg [7:0] exp_res;
    reg [24:0] frac_res;
	assign out[31] = sign_res;
    assign out[30:23] = exp_res;
    assign out[22:0] = frac_res[22:0];
    always @(*) begin
        sign1 = f1add[31];
        sign2 = f2add[31];
        exp1 = f1add[30:23];
        exp2 = f2add[30:23];
        frac1 = {1'b1, f1add[22:0]};
        frac2 = {1'b1, f2add[22:0]};
        smallest = exp1 > exp2 ? frac2 : frac1;
        largest = exp1 < exp2 ? frac2 : frac1;
		if (exp1 > exp2) begin
            smallest = frac2;
            largest = frac1;
            sign_small = sign2;
            sign_large = sign1;
        end
        else if (exp1 < exp2) begin
            smallest = frac1;
            largest = frac2;
            sign_small = sign1;
            sign_large = sign2;
        end
        // Find the difference between exponents
        if (exp1 >= exp2) begin
            shmt = exp1 - exp2;
            exp_res = exp1;
        end 
        else begin
            shmt = exp2 - exp1;
            exp_res = exp2;
        end
        //rounding hardware
    smallest_shifted = smallest >> shmt;

    //shifted bits. are they significant?
    shifted_bits = smallest & ((1 << shmt) - 1);

    //if the last shifted bit was 1 then round by adding one
    if (shifted_bits & (1 << (shmt - 1))) begin
        smallest_shifted = smallest_shifted + 1;
		
    end
	smallest = smallest_shifted;
        if (sign1 == 0 && sign2 == 0) begin // Handle other sign cases later!!
            frac_res = smallest + largest;
			//frac_res = 25'h980000;
            sign_res = 0;
        end
	
				
        // Normalization
        // If frac_res > 011111111111111111111111 (0x7FFFFF) 
	   if (frac_res & 25'h1000000) begin
            frac_res = frac_res >> 1;
            exp_res = exp_res + 1;
	   end
	   else begin
			while (frac_res && (frac_res & 25'h800000) == 0) begin
				frac_res = frac_res << 1;
				exp_res = exp_res - 1;
			end
		end
		out_temp = {sign1, exp_res, frac_res[22:0]};
        
        // If frac_res < 010000000000000000000000 (0x400000)

    end


endmodule
