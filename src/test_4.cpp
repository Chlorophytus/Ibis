#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

bool test::test_4(const U64 &step, Vibis_vga_timing &dut,
                  const std::string &description) {
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
