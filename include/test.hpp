#pragma once
#include "con.hpp"
#include "main.hpp"
namespace ibis {
/// @brief Test Verilog with C++ Abstract Base Classes
namespace test {
using step_t = U64;
template <typename D>
using run_func_t = std::function<bool(const step_t &, D &)>;
/// @brief A class for testing Verilog designs
class tester {
  std::shared_ptr<VerilatedContext> _context;
  std::mutex _debug;

public:
  template <typename D>
  void run(run_func_t<D> &&func, std::atomic<U64> &sema,
           std::string &&description) {
		sema++;
    {
      std::scoped_lock s(_debug);
      con::listener::informational("[", description, "] Starting test");
    }
    step_t _step = 0;
    run_func_t<D> _func = func;
    std::unique_ptr<D> _device_under_test = std::make_unique<D>(_context.get());
    while (_func(_step, *_device_under_test)) {
      _step++;
    }
    {
      std::scoped_lock s(_debug);
      con::listener::informational("[", description, "] Finished test in ", _step,
                                   " steps");
    }
    sema--;
  }

  tester(std::shared_ptr<VerilatedContext> &);
  ~tester() = default;

  tester(const tester &) = delete;
  tester(tester &&) = delete;
  tester &operator=(const tester &) = delete;
  tester &operator=(tester &&) = delete;
};
bool test_0(const U64 &, Vibis_tmds_encoder &);
bool test_0(const U64 &, Vibis_vga_timing &);
} // namespace test
} // namespace ibis
