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

bool test::test_square_root(const U64 &step, Vibis_square_root &dut, const std::string &description) {
  dut.in_bits = step;
  dut.eval();

  U32 truncated = std::trunc(std::sqrt(step) * 16);
  con::listener::debug(description, ": (", step, ") ", truncated, " =?= ", dut.square_root);
  assert(truncated == dut.square_root);
  
  return step < (1 << 8) - 1;
}
