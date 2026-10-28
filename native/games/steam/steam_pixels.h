// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <cstdint>
#include <vector>
namespace plezy::steam {
struct DecodedPixels {
  uint32_t width = 0, height = 0, id = 0;
  std::vector<uint8_t> rgba;
};
}  // namespace plezy::steam
