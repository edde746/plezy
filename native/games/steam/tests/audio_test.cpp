// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_audio.h"
#include <cassert>
#include <cmath>
#include <cstring>
#include <vector>
using namespace plezy::steam;

int main() {
  AudioLayout layout;
  assert(parseAudioLayout(1, 48000, nullptr, 0, layout) && layout.coupled == 0);
  assert(parseAudioLayout(2, 48000, nullptr, 0, layout) && layout.mapping[1] == 1);
  assert(!parseAudioLayout(6, 48000, nullptr, 0, layout));
  assert(!parseAudioLayout(3, 48000, nullptr, 0, layout));
  assert(!parseAudioLayout(2, 44100, nullptr, 0, layout));
  assert(!parseAudioLayout(2, 48000, nullptr, 19, layout));

  for (int channels : {1, 2, 4, 6}) {
    int streams = 0, coupled = 0, error = 0;
    unsigned char mapping[6]{};
    auto* encoder = opus_multistream_surround_encoder_create(48000, channels, channels < 3 ? 0 : 1,
        &streams, &coupled, mapping, OPUS_APPLICATION_RESTRICTED_LOWDELAY, &error);
    assert(encoder && error == OPUS_OK);
    assert(opus_multistream_encoder_ctl(encoder, OPUS_SET_BITRATE(64000 * channels)) == OPUS_OK);
    std::vector<uint8_t> header(channels < 3 ? 19 : 21 + channels, 0);
    std::memcpy(header.data(), "OpusHead", 8);
    header[8] = 1;
    header[9] = channels;
    if (channels > 2) {
      header[18] = 1;
      header[19] = streams;
      header[20] = coupled;
      std::memcpy(header.data() + 21, mapping, channels);
    }
    assert(parseAudioLayout(channels, 48000, header.data(), header.size(), layout));
    AudioDecoder decoder;
    assert(decoder.start(channels, 48000, header.data(), header.size()));
    std::array<int16_t, AudioDecoder::maxSamples> output{};
    std::vector<int16_t> input(960 * channels);
    const int frequencies[] = {400, 800, 1200, 1600, 2000, 100};
    constexpr double pi = 3.14159265358979323846;
    uint8_t encoded[16384]{};
    // Unique tones exercise actual Opus multistream decoding and speaker
    // routing, including the Vorbis centre/LFE reorder. Warm up codec overlap.
    for (int packet = 0; packet < 12; ++packet) {
      for (int f = 0; f < 960; ++f)
        for (int c = 0; c < channels; ++c)
          input[f * channels + c] = int16_t(8000 * std::sin(2 * pi * frequencies[c] * f / 48000));
      const int length = opus_multistream_encode(encoder, input.data(), 960, encoded, sizeof(encoded));
      assert(length > 0);
      assert(decoder.decode(encoded, length, output.data()) == 960 * channels);
    }
    const unsigned order[] = {0, 2, 1, 5, 3, 4};
    for (int c = 0; c < channels; ++c) {
      double energies[6]{};
      for (int tone = 0; tone < channels; ++tone) {
        double re = 0, im = 0;
        for (int f = 0; f < 960; ++f) {
          double phase = 2 * pi * frequencies[tone] * f / 48000;
          re += output[f * channels + c] * std::cos(phase);
          im += output[f * channels + c] * std::sin(phase);
        }
        energies[tone] = re * re + im * im;
      }
      unsigned expected = channels == 6 ? order[c] : unsigned(c);
      assert(energies[expected] > 1e9);
      for (int tone = 0; tone < channels; ++tone)
        if (unsigned(tone) != expected) assert(energies[expected] > energies[tone] * 2);
    }
    assert(decoder.decode(nullptr, 0, output.data()) == -1);
    assert(decoder.decode(encoded, 16385, output.data()) == -1);
    decoder.reset();
    assert(decoder.decode(encoded, 3, output.data()) == -1);
    for (size_t length = 1; length < header.size(); ++length)
      assert(!parseAudioLayout(channels, 48000, header.data(), length, layout));
    header[8] = 255;
    assert(!decoder.start(channels, 48000, header.data(), header.size()));
    header[8] = 1;
    header[18] = 255;
    assert(!decoder.start(channels, 48000, header.data(), header.size()));
    if (channels > 2) {
      header[18] = 1;
      header[22] = header[21]; // Duplicate speaker/stream identities are ambiguous.
      assert(!decoder.start(channels, 48000, header.data(), header.size()));
    }
    opus_multistream_encoder_destroy(encoder);
  }
}
