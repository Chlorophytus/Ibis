`timescale 1ns / 1ps
`default_nettype none
// combines a pump and an encoder
module ibis_tmds
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic data_enable,
  input wire logic unsigned [1:0] control,
  input wire logic unsigned [7:0] data,
  output wire logic out_serial);

  wire logic unsigned [9:0] parallel;
  
  ibis_tmds_pump pump(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .in_parallel(parallel),
    .out_serial(out_serial)
  );

  ibis_tmds_encoder encoder(
    .aclk(aclk),
    .aresetn(aresetn),
    .enable(enable),
    .data(data),
    .data_enable(data_enable),
    .control(control),
    .out_parallel(parallel),

    .debug_balance(),
    .debug_bias()
  );
endmodule: ibis_tmds
