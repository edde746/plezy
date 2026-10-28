// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

namespace plezy::steam {
struct StreamOptions {
  int width = 1920, height = 1080, fps = 60, bitrateKbps = 30000;
  int controllerCount = 1;
  // Current request bounds, not the decoder's theoretical limits.
  bool valid() const {
    return width >= 640 && width <= 1920 && height >= 360 && height <= 1080 &&
           width % 2 == 0 && height % 2 == 0 && fps >= 15 && fps <= 60 &&
           bitrateKbps >= 1000 && bitrateKbps <= 50000 && controllerCount >= 1 && controllerCount <= 4;
  }
};
}  // namespace plezy::steam
