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
// 10-stage texture mapper for texture addressing
module ibis_texture_mapper
#(parameter TILE_SIZE_POW2 = 7,
  parameter WIDTH = 11)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [5:0] write_matrix,
  input wire logic unsigned [WIDTH - 1:0] x,
  input wire logic unsigned [WIDTH - 1:0] y,
  input wire logic signed [15:0] texture_matrixA,
  input wire logic signed [15:0] texture_matrixB,
  input wire logic signed [15:0] texture_matrixC,
  input wire logic signed [15:0] texture_matrixD,
  input wire logic signed [15:0] texture_translateX,
  input wire logic signed [15:0] texture_translateY,
  output logic unsigned [(TILE_SIZE_POW2 * 2) - 1:0] map_address,
  output logic stencil_test,
  output logic ready);
  // ==========================================================================
  // 10-stage r_state machine
  // ==========================================================================
  logic unsigned [9:0] r_state;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_statem
    if(!aresetn) begin
      r_state <= 10'b00000_00001;
    end else if(enable) begin
      r_state <= {r_state[8:0], r_state[9]};
    end
  end: ibis_texture_mapper_statem
  // ==========================================================================
  // First cycle will lock on the texture matrix.
  // ==========================================================================
  logic signed [15:0] r_texture_matrix[8];
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_A
    if(!aresetn) begin
      r_texture_matrix[0] <= 16'sh0040;
    end else if(enable & write_matrix[0] & r_state[0]) begin
      r_texture_matrix[0] <= texture_matrixA;
    end
  end: ibis_texture_mapper_hold_A
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_B
    if(!aresetn) begin
      r_texture_matrix[1] <= 16'sh0000;
    end else if(enable & write_matrix[1] & r_state[0]) begin
      r_texture_matrix[1] <= texture_matrixB;
    end
  end: ibis_texture_mapper_hold_B
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_C
    if(!aresetn) begin
      r_texture_matrix[2] <= 16'sh0000;
    end else if(enable & write_matrix[2] & r_state[0]) begin
      r_texture_matrix[2] <= texture_matrixC;
    end
  end: ibis_texture_mapper_hold_C
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_D
    if(!aresetn) begin
      r_texture_matrix[3] <= 16'sh0040;
    end else if(enable & write_matrix[3] & r_state[0]) begin
      r_texture_matrix[3] <= texture_matrixD;
    end
  end: ibis_texture_mapper_hold_D
  // Translations
   always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Tx
    if(!aresetn) begin
      r_texture_matrix[4] <= 16'sh0000;
    end else if(enable & write_matrix[4] & r_state[0]) begin
      r_texture_matrix[4] <= texture_translateX;
    end
  end: ibis_texture_mapper_hold_Tx
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Ty
    if(!aresetn) begin
      r_texture_matrix[5] <= 16'sh0000;
    end else if(enable & write_matrix[5] & r_state[0]) begin
      r_texture_matrix[5] <= texture_translateY;
    end
  end: ibis_texture_mapper_hold_Ty
  // Hold on to X and Y for now, these should not be signed.
  // These also should be offset to the center.
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_X
    if(enable & r_state[1]) begin
      r_texture_matrix[6] <= signed'({1'b0, x[8:0], 6'h00}) - r_texture_matrix[4];
    end
  end: ibis_texture_mapper_hold_X
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Y
    if(enable & r_state[3]) begin
      r_texture_matrix[7] <= signed'({1'b0, y[8:0], 6'h00}) - r_texture_matrix[5];
    end
  end: ibis_texture_mapper_hold_Y
  // ==========================================================================
  // Next 4 will calculate this matrix multiplication with the DSP slices:
  //
  // [ A B ] * [ x ] = [ x' ]
  // [ C D ] * [ y ] = [ y' ]
  //
  // Being:
  // Ax + By = x'
  // Cx + Dy = y'
  // ==========================================================================
  // Intermediary multiplications
  // ==========================================================================
  logic signed [31:0] r_intermediaries[4];
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Ax
    if(!aresetn) begin
      r_intermediaries[0] <= 32'sh0;
    end else if(enable & r_state[2]) begin
      r_intermediaries[0] <= r_texture_matrix[0] * r_texture_matrix[6];
    end
  end: ibis_texture_mapper_calc_Ax
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_By
    if(!aresetn) begin
      r_intermediaries[1] <= 32'sh0;
    end else if(enable & r_state[4]) begin
      r_intermediaries[1] <= r_texture_matrix[1] * r_texture_matrix[7];
    end
  end: ibis_texture_mapper_calc_By
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Cx
    if(!aresetn) begin
      r_intermediaries[2] <= 32'sh0;
    end else if(enable & r_state[2]) begin
      r_intermediaries[2] <= r_texture_matrix[2] * r_texture_matrix[6];
    end
  end: ibis_texture_mapper_calc_Cx
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Dy
    if(!aresetn) begin
      r_intermediaries[3] <= 32'sh0;
    end else if(enable & r_state[4]) begin
      r_intermediaries[3] <= r_texture_matrix[3] * r_texture_matrix[7];
    end
  end: ibis_texture_mapper_calc_Dy
  // ==========================================================================
  // Final sums
  // ==========================================================================
  logic signed [31:0] r_final_sums[2];
  logic unsigned [1:0] r_stencil;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Xp
    if(!aresetn) begin
      r_final_sums[0] <= 32'sh0;
    end else if(enable & r_state[5]) begin
      r_final_sums[0] <= (r_intermediaries[0] + r_intermediaries[1]) + (32'sh800 <<< TILE_SIZE_POW2);
    end
  end: ibis_texture_mapper_calc_Xp
  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencilX
    if(!aresetn) begin
      r_stencil[0] <= 1'b0;
    end else if(enable & r_state[6]) begin
      r_stencil[0] <= ~|(r_final_sums[0][31:TILE_SIZE_POW2 + 12]);
    end
  end: ibis_texture_mapper_stencilX
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Yp
    if(!aresetn) begin
      r_final_sums[1] <= 32'sh0;
    end else if(enable & r_state[7]) begin
      r_final_sums[1] <= (r_intermediaries[2] + r_intermediaries[3]) + (32'sh800 <<< TILE_SIZE_POW2);
    end
  end: ibis_texture_mapper_calc_Yp
  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencilY
    if(!aresetn) begin
      r_stencil[1] <= 1'b0;
    end else if(enable & r_state[8]) begin
      r_stencil[1] <= ~|(r_final_sums[1][31:TILE_SIZE_POW2 + 12]);
    end
  end: ibis_texture_mapper_stencilY
  // ==========================================================================
  // Texture memory access
  // ==========================================================================
  logic unsigned [(TILE_SIZE_POW2 * 2) - 1:0] r_map_address;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_address
    if(enable & r_state[9]) begin
      r_map_address <= {
        r_final_sums[1][TILE_SIZE_POW2 + 11:12],
        r_final_sums[0][TILE_SIZE_POW2 + 11:12]
      };
    end
  end: ibis_texture_mapper_address
  assign map_address = r_map_address;
  assign ready = r_state[9];
  assign stencil_test = &r_stencil;
endmodule: ibis_texture_mapper
