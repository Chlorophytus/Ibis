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
#pragma once
#include "con.hpp"
#include "main.hpp"
#include "framebuffer.hpp"
namespace ibis {
/// @brief Test Verilog with C++ Abstract Base Classes
namespace test {
using step_t = U64;
template <typename D>
using run_func_t =
    std::function<bool(const step_t &, D &, const std::string &)>;
/// @brief A class for testing Verilog designs
class tester {
  std::shared_ptr<VerilatedContext> _context;

public:
  template <typename D>
  void run(run_func_t<D> &&func, std::string &&_description) {
    const auto description = _description;
    con::listener::informational(description, ": Starting test");
    step_t _step = 0;
    run_func_t<D> _func = func;
    std::unique_ptr<D> _device_under_test = std::make_unique<D>(_context.get());
    while (_func(_step, *_device_under_test, description)) {
      _step++;
    }
    con::listener::informational(description, ": Finished test in ", _step,
                                 " steps");
  }

  tester(std::shared_ptr<VerilatedContext> &);
  ~tester() = default;

  tester(const tester &) = delete;
  tester(tester &&) = delete;
  tester &operator=(const tester &) = delete;
  tester &operator=(tester &&) = delete;
};
bool test_vga_timings(const U64 &, Vibis_vga_timing &, const std::string &);
bool test_popcnt(const U64 &, Vibis_popcnt6 &, const std::string &);
bool test_tmds_disparity(const U64 &, Vibis_tmds_encoder &,
                         const std::string &);
bool test_texture_mapper(const U64 &, Vibis_texture_mapper &,
                         const std::string &);
bool test_lighting(const U64 &, Vibis_lighting &,
                         const std::string &);
bool test_square_root(const U64 &, Vibis_square_root &,
                         const std::string &);
} // namespace test
} // namespace ibis
