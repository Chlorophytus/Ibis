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

static F32 current_pattern = 0.0f;
static U32 num_patterns = 0;
static U64 offset_step = 0;

U32 convert_to_fixed(F32 pattern) {
  constexpr auto FIXED_COEFF = 8;

  F32 abs = std::abs(pattern);
  U32 int_part = std::trunc(abs);
  U32 frac_part = (abs - int_part) * (1 << FIXED_COEFF);

  if (std::signbit(pattern)) {
    return (~((int_part << FIXED_COEFF) |
              (frac_part & ((1 << FIXED_COEFF) - 1)))) +
           1;
  } else {
    return (int_part << FIXED_COEFF) | (frac_part & ((1 << FIXED_COEFF) - 1));
  }
}

bool test::test_texture_mapper(const U64 &step, Vibis_texture_mapper &dut,
                               const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  constexpr auto X_WIDTH = 320;
  constexpr auto Y_WIDTH = 240;
  constexpr auto SCALE = 1.0f;

  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    dut.texture_translateX = convert_to_fixed(160);
    dut.texture_translateY = convert_to_fixed(120);
    auto reset_mat = glm::mat2(SCALE, 0.0, 0.0, SCALE);
    dut.texture_matrixA = convert_to_fixed(reset_mat[0][0]);
    dut.texture_matrixB = convert_to_fixed(reset_mat[0][1]);
    dut.texture_matrixC = convert_to_fixed(reset_mat[1][0]);
    dut.texture_matrixD = convert_to_fixed(reset_mat[1][1]);
    dut.texture_power2 = 5;
    dut.write_registers = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) |
                          (1 << 5) | (1 << 6);

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
        auto trans_mat =
            glm::mat2(glm::mix(SCALE / 2.0f, SCALE / 3.0f, y / 240.0f), 0.0f,
                      0.0f, SCALE);
        trans_mat *=
            glm::mat2(std::cos(current_pattern), -std::sin(current_pattern),
                      std::sin(current_pattern), std::cos(current_pattern));
        dut.texture_matrixA = convert_to_fixed(trans_mat[0][0]);
        dut.texture_matrixB = convert_to_fixed(trans_mat[0][1]);
        dut.texture_matrixC = convert_to_fixed(trans_mat[1][0]);
        dut.texture_matrixD = convert_to_fixed(trans_mat[1][1]);
        dut.write_registers = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);
        if (y == 0) {
          current_pattern += std::numbers::pi / 32.0;
          BeginDrawing();
          if (WindowShouldClose()) {
            con::listener::informational(description, ": Test forced finish");
            return false;
          }
          ibis::framebuffer::draw();
          EndDrawing();
          num_patterns++;
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

      if (dut.stencil_test) {
        U8 r = (dut.map_address & (0x007F << 0)) >> 0;
        U8 g = (dut.map_address & (0x007F << 7)) >> 7;
        U32 color = 0xFF;
        color <<= 8;
        color |= (r ^ g) << 1;
        color <<= 8;
        color |= g << 1;
        color <<= 8;
        color |= r << 1;
        buffer[(320 * y) + x] = color;
      } else {
        buffer[(320 * y) + x] = 0xFF000000;
      }

      if ((x == (X_WIDTH - 1)) && (y == (Y_WIDTH - 1))) {
        con::listener::debug(
            description, ": (", step, ") | NEXT ROTATION MATRIX (",
            current_pattern * (360.0f / (std::numbers::pi * 2.0f)), "°)");
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

  return current_pattern < (std::numbers::pi * 2.0f);
}
