/**
 *  Copyright 2025 Roland Metivier
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
 *  not use this file except in compliance with the License, or, at your option,
 *  the Apache License version 2.0.
 *
 *  You may obtain a copy of the License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
#include "../include/framebuffer.hpp"
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
