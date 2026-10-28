// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include "steam_runtime.h"
#include <CoreVideo/CoreVideo.h>
#include <functional>

namespace plezy::steam {
class AppleSink final : public Sink {
 public:
  // The callback may retain the pixel buffer. Completion belongs to the
  // texture consumer, not merely the successful decoder submission.
  using Present = std::function<bool(CVPixelBufferRef, uint32_t)>;
  using Complete = std::function<void(uint32_t,bool)>;
  using Failed = std::function<void(bool audio)>;
  AppleSink(Present, Complete, Failed);
  ~AppleSink() override;
  static bool supportsHevc();
  static bool supportsPyrowave();
  bool video(int,int,int,const uint8_t*,size_t) override;
  bool frame(const uint8_t*,size_t,uint32_t,bool) override;
  bool audio(int,int) override;
  void audioUnavailable() override;
  void samples(const int16_t*,size_t) override;
  void volume(bool);
  int decoderKind() const;
  int chromaFormat() const;
  void close();
 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
}
