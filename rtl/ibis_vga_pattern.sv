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
module ibis_vga_pattern
#(parameter WIDTH = 10)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [WIDTH-1:0] ord_x,
  input wire logic unsigned [WIDTH-1:0] ord_y,
  output logic unsigned [7:0] red,
  output logic unsigned [7:0] grn,
  output logic unsigned [7:0] blu);

  logic unsigned [4:0] r_state;
  always_ff @(posedge aclk) begin: ibis_vga_pattern_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_vga_pattern_statem

  logic unsigned [WIDTH-1:0] r_x;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_x <= {WIDTH{1'b0}};
    end else if(enable & r_state[4]) begin
      r_x <= ord_x;
    end
  end

  logic unsigned [WIDTH-1:0] r_y;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_y <= {WIDTH{1'b0}};
    end else if(enable & r_state[4]) begin
      r_y <= ord_y;
    end
  end

  logic unsigned [WIDTH-1:0] r_y;
  
  logic unsigned [7:0] r_red;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_red <= 8'h00;
    end else if(enable & r_state[4]) begin
      r_red <= r_x[7:0];
    end
  end

  logic unsigned [7:0] r_grn;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_grn <= 8'h00;
    end else if(enable & r_state[4]) begin
      r_grn <= r_y[7:0];
    end
  end

  logic unsigned [7:0] r_blu;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_blu <= 8'h00;
    end else if(enable & r_state[4]) begin
      r_blu <= r_x[7:0] ^ r_y[7:0];
    end
  end

  assign red = r_red;
  assign grn = r_grn;
  assign blu = r_blu;
endmodule: ibis_vga_pattern
