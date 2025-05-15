#include "../include/framebuffer.hpp"
#include <raylib.h>
using namespace ibis;

static std::shared_ptr<std::array<U32, 640 * 480>> buffer{nullptr};
static Texture2D render;

void framebuffer::init() {
  buffer = std::make_shared<std::array<U32, 640 * 480>>();

  for(auto &&pixel : *buffer) {
    pixel = 0xFFFFFFFF;
  }

  InitWindow(640, 480, "Ibis Simulated Framebuffer");
  SetTargetFPS(60);
  auto image = GenImageColor(640, 480, GRAY);
  render = LoadTextureFromImage(image);
  UnloadImage(image);
}

void framebuffer::draw() {
  BeginDrawing();
  ClearBackground(BLACK);
  UpdateTexture(render, buffer->data());
  DrawTexture(render, 0, 0, WHITE);
  DrawFPS(20, 20);
  EndDrawing();
}

std::weak_ptr<std::array<U32, 640*480>> framebuffer::access() {
  return buffer;
}

void framebuffer::destroy() {
  CloseWindow();
}
