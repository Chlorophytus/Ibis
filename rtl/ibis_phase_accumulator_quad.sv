`timescale 1ns / 1ps
`default_nettype none
// Four phase accumulators, makes a 16-bit one
module ibis_phase_accumulator_quad
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic write_enable,
  input wire logic phase_reset,
  input wire logic unsigned [15:0] phase_in,
  output logic unsigned [3:0] DEBUG_phase0,
  output logic unsigned [3:0] DEBUG_phase1,
  output logic unsigned [3:0] DEBUG_phase2,
  output logic unsigned [3:0] DEBUG_phase3,
  output logic unsigned [3:0] DEBUG_phase0_hold,
  output logic unsigned [3:0] DEBUG_phase1_hold,
  output logic unsigned [3:0] DEBUG_phase2_hold,
  output logic unsigned [3:0] DEBUG_phase3_hold,
  output logic unsigned [15:0] DEBUG_phase_all,
  output logic phase_is_zero);
  
  logic unsigned [3:0] r_phase3_set;
  logic unsigned [3:0] r_phase2_set;
  logic unsigned [3:0] r_phase1_set;
  logic unsigned [3:0] r_phase0_set;

  // Setter actual register setting
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_quad_setter_set3
    if(!aresetn) begin
      r_phase3_set <= 4'b0000;
    end else if(enable & write_enable) begin
      r_phase3_set <= phase_in[15:12];
    end
  end: ibis_phase_accumulator_quad_setter_set3
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_quad_setter_set2
    if(!aresetn) begin
      r_phase2_set <= 4'b0000;
    end else if(enable & write_enable) begin
      r_phase2_set <= phase_in[11:8];
    end
  end: ibis_phase_accumulator_quad_setter_set2
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_quad_setter_set1
    if(!aresetn) begin
      r_phase1_set <= 4'b0000;
    end else if(enable & write_enable) begin
      r_phase1_set <= phase_in[7:4];
    end
  end: ibis_phase_accumulator_quad_setter_set1
  always_ff @(posedge aclk) begin: ibis_phase_accumulator_quad_setter_set0
    if(!aresetn) begin
      r_phase0_set <= 4'b0000;
    end else if(enable & write_enable) begin
      // TODO: Check if this subtraction behaves correctly
      r_phase0_set <= phase_in[3:0];
    end
  end: ibis_phase_accumulator_quad_setter_set0

  // Phase accumulators
  wire logic unsigned [3:0] phases_are_zero;

  ibis_phase_accumulator phase0(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .write_enable(write_enable),
    .phase_carry(phases_are_zero[0] & !(write_enable | phase_reset | (&phases_are_zero[3:1]))),
    .phase_reset(phase_reset),
    .phase_in(r_phase0_set),
    .DEBUG_phase(DEBUG_phase0),
    .DEBUG_phase_hold(DEBUG_phase0_hold),
    .phase_is_zero(phases_are_zero[0])
  );

  ibis_phase_accumulator phase1(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & (write_enable | phase_reset | (&phases_are_zero[0:0]))),
    .write_enable(write_enable),
    .phase_carry(phases_are_zero[1] & !(write_enable | phase_reset | (&phases_are_zero[3:2]))),
    .phase_reset(phase_reset),
    .phase_in(r_phase1_set),
    .DEBUG_phase(DEBUG_phase1),
    .DEBUG_phase_hold(DEBUG_phase1_hold),
    .phase_is_zero(phases_are_zero[1])
  );

  ibis_phase_accumulator phase2(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & (write_enable | phase_reset | (&phases_are_zero[1:0]))),
    .write_enable(write_enable),
    .phase_carry(phases_are_zero[2] & !(write_enable | phase_reset | (&phases_are_zero[3:3]))),
    .phase_reset(phase_reset),
    .phase_in(r_phase2_set),
    .DEBUG_phase(DEBUG_phase2),
    .DEBUG_phase_hold(DEBUG_phase2_hold),
    .phase_is_zero(phases_are_zero[2])
  );

  ibis_phase_accumulator phase3(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & (write_enable | phase_reset | (&phases_are_zero[2:0]))),
    .write_enable(write_enable),
    .phase_carry(1'b0),
    .phase_reset(phase_reset),
    .phase_in(r_phase3_set),
    .DEBUG_phase(DEBUG_phase3),
    .DEBUG_phase_hold(DEBUG_phase3_hold),
    .phase_is_zero(phases_are_zero[3])
  );

  assign phase_is_zero = &phases_are_zero;
  assign DEBUG_phase_all = {DEBUG_phase3, DEBUG_phase2, DEBUG_phase1, DEBUG_phase0};
endmodule: ibis_phase_accumulator_quad
