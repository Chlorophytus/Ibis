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
  output logic unsigned [11:0] ord_x,
  output logic unsigned [11:0] ord_y);
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

  // X ordinate changes first
  logic unsigned [11:0] r_ord_x;
  always_ff @(posedge aclk) begin: ibis_vga_timing_x
    if(!aresetn) begin
      r_ord_x <= X_BACK_PORCH - 12'h001;
    end else if(enable & r_state[0]) begin
      if(r_ord_x < X_BACK_PORCH) begin
        r_ord_x <= r_ord_x + 12'h001;
      end else begin
        r_ord_x <= 12'h000;
      end
    end
  end: ibis_vga_timing_x

  // y ordinate changes when x == 12'h000
  logic unsigned [11:0] r_ord_y;
  always_ff @(posedge aclk) begin: ibis_vga_timing_y
    if(!aresetn) begin
      r_ord_y <= Y_BACK_PORCH - 12'h001;
    end else if(enable & r_state[1] & ~(|r_ord_x)) begin
      if(r_ord_y < Y_BACK_PORCH) begin
        r_ord_y <= r_ord_y + 12'h001;
      end else begin
        r_ord_y <= 12'h000;
      end
    end
  end: ibis_vga_timing_y

  // hopefully when syncing to state bit 4 we can get a uniform output
  logic unsigned [11:0] r_out_ord_x;
  logic unsigned [11:0] r_out_ord_y;
  always_ff @(posedge aclk) begin: ibis_vga_timing_xy_sync
    if(!aresetn) begin
      r_out_ord_x <= 12'h000;
      r_out_ord_y <= 12'h000;
    end else if(enable & r_state[4]) begin
      r_out_ord_x <= r_ord_x;
      r_out_ord_y <= r_ord_y;
    end
  end: ibis_vga_timing_xy_sync
  assign ord_x = r_out_ord_x;
  assign ord_y = r_out_ord_y;

  // Both sync pulses are negative
  // NOTE: We keep track of the X/Y ordinates starting with 0 instead of 1
  assign hsync = (ord_x < X_FRONT_PORCH) | (ord_x >= X_SYNC_WIDTH);
  assign vsync = (ord_y < Y_FRONT_PORCH) | (ord_y >= Y_SYNC_WIDTH);

  // NEGATIVE blanking intervals
  assign hblankn = ord_x < X_ACTIVE;
  assign vblankn = ord_y < Y_ACTIVE;
endmodule: ibis_vga_timing
