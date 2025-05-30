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
// 10-to-1 serializer
module ibis_tmds_pump
 (input wire logic aclk,
  input wire logic aresetn,
  input wire logic enable,
  input wire logic unsigned [9:0] in_parallel,
  output wire logic out_serial);
  // Shift-to-5 state machine
  logic unsigned [4:0] r_state;
  logic unsigned [9:0] r_parallel;
  always_ff @(posedge aclk) begin: ibis_tmds_pump_statem
    if(!aresetn) begin
      r_state <= 5'b00001;
    end else if(enable) begin
      r_state <= {r_state[3:0], r_state[4]};
    end
  end: ibis_tmds_pump_statem

  always_ff @(posedge aclk) begin: ibis_tmds_pump_shift_register
    if(!aresetn) begin
      r_parallel <= 10'b00000_00000;
    end else if(enable) begin
      if(r_state[0]) begin
        r_parallel <= in_parallel;
      end else begin
        r_parallel <= {2'b00, r_parallel[9:2]};
      end
    end
  end: ibis_tmds_pump_shift_register

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),
    .SRTYPE("ASYNC")
  ) ibis_tmds_pump_2to1 (
    .Q(out_serial),
    .C(aclk),
    .CE(enable),
    .D1(r_parallel[0]),
    .D2(r_parallel[1]),
    .R(!aresetn),
    .S()
  );
endmodule: ibis_tmds_pump
