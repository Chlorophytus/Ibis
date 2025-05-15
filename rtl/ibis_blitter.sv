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
// 5-stage texture bit-block transfer
module ibis_blitter
#(parameter WIDTH = 10,
  parameter X_MAX = 640,
  parameter Y_MAX = 480)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [WIDTH-1:0] x,
  input wire logic unsigned [WIDTH-1:0] y,
  // Origin x0 and y0, destination x1 and y1
  input wire logic unsigned [WIDTH-1:0] translate_x_src,
  input wire logic unsigned [WIDTH-1:0] translate_y_src,
  input wire logic unsigned [WIDTH-1:0] translate_x_dst,
  input wire logic unsigned [WIDTH-1:0] translate_y_dst,
  // Width and height
  input wire logic unsigned [WIDTH-1:0] translate_width,
  input wire logic unsigned [WIDTH-1:0] translate_height,
  // Are we outputting?
  output logic translate_out_valid,
  // The X and Y value we read. Garbage if `translate_out_valid` is 1'b0.
  output logic unsigned [WIDTH-1:0] translate_out_x,
  output logic unsigned [WIDTH-1:0] translate_out_y);
  // TODO
endmodule: ibis_blitter
