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

bool test::test_popcnt(const U64 &step, Vibis_popcnt6 &dut, const std::string &description) {
  dut.in_bits = step;
  dut.eval();

  con::listener::debug(description, ": (", step, ") ", std::popcount(step), " =?= ", dut.count);
  
  return step < 1 << 6;
}
