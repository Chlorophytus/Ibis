`timescale 1ns / 1ps
`default_nettype none
// 10-to-1 serializer
module ibis_tmds_pump
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [9:0] in_parallel,
  output wire logic out_serial);
  // Shift-to-5 state machine
  logic unsigned [4:0] r_state;
  logic unsigned [9:0] r_parallel;
  always_ff @(posedge aclk) begin: ibis_tmds_pump_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_tmds_pump_statem

  always_ff @(posedge aclk) begin: ibis_tmds_pump_hold
    if(!aresetn) begin
      r_parallel <= 10'b00000_00000;
    end else if(enable & r_state[0]) begin
      r_parallel <= in_parallel;
    end
  end: ibis_tmds_pump_hold
  
  logic unsigned [1:0] r_parallel_block;
  always_comb begin: ibis_tmds_pump_10to2
    priority casez(r_state)
      5'b00001: r_parallel_block = r_parallel[1:0];
      5'b0001z: r_parallel_block = r_parallel[3:2];
      5'b001zz: r_parallel_block = r_parallel[5:4];
      5'b01zzz: r_parallel_block = r_parallel[7:6];
      5'b1zzzz: r_parallel_block = r_parallel[9:8];
      default: ;
    endcase
  end: ibis_tmds_pump_10to2

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),
    .SRTYPE("ASYNC")
  ) ibis_tmds_pump_2to1 (
    .Q(out_serial),
    .C(aclk),
    .CE(enable),
    .D1(r_parallel_block[0]),
    .D2(r_parallel_block[1]),
    .R(!aresetn),
    .S()
  );
endmodule: ibis_tmds_pump
