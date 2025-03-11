#include "../include/test.hpp"
#include "con.hpp"
using namespace ibis;

static std::unique_ptr<std::vector<F32>> ptr_qs{nullptr};
static std::unique_ptr<std::mt19937> ptr_rng{nullptr};
static std::uniform_int_distribution<U8> gen(0, 255);

bool test::test_tmds_disparity(const U64 &step, Vibis_tmds_encoder &dut,
                               const std::string &description) {
  constexpr auto RESET_OFF_WHEN = 16;
  constexpr auto ITERATIONS = 1024;
  constexpr auto FINISH = RESET_OFF_WHEN + (ITERATIONS << 1);
  switch (step) {
  case 0: {
    ptr_qs = std::make_unique<std::vector<F32>>();
    std::random_device rd;
    auto seed = rd();
    ptr_rng = std::make_unique<std::mt19937>(seed);
    con::listener::debug(description, ": (", step, ") seed: ", seed);

    dut.aresetn = false;
    dut.enable = true;
    dut.data_enable = false;
    break;
  }
  case RESET_OFF_WHEN: {
    dut.aresetn = true;
    dut.data_enable = true;
    break;
  }
  default: {
    break;
  }
  }

  dut.aclk = (step % 2) == 0;
  if (dut.aclk) {
    dut.data = gen(*ptr_rng);
  }
  dut.eval();

  if (dut.aclk && step > RESET_OFF_WHEN) {
    // This bit shifting is necessary since Verilator doesn't do it
    U8 bias_castee = dut.debug_bias;
    bias_castee <<= 3;
    const auto bias = std::bit_cast<S8>(bias_castee) / (1 << 3);

    con::listener::debug(description, ": (", step, ") bias: ", bias);
    ptr_qs->emplace_back(bias);
  }

  if (step >= FINISH) {
    auto acc = std::accumulate(ptr_qs->cbegin(), ptr_qs->cend(), 0.0f) /
               F32{ITERATIONS};
    con::listener::debug(description, ": (", step, ") bias average is ", acc);
  }

  return step < FINISH;
}
