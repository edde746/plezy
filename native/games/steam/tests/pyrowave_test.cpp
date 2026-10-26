// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_pyrowave.h"

#include <array>
#include <cassert>
#include <cstdint>
#include <vector>

namespace {
void write32(uint8_t* out, uint32_t value) {
  for (int i = 0; i < 4; ++i) out[i] = static_cast<uint8_t>(value >> (8 * i));
}
std::array<uint8_t, 16> sequenceFrame(bool fullRange = false) {
  std::array<uint8_t, 16> bytes{};
  // A 2x2 SDR 4:2:0 sequence header, then one empty 2-word block packet.
  write32(bytes.data(), 1u | (1u << 14) | (1u << 31));
  write32(bytes.data() + 4, uint32_t(fullRange ? 0 : 1) << 30);
  bytes[10] = 2;
  return bytes;
}
void sequenceValidation() {
  auto bytes = sequenceFrame();
  plezy::steam::PyrowaveFrameInfo info{};
  assert(plezy::steam::parsePyrowaveFrame(bytes.data(), bytes.size(), 2, 2, info));
  assert(info.width == 2 && info.height == 2 && !info.fullRange);
  assert(!plezy::steam::parsePyrowaveFrame(bytes.data(), bytes.size() - 1, 2, 2, info));
  assert(!plezy::steam::parsePyrowaveFrame(bytes.data(), bytes.size(), 4, 2, info));
  bytes[10] = 0;  // zero payload_words is not a valid block
  assert(!plezy::steam::parsePyrowaveFrame(bytes.data(), bytes.size(), 2, 2, info));
  bytes = sequenceFrame();
  bytes[7] |= 0x10;  // PQ transfer function
  assert(!plezy::steam::parsePyrowaveFrame(bytes.data(), bytes.size(), 2, 2, info));
}
void colorConversion() {
  const uint8_t y[4] = {16, 235, 16, 235};
  const uint8_t cb[1] = {128}, cr[1] = {128};
  plezy::steam::PyrowaveFrameInfo info{2, 2, false};
  std::vector<uint8_t> argb;
  plezy::steam::convertPyrowave420ToArgb(y, 2, cb, 1, cr, 1, info, argb);
  assert(argb.size() == 16);
  assert(argb[0] == 0 && argb[1] == 0 && argb[2] == 0 && argb[3] == 255);
  assert(argb[4] == 255 && argb[5] == 255 && argb[6] == 255 && argb[7] == 255);

  const uint8_t paddedY[6] = {255, 255, 99, 0, 0, 99};
  info.fullRange = true;
  plezy::steam::convertPyrowave420ToArgb(paddedY, 3, cb, 1, cr, 1, info, argb);
  assert(argb[0] == 255 && argb[1] == 255 && argb[2] == 255);
  assert(argb[8] == 0 && argb[9] == 0 && argb[10] == 0);
}
}  // namespace

int main() {
  sequenceValidation();
  colorConversion();
}
