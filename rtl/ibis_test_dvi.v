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
module ibis_test_dvi
 (input wire aclk, // 125.875 MHz
  input wire aresetn,
  input wire enable,
  output wire tmds_red,
  output wire tmds_grn,
  output wire tmds_blu,
  output wire tmds_clk);

  wire data_enable;
  wire vblank;
  wire hblank;
  wire hsync;
  wire vsync;
  wire [9:0] x;
  wire [9:0] y;
  wire [7:0] red;
  wire [7:0] grn;
  wire [7:0] blu;

  ibis_vga_timing timing(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .vsync(vsync),
    .vblank(vblank),
    .hsync(hsync),
    .hblank(hblank),
    .data_enable(data_enable),
    .ord_x(x),
    .ord_y(y)
  );
  ibis_vga_pattern pattern(
   .aclk(aclk),
   .aresetn(aresetn),
   .enable(enable),
   .ord_x(x),
   .ord_y(y),
   .red(red),
   .grn(grn),
   .blu(blu)
  );

  // TMDS Blue channel
  ibis_tmds ibis_tmds_blu(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control({vsync, hsync}),
    .data(blu),
    .out_serial(tmds_blu)
  );
  // TMDS Green channel
  ibis_tmds ibis_tmds_grn(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(grn),
    .out_serial(tmds_grn)
  );
  // TMDS Red channel
  ibis_tmds ibis_tmds_red(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(red),
    .out_serial(tmds_red)
  );
  // TMDS is rising-edge clock
  ibis_tmds_pump ibis_tmds_clk(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .in_parallel(10'b00000_11111),
    .out_serial(tmds_clk)
  );
endmodule
 
