#include "../include/test.hpp"
using namespace ibis;

// TODO: FIX

static std::unique_ptr<std::stringstream> ptr_stream{nullptr};
static F32 current_pattern = 0.0f;
static U32 num_patterns = 0;

bool test::test_forward_mapper(const U64 &step, Vibis_forward_mapper &dut,
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
    dut.texture_translateX = 10;
    dut.texture_translateY = 10;
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
  const auto offset_step = step - (RESET_OFF_WHEN + 40);
  const auto x = (offset_step / 20) % X_WIDTH;
  const auto y = (offset_step / (20 * X_WIDTH)) % Y_WIDTH;
  dut.x = x;
  dut.y = y;
  if (offset_step > 0) {
    switch (offset_step % 20) {
    case 0: {
      if (x == 0 && y == 0) {
#if 0
        dut.texture_matrixA = std::bit_cast<U16>(static_cast<S16>(
                                  std::cos(current_pattern) * 12)) >>
                              4;
        dut.texture_matrixB = std::bit_cast<U16>(static_cast<S16>(
                                  -std::sin(current_pattern) * 4)) >>
                              4;
        dut.texture_matrixC = std::bit_cast<U16>(static_cast<S16>(
                                  std::sin(current_pattern) * 4)) >>
                              4;
        dut.texture_matrixD = std::bit_cast<U16>(static_cast<S16>(
                                  std::cos(current_pattern) * 12)) >>
                              4;
        dut.write_matrix = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3);
#endif
        current_pattern += std::numbers::pi / 8.0f;
        num_patterns++;
      }
      break;
    }
    case 2: {
      dut.write_matrix = 0;
      break;
    }
    case 18: {
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
  }
  dut.eval();
  return num_patterns < 32;
}
