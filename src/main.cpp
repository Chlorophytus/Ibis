#include "../include/main.hpp"
#include "../include/con.hpp"
#include "../include/test.hpp"
#include "Vibis_phase_accumulator.h"
#include "Vibis_ripple_carry.h"
#include <atomic>
#include <chrono>

int main(int argc, char **argv) {
  int error_code = EXIT_FAILURE;
  ibis::con::init();
  ibis::con::listener::all.emplace_back(new ibis::con::listener_stderr);
//  ibis::con::listener::all.front()->priority_set(
//      ibis::con::priority::informational);
  try {
    ibis::con::listener::informational("Ibis Test Framework ",
                                       ibis_VSTRING_FULL);
    std::shared_ptr<VerilatedContext> context{new VerilatedContext};
    context->commandArgs(argc, argv);

    // Test case runner
    std::list<std::thread> tests{};
    const U64 max_threads = std::thread::hardware_concurrency();
    std::atomic<U64> tests_semaphore(0);
    ibis::test::tester t{context};

    // Test cases...
    tests.emplace_back([&t, &tests_semaphore] {
      t.run<Vibis_ripple_carry>(ibis::test::test_1, tests_semaphore,
                                "2-bit ripple-carry works properly");
    });
    tests.emplace_back([&t, &tests_semaphore] {
      t.run<Vibis_phase_accumulator>(
          ibis::test::test_2, tests_semaphore,
          "lone 5-bit phase accumulator works properly");
    });
    // Multithreaded runner
    while (!tests.empty()) {
      // Dispatch for this many threads
      for (auto thread_i = 0; thread_i < max_threads; thread_i++) {
        if (tests.empty()) {
          break;
        }
        tests.front().detach();
        tests.pop_front();
      }
      do {
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
      } while (tests_semaphore > 0);
    }
    error_code = EXIT_SUCCESS;
  } catch (const std::exception &e) {
    ibis::con::listener::error(e.what());
  }
}
