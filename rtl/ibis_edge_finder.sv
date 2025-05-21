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
// edge finder based around Pineda's edge function (TODO)
module ibis_edge_finder
#(parameter WIDTH = 11)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [5:0] write_locs,
  input wire logic unsigned [WIDTH - 1:0] a_x,
  input wire logic unsigned [WIDTH - 1:0] a_y,
  input wire logic unsigned [WIDTH - 1:0] b_x,
  input wire logic unsigned [WIDTH - 1:0] b_y,
  input wire logic unsigned [WIDTH - 1:0] c_x,
  input wire logic unsigned [WIDTH - 1:0] c_y,
  output logic stencil_test,
  output logic ready);
  // ==========================================================================
  // 10-stage state machine
  // ==========================================================================
  logic unsigned [4:0] r_state;
  always_ff @(posedge aclk) begin: ibis_edge_finder_statem
    if(!aresetn) begin
      r_state <= 10'b00000_00001;
    end else if(enable) begin
      r_state <= {r_state[8:0], r_state[9]};
    end
  end: ibis_edge_finder_statem
  // ==========================================================================
  // Hold on to the ordinates for the edge test
  // ==========================================================================
  logic unsigned [11:0] r_ordinates[6];
  // hold a_x
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Ax
    if(!aresetn) begin
      r_ordinates[0] <= 12'h000;
    end else if(enable & write_locs[0] & r_state[0]) begin
      r_ordinates[0] <= a_x;
    end
  end: ibis_texture_mapper_hold_Ax
  // hold a_y
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Ay
    if(!aresetn) begin
      r_ordinates[1] <= 12'h000;
    end else if(enable & write_locs[1] & r_state[0]) begin
      r_ordinates[1] <= a_y;
    end
  end: ibis_texture_mapper_hold_Ay
  // hold b_x
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Bx
    if(!aresetn) begin
      r_ordinates[2] <= 12'h000;
    end else if(enable & write_locs[2] & r_state[0]) begin
      r_ordinates[2] <= b_x;
    end
  end: ibis_texture_mapper_hold_Bx
  // hold b_y
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_By
    if(!aresetn) begin
      r_ordinates[3] <= 12'h000;
    end else if(enable & write_locs[3] & r_state[0]) begin
      r_ordinates[3] <= b_y;
    end
  end: ibis_texture_mapper_hold_By
  // hold c_x
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Cx
    if(!aresetn) begin
      r_ordinates[4] <= 12'h000;
    end else if(enable & write_locs[4] & r_state[0]) begin
      r_ordinates[4] <= c_x;
    end
  end: ibis_texture_mapper_hold_Cx
  // hold c_y
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Cy
    if(!aresetn) begin
      r_ordinates[5] <= 12'h000;
    end else if(enable & write_locs[5] & r_state[0]) begin
      r_ordinates[5] <= c_y;
    end
  end: ibis_texture_mapper_hold_Cy
  // ==========================================================================
  // Subtractions
  // ==========================================================================
  logic signed [13:0] r_intermediates[4];
  // c.x - a.x
  always_ff @(posedge aclk) begin: ibis_edge_finder_intermediate_CxAx
    if(!aresetn) begin
      r_intermediates[0] <= 14'sh0;
    end else if(enable & r_state[1]) begin
      r_intermediates[0] <= signed'({2'b00, r_ordinates[4]}) -
                            signed'({2'b00, r_ordinates[0]});
    end
  end: ibis_edge_finder_intermediate_CxAx
  // b.y - a.y
  always_ff @(posedge aclk) begin: ibis_edge_finder_intermediate_ByAy
    if(!aresetn) begin
      r_intermediates[1] <= 14'sh0;
    end else if(enable & r_state[1]) begin
      r_intermediates[1] <= signed'({2'b00, r_ordinates[3]}) -
                            signed'({2'b00, r_ordinates[1]});
    end
  end: ibis_edge_finder_intermediate_ByAy
  // c.y - a.y
  always_ff @(posedge aclk) begin: ibis_edge_finder_intermediate_CyAy
    if(!aresetn) begin
      r_intermediates[2] <= 14'sh0;
    end else if(enable & r_state[1]) begin
      r_intermediates[2] <= signed'({2'b00, r_ordinates[5]}) -
                            signed'({2'b00, r_ordinates[1]});
    end
  end: ibis_edge_finder_intermediate_CyAy
  // b.x - a.x
  always_ff @(posedge aclk) begin: ibis_edge_finder_intermediate_BxAx
    if(!aresetn) begin
      r_intermediates[3] <= 14'sh0;
    end else if(enable & r_state[1]) begin
      r_intermediates[3] <= signed'({2'b00, r_ordinates[2]}) -
                            signed'({2'b00, r_ordinates[0]});
    end
  end: ibis_edge_finder_intermediate_BxAx
  // ==========================================================================
  // Staggered multiplications
  // ==========================================================================
  logic signed [27:0] r_multiplications[2];
  always_ff @(posedge aclk) begin: ibis_edge_finder_multiply_CxAx_ByAy
    if(!aresetn) begin
      r_multiplications[0] <= 28'sh0;
    end else if(enable & r_state[2]) begin
      r_multiplications[0] <= r_intermediates[0] * r_intermediates[1];
    end
  end: ibis_edge_finder_multiply_CxAx_ByAy
  always_ff @(posedge aclk) begin: ibis_edge_finder_multiply_CyAy_BxAx
    if(!aresetn) begin
      r_multiplications[1] <= 28'sh0;
    end else if(enable & r_state[5]) begin
      r_multiplications[1] <= r_intermediates[2] * r_intermediates[3];
    end
  end: ibis_edge_finder_multiply_CyAy_BxAx
  // ==========================================================================
  // Final subtraction
  // ==========================================================================
  logic signed [27:0] r_final_subtraction;
  always_ff @(posedge aclk) begin: ibis_edge_finder_final_subtraction
    if(!aresetn) begin
      r_final_subtraction <= 28'sh0;
    end else if(enable & r_state[8]) begin
      r_final_subtraction <= r_multiplications[0] - r_multiplications[1];
    end
  end: ibis_edge_finder_final_subtraction
  assign stencil_test = ~r_final_subtraction[27];
  assign ready = r_state[9];
endmodule: ibis_edge_finder
