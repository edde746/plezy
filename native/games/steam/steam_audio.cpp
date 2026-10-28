// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_audio.h"
#include <algorithm>
#include <cstring>

namespace plezy::steam {
bool parseAudioLayout(unsigned channels, unsigned rate, const uint8_t* data, size_t length, AudioLayout& out) {
  if (rate != 48000 || (channels != 1 && channels != 2 && channels != 4 && channels != 6)) return false;
  AudioLayout result{};
  result.channels = channels;
  if (length == 0) {
    if (channels > 2) return false;
    result.streams = 1;
    result.coupled = channels == 2;
    result.mapping[1] = 1;
    out = result;
    return true;
  }
  if (!data || length < 19 || length > 27 || std::memcmp(data, "OpusHead", 8) || data[8] != 1 ||
      data[9] != channels) return false;
  result.skip = int(data[10]) | (int(data[11]) << 8);
  if (result.skip > 5760) return false;
  const unsigned rawGain = unsigned(data[16]) | (unsigned(data[17]) << 8);
  result.gain = rawGain < 0x8000 ? int(rawGain) : int(rawGain) - 0x10000;
  if (data[18] == 0) {
    if (channels > 2 || length != 19) return false;
    result.streams = 1;
    result.coupled = channels == 2;
    result.mapping[1] = 1;
  } else {
    // RFC 7845 family 1 defines speaker positions. Family 255 explicitly does
    // not: accepting it as 5.1 would silently send dialog/LFE to wrong speakers.
    if (data[18] != 1 || length != 21 + channels) return false;
    result.streams = data[19];
    result.coupled = data[20];
    if (result.streams < 1 || result.coupled > result.streams ||
        result.streams + result.coupled != int(channels)) return false;
    unsigned seen = 0;
    for (unsigned i = 0; i < channels; ++i) {
      const auto value = data[21 + i];
      if (value >= channels || (seen & (1u << value))) return false;
      seen |= 1u << value;
      result.mapping[i] = value;
    }
    if (channels == 6) {
      constexpr unsigned vorbisToPcm[] = {0, 2, 1, 5, 3, 4};
      for (unsigned i = 0; i < 6; ++i) result.mapping[i] = data[21 + vorbisToPcm[i]];
    }
  }
  out = result;
  return true;
}

bool AudioDecoder::start(unsigned channels, unsigned rate, const uint8_t* extra, size_t length) {
  reset();
  AudioLayout layout;
  if (!parseAudioLayout(channels, rate, extra, length, layout)) return false;
  int error = 0;
  decoder_ = opus_multistream_decoder_create(rate, channels, layout.streams, layout.coupled,
                                            layout.mapping.data(), &error);
  if (!decoder_ || error != OPUS_OK || opus_multistream_decoder_ctl(decoder_, OPUS_SET_GAIN(layout.gain)) != OPUS_OK) {
    reset();
    return false;
  }
  channels_ = channels;
  skip_ = layout.skip;
  return true;
}
int AudioDecoder::decode(const uint8_t* bytes, size_t length, int16_t* pcm) {
  if (!decoder_ || !bytes || !pcm || length == 0 || length > 16384) return -1;
  const int frames = opus_multistream_decode(decoder_, bytes, static_cast<opus_int32>(length), pcm, 5760, 0);
  if (frames < 0) return -1;
  const int skipped = std::min(skip_, frames);
  skip_ -= skipped;
  const int samples = (frames - skipped) * channels_;
  if (skipped && samples) std::memmove(pcm, pcm + skipped * channels_, samples * sizeof(int16_t));
  return samples;
}
void AudioDecoder::reset() {
  if (decoder_) opus_multistream_decoder_destroy(decoder_);
  decoder_ = nullptr;
  channels_ = skip_ = 0;
}
} // namespace plezy::steam
