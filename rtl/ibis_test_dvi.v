`timescale 1ns / 1ps
`default_nettype none
module ibis_test_dvi
 (input wire aclk,
  input wire aresetn,
  input wire enable,
  output wire tmds_red,
  output wire tmds_grn,
  output wire tmds_blu,
  output wire tmds_clk);

  wire data_enable;
  wire vblankn;
  wire hblankn;
  wire hsync;
  wire vsync;
  wire [15:0] x;
  wire [15:0] y;

  ibis_vga_timing timing(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .vsync(vsync),
    .vblankn(vblankn),
    .hsync(hsync),
    .hblankn(hblankn),
    .ord_x(x),
    .ord_y(y)
  );
  assign data_enable = !(vblankn | hblankn);

  // TMDS Blue channel
  ibis_tmds ibis_tmds_blu(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control({vsync, hsync}),
    .data(x[7:0] ^ y[7:0]),
    .out_serial(tmds_blu)
  );
  // TMDS Green channel
  ibis_tmds ibis_tmds_grn(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(y[7:0]),
    .out_serial(tmds_grn)
  );
  // TMDS Red channel
  ibis_tmds ibis_tmds_red(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(x[7:0]),
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
endmodule: ibis_test_dvi
 
