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
    tests.emplace_back([&t] {
      t.run<Vibis_ripple_carry>(ibis::test::test_1,
                                "2-bit ripple-carry works properly");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_phase_accumulator>(
          ibis::test::test_2,
          "lone 5-bit phase accumulator works properly");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_phase_accumulator_dual>(
          ibis::test::test_3,
          "carrying dual 5-bit phase accumulators work properly");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_vga_timing>(
          ibis::test::test_4,
          "VGA timings work properly");
    });
    tests.emplace_back([&t] {
      t.run<Vibis_popcnt6>(
          ibis::test::test_5,
          "6-bit population count is fully verified");
    });    tests.emplace_back([&t] {
      t.run<Vibis_tmds_encoder>(
          ibis::test::test_6,
          "TMDS encoder doesn't over/under-bias");
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
