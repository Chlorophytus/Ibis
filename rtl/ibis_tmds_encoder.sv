`timescale 1ns / 1ps
`default_nettype none
// https://github.com/projf/display_controller/blob/master/rtl/tmds_encoder_dvi.v
module ibis_tmds_encoder
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [7:0] data,
  input wire logic data_enable,
  input wire logic unsigned [1:0] control,
  output logic unsigned [9:0] out_parallel,

  output logic signed [4:0] debug_balance,
  output logic signed [4:0] debug_bias);

  logic unsigned [1:0] r_control;
  logic signed [4:0] r_bias;
  logic unsigned [9:0] r_out;
  wire logic signed [4:0] w_i_zeroes;
  wire logic signed [4:0] w_balance;
/* verilator lint_off UNOPTFLAT */
  wire logic unsigned [8:0] w_i; // q_m from the TMDS specification
/* verilator lint_on UNOPTFLAT */
  wire logic w_use_xnor;

  wire logic unsigned [3:0] w_ones;
  wire logic unsigned [2:0] w_ones_7to4;
  wire logic unsigned [2:0] w_ones_3to0;
  wire logic signed [4:0] w_i_ones;
  wire logic unsigned [2:0] w_i_ones_7to4;
  wire logic unsigned [2:0] w_i_ones_3to0;

  ibis_popcnt6 ones_7to4(
    .in_bits({2'b00, data[7:4]}),
    .count(w_ones_7to4)
  );
  ibis_popcnt6 ones_3to0(
    .in_bits({2'b00, data[3:0]}),
    .count(w_ones_3to0)
  );
  assign w_ones = {1'b0, w_ones_7to4} + {1'b0, w_ones_3to0};

  assign w_use_xnor = (w_ones > 4'h4) | ((w_ones == 4'h4) & (~data[0]));
  assign w_i[0] = data[0];
  assign w_i[1] = (w_use_xnor ? (~(w_i[0] ^ data[1])) : (w_i[0] ^ data[1]));
  assign w_i[2] = (w_use_xnor ? (~(w_i[1] ^ data[2])) : (w_i[1] ^ data[2]));
  assign w_i[3] = (w_use_xnor ? (~(w_i[2] ^ data[3])) : (w_i[2] ^ data[3]));
  assign w_i[4] = (w_use_xnor ? (~(w_i[3] ^ data[4])) : (w_i[3] ^ data[4]));
  assign w_i[5] = (w_use_xnor ? (~(w_i[4] ^ data[5])) : (w_i[4] ^ data[5]));
  assign w_i[6] = (w_use_xnor ? (~(w_i[5] ^ data[6])) : (w_i[5] ^ data[6]));
  assign w_i[7] = (w_use_xnor ? (~(w_i[6] ^ data[7])) : (w_i[6] ^ data[7]));
  assign w_i[8] = ~w_use_xnor;

  ibis_popcnt6 i_ones_7to4(
    .in_bits({2'b00, w_i[7:4]}),
    .count(w_i_ones_7to4)
  );
  ibis_popcnt6 i_ones_3to0(
    .in_bits({2'b00, w_i[3:0]}),
    .count(w_i_ones_3to0)
  );

  assign w_i_ones = signed'({1'b0, {1'b0, w_i_ones_7to4} + {1'b0, w_i_ones_3to0}});
  assign w_i_zeroes = 5'sh8 - w_i_ones;
  assign w_balance = w_i_ones - w_i_zeroes;

  always_ff @(posedge aclk) begin: ibis_tmds_encoder_control
		if(!aresetn) begin
			r_control <= 2'b00;
		end else if(enable) begin
      r_control <= control;
    end
  end: ibis_tmds_encoder_control

  always_ff @(posedge aclk) begin: ibis_tmds_encoder_output
    if(!aresetn) begin
        // synchronous reset sequence for bias to become zero
        r_bias <= 5'sh0;
    end else if(enable & data_enable) begin
      if((r_bias == 5'sh0) | (w_balance == 5'sh0)) begin
        if(~w_i[8]) begin
          r_out <= {2'b10, ~unsigned'(w_i[7:0])};
          r_bias <= r_bias - w_balance;
        end else begin
          r_out <= {2'b01, unsigned'(w_i[7:0])};
          r_bias <= r_bias + w_balance;
        end
      end else if(
          ((r_bias > 5'sh0) & (w_balance > 5'sh0)) |
          ((r_bias < 5'sh0) & (w_balance < 5'sh0)) 
      ) begin
        r_out <= {1'b1, w_i[8], ~w_i[7:0]};
        r_bias <= r_bias + signed'({3'b000, w_i[8], 1'b0}) - w_balance;
      end else begin
        r_out <= {1'b0, w_i[8], w_i[7:0]};
        r_bias <= r_bias - signed'({3'b000, ~w_i[8], 1'b0}) + w_balance;
      end
    end else if(enable) begin
      unique case(r_control)
        2'b00: r_out <= 10'b1101010100;
        2'b01: r_out <= 10'b0010101011;
        2'b10: r_out <= 10'b0101010100;
        2'b11: r_out <= 10'b1010101011;
        default: ;
      endcase
      r_bias <= 5'sh0;
    end
  end: ibis_tmds_encoder_output

  assign out_parallel = r_out;
  assign debug_balance = w_balance;
  assign debug_bias = r_bias;
endmodule: ibis_tmds_encoder
