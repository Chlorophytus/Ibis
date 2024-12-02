#include "../include/test.hpp"
using namespace ibis;

bool test::test_7(const U64 &step, Vibis_phase_accumulator_quad &dut,
                  const std::string &description) {
  constexpr auto PHASE = (1 << 13) + 1337;
  constexpr auto RESET_OFF_WHEN = 16;
  const auto pCexpected = (dut.DEBUG_phase_all > 0) ? (PHASE - ((step - (RESET_OFF_WHEN + 6)) >> 1)) : 0;
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

  con::listener::debug(
      description, ": (", step, ") p0: ", dut.DEBUG_phase0,
      " p0hold: ", dut.DEBUG_phase0_hold, " p1: ", dut.DEBUG_phase1,
      " p1hold: ", dut.DEBUG_phase1_hold, " p2: ", dut.DEBUG_phase2,
      " p2hold: ", dut.DEBUG_phase2_hold, " p3: ", dut.DEBUG_phase3,
      " p3hold: ", dut.DEBUG_phase3_hold, " iszero: ", dut.phase_is_zero,
      " pC: ", dut.DEBUG_phase_all, " pCexpected: ", pCexpected);

  if (step > (RESET_OFF_WHEN + 8)) {
    assert(pCexpected == dut.DEBUG_phase_all);
  }

  return step < RESET_OFF_WHEN + (PHASE << 1) + 64;
}
