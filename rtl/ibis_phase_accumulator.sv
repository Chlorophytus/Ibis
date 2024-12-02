`timescale 1ns / 1ps
`default_nettype none
// CARRY4-conscientious phase accumulator block
// NOTE: Full LUT5/LUT6 utilization seems just for non-CARRY4 tasks
module ibis_phase_accumulator
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic write_enable,
  input wire logic phase_carry,
  input wire logic phase_reset,
  input wire logic unsigned [3:0] phase_in,
  output logic unsigned [3:0] DEBUG_phase,
  output logic unsigned [3:0] DEBUG_phase_hold,
  output logic phase_is_zero);

  logic unsigned [3:0] r_phase;
  logic unsigned [3:0] r_phase_in;

  // Holds the reset value
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_input
    if(!aresetn) begin
      r_phase_in <= 4'b0000;
    end else if(enable & write_enable) begin
      r_phase_in <= phase_in;
    end
  end: ibis_phase_accumulator_input

  // Phase accumulator reset/carry/decrement control logic
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_control
    if(!aresetn) begin
      r_phase <= 4'b0000;
  end else if(enable) begin
      if(phase_reset) begin
        // When the phase should be reset, it'll reset to the held value
        r_phase <= r_phase_in;
      end else if(phase_carry) begin
        // Since we're unsigned, carrying will force the phase to all high
        r_phase <= 4'b1111;
      end else if(|r_phase) begin
        // Decrement the phase accumulator until it is zero
        r_phase <= r_phase - 4'b0001;
      end
    end
  end: ibis_phase_accumulator_control

  assign phase_is_zero = ~|r_phase;
  assign DEBUG_phase = r_phase;
  assign DEBUG_phase_hold = r_phase_in;
endmodule: ibis_phase_accumulator
 
