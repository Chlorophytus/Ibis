#include "../include/main.hpp"
#include "../include/con.hpp"
#include "../include/test.hpp"

int main(int argc, char **argv)
{
    int error_code = EXIT_FAILURE;
    ibis::con::init();
    ibis::con::listener::all.emplace_back(new ibis::con::listener_stderr);
    try
    {
        ibis::con::listener::informational("Ibis Test Framework ", ibis_VSTRING_FULL);
        std::shared_ptr<VerilatedContext> context{new VerilatedContext};
        context->commandArgs(argc, argv);

        std::list<std::thread> tests{};
        const U64 max_threads = std::thread::hardware_concurrency();
        std::counting_semaphore tests_semaphore{0};
        std::mutex debug;
        tests.emplace_back([&debug, &context, &tests_semaphore]
                           {
            ibis::test::tester t{context};
            { 
                std::scoped_lock s(debug);
                ibis::con::listener::informational("Test 0 started");
            }
            t.run<Vibis_tmds_encoder>(ibis::test::test_0, tests_semaphore);
            { 
                std::scoped_lock s(debug);
                ibis::con::listener::informational("Test 0 finished");
            } });
            
        while (!tests.empty())
        {
            tests.front().detach();
            tests.pop_front();
            tests_semaphore.acquire();
        }
        error_code = EXIT_SUCCESS;
    }
    catch (const std::exception &e)
    {
        ibis::con::listener::error(e.what());
    }
}