`timescale 1ns / 1ps
`default_nettype none
module ibis
 (input wire aclk,
  input wire aresetn,
  input wire enable,
  // ==========================================================================
  // AXI4 write address bus
  // TODO: awaddr
  input wire awvalid,
  output wire awready,
  // AXI4 write data bus
  input wire [31:0] wdata,
  input wire wvalid,
  output wire wready,
  // AXI4 write response bus
  output wire [1:0] bresp,
  output wire bvalid,
  input wire bready,
  // ==========================================================================
  // AXI4 read address bus
  // TODO: araddr
  input wire arvalid,
  output wire arready,
  // AXI4 read data bus
  output wire [31:0] rdata,
  output wire [1:0] rresp,
  output wire rvalid,
  input wire rready);

  ibis_axi4 axi4(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready)
  );
endmodule: ibis
