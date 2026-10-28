// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <functional>

#include "steam_pixels.h"
#include "steam_runtime.h"

namespace plezy::steam {
// Media Foundation conventional receiver; SDR NV12 -> RGBA texture. This
// adapter deliberately does not advertise HDR or direct GPU presentation.
class WindowsSink final : public Sink {
 public:
  using Present = std::function<bool(DecodedPixels&&)>;
  using Complete = std::function<void(uint32_t, bool)>;
  using Failed = std::function<void(bool audio)>;
  WindowsSink(Present, Complete, Failed);
  ~WindowsSink() override;
  static bool supported(bool hevc = false);
  bool video(int, int, int, const uint8_t*, size_t) override;
  bool frame(const uint8_t*, size_t, uint32_t, bool) override;
  bool audio(int, int) override;
  void audioUnavailable() override;
  void samples(const int16_t*, size_t) override;
  void volume(bool enabled);
  void close();

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
}  // namespace plezy::steam
