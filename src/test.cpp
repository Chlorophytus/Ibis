#include "../include/test.hpp"
using namespace ibis;

test::tester::tester(std::shared_ptr<VerilatedContext> &context) {
  _context = context;
}
