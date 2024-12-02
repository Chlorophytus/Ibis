`timescale 1ns / 1ps
`default_nettype none
// Phase accumulator block, width can be changed
module ibis_phase_accumulator
#(parameter WIDTH = 16)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic write_enable,
  input wire logic phase_reset,
  input wire logic unsigned [WIDTH-1:0] phase_in,
  output logic unsigned [WIDTH-1:0] DEBUG_phase,
  output logic unsigned [WIDTH-1:0] DEBUG_phase_hold,
  output logic phase_is_zero);

  logic unsigned [WIDTH-1:0] r_phase;
  logic unsigned [WIDTH-1:0] r_phase_in;

  // Holds the reset value
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_input
    if(!aresetn) begin
      r_phase_in <= {WIDTH{1'b0}};
    end else if(enable & write_enable) begin
      r_phase_in <= phase_in;
    end
  end: ibis_phase_accumulator_input

  // Phase accumulator reset/carry/decrement control logic
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_control
    if(!aresetn) begin
      r_phase <= '0;
  end else if(enable) begin
      if(phase_reset) begin
        // When the phase should be reset, it'll reset to the held value
        r_phase <= r_phase_in;
      end else if(|r_phase) begin
        // Decrement the phase accumulator until it is zero
        r_phase <= r_phase - {({WIDTH-1{1'b0}}), 1'b1};
      end
    end
  end: ibis_phase_accumulator_control

  assign phase_is_zero = ~|r_phase;
  assign DEBUG_phase = r_phase;
  assign DEBUG_phase_hold = r_phase_in;
endmodule: ibis_phase_accumulator
 
