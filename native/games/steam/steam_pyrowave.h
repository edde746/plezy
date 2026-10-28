// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <vector>

namespace plezy::steam {
struct PyrowaveFrameInfo {
  uint32_t width = 0;
  uint32_t height = 0;
  bool fullRange = false;
  bool chroma444 = false;
  bool chromaLeft = false;
};

enum class PyrowaveDecodeStatus { frame, pending, invalid };

// Parses the pinned v1 bitstream without trusting packet lengths or dimensions.
bool parsePyrowaveFrame(
    const uint8_t* bytes, size_t length, uint32_t width, uint32_t height, PyrowaveFrameInfo& info,
    bool allow444 = false);
void convertPyrowave420ToArgb(
    const uint8_t* y, size_t yStride, const uint8_t* cb, size_t cbStride, const uint8_t* cr, size_t crStride,
    const PyrowaveFrameInfo& info, std::vector<uint8_t>& argb);

// The upstream C API is unstable. Keep its objects and ABI behind this adapter.
class PyrowaveDecoder {
 public:
  PyrowaveDecoder();
  ~PyrowaveDecoder();
  PyrowaveDecoder(const PyrowaveDecoder&) = delete;
  PyrowaveDecoder& operator=(const PyrowaveDecoder&) = delete;

  static bool probe();
  bool start(int width, int height, const uint8_t* initial = nullptr, size_t initialLength = 0);
  PyrowaveDecodeStatus decode(const uint8_t* bytes, size_t length, std::vector<uint8_t>& argb);
  void reset();

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
}  // namespace plezy::steam
