#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

bool test::test_2(const U64 &step, Vibis_phase_accumulator &dut,
                  const std::string &description) {
  constexpr auto PHASE = 10;
  constexpr auto RESET_OFF_WHEN = 16;
  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    dut.phase_in = PHASE;
    dut.write_enable = true;
    break;
  }
  case RESET_OFF_WHEN + 4: {
    dut.phase_reset = true;
    break;
  }
  case RESET_OFF_WHEN + 8: {
    dut.write_enable = false;
    dut.phase_reset = false;
    break;
  }
  default: {
    break;
  }
  }

  dut.aclk = (step % 2) == 0;
  dut.eval();

  con::listener::debug(description, ": (", step, ") p: ", dut.DEBUG_phase,
                       " phold: ", dut.DEBUG_phase_hold,
                       " iszero: ", dut.phase_is_zero);

  return step < RESET_OFF_WHEN + (PHASE << 1) + 8;
}
