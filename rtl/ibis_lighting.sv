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
// 10-stage 8-bit value lighting
module ibis_lighting
#(parameter WIDTH = 11)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [2:0] write_registers,
  input wire logic unsigned [WIDTH - 1:0] x,
  input wire logic unsigned [WIDTH - 1:0] y,
  input wire logic unsigned [3:0] attenuation,
  input wire logic unsigned [WIDTH - 1:0] origin_x,
  input wire logic unsigned [WIDTH - 1:0] origin_y,
  input wire logic unsigned [7:0] value_in0,
  input wire logic unsigned [7:0] value_in1,
  output logic unsigned [7:0] value_out,
  output logic ready);
  // ==========================================================================
  // 10-stage r_state machine
  // ==========================================================================
  logic unsigned [9:0] r_state;
  always_ff @(posedge aclk) begin: ibis_lighting_statem
    if(!aresetn) begin
      r_state <= 10'b00000_00001;
    end else if(enable) begin
      r_state <= {r_state[8:0], r_state[9]};
    end
  end: ibis_lighting_statem
  // =================================================e=========================
  // Store registers
  // ==========================================================================
  logic signed [WIDTH:0] r_coord[2];
  logic signed [WIDTH:0] r_origin[2];
  logic unsigned [3:0] r_attenuation;
  logic unsigned [7:0] r_values[2];
  // store user config
  always_ff @(posedge aclk) begin: ibis_lighting_store_mode
    if(!aresetn) begin
      r_attenuation <= 4'h0;
    end else if(enable & write_registers[0] & r_state[0]) begin
      r_attenuation <= attenuation;
    end
  end: ibis_lighting_store_mode
  always_ff @(posedge aclk) begin: ibis_lighting_storeOX
    if(!aresetn) begin
      r_origin[0] <= '0;
    end else if(enable & write_registers[1] & r_state[0]) begin
      r_origin[0] <= signed'({1'b0, origin_x});
    end
  end: ibis_lighting_storeOX
  always_ff @(posedge aclk) begin: ibis_lighting_storeOY
    if(!aresetn) begin
      r_origin[1] <= '0;
    end else if(enable & write_registers[2] & r_state[0]) begin
      r_origin[1] <= signed'({1'b0, origin_y});
    end
  end: ibis_lighting_storeOY
  // store X/Y vals
  always_ff @(posedge aclk) begin: ibis_lighting_storeX
    if(!aresetn) begin
      r_coord[0] <= '0;
    end else if(enable & r_state[0]) begin
      r_coord[0] <= signed'({1'b0, x});
    end
  end: ibis_lighting_storeX
  always_ff @(posedge aclk) begin: ibis_lighting_storeY
    if(!aresetn) begin
      r_coord[1] <= '0;
    end else if(enable & r_state[0]) begin
      r_coord[1] <= signed'({1'b0, y});
    end
  end: ibis_lighting_storeY
  // store components
  always_ff @(posedge aclk) begin: ibis_lighting_storeC0
    if(!aresetn) begin
      r_values[0] <= 8'h00;
    end else if(enable & r_state[0]) begin
      r_values[0] <= value_in0;
    end
  end: ibis_lighting_storeC0
  always_ff @(posedge aclk) begin: ibis_lighting_storeC1
    if(!aresetn) begin
      r_values[1] <= 8'h00;
    end else if(enable & r_state[0]) begin
      r_values[1] <= value_in1;
    end
  end: ibis_lighting_storeC1
  // ==========================================================================
  // Distances
  // ==========================================================================
  logic signed [WIDTH:0] r_sub[2];
  // first get subtracts
  always_ff @(posedge aclk) begin: ibis_lighting_subX
    if(!aresetn) begin
      r_sub[0] <= '0;
    end else if(enable & r_state[1]) begin
      r_sub[0] <= r_coord[0] - r_origin[0];
    end
  end: ibis_lighting_subX
  always_ff @(posedge aclk) begin: ibis_lighting_subY
    if(!aresetn) begin
      r_sub[1] <= '0;
    end else if(enable & r_state[3]) begin
      r_sub[1] <= r_coord[1] - r_origin[1];
    end
  end: ibis_lighting_subY
  // then squares
  logic signed [WIDTH*2:0] r_square[2];
  always_ff @(posedge aclk) begin: ibis_lighting_squareDX
    if(!aresetn) begin
      r_square[0] <= '0;
    end else if(enable & r_state[2]) begin
      r_square[0] <= r_sub[0] * r_sub[0];
    end
  end: ibis_lighting_squareDX
  always_ff @(posedge aclk) begin: ibis_lighting_squareDY
    if(!aresetn) begin
      r_square[1] <= '0;
    end else if(enable & r_state[4]) begin
      r_square[1] <= r_sub[1] * r_sub[1];
    end
  end: ibis_lighting_squareDY
  // then add
  logic signed [WIDTH * 2:0] r_distance;
  always_ff @(posedge aclk) begin: ibis_lighting_addD
    if(!aresetn) begin
      r_distance <= '0;
    end else if(enable & r_state[5]) begin
      r_distance <= r_square[0] + r_square[1];
    end
  end: ibis_lighting_addD
  // ==========================================================================
  // Attenuated Mix
  // ==========================================================================
  logic unsigned [7:0] r_attenuation_coeff;
  logic r_stencil;
  always_ff @(posedge aclk) begin: ibis_lighting_attenuate
    if(!aresetn) begin
      r_attenuation_coeff <= 8'h00;
    end else if(enable & r_state[6]) begin
      unique case(r_attenuation)
        4'h0: r_attenuation_coeff <= 8'h00;
        4'h1: r_attenuation_coeff <= r_distance[(WIDTH * 2)-2:(WIDTH * 2)-9];
        4'h2: r_attenuation_coeff <= r_distance[(WIDTH * 2)-3:(WIDTH * 2)-10];
        4'h3: r_attenuation_coeff <= r_distance[(WIDTH * 2)-4:(WIDTH * 2)-11];
        4'h4: r_attenuation_coeff <= r_distance[(WIDTH * 2)-5:(WIDTH * 2)-12];
        4'h5: r_attenuation_coeff <= r_distance[(WIDTH * 2)-6:(WIDTH * 2)-13];
        4'h6: r_attenuation_coeff <= r_distance[(WIDTH * 2)-7:(WIDTH * 2)-14];
        4'h7: r_attenuation_coeff <= r_distance[(WIDTH * 2)-8:(WIDTH * 2)-15];
        4'h8: r_attenuation_coeff <= r_distance[(WIDTH * 2)-9:(WIDTH * 2)-16];
        4'h9: r_attenuation_coeff <= r_distance[(WIDTH * 2)-10:(WIDTH * 2)-17];
        4'hA: r_attenuation_coeff <= r_distance[(WIDTH * 2)-11:(WIDTH * 2)-18];
        4'hB: r_attenuation_coeff <= r_distance[(WIDTH * 2)-12:(WIDTH * 2)-19];
        4'hC: r_attenuation_coeff <= r_distance[(WIDTH * 2)-13:(WIDTH * 2)-20];
        4'hD: r_attenuation_coeff <= r_distance[(WIDTH * 2)-14:(WIDTH * 2)-21];
        4'hE: r_attenuation_coeff <= r_distance[(WIDTH * 2)-15:(WIDTH * 2)-22];
        4'hF: r_attenuation_coeff <= 8'hFF;
        default: ;
      endcase
    end
  end: ibis_lighting_attenuate
  
  // wire unsigned [7:0] attenuation_sqrt;
  // ibis_square_root sqrt(
  //   .in_bits(r_attenuation_coeff),
  //   .square_root(attenuation_sqrt)
  // );

  always_ff @(posedge aclk) begin: ibis_lighting_stencil
    if(!aresetn) begin
      r_stencil <= 1'b0;
    end else if(enable & r_state[6]) begin
      unique case(r_attenuation)
        4'h0: r_stencil <= 1'b1;
        4'h1: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-1];
        4'h2: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-2];
        4'h3: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-3];
        4'h4: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-4];
        4'h5: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-5];
        4'h6: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-6];
        4'h7: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-7];
        4'h8: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-8];
        4'h9: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-9];
        4'hA: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-10];
        4'hB: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-11];
        4'hC: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-12];
        4'hD: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-13];
        4'hE: r_stencil <= ~|r_distance[(WIDTH * 2)-1:(WIDTH * 2)-14];
        4'hF: r_stencil <= 1'b0;
        default: ;
      endcase
    end
  end: ibis_lighting_stencil

  logic unsigned [15:0] r_mixes[2];
  always_ff @(posedge aclk) begin: ibis_lighting_final0
    if(!aresetn) begin
      r_mixes[0] <= 16'h0000;
    end else if(enable & r_state[7]) begin
      r_mixes[0] <= {8'h00, r_values[0]} * {8'h00, (8'hFF - r_attenuation_coeff)};
    end
  end: ibis_lighting_final0
  always_ff @(posedge aclk) begin: ibis_lighting_final1
    if(!aresetn) begin
      r_mixes[1] <= 16'h0000;
    end else if(enable & r_state[7]) begin
      r_mixes[1] <= {8'h00, r_values[1]} * {8'h00, r_attenuation_coeff};
    end
  end: ibis_lighting_final1
  logic unsigned [7:0] r_value_out;
  always_ff @(posedge aclk) begin: ibis_lighting_final_sum
    if(!aresetn) begin
      r_value_out <= 8'h00;
    end else if(enable & r_state[9]) begin
      r_value_out <= r_stencil ? (r_mixes[0][15:8] + r_mixes[1][15:8]) : r_values[1];
    end
  end: ibis_lighting_final_sum
  
  assign value_out = r_value_out;
  assign ready = r_state[9];
endmodule: ibis_lighting
