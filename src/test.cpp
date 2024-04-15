#include "../include/con.hpp"
#include "../include/test.hpp"
using namespace ibis;

test::tester::tester(std::shared_ptr<VerilatedContext> &context)
{
    _context = context;
}
bool test::test_0(const U64 &step, Vibis_tmds_encoder &dut)
{
    dut.clock = (step % 2) == 0;
    dut.eval();
    return step < 1000000;
}