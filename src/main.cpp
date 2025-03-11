#include "../include/main.hpp"
#include "../include/con.hpp"
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
    std::list<std::thread> tests{};
    ibis::test::tester t{context};

    // Test cases...
#if 0
    tests.emplace_back([&t] {
      t.run<Vibis_vga_timing>(ibis::test::test_vga_timings,
                              "VGA timings work properly");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_popcnt6>(ibis::test::test_popcnt,
                           "6-bit population count is fully verified");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_tmds_encoder>(ibis::test::test_tmds_disparity,
                                "TMDS encoder doesn't over/under-bias");
    });
#endif
    tests.emplace_back([&t] {
      t.run<Vibis_forward_mapper>(ibis::test::test_forward_mapper,
                                  "Forward mapper works properly");
    });

    while (!tests.empty()) {
      // Verilator doesn't like to single-thread, just do them one at a time.
      tests.front().join();
      tests.pop_front();
    }
    error_code = EXIT_SUCCESS;
  } catch (const std::exception &e) {
    ibis::con::listener::error(e.what());
  }
}
