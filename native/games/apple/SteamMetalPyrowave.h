// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <CoreVideo/CoreVideo.h>

#include "steam_pyrowave.h"

namespace plezy::steam {
// Worker-thread owned. The compressed bitstream is uploaded, but decoded
// planes and color conversion remain on Metal through the CVPixelBuffer.
class MetalPyrowave {
 public:
  MetalPyrowave();
  ~MetalPyrowave();
  static bool supported();
  bool start(int width, int height, const uint8_t* extra, size_t length);
  // On frame, caller owns the returned pixel buffer reference.
  PyrowaveDecodeStatus decode(const uint8_t*, size_t, CVPixelBufferRef*);
  void reset();
  bool chroma444() const;

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
}  // namespace plezy::steam
