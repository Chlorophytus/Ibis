`timescale 1ns / 1ps
`default_nettype none
module ibis_vga_blit
#(parameter WIDTH = 10)
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [WIDTH-1:0] ord_x,
  input wire logic unsigned [WIDTH-1:0] ord_y,
  output logic unsigned [7:0] red,
  output logic unsigned [7:0] grn,
  output logic unsigned [7:0] blu,
  output logic unsigned [7:0] mix);
  // ==========================================================================
  // TODO: Place the innerworkings/details in a wiki or README document
  //
  // 0x0000 = X size enum, Y size enum, reserved other bits
  // 0x0001 = X scroll delta
  // 0x0002 = Y scroll delta
  // 0x0003, ..., 0x000F = **reserved**
  // 0x0010 = Global RED
  // 0x0011 = Global GRN
  // 0x0012 = Global BLU
  // 0x0013 = Global MIX
  // 0x0014, ..., 0x00FF = **reserved**
  // 0x0100, ..., 0x04FF = palette memory (RGBA8888)
  // 0x0500, ..., 0x0FFF = object tile memory (maps to texture memory)
  // 0x1000, ..., 0x1FFF = texture memory (maps to palette memory)
  // ==========================================================================
  logic unsigned [7:0] r_memory[8192];

  logic unsigned [4:0] r_state;
  always_ff @(posedge aclk) begin: ibis_vga_blit_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_vga_blit_statem

  logic unsigned [WIDTH-1:0] r_x;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_x <= {WIDTH{1'b0}};
    end else if(enable & r_state[0]) begin
      r_x <= ord_x;
    end
  end

  logic unsigned [WIDTH-1:0] r_y;
  always_ff @(posedge aclk) begin
    if(!aresetn) begin
      r_y <= {WIDTH{1'b0}};
    end else if(enable & r_state[0]) begin
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
endmodule: ibis_vga_blit
