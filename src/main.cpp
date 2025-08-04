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
#include "../include/main.hpp"
#include "../include/con.hpp"
#include "../include/framebuffer.hpp"
#include "../include/test.hpp"

int main(int argc, char **argv) {
  int error_code = EXIT_FAILURE;
  ibis::con::init();
  ibis::con::listener::all.emplace_back(new ibis::con::listener_stdio);
#ifdef ibis_NDEBUG
  ibis::con::listener::all.front()->priority_set(
      ibis::con::priority::informational);
#endif
  try {
    ibis::con::listener::informational("Ibis Test Framework ",
                                       ibis_VSTRING_FULL);
    std::shared_ptr<VerilatedContext> context{new VerilatedContext};
    context->commandArgs(argc, argv);

    // Test case runner
    ibis::test::tester t{context};

    ibis::framebuffer::init();
    // Test cases...
#if 0
    t.run<Vibis_vga_timing>(ibis::test::test_vga_timings,
                            "VGA timings work properly");
    t.run<Vibis_tmds_encoder>(ibis::test::test_tmds_disparity,
                              "TMDS encoder doesn't over/under-bias");
    t.run<Vibis_texture_mapper>(ibis::test::test_texture_mapper,
                                "Texture mapper works properly");
#endif
    t.run<Vibis_popcnt6>(ibis::test::test_popcnt,
                         "6-bit population count is fully verified");
    t.run<Vibis_square_root>(ibis::test::test_square_root,
                         "8-bit square root is fully verified");
    t.run<Vibis_lighting>(ibis::test::test_lighting,
                          "Lighting engine works properly");
    ibis::framebuffer::destroy();
    error_code = EXIT_SUCCESS;
  } catch (const std::exception &e) {
    ibis::con::listener::error(e.what());
  }
}
