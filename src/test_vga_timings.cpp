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
#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

bool test::test_vga_timings(const U64 &step, Vibis_vga_timing &dut,
                            const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    break;
  }
  default: {
    break;
  }
  }

  dut.aclk = (step % 2) == 0;
  dut.eval();

  if (dut.ord_x == 0) {
    con::listener::debug(description, ": (", step,
                         ") x ordinate is zero, y is ", dut.ord_y);
  }
  if (dut.ord_y == 0) {
    con::listener::debug(description, ": (", step, ") y ordinate is zero");
  }

  con::listener::debug(description, ": (", step, ") Vsync: ", dut.vsync,
                       " Vblank: ", dut.vblank, " Hsync: ", dut.hsync,
                       " Hblank: ", dut.hblank, " X: ", dut.ord_x, " Y ",
                       dut.ord_y);
  return step < RESET_OFF_WHEN + (800 * 525 * 10);
}
