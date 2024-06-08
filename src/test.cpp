#include "../include/test.hpp"
using namespace ibis;

test::tester::tester(std::shared_ptr<VerilatedContext> &context) {
  _context = context;
}
bool test::test_0(const U64 &step, Vibis_tmds_encoder &dut) {
  switch (step) {
  case 0: {
    dut.reset = true;
    break;
  }
  case 16: {
    dut.reset = false;
    break;
  }
  default: {
    break;
  }
  }
  dut.clock = (step % 2) == 0;
  dut.eval();
  return step < 1000000;
}
bool test::test_1(const U64 &step, Vibis_vga_timing &dut) {
  switch (step) {
  case 0: {
    dut.reset = true;
    break;
  }
  case 16: {
    dut.reset = false;
    break;
  }
  default: {
    break;
  }
  }
  dut.clock = (step % 2) == 0;
  dut.eval();
  return step < 1000000;
}
