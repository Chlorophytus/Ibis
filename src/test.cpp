#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

test::tester::tester(std::shared_ptr<VerilatedContext> &context) {
  _context = context;
}

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

bool test::test_2(const U64 &step, Vibis_phase_accumulator &dut,
                  const std::string &description) {
  constexpr auto PHASE = 10;
  constexpr auto RESET_OFF_WHEN = 16;
  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    dut.phase_carry = false;
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

bool test::test_3(const U64 &step, Vibis_phase_accumulator_dual &dut,
                  const std::string &description) {
  constexpr auto PHASE = 100;
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

  con::listener::debug(
      description, ": (", step, ") p0: ", dut.DEBUG_phase0,
      " p0hold: ", dut.DEBUG_phase0_hold, " p1: ", dut.DEBUG_phase1,
      " p1hold: ", dut.DEBUG_phase1_hold, " iszero: ", dut.phase_is_zero,
      " pC: ", dut.DEBUG_phase_all);

  return step < RESET_OFF_WHEN + (PHASE << 1) + 8;
}
bool test::test_4(const U64 &step, Vibis_vga_timing &dut, const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    break;
  }
  default: {
    break;
  }
  }

  dut.aclk = (step % 2) == 0;
  dut.eval();

#if 0
  if(dut.ord_x == 0) {
    con::listener::debug(description, ": (", step, ") x ordinate is zero, y is ", dut.ord_y);
  }
  if(dut.ord_y == 0) {
    con::listener::debug(description, ": (", step, ") y ordinate is zero");
  }

  con::listener::debug(description, ": (", step, ") Vsync: ", dut.vsync,
                       " VblankN: ", dut.vblankn, " Hsync: ", dut.hsync,
                       " HblankN: ", dut.hblankn, " X: ", dut.ord_x, " Y ",
                       dut.ord_y);
#endif
  return step < RESET_OFF_WHEN + ((800 * 525 * 5) << 1);
}
