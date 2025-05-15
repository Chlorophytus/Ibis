/**
 *  Copyright 2025 Roland Metivier
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
 *  not use this file except in compliance with the License, or, at your option,
 *  the Apache License version 2.0.
 *
 *  You may obtain a copy of the License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
`timescale 1ns / 1ps
`default_nettype none
// https://projectf.io/posts/video-timings-vga-720p-1080p/#vga-640x480-60-hz
module ibis_vga_timing
#(parameter WIDTH = 10)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  // With sync it's the sync pulse, with blank it's when we're sending control
  // codes through TMDS, or rather blanking
  output logic vsync,
  output logic vblank,
  output logic hsync,
  output logic hblank,
  output logic data_enable,
  output logic unsigned [WIDTH-1:0] ord_x,
  output logic unsigned [WIDTH-1:0] ord_y);
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

  logic unsigned [4:0] r_state;
  always_ff @(posedge aclk) begin: ibis_vga_timing_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_vga_timing_statem

  // Counters
  logic unsigned [WIDTH-1:0] r_x;
  always_ff @(posedge aclk) begin: ibis_vga_timing_counter_x
    if(!aresetn) begin
      r_x <= {WIDTH{1'b0}};
    end else if(enable & r_state[4]) begin
      if(r_x < X_BACK_PORCH) begin
        r_x <= r_x + {({WIDTH-1{1'b0}}), 1'b1};
      end else begin
        r_x <= {WIDTH{1'b0}};
      end
    end
  end: ibis_vga_timing_counter_x
  logic unsigned [WIDTH-1:0] r_y;
  always_ff @(posedge aclk) begin: ibis_vga_timing_counter_y
    if(!aresetn) begin
      r_y <= {WIDTH{1'b0}};
    end else if(enable & r_state[4] & !(|r_x)) begin
      if(r_y < Y_BACK_PORCH) begin
        r_y <= r_y + {({WIDTH-1{1'b0}}), 1'b1};
      end else begin
        r_y <= {WIDTH{1'b0}};
      end
    end
  end: ibis_vga_timing_counter_y

  logic r_do_hsync;
  logic r_do_vsync;

  logic r_do_hblank;
  logic r_do_vblank;

  // VSync/HSync logic
  always_ff @(posedge aclk) begin: ibis_vga_timing_hsync
    if(!aresetn) begin
      r_do_hsync <= 1'b1;
    end else if(enable & r_state[4]) begin
      case(r_x)
        {WIDTH{1'b0}}: r_do_hsync <= 1'b1;
        X_FRONT_PORCH - {({WIDTH-1{1'b0}}), 1'b1}: r_do_hsync <= 1'b0;
        X_SYNC_WIDTH - {({WIDTH-1{1'b0}}), 1'b1}: r_do_hsync <= 1'b1;
        default: ;
      endcase
    end
  end: ibis_vga_timing_hsync
  always_ff @(posedge aclk) begin: ibis_vga_timing_vsync
    if(!aresetn) begin
      r_do_vsync <= 1'b1;
    end else if(enable & r_state[4]) begin
      case(r_y)
        {WIDTH{1'b0}}: r_do_vsync <= 1'b1;
        Y_FRONT_PORCH - {({WIDTH-1{1'b0}}), 1'b1}: r_do_vsync <= 1'b0;
        Y_SYNC_WIDTH - {({WIDTH-1{1'b0}}), 1'b1}: r_do_vsync <= 1'b1;
        default: ;
      endcase
    end
  end: ibis_vga_timing_vsync
  
  // VBlank/HBlank logic
  always_ff @(posedge aclk) begin: ibis_vga_timing_hblank
    if(!aresetn) begin
      r_do_hblank <= 1'b1;
    end else if(enable & r_state[4]) begin
      case(r_x)
        {WIDTH{1'b0}}: r_do_hblank <= 1'b0;
        X_ACTIVE - {({WIDTH-1{1'b0}}), 1'b1}: r_do_hblank <= 1'b1;
        default: ;
      endcase
    end
  end: ibis_vga_timing_hblank
  always_ff @(posedge aclk) begin: ibis_vga_timing_vblank
    if(!aresetn) begin
      r_do_vblank <= 1'b1;
    end else if(enable & r_state[4]) begin
      case(r_y)
        {WIDTH{1'b0}}: r_do_vblank <= 1'b0;
        Y_ACTIVE - {({WIDTH-1{1'b0}}), 1'b1}: r_do_vblank <= 1'b1;
        default: ;
      endcase
    end
  end: ibis_vga_timing_vblank

  logic r_data_enable;
  always_ff @(posedge aclk) begin: ibis_vga_timing_data_enable
    if(!aresetn) begin
      r_data_enable <= 1'b0;
    end else if(enable & r_state[4]) begin
      if((r_x < X_ACTIVE) & (r_y < Y_ACTIVE)) begin
        r_data_enable <= 1'b1;
      end else begin
        r_data_enable <= 1'b0;
      end
    end
  end: ibis_vga_timing_data_enable

  // Both sync pulses are negative
  assign ord_x = r_x;
  assign ord_y = r_y;
  assign hsync = r_do_hsync;
  assign vsync = r_do_vsync;
  assign hblank = r_do_hblank;
  assign vblank = r_do_vblank;
  assign data_enable = r_data_enable;
endmodule: ibis_vga_timing
