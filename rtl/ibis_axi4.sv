`timescale 1ns / 1ps
`default_nettype none
module ibis_axi4
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,

	// AXI4 write address bus
	// TODO: awaddr
	input wire logic awvalid,
	output logic awready,
	// AXI4 write data bus
	input wire logic unsigned [31:0] wdata,
	input wire logic wvalid,
	output logic wready,
	// AXI4 write response bus
	output logic [1:0] bresp,
	output logic bvalid,
	input wire logic bready,

	// AXI4 read address bus
	// TODO: araddr
	input wire logic arvalid,
	output logic arready,
	// AXI4 read data bus
	output logic unsigned [31:0] rdata,
	output logic [1:0] rresp,
	output logic rvalid,
	input wire logic rready);
endmodule: ibis_axi4
