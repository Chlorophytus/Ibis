`timescale 1ns / 1ps
`default_nettype none
module ibis_test_dvi
 (input wire aclk, // 125.875 MHz
  input wire tclk, //  25.175 MHz
  input wire aresetn,
  input wire enable,
  output wire tmds_red,
  output wire tmds_grn,
  output wire tmds_blu,
  output wire tmds_clk);

  wire data_enable;
  wire vblank;
  wire hblank;
  wire hsync;
  wire vsync;
  wire [9:0] x;
  wire [9:0] y;
  wire [7:0] red;
  wire [7:0] grn;
  wire [7:0] blu;

  ibis_vga_timing timing(
    .aclk(tclk),
    .aresetn(aresetn),
    .enable(enable),
    .vsync(vsync),
    .vblank(vblank),
    .hsync(hsync),
    .hblank(hblank),
    .data_enable(data_enable),
    .ord_x(x),
    .ord_y(y)
  );
  ibis_vga_pattern pattern(
   .aclk(tclk),
   .aresetn(aresetn),
   .enable(enable),
   .ord_x(x),
   .ord_y(y),
   .red(red),
   .grn(grn),
   .blu(blu)
  );

  // TMDS Blue channel
  ibis_tmds ibis_tmds_blu(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control({vsync, hsync}),
    .data(blu),
    .out_serial(tmds_blu)
  );
  // TMDS Green channel
  ibis_tmds ibis_tmds_grn(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(grn),
    .out_serial(tmds_grn)
  );
  // TMDS Red channel
  ibis_tmds ibis_tmds_red(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data_enable(data_enable),
    .control(2'b00),
    .data(red),
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
endmodule
 
