#include "../include/test.hpp"
using namespace ibis;

bool test::test_popcnt(const U64 &step, Vibis_popcnt6 &dut, const std::string &description) {
  dut.in_bits = step;
  dut.eval();

  con::listener::debug(description, ": (", step, ") ", std::popcount(step), " =?= ", dut.count);
  
  return step < 1 << 6;
}
