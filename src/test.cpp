#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

test::tester::tester(std::shared_ptr<VerilatedContext> &context) {
  _context = context;
}

bool test::test_0(const U64 &step, Vibis_tmds_encoder &dut,
                  const std::string &description) {
	// TODO
  switch (step) {
  case 0: {
    dut.aresetn = false;
    break;
  }
  case 16: {
    dut.aresetn = true;
    break;
  }
  default: {
    break;
  }
  }
  dut.aclk = (step % 2) == 0;
  dut.eval();
  return step < 1000000;
}
bool test::test_1(const U64 &step, Vibis_vga_timing &dut,
                  const std::string &description) {
	// TODO
  switch (step) {
  case 0: {
    dut.aresetn = false;
    break;
  }
  case 16: {
    dut.aresetn = true;
    break;
  }
  default: {
    break;
  }
  }
  dut.aclk = (step % 2) == 0;
  dut.eval();
  return step < 1000000;
}

bool test::test_2(const U64 &step, Vibis_ripple_carry &dut,
                  const std::string &description) {
  const auto lhs = (step >> 2) % 4;
  const auto rhs = step % 4;
  dut.addend0 = lhs;
  dut.addend1 = rhs;
  dut.carry_i = step > 15;
  dut.eval();

  con::listener::debug(description, ": ", lhs, " + ", rhs, " + [C ",
                       dut.carry_i, "] =?= ", (dut.carry_o << 2) | dut.sum,
                       " (", dut.sum, " [C ", dut.carry_o, "])");

  if (step < 16) {
    assert(dut.sum == ((lhs + rhs) % 4));
    assert(dut.carry_o == ((lhs + rhs) > 3));
  } else {
    assert(dut.sum == ((lhs + rhs + 1) % 4));
    assert(dut.carry_o == ((lhs + rhs + 1) > 3));
  }

  return step < 31;
}
