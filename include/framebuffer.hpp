#pragma once
#include "main.hpp"
namespace ibis {
namespace framebuffer {
void init();
std::weak_ptr<std::array<U32, 640 * 480>> access();
void draw();
void destroy();
}
}
