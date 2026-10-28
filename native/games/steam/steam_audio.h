// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" {
#include <opus_multistream.h>
}

namespace plezy::steam {
// PCM order is FL, FR, FC, LFE, BL, BR (quad: FL, FR, BL, BR).
// Multichannel streams MUST supply their OpusHead mapping. A channel count
// alone cannot identify which speaker an encoded stream belongs to.
struct AudioLayout {
  int channels = 0, streams = 0, coupled = 0, gain = 0, skip = 0;
  std::array<unsigned char, 6> mapping{};
};
bool parseAudioLayout(unsigned channels, unsigned rate, const uint8_t* data, size_t length, AudioLayout& out);

class AudioDecoder {
 public:
  static constexpr size_t maxSamples = 5760 * 6;
  AudioDecoder() = default;
  AudioDecoder(const AudioDecoder&) = delete;
  AudioDecoder& operator=(const AudioDecoder&) = delete;
  ~AudioDecoder() { reset(); }
  bool start(unsigned channels, unsigned rate, const uint8_t* extra, size_t length);
  // Returns interleaved sample count, 0 for a fully pre-skipped packet, -1 on
  // invalid input. Caller owns a maxSamples-sized buffer. No packet allocation.
  int decode(const uint8_t* bytes, size_t length, int16_t* pcm);
  void reset();
 private:
  OpusMSDecoder* decoder_ = nullptr;
  int channels_ = 0, skip_ = 0;
};
} // namespace plezy::steam
