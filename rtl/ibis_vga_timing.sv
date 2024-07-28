`timescale 1ns / 1ps
`default_nettype none
// https://projectf.io/posts/video-timings-vga-720p-1080p/#vga-640x480-60-hz
module ibis_vga_timing
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  // With sync it's the sync pulse, with blank it's when we're sending control
  // codes through TMDS, or rather blanking
  output logic vsync,
  output logic vblankn,
  output logic hsync,
  output logic hblankn,
  output logic unsigned [9:0] ord_x,
  output logic unsigned [9:0] ord_y);
  // Configure horizontal display timings here
  localparam X_ACTIVE = 640;
  localparam X_FRONT_PORCH = X_ACTIVE + 16;
  localparam X_SYNC_WIDTH = X_FRONT_PORCH + 96;
  localparam X_BACK_PORCH = X_SYNC_WIDTH + 48;
  // Configure vertical display timings here
  localparam Y_ACTIVE = 480;
  localparam Y_FRONT_PORCH = Y_ACTIVE + 10;
  localparam Y_SYNC_WIDTH = Y_FRONT_PORCH + 2;
  localparam Y_BACK_PORCH = Y_SYNC_WIDTH + 33;

  // Shift-to-5 state machine to step the clock from TMDS speed to ~25.175MHz
  logic unsigned [4:0] r_state;
  always_ff @(posedge aclk) begin: ibis_vga_timing_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_vga_timing_statem

  logic unsigned [1:0] r_state_writer;

  always_ff @(posedge aclk) begin: ibis_vga_timing_writer_statem
    if(!aresetn) begin
      r_state_writer <= 2'b01;
    end else if(enable & r_state[4]) begin
      r_state_writer <= r_state_writer << 1;
    end
  end: ibis_vga_timing_writer_statem

  wire logic unsigned [3:0] x_status;
  wire logic accumulators_enable;
  assign accumulators_enable = |r_state_writer | r_state[4];
  ibis_phase_accumulator_dual x_active_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | x_status[3]),
    .phase_in(X_ACTIVE - 1),
    .phase_is_zero(x_status[0]),

    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual x_front_porch_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1]  | x_status[3]),
    .phase_in(X_FRONT_PORCH - 1),
    .phase_is_zero(x_status[1]),
    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual x_sync_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | x_status[3]),
    .phase_in(X_SYNC_WIDTH - 1),
    .phase_is_zero(x_status[2]),
    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual x_back_porch_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | x_status[3]),
    .phase_in(X_BACK_PORCH - 1),
    .phase_is_zero(x_status[3]),
    .DEBUG_phase_all(ord_x),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );

  wire logic unsigned [3:0] y_status;
  ibis_phase_accumulator_dual y_active_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable & x_status[3]),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | y_status[3]),
    .phase_in(Y_ACTIVE - 1),
    .phase_is_zero(y_status[0]),
    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual y_front_porch_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable & x_status[3]),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | y_status[3]),
    .phase_in(Y_FRONT_PORCH - 1),
    .phase_is_zero(y_status[1]),
    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual y_sync_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable & x_status[3]),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | y_status[3]),
    .phase_in(Y_SYNC_WIDTH - 1),
    .phase_is_zero(y_status[2]),
    .DEBUG_phase_all(),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );
  ibis_phase_accumulator_dual y_back_porch_acc(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable & accumulators_enable & x_status[3]),
    .write_enable(r_state_writer[0]),
    .phase_reset(r_state_writer[1] | y_status[3]),
    .phase_in(Y_BACK_PORCH - 1),
    .phase_is_zero(y_status[3]),
    .DEBUG_phase_all(ord_y),
    .DEBUG_phase0(),
    .DEBUG_phase1(),
    .DEBUG_phase0_hold(),
    .DEBUG_phase1_hold()
  );

  // Both sync pulses are negative
  // NOTE: We keep track of the X/Y ordinates starting with 0 instead of 1
  assign hsync = !(x_status[1] & !x_status[2]);
  assign vsync = !(y_status[1] & !y_status[2]);

  // NEGATIVE blanking intervals
  assign hblankn = x_status[0];
  assign vblankn = y_status[0];
endmodule: ibis_vga_timing
