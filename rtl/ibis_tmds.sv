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
