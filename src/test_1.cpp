#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

bool test::test_1(const U64 &step, Vibis_ripple_carry &dut,
                  const std::string &description) {
  const auto lhs = (step >> 2) % 4;
  const auto rhs = step % 4;
  dut.addend0 = lhs;
  dut.addend1 = rhs;
  dut.carry_i = step > 15;
  dut.eval();

  con::listener::debug(description, ": (", step, ") ", lhs, " + ", rhs,
                       " + [C ", dut.carry_i,
                       "] =?= ", (dut.carry_o << 2) | dut.sum, " (", dut.sum,
                       " [C ", dut.carry_o, "])");

  if (step < 16) {
    assert(dut.sum == ((lhs + rhs) % 4));
    assert(dut.carry_o == ((lhs + rhs) > 3));
  } else {
    assert(dut.sum == ((lhs + rhs + 1) % 4));
    assert(dut.carry_o == ((lhs + rhs + 1) > 3));
  }

  return step < 31;
}
