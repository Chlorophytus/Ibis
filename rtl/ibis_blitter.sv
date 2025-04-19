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
