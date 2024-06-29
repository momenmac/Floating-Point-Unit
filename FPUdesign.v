`timescale 1ns / 1ns
module FPU (
    input [31:0] F1,
    input [31:0] F2,
    output [31:0] F3
);

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

    FPU_adder Add (
        .f1add(adder_in1),
        .f2add(adder_in2),
        .out(adder_out)
    );

    always @(*) begin
        //if F1 is NaN or F2 is zero, return F1
        if ((exp1 == 8'hFF && frac1 != 0) || (exp2 == 8'h00 && frac2 == 0)) begin
            sign_res = sign1;
            exp_res = exp1;
            frac_res = frac1;
        end
        //if F2 is NaN or F1 is zero, return F2
        else if ((exp2 == 8'hFF && frac2 != 0) || (exp1 == 8'h00 && frac1 == 0)) begin
            sign_res = sign2;
            exp_res = exp2;
            frac_res = frac2;
        end
        //if either operand is infinity, result is infinity
        else if (exp1 == 8'hFF || exp2 == 8'hFF) begin
            sign_res = sign1 & sign2;
            exp_res = 8'hFF;
            frac_res = 0;
        end
        //addition
        else begin
            adder_in1 = F1;
            adder_in2 = F2;
            sign_res = adder_out[31];
            exp_res = adder_out[30:23];
            frac_res = {1'b0, adder_out[22:0]};
        end
    end 
    assign F3[31] = sign_res;
    assign F3[30:23] = exp_res;
    assign F3[22:0] = frac_res[22:0];
endmodule


module FPU_adder (
    input [31:0] f1add,
    input [31:0] f2add,
    output [31:0] out
);
	//interconnection signals
    wire sign1, sign2;
    wire [7:0] exp1, exp2, exp_res_small_alu, exp_res_norm;
    wire [23:0] frac1, frac2, smallest, largest, smallest_shifted, rounded_smallest;
    wire [24:0] frac_res_big_alu, frac_res_norm;
    wire sign_small, sign_large, sign_res_big_alu, sign_res_norm;
    wire [5:0] shmt;

    //extract fractions and exponents
    assign sign1 = f1add[31];
    assign sign2 = f2add[31];
    assign exp1 = f1add[30:23];
    assign exp2 = f2add[30:23];
    assign frac1 = {1'b1, f1add[22:0]};
    assign frac2 = {1'b1, f2add[22:0]};

    //small alu to find exponent difference and determine which number is larger
    small_alu small_alu_inst (
        .exp1(exp1),
        .exp2(exp2),
        .frac1(frac1),
        .frac2(frac2),
        .sign1(sign1),
        .sign2(sign2),
        .smallest(smallest),
        .largest(largest),
        .sign_small(sign_small),
        .sign_large(sign_large),
        .shmt(shmt),
        .exp_res(exp_res_small_alu)
    );

    //round the smallest after shifting right
    rounding_unit rounding_unit_inst(
        .smallest(smallest),
        .shmt(shmt),
        .rounded_smallest(rounded_smallest)
    );


    //big alu to find the sum of fractions
    big_alu big_alu_inst (
        .smallest(rounded_smallest),
        .largest(largest),
        .sign_small(sign_small),
        .sign_large(sign_large),
        .frac_res(frac_res_big_alu),
        .sign_res(sign_res_big_alu)
    );

    //normalization and rounding unit
    normalization_unit normalization_unit_inst (
        .frac_res_in(frac_res_big_alu),
        .exp_res_in(exp_res_small_alu),
        .sign_res_in(sign_res_big_alu),
        .frac_res(frac_res_norm),
        .exp_res(exp_res_norm),
        .sign_res(sign_res_norm)
    );

    //outputs
    assign out[31] = sign_res_norm;
    assign out[30:23] = exp_res_norm;
    assign out[22:0] = frac_res_norm[22:0];

endmodule


module normalization_unit (
    input [24:0] frac_res_in,
    input [7:0] exp_res_in,
    input sign_res_in,
    output reg [24:0] frac_res,
    output reg [7:0] exp_res,
    output reg sign_res
);
    always @(*) begin
        frac_res = frac_res_in;
        exp_res = exp_res_in;
        sign_res = sign_res_in;
        
        //normalization
        while (frac_res & 25'h1000000) begin
            frac_res = frac_res >> 1;
            exp_res = exp_res + 1;
            if (exp_res == 255) begin // overflow exception
                frac_res = 0;
            end
            if (frac_res[22:0] == 23'h3FFFFF) begin
                frac_res = frac_res + 1; // rounding logic
            end
        end

        while (frac_res && (frac_res[23]) == 0) begin
            frac_res = frac_res << 1;
            exp_res = exp_res - 1;
            if (exp_res == -1) begin // underflow exception
                frac_res = 0;
                exp_res = 0;
                sign_res = 0;
            end
        end
    end
endmodule


module big_alu (
    input [23:0] smallest,
    input [23:0] largest,
    input sign_small,
    input sign_large,
    output reg [24:0] frac_res,
    output reg sign_res
);
    always @(*) begin
        if (sign_large == 0 && sign_small == 0) begin//both +ve
            frac_res = smallest + largest;
            sign_res = 0;
        end else if (sign_small == 1 && sign_large == 0) begin//if one is -ve the other +ve
            frac_res = largest - smallest;
            sign_res = 0;
        end else if (sign_small == 0 && sign_large == 1) begin//one is +ve the other is -ve
            frac_res = largest - smallest;
            sign_res = 1;
        end else if (sign_small == 1 && sign_large == 1) begin//both -ve
            frac_res = smallest + largest;
            sign_res = 1;
        end
    end
endmodule


module small_alu (
    input [7:0] exp1,
    input [7:0] exp2,
    input [23:0] frac1,
    input [23:0] frac2,
    input sign1,
    input sign2,
    output reg [23:0] smallest,
    output reg [23:0] largest,
    output reg sign_small,
    output reg sign_large,
    output reg [5:0] shmt,
    output reg [7:0] exp_res
);
	always @(*) begin
		 //determine the larger number from exponent, if both where equal determine from fraction
        if (exp1 > exp2 || ((exp1 == exp2) && (frac1 >= frac2))) begin
            smallest = frac2;
            largest = frac1;
            sign_small = sign2;
            sign_large = sign1;
            shmt = exp1 - exp2;//exponent difference is used as shift amount (shmt)
            exp_res = exp1;
        end else if (exp1 < exp2 || ((exp1 == exp2) && (frac2 > frac1))) begin
            smallest = frac1;
            largest = frac2;
            sign_small = sign1;
            sign_large = sign2;
            shmt = exp2 - exp1;
            exp_res = exp2;
        end
    end
endmodule


module rounding_unit (
    input [23:0] smallest,
    input [5:0] shmt,
    output reg [23:0] rounded_smallest
);

	reg [23:0] shifted_bits;
    always @(*) begin
        rounded_smallest = smallest >> shmt;//shift right the smallest before summation in big alu unit

        //shifted bits... are they significant?
        shifted_bits = smallest & ((1 << shmt) - 1);

        //if the last shifted bit was 1 then round by adding one
        if (shifted_bits & (1 << (shmt - 1))) begin
            rounded_smallest = rounded_smallest + 1;	
        end
    end

    
endmodule
