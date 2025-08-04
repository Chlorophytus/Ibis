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
using namespace ibis;

static U64 current_attenuation = 0;
static U64 offset_step = 0;

bool test::test_lighting(const U64 &step, Vibis_lighting &dut,
                         const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  constexpr auto X_WIDTH = 320;
  constexpr auto Y_WIDTH = 240;
  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    dut.attenuation = 0;
    dut.origin_x = X_WIDTH / 2;
    dut.origin_y = Y_WIDTH / 2;
    dut.value_in1 = 0x00;
    dut.value_in0 = 0xFF;
    dut.write_registers = (1 << 0) | (1 << 1) | (1 << 2);
    break;
  }
  case RESET_OFF_WHEN + 20: {
    dut.write_registers = 0;
    break;
  }
  default: {
    break;
  }
  }
  dut.aclk = (step % 2) == 0;
  if (offset_step > 0) {
    const auto x = ((step - offset_step) / 40) % X_WIDTH;
    const auto y = ((step - offset_step) / (40 * X_WIDTH)) % Y_WIDTH;
    dut.x = x;
    dut.y = y;

    switch ((step - offset_step) % 40) {
    case 0: {
      if (x == 0) {
        dut.attenuation = current_attenuation;
        dut.origin_x = X_WIDTH / 2;
        dut.origin_y = Y_WIDTH / 2;
        dut.write_registers = (1 << 0) | (1 << 1) | (1 << 2);
        if (y == 0) {
          current_attenuation++;
          BeginDrawing();
          if (WindowShouldClose()) {
            con::listener::informational(description, ": Test forced finish");
            return false;
          }
          ibis::framebuffer::draw();
          EndDrawing();
        }
      }
      break;
    }
    case 18: {
      dut.write_registers = 0;
      break;
    }

    case 38: {
      auto &&buffer = ibis::framebuffer::access();
      U32 color = 0xFF;
      color <<= 8;
      color |= dut.value_out;
      color <<= 8;
      color |= dut.value_out;
      color <<= 8;
      color |= dut.value_out;
      buffer[(320 * y) + x] = color;
      if ((x == (X_WIDTH - 1)) && (y == (Y_WIDTH - 1))) {
        con::listener::debug(description, ": (", step, ") | NEXT ATTENUATION (",
                             current_attenuation, ")");
      }
      break;
    }
    default: {
      break;
    }
    }
  } else if (dut.ready) {
    offset_step = step;
    con::listener::debug(description, ": (", step,
                         ") - ready finally asserted");
  }
  dut.eval();
  return current_attenuation < 17;
}