#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

bool test::test_5(const U64 &step, Vibis_popcnt6 &dut, const std::string &description) {
  dut.in_bits = step;
  dut.eval();

  con::listener::debug(description, ": (", step, ") ", std::popcount(step), " =?= ", dut.count);
  
  assert(dut.count == std::popcount(step));

  return step < 1 << 6;
}
