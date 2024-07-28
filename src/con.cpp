#include "../include/con.hpp"
using namespace ibis;
std::vector<std::unique_ptr<con::listener>> con::listener::all;

void con::init() {
  con::listener::all = std::vector<std::unique_ptr<con::listener>>{};
}
