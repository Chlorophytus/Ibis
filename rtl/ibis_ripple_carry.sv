`timescale 1ns / 1ps
`default_nettype none
// LUT5-conscientious ripple carry block
module ibis_ripple_carry
 (input wire logic unsigned [1:0] addend0,
	input wire logic unsigned [1:0] addend1,
	input wire logic carry_i,
	output logic unsigned [1:0] sum,
	output logic carry_o);

	always_comb begin: ibis_ripple_carry_lookup
		unique case({carry_i, addend0, addend1})
			5'b00000: {carry_o, sum} = 3'b000; // 0 + 0 = 0
			5'b00001: {carry_o, sum} = 3'b001; // 0 + 1 = 1
			5'b00010: {carry_o, sum} = 3'b010; // 0 + 2 = 2
			5'b00011: {carry_o, sum} = 3'b011; // 0 + 3 = 3

			5'b00100: {carry_o, sum} = 3'b001; // 1 + 0 = 1
			5'b00101: {carry_o, sum} = 3'b010; // 1 + 1 = 2
			5'b00110: {carry_o, sum} = 3'b011; // 1 + 2 = 3
			5'b00111: {carry_o, sum} = 3'b100; // 1 + 3 = 4

			5'b01000: {carry_o, sum} = 3'b010; // 2 + 0 = 2
			5'b01001: {carry_o, sum} = 3'b011; // 2 + 1 = 3
			5'b01010: {carry_o, sum} = 3'b100; // 2 + 2 = 4
			5'b01011: {carry_o, sum} = 3'b101; // 2 + 3 = 5

			5'b01100: {carry_o, sum} = 3'b011; // 3 + 0 = 3
			5'b01101: {carry_o, sum} = 3'b100; // 3 + 1 = 4
			5'b01110: {carry_o, sum} = 3'b101; // 3 + 2 = 5
			5'b01111: {carry_o, sum} = 3'b110; // 3 + 3 = 6

			5'b10000: {carry_o, sum} = 3'b001; // 4 + 0 = 4
			5'b10001: {carry_o, sum} = 3'b010; // 4 + 1 = 5
			5'b10010: {carry_o, sum} = 3'b011; // 4 + 2 = 6
			5'b10011: {carry_o, sum} = 3'b100; // 4 + 3 = 7

			5'b10100: {carry_o, sum} = 3'b010; // 5 + 0 = 5
			5'b10101: {carry_o, sum} = 3'b011; // 5 + 1 = 6
			5'b10110: {carry_o, sum} = 3'b100; // 5 + 2 = 7
			5'b10111: {carry_o, sum} = 3'b101; // 5 + 3 = 8

			5'b11000: {carry_o, sum} = 3'b011; // 6 + 0 = 6
			5'b11001: {carry_o, sum} = 3'b100; // 6 + 1 = 7
			5'b11010: {carry_o, sum} = 3'b101; // 6 + 2 = 8
			5'b11011: {carry_o, sum} = 3'b110; // 6 + 3 = 9

			5'b11100: {carry_o, sum} = 3'b100; // 7 + 0 = 7
			5'b11101: {carry_o, sum} = 3'b101; // 7 + 1 = 8
			5'b11110: {carry_o, sum} = 3'b110; // 7 + 2 = 9
			5'b11111: {carry_o, sum} = 3'b111; // 7 + 3 = 10

			default: ; // Do nothing otherwise
		endcase
	end: ibis_ripple_carry_lookup
endmodule: ibis_ripple_carry
