`timescale 1ns / 1ps
`default_nettype none
// LUT5-conscientious phase accumulator block
module ibis_phase_accumulator
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic write_enable,
  input wire logic phase_carry,
  input wire logic phase_reset,
  input wire logic unsigned [4:0] phase_in,
  output logic unsigned [4:0] DEBUG_phase,
  output logic unsigned [4:0] DEBUG_phase_hold,
  output logic phase_is_zero);

  logic unsigned [4:0] r_phase;
  logic unsigned [4:0] r_phase_hold;

  // Holds the reset value
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_write
    if(!aresetn) begin
      r_phase_hold <= 5'b00000;
    end else if(enable & write_enable) begin
      r_phase_hold <= phase_in;
    end
  end: ibis_phase_accumulator_write

  // Decrements the phase accumulator
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_decrement
    if(!aresetn) begin
      r_phase <= 5'b00000;
    end else if (enable) begin
      if(phase_reset) begin
        // When the phase should be reset, it'll reset to the hold value
        r_phase <= r_phase_hold;
      end else if(phase_carry) begin
        // Carrying will force the phase to all high
        r_phase <= 5'b11111;
      end else if((|r_phase)) begin
        // Decrement the phase accumulator until it is zero
        r_phase <= r_phase - 5'b00001;
      end
    end
  end: ibis_phase_accumulator_decrement

  assign phase_is_zero = ~|r_phase;
  assign DEBUG_phase = r_phase;
  assign DEBUG_phase_hold = r_phase_hold;
endmodule: ibis_phase_accumulator
 
