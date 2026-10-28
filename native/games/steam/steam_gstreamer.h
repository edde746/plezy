// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "steam_runtime.h"
#include <functional>

namespace plezy::steam {
struct DecodedPixels {
  uint32_t width = 0, height = 0, id = 0;
  std::vector<uint8_t> rgba;
};
// A dedicated games decoder. No media-library player, file URI, external
// process or user-provided pipeline is involved. All queues are bounded.
class GStreamerSink final : public Sink {
 public:
  using Present = std::function<bool(DecodedPixels&&)>;
  using Complete = std::function<void(uint32_t, bool)>;
  using Failed = std::function<void(bool audio)>;
  GStreamerSink(Present, Complete, Failed, bool testAudio = false);
  ~GStreamerSink() override;
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
} // namespace plezy::steam
