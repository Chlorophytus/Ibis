`timescale 1ns / 1ps
`default_nettype none
// Two phase accumulators
module ibis_phase_accumulator_dual
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic write_enable,
  input wire logic phase_reset,
  input wire logic unsigned [9:0] phase_in,
  output logic unsigned [4:0] DEBUG_phase0,
  output logic unsigned [4:0] DEBUG_phase1,
  output logic unsigned [4:0] DEBUG_phase0_hold,
  output logic unsigned [4:0] DEBUG_phase1_hold,
  output logic unsigned [9:0] DEBUG_phase_all,
  output logic phase_is_zero);
  
  logic unsigned [4:0] r_phase0_set;
  logic unsigned [4:0] r_phase0_hold;
  logic unsigned [4:0] r_phase1_set;

  // Setter actual register setting
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_dual_setter_set1
    if(!aresetn) begin
      r_phase1_set <= 5'b00000;
    end else if(enable & write_enable) begin
      r_phase1_set <= phase_in[9:5];
    end
  end: ibis_phase_accumulator_dual_setter_set1
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_dual_setter_set0
    if(!aresetn) begin
      r_phase0_set <= 5'b00000;
    end else if(enable & write_enable) begin
      // TODO: Check if this subtraction behaves correctly
      r_phase0_set <= phase_in[4:0];
    end
  end: ibis_phase_accumulator_dual_setter_set0

  // Phase accumulators
  wire logic phase0_is_zero;
  wire logic phase1_is_zero;
  ibis_phase_accumulator phase0(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .write_enable(write_enable),
    .phase_carry(phase0_is_zero & !(write_enable | phase_reset | phase1_is_zero)),
    .phase_reset(phase_reset),
    .phase_in(r_phase0_set),
    .DEBUG_phase(DEBUG_phase0),
    .DEBUG_phase_hold(DEBUG_phase0_hold),
    .phase_is_zero(phase0_is_zero)
  );
  ibis_phase_accumulator phase1(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & (write_enable | phase_reset | phase0_is_zero)),
    .write_enable(write_enable),
    .phase_carry(1'b0),
    .phase_reset(phase_reset),
    .phase_in(r_phase1_set),
    .DEBUG_phase(DEBUG_phase1),
    .DEBUG_phase_hold(DEBUG_phase1_hold),
    .phase_is_zero(phase1_is_zero)
  );

  assign phase_is_zero = phase0_is_zero & phase1_is_zero;
  assign DEBUG_phase_all = {DEBUG_phase1, DEBUG_phase0};
endmodule: ibis_phase_accumulator_dual
