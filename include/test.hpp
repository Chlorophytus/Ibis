#pragma once
#include "main.hpp"
namespace ibis
{
    /// @brief Test Verilog with C++ Abstract Base Classes
    namespace test
    {
        /// @brief A class for testing Verilog designs
        class tester
        {
            std::shared_ptr<VerilatedContext> _context;
            U64 _step = 0;

        public:
            template <typename D>
            void run(std::function<bool(const decltype(_step) &, D &)> &&func, std::counting_semaphore<> &sema)
            {
                std::function<bool(const decltype(_step) &, D &)> _func = func;
                std::unique_ptr<D> _device_under_test = std::make_unique<D>(_context.get());
                while (_func(_step, *_device_under_test))
                {
                    _step++;
                }
                sema.release();
            }

            tester(std::shared_ptr<VerilatedContext> &);
            ~tester() = default;

            tester(const tester &) = delete;
            tester(tester &&) = delete;
            tester &operator=(const tester &) = delete;
            tester &operator=(tester &&) = delete;
        };
        bool test_0(const U64 &, Vibis_tmds_encoder &);
    }
}