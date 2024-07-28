`timescale 1ns / 1ps
`default_nettype none
// 6-bit population count
module ibis_popcnt6
 (input wire logic unsigned [5:0] in_bits,
  output logic unsigned [2:0] count);
  always_comb begin: ibis_popcnt6_counting
    unique case(in_bits)
      // 0x00 - 0x07
      6'b000000: count = 3'd0;
      6'b000001: count = 3'd1;
      6'b000010: count = 3'd1;
      6'b000011: count = 3'd2;
      6'b000100: count = 3'd1;
      6'b000101: count = 3'd2;
      6'b000110: count = 3'd2;
      6'b000111: count = 3'd3;

      // 0x08 - 0x10
      6'b001000: count = 3'd1;
      6'b001001: count = 3'd2;
      6'b001010: count = 3'd2;
      6'b001011: count = 3'd3;
      6'b001100: count = 3'd2;
      6'b001101: count = 3'd3;
      6'b001110: count = 3'd3;
      6'b001111: count = 3'd4;

      // 0x10 - 0x17
      6'b010000: count = 3'd1;
      6'b010001: count = 3'd2;
      6'b010010: count = 3'd2;
      6'b010011: count = 3'd3;
      6'b010100: count = 3'd2;
      6'b010101: count = 3'd3;
      6'b010110: count = 3'd3;
      6'b010111: count = 3'd4;

      // 0x18 - 0x20
      6'b011000: count = 3'd2;
      6'b011001: count = 3'd3;
      6'b011010: count = 3'd3;
      6'b011011: count = 3'd4;
      6'b011100: count = 3'd3;
      6'b011101: count = 3'd4;
      6'b011110: count = 3'd4;
      6'b011111: count = 3'd5;

      // 0x20 - 0x27
      6'b100000: count = 3'd1;
      6'b100001: count = 3'd2;
      6'b100010: count = 3'd2;
      6'b100011: count = 3'd3;
      6'b100100: count = 3'd2;
      6'b100101: count = 3'd3;
      6'b100110: count = 3'd3;
      6'b100111: count = 3'd4;

      // 0x28 - 0x30
      6'b101000: count = 3'd2;
      6'b101001: count = 3'd3;
      6'b101010: count = 3'd3;
      6'b101011: count = 3'd4;
      6'b101100: count = 3'd3;
      6'b101101: count = 3'd4;
      6'b101110: count = 3'd4;
      6'b101111: count = 3'd5;

      // 0x30 - 0x37
      6'b110000: count = 3'd2;
      6'b110001: count = 3'd3;
      6'b110010: count = 3'd3;
      6'b110011: count = 3'd4;
      6'b110100: count = 3'd3;
      6'b110101: count = 3'd4;
      6'b110110: count = 3'd4;
      6'b110111: count = 3'd5;

      // 0x38 - 0x40
      6'b111000: count = 3'd3;
      6'b111001: count = 3'd4;
      6'b111010: count = 3'd4;
      6'b111011: count = 3'd5;
      6'b111100: count = 3'd4;
      6'b111101: count = 3'd5;
      6'b111110: count = 3'd5;
      6'b111111: count = 3'd6;

      default: ;
    endcase
  end: ibis_popcnt6_counting
endmodule: ibis_popcnt6
