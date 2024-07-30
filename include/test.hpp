#pragma once
#include "Vibis_ripple_carry.h"
#include "con.hpp"
#include "main.hpp"
namespace ibis {
/// @brief Test Verilog with C++ Abstract Base Classes
namespace test {
using step_t = U64;
template <typename D>
using run_func_t = std::function<bool(const step_t &, D &, const std::string &)>;
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
bool test_1(const U64 &, Vibis_ripple_carry &, const std::string &);
bool test_2(const U64 &, Vibis_phase_accumulator &, const std::string &);
bool test_3(const U64 &, Vibis_phase_accumulator_dual &, const std::string &);
bool test_4(const U64 &, Vibis_vga_timing &, const std::string &);
bool test_5(const U64 &, Vibis_popcnt6 &, const std::string &);
bool test_6(const U64 &, Vibis_tmds_encoder &, const std::string &);
} // namespace test
} // namespace ibis
