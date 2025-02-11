`timescale 1ns / 1ps
`default_nettype none
// 10-stage forward mapper
module ibis_forward_mapper
#(parameter TILE_SIZE_POW2 = 5,
  parameter WIDTH = 10)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [3:0] write_matrix,
  input wire logic write_texels,
  input wire logic unsigned [WIDTH - 1:0] x,
  input wire logic unsigned [WIDTH - 1:0] y,
  input wire logic signed [11:0] texture_matrixA,
  input wire logic signed [11:0] texture_matrixB,
  input wire logic signed [11:0] texture_matrixC,
  input wire logic signed [11:0] texture_matrixD,
  input wire logic unsigned [(TILE_SIZE_POW2 * 2) - 1:0] in_address,
  input wire logic unsigned [8:0] in_data,
  output logic unsigned [8:0] out_data,
  output logic cycle_complete);
  // ==========================================================================
  // 10-stage r_state machine
  // ==========================================================================
  logic unsigned [9:0] r_state;
  always_ff @(posedge aclk) begin: ibis_forward_mapper_statem
    if(!aresetn) begin
      r_state <= 10'b00000_00001;
    end else if(enable) begin
      r_state <= {r_state[8:0], r_state[9]};
    end
  end: ibis_forward_mapper_statem
  assign cycle_complete = r_state[9];
  // ==========================================================================
  // First cycle will lock on the texture matrix.
  // ==========================================================================
  logic signed [11:0] r_texture_matrix[6];
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_A
    if(!aresetn) begin
      r_texture_matrix[0] <= 12'sh010;
    end else if(enable & write_matrix[0] & r_state[0]) begin
      r_texture_matrix[0] <= texture_matrixA;
    end
  end: ibis_forward_mapper_hold_A
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_B
    if(!aresetn) begin
      r_texture_matrix[1] <= 12'sh000;
    end else if(enable & write_matrix[1] & r_state[0]) begin
      r_texture_matrix[1] <= texture_matrixB;
    end
  end: ibis_forward_mapper_hold_B
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_C
    if(!aresetn) begin
      r_texture_matrix[2] <= 12'sh000;
    end else if(enable & write_matrix[2] & r_state[0]) begin
      r_texture_matrix[2] <= texture_matrixC;
    end
  end: ibis_forward_mapper_hold_C
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_D
    if(!aresetn) begin
      r_texture_matrix[3] <= 12'sh010;
    end else if(enable & write_matrix[3] & r_state[0]) begin
      r_texture_matrix[3] <= texture_matrixD;
    end
  end: ibis_forward_mapper_hold_D
  // Hold on to X and Y for now, these ought to not be signed.
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_X
    if(enable & r_state[0]) begin
      r_texture_matrix[4] <= {1'b0, x[6:0], 4'h0};
    end
  end: ibis_forward_mapper_hold_X
  always_ff @(posedge aclk) begin: ibis_forward_mapper_hold_Y
    if(enable & r_state[0]) begin
      r_texture_matrix[5] <= {1'b0, y[6:0], 4'h0};
    end
  end: ibis_forward_mapper_hold_Y
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
  logic signed [23:0] r_intermediaries[4];
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_Ax
    if(!aresetn) begin
      r_intermediaries[0] <= 24'sh000_000;
    end else if(enable & r_state[2]) begin
      r_intermediaries[0] <= r_texture_matrix[0] * r_texture_matrix[4];
    end
  end: ibis_forward_mapper_calc_Ax
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_By
    if(!aresetn) begin
      r_intermediaries[1] <= 24'sh000_000;
    end else if(enable & r_state[4]) begin
      r_intermediaries[1] <= r_texture_matrix[1] * r_texture_matrix[5];
    end
  end: ibis_forward_mapper_calc_By
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_Cx
    if(!aresetn) begin
      r_intermediaries[2] <= 24'sh000_000;
    end else if(enable & r_state[2]) begin
      r_intermediaries[2] <= r_texture_matrix[2] * r_texture_matrix[4];
    end
  end: ibis_forward_mapper_calc_Cx
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_Dy
    if(!aresetn) begin
      r_intermediaries[3] <= 24'sh000_000;
    end else if(enable & r_state[4]) begin
      r_intermediaries[3] <= r_texture_matrix[3] * r_texture_matrix[5];
    end
  end: ibis_forward_mapper_calc_Dy
  // ==========================================================================
  // Final sums
  // ==========================================================================
  logic signed [23:0] r_final_sums[2];
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_Xp
    if(!aresetn) begin
      r_final_sums[0] <= 24'sh000_000;
    end else if(enable & r_state[5]) begin
      r_final_sums[0] <= r_intermediaries[0] + r_intermediaries[1];
    end
  end: ibis_forward_mapper_calc_Xp
  always_ff @(posedge aclk) begin: ibis_forward_mapper_calc_Yp
    if(!aresetn) begin
      r_final_sums[1] <= 24'sh000_000;
    end else if(enable & r_state[7]) begin
      r_final_sums[1] <= r_intermediaries[2] + r_intermediaries[3];
    end
  end: ibis_forward_mapper_calc_Yp
  // ==========================================================================
  // Texture memory access
  // ==========================================================================
  logic unsigned [8:0] texture_memory[1 << (TILE_SIZE_POW2 * 2)];
  logic unsigned [(TILE_SIZE_POW2 * 2) - 1:0] r_address_write;
  logic unsigned [(TILE_SIZE_POW2 * 2) - 1:0] r_address_read;
  logic unsigned [8:0] r_texture_read;
  always_ff @(posedge aclk) begin: ibis_forward_mapper_tmem_address
    if(enable) begin
      if(write_texels & r_state[0]) begin
        r_address_write <= in_address;
      end else if(r_state[8]) begin
        r_address_read <= {
          r_final_sums[1][TILE_SIZE_POW2 + 3:4],
          r_final_sums[0][TILE_SIZE_POW2 + 3:4]
        };
      end
    end
  end: ibis_forward_mapper_tmem_address
  always_ff @(posedge aclk) begin: ibis_forward_mapper_tmem_data
    if(enable & r_state[9]) begin
      if(write_texels) begin
        texture_memory[r_address_write] <= in_data;
      end else begin
        r_texture_read <= texture_memory[r_address_read];
      end
    end
  end: ibis_forward_mapper_tmem_data
  assign out_data = r_texture_read;
endmodule: ibis_forward_mapper
