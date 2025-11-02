// ==========================================================
// Basic Gate-Level Building Blocks
// ==========================================================

// ----------------------------------------------------------
// Multi-input AND gates
// ----------------------------------------------------------
module and3(output out, input a, b, c);
    assign out = a & b & c;
endmodule

module and4(output out, input a, b, c, d);
    assign out = a & b & c & d;
endmodule

module and5(output out, input a, b, c, d, e);
    assign out = a & b & c & d & e;
endmodule

// ----------------------------------------------------------
// 2-to-1 MUX (1-bit, 2-bit, 8-bit)
// ----------------------------------------------------------
module mux_2to1_1bit(input in0, input in1, input sel, output out);
    wire not_sel, out0, out1;
    not n1 (not_sel, sel);
    and a0 (out0, in0, not_sel);
    and a1 (out1, in1, sel);
    or o1 (out, out0, out1);
endmodule

module mux_2to1_2bit(input [1:0] in0, input [1:0] in1, input sel, output [1:0] out);
    mux_2to1_1bit m0 (in0[0], in1[0], sel, out[0]);
    mux_2to1_1bit m1 (in0[1], in1[1], sel, out[1]);
endmodule

module mux_2to1_8bit(input [7:0] in0, input [7:0] in1, input sel, output [7:0] out);
    mux_2to1_1bit m0 (in0[0], in1[0], sel, out[0]);
    mux_2to1_1bit m1 (in0[1], in1[1], sel, out[1]);
    mux_2to1_1bit m2 (in0[2], in1[2], sel, out[2]);
    mux_2to1_1bit m3 (in0[3], in1[3], sel, out[3]);
    mux_2to1_1bit m4 (in0[4], in1[4], sel, out[4]);
    mux_2to1_1bit m5 (in0[5], in1[5], sel, out[5]);
    mux_2to1_1bit m6 (in0[6], in1[6], sel, out[6]);
    mux_2to1_1bit m7 (in0[7], in1[7], sel, out[7]);
endmodule

// ----------------------------------------------------------
// 4-to-1 MUX (1-bit, 2-bit, 8-bit)
// ----------------------------------------------------------
module mux_4to1_2bit(
    input [1:0] in0, input [1:0] in1, input [1:0] in2, input [1:0] in3, 
    input [1:0] sel, 
    output [1:0] out
);
    wire [1:0] m01_out, m23_out;
    mux_2to1_2bit m01 (in0, in1, sel[0], m01_out);
    mux_2to1_2bit m23 (in2, in3, sel[0], m23_out);
    mux_2to1_2bit m_final (m01_out, m23_out, sel[1], out);
endmodule

module mux_4to1_8bit(
    input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, 
    input [1:0] sel, 
    output [7:0] out
);
    wire [7:0] m01_out, m23_out;
    mux_2to1_8bit m01 (in0, in1, sel[0], m01_out);
    mux_2to1_8bit m23 (in2, in3, sel[0], m23_out);
    mux_2to1_8bit m_final (m01_out, m23_out, sel[1], out);
endmodule

// ----------------------------------------------------------
// 2-to-4 Decoder
// ----------------------------------------------------------
module decoder_2to4(input [1:0] in, output [3:0] out);
    wire not_in0, not_in1;
    not n0 (not_in0, in[0]);
    not n1 (not_in1, in[1]);
    
    and a0 (out[0], not_in1, not_in0); // 00
    and a1 (out[1], not_in1, in[0]);  // 01
    and a2 (out[2], in[1],  not_in0); // 10
    and a3 (out[3], in[1],  in[0]);   // 11
endmodule

// ----------------------------------------------------------
// D Flip-Flop with asynchronous active-low reset
// ----------------------------------------------------------
module dff_rst(input clk, input rst_n, input d, output reg q);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule

// ----------------------------------------------------------
// Register (with enable and async reset)
// ----------------------------------------------------------
module register_2bit_rst(input clk, input rst_n, input en, input [1:0] d, output reg [1:0] q);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 2'd0;
        else if (en)
            q <= d;
    end
endmodule

module register_8bit_rst(input clk, input rst_n, input en, input [7:0] d, output reg [7:0] q);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'd0;
        else if (en)
            q <= d;
    end
endmodule

// ----------------------------------------------------------
// Adder (Gate level is too complex, using dataflow)
// ----------------------------------------------------------
module adder_8bit(input [7:0] a, input [7:0] b, output [7:0] sum);
    assign sum = a + b;
endmodule

// ----------------------------------------------------------
// Comparator (Gate level is too complex, using dataflow)
// ----------------------------------------------------------
module comparator_2bit(
    input [1:0] a,
    input [1:0] b,
    output gt, eq, lt
);
    assign gt = (a > b);
    assign eq = (a == b);
    assign lt = (a < b);
endmodule

module comparator_8bit(
    input [7:0] a,
    input [7:0] b,
    output gt, eq, lt
);
    assign gt = (a > b);
    assign eq = (a == b);
    assign lt = (a < b);
endmodule

// ----------------------------------------------------------
// 2-bit Counter with async reset
// ----------------------------------------------------------
module counter_2bit_rst(
    input wire clk,
    input wire rst_n, // Active-low reset
    input wire en,    // Count enable
    output reg [1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 2'b00;
        else if (en)
            q <= q + 1;
    end
endmodule

// ----------------------------------------------------------
// 8-bit Counter with async reset
// ----------------------------------------------------------
module counter_8bit_rst(
    input wire clk,
    input wire rst_n, // Active-low reset
    input wire en_up,  // Count up
    input wire en_down,// Count down
    output reg [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 8'b0;
        else if (en_up)
            q <= q + 1;
        else if (en_down)
            q <= q - 1;
    end
endmodule
