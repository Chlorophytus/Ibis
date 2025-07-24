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
#(parameter TILE_SIZE_POW2_MAX = 9,
  parameter WIDTH = 11)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  // > Register writes are a bitmask.
  // Bit 0: TextureMatrixA
  // Bit 1: TextureMatrixB
  // Bit 2: TextureMatrixC
  // Bit 3: TextureMatrixD
  // Bit 4: TextureTranslateX
  // Bit 5: TextureTranslateY
  // Bit 6: TexturePower2
  input wire logic unsigned [6:0] write_registers,
  input wire logic unsigned [WIDTH - 1:0] x,
  input wire logic unsigned [WIDTH - 1:0] y,
  input wire logic unsigned [2:0] texture_power2,
  input wire logic signed [17:0] texture_matrixA,
  input wire logic signed [17:0] texture_matrixB,
  input wire logic signed [17:0] texture_matrixC,
  input wire logic signed [17:0] texture_matrixD,
  input wire logic signed [17:0] texture_translateX,
  input wire logic signed [17:0] texture_translateY,
  output logic unsigned [(TILE_SIZE_POW2_MAX * 2) - 1:0] map_address,
  output logic stencil_test, // for sprite operations
  output logic stencil_step, // for tile layer operations
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
  // Size power of 2
  // ==========================================================================
  logic unsigned [3:0] r_texture_power2;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_power2
    if(!aresetn) begin
      // this is a randomly picked default of 2^5 tile = 32x32
      r_texture_power2 <= 4'h5;
    end else if(enable & write_registers[6] & r_state[0]) begin
      r_texture_power2 <= {1'b0, texture_power2} + 4'h1;
    end
  end: ibis_texture_mapper_hold_power2
  // ==========================================================================
  // First cycle will lock on the texture matrix.
  // ==========================================================================
  logic signed [17:0] r_texture_matrix[8];
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_A
    if(!aresetn) begin
      r_texture_matrix[0] <= 18'sh00100;
    end else if(enable & write_registers[0] & r_state[0]) begin
      r_texture_matrix[0] <= texture_matrixA;
    end
  end: ibis_texture_mapper_hold_A
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_B
    if(!aresetn) begin
      r_texture_matrix[1] <= 18'sh00000;
    end else if(enable & write_registers[1] & r_state[0]) begin
      r_texture_matrix[1] <= texture_matrixB;
    end
  end: ibis_texture_mapper_hold_B
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_C
    if(!aresetn) begin
      r_texture_matrix[2] <= 18'sh00000;
    end else if(enable & write_registers[2] & r_state[0]) begin
      r_texture_matrix[2] <= texture_matrixC;
    end
  end: ibis_texture_mapper_hold_C
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_D
    if(!aresetn) begin
      r_texture_matrix[3] <= 18'sh00100;
    end else if(enable & write_registers[3] & r_state[0]) begin
      r_texture_matrix[3] <= texture_matrixD;
    end
  end: ibis_texture_mapper_hold_D
  // Translations
   always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Tx
    if(!aresetn) begin
      r_texture_matrix[4] <= 18'sh00000;
    end else if(enable & write_registers[4] & r_state[0]) begin
      r_texture_matrix[4] <= texture_translateX;
    end
  end: ibis_texture_mapper_hold_Tx
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Ty
    if(!aresetn) begin
      r_texture_matrix[5] <= 18'sh00000;
    end else if(enable & write_registers[5] & r_state[0]) begin
      r_texture_matrix[5] <= texture_translateY;
    end
  end: ibis_texture_mapper_hold_Ty
  // Hold on to X and Y for now, these should not be signed.
  // These also should be offset to the center.
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_X
    if(enable & r_state[1]) begin
      r_texture_matrix[6] <= signed'({1'b0, x[8:0], 8'h00}) - r_texture_matrix[4];
    end
  end: ibis_texture_mapper_hold_X
  always_ff @(posedge aclk) begin: ibis_texture_mapper_hold_Y
    if(enable & r_state[3]) begin
      r_texture_matrix[7] <= signed'({1'b0, y[8:0], 8'h00}) - r_texture_matrix[5];
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
  logic signed [35:0] r_intermediaries[4];
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Ax
    if(!aresetn) begin
      r_intermediaries[0] <= 36'sh0;
    end else if(enable & r_state[2]) begin
      r_intermediaries[0] <= r_texture_matrix[0] * r_texture_matrix[6];
    end
  end: ibis_texture_mapper_calc_Ax
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_By
    if(!aresetn) begin
      r_intermediaries[1] <= 36'sh0;
    end else if(enable & r_state[4]) begin
      r_intermediaries[1] <= r_texture_matrix[1] * r_texture_matrix[7];
    end
  end: ibis_texture_mapper_calc_By
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Cx
    if(!aresetn) begin
      r_intermediaries[2] <= 36'sh0;
    end else if(enable & r_state[2]) begin
      r_intermediaries[2] <= r_texture_matrix[2] * r_texture_matrix[6];
    end
  end: ibis_texture_mapper_calc_Cx
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Dy
    if(!aresetn) begin
      r_intermediaries[3] <= 36'sh0;
    end else if(enable & r_state[4]) begin
      r_intermediaries[3] <= r_texture_matrix[3] * r_texture_matrix[7];
    end
  end: ibis_texture_mapper_calc_Dy
  // ==========================================================================
  // Final sums
  // ==========================================================================
  logic signed [35:0] r_final_sums[2];
  logic unsigned [1:0] r_stencil;
  logic unsigned [1:0] r_stencil_step;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Xp
    if(!aresetn) begin
      r_final_sums[0] <= 36'sh0;
    end else if(enable & r_state[5]) begin
      r_final_sums[0] <= (r_intermediaries[0] + r_intermediaries[1]) + (36'sh10000 <<< r_texture_power2);
    end
  end: ibis_texture_mapper_calc_Xp
  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencilX
    if(!aresetn) begin
      r_stencil[0] <= 1'b0;
    end else if(enable & r_state[6]) begin
      unique case(r_texture_power2)
        4'h1: r_stencil[0] <= ~|(r_final_sums[0][35:18]);
        4'h2: r_stencil[0] <= ~|(r_final_sums[0][35:19]);
        4'h3: r_stencil[0] <= ~|(r_final_sums[0][35:20]);
        4'h4: r_stencil[0] <= ~|(r_final_sums[0][35:21]);
        4'h5: r_stencil[0] <= ~|(r_final_sums[0][35:22]);
        4'h6: r_stencil[0] <= ~|(r_final_sums[0][35:23]);
        4'h7: r_stencil[0] <= ~|(r_final_sums[0][35:24]);
        4'h8: r_stencil[0] <= ~|(r_final_sums[0][35:25]);
        default: ;
      endcase
    end
  end: ibis_texture_mapper_stencilX
  always_ff @(posedge aclk) begin: ibis_texture_mapper_calc_Yp
    if(!aresetn) begin
      r_final_sums[1] <= 36'sh0;
    end else if(enable & r_state[7]) begin
      r_final_sums[1] <= (r_intermediaries[2] + r_intermediaries[3]) + (36'sh10000 <<< r_texture_power2);
    end
  end: ibis_texture_mapper_calc_Yp
  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencilY
    if(!aresetn) begin
      r_stencil[1] <= 1'b0;
    end else if(enable & r_state[8]) begin
      unique case(r_texture_power2)
        4'h1: r_stencil[1] <= ~|(r_final_sums[1][35:18]);
        4'h2: r_stencil[1] <= ~|(r_final_sums[1][35:19]);
        4'h3: r_stencil[1] <= ~|(r_final_sums[1][35:20]);
        4'h4: r_stencil[1] <= ~|(r_final_sums[1][35:21]);
        4'h5: r_stencil[1] <= ~|(r_final_sums[1][35:22]);
        4'h6: r_stencil[1] <= ~|(r_final_sums[1][35:23]);
        4'h7: r_stencil[1] <= ~|(r_final_sums[1][35:24]);
        4'h8: r_stencil[1] <= ~|(r_final_sums[1][35:25]);
        default: ;
      endcase
    end
  end: ibis_texture_mapper_stencilY

  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencil_stepX
    if(enable & r_state[8]) begin
      unique case(r_texture_power2)
        4'h1: r_stencil_step[0] <= ~r_final_sums[0][16];
        4'h2: r_stencil_step[0] <= ~r_final_sums[0][17];
        4'h3: r_stencil_step[0] <= ~r_final_sums[0][18];
        4'h4: r_stencil_step[0] <= ~r_final_sums[0][19];
        4'h5: r_stencil_step[0] <= ~r_final_sums[0][20];
        4'h6: r_stencil_step[0] <= ~r_final_sums[0][21];
        4'h7: r_stencil_step[0] <= ~r_final_sums[0][22];
        4'h8: r_stencil_step[0] <= ~r_final_sums[0][23];
        default: ;
      endcase
    end
  end: ibis_texture_mapper_stencil_stepX

  always_ff @(posedge aclk) begin: ibis_texture_mapper_stencil_stepY
    if(enable & r_state[8]) begin
      unique case(r_texture_power2)
        4'h1: r_stencil_step[1] <= ~r_final_sums[1][16];
        4'h2: r_stencil_step[1] <= ~r_final_sums[1][17];
        4'h3: r_stencil_step[1] <= ~r_final_sums[1][18];
        4'h4: r_stencil_step[1] <= ~r_final_sums[1][19];
        4'h5: r_stencil_step[1] <= ~r_final_sums[1][20];
        4'h6: r_stencil_step[1] <= ~r_final_sums[1][21];
        4'h7: r_stencil_step[1] <= ~r_final_sums[1][22];
        4'h8: r_stencil_step[1] <= ~r_final_sums[1][23];
        default: ;
      endcase
    end
  end: ibis_texture_mapper_stencil_stepY
  // ==========================================================================
  // Texture memory access
  // ==========================================================================
  logic unsigned [(TILE_SIZE_POW2_MAX * 2) - 1:0] r_map_address;
  always_ff @(posedge aclk) begin: ibis_texture_mapper_address
    if(enable & r_state[9]) begin
      unique case(r_texture_power2)
        4'h1: r_map_address <= {14'b0, r_final_sums[1][17:16], r_final_sums[0][17:16]};
        4'h2: r_map_address <= {12'b0, r_final_sums[1][18:16], r_final_sums[0][18:16]};
        4'h3: r_map_address <= {10'b0, r_final_sums[1][19:16], r_final_sums[0][19:16]};
        4'h4: r_map_address <= {8'b0, r_final_sums[1][20:16], r_final_sums[0][20:16]};
        4'h5: r_map_address <= {6'b0, r_final_sums[1][21:16], r_final_sums[0][21:16]};
        4'h6: r_map_address <= {4'b0, r_final_sums[1][22:16], r_final_sums[0][22:16]};
        4'h7: r_map_address <= {2'b0, r_final_sums[1][23:16], r_final_sums[0][23:16]};
        4'h8: r_map_address <= {r_final_sums[1][24:16], r_final_sums[0][24:16]};
        default: ;
      endcase
    end
  end: ibis_texture_mapper_address

  assign map_address = r_map_address;
  assign ready = r_state[9];
  assign stencil_test = &r_stencil;
  assign stencil_step = &r_stencil_step;
endmodule: ibis_texture_mapper
