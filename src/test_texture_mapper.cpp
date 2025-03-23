#include "../include/test.hpp"
using namespace ibis;

static std::unique_ptr<std::stringstream> ptr_stream{nullptr};
static F64 current_pattern = 0.0f;
static U32 num_patterns = 0;
static U64 offset_step = 0;

U16 convert_to_s12(F64 pattern) {
  U16 converted = std::abs(pattern * (1 << 7));
  if(std::signbit(pattern)) {
    converted = ~converted + 1;
  }
  return converted >> 3;
}

bool test::test_texture_mapper(const U64 &step, Vibis_texture_mapper &dut,
                               const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  constexpr auto X_WIDTH = 40;
  constexpr auto Y_WIDTH = 24;

  switch (step) {
  case 0: {
    dut.aresetn = false;
    dut.enable = true;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    dut.texture_translateX = 2;
    dut.texture_translateY = 2;
    dut.write_matrix = (1 << 4) | (1 << 5);

    ptr_stream = std::make_unique<std::stringstream>();
    break;
  }
  case RESET_OFF_WHEN + 20: {
    dut.write_matrix = 0;
    break;
  }
  default: {
    break;
  }
  }
  dut.aclk = (step % 2) == 0;
  if (offset_step > 0) {
    const auto x = ((step - offset_step) / 40) % X_WIDTH;
    const auto y = ((step - offset_step) / (40 * X_WIDTH)) % Y_WIDTH;
    dut.x = x;
    dut.y = y;
    switch ((step - offset_step) % 40) {
    case 0: {
      if (x == 0 && y == 0) {
        dut.texture_matrixA = convert_to_s12(std::cos(current_pattern));
        dut.texture_matrixB = convert_to_s12(-std::sin(current_pattern));
        dut.texture_matrixC = convert_to_s12(std::sin(current_pattern));
        dut.texture_matrixD = convert_to_s12(std::cos(current_pattern));
        dut.write_matrix = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);
        current_pattern += std::numbers::pi / 16.0;
        num_patterns++;
      }
      break;
    }
    case 18: {
      dut.write_matrix = 0;
      break;
    }
    case 38: {
      if (dut.stencil_test) {
        *ptr_stream << std::setfill('0') << std::setw(3) << std::hex
                    << dut.map_address << " ";
      } else {

        *ptr_stream << std::hex << "--- ";
      }
      if (x == (X_WIDTH - 1)) {
        con::listener::debug(description, ": (", step, ") | ",
                             ptr_stream->str());
        ptr_stream = std::make_unique<std::stringstream>();
      }
      break;
    }
    default: {
      break;
    }
    }
  } else if (dut.ready) {
    offset_step = step;
    con::listener::debug(description, ": (", step,
                         ") - ready finally asserted");
  }
  dut.eval();
  return num_patterns < 16;
}
