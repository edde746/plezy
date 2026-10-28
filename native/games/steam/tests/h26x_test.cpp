// SPDX-License-Identifier: GPL-3.0-or-later
#include <cassert>
#include <random>

#include "red_h264.h"
#include "steam_h26x.h"
#include "steam_runtime.h"
using namespace plezy::steam;
int main() {
  H26xParser parser;
  std::vector<uint8_t> output;
  bool changed = false;
  const uint8_t annex[] = {0, 0,    0,    1,    0x67, 0x42, 0, 0x1e, 0x80, 0,    0,
                           1, 0x68, 0xce, 0x38, 0x80, 0,    0, 1,    0x65, 0x88, 0x84};
  assert(parser.configure(IHS_StreamVideoCodecH264, nullptr, 0));
  assert(parser.accessUnit(redH264, sizeof(redH264), output, changed));
  assert(changed && parser.ready() && output.size() > 4);
  assert(parser.configure(IHS_StreamVideoCodecH264, nullptr, 0));
  assert(!parser.ready());
  assert(parser.accessUnit(annex, sizeof(annex), output, changed));
  assert(changed && parser.ready());
  assert((output == std::vector<uint8_t>{0, 0, 0, 3, 0x65, 0x88, 0x84}));
  assert(parser.accessUnit(annex, sizeof(annex), output, changed) && !changed);
  const auto before = parser.parameters();
  // A new SPS followed by an empty NAL is transactional, not a partial update.
  const uint8_t broken[] = {0, 0, 1, 0x67, 0x80, 0, 0, 1};
  assert(!parser.accessUnit(broken, sizeof(broken), output, changed));
  assert(output.empty() && !changed && parser.parameters() == before);
  const uint8_t avcc[] = {1, 0x42, 0,    0x1e, 0xff, 0xe1, 0,    5,    0x67, 0x42,
                          0, 0x1e, 0x80, 1,    0,    4,    0x68, 0xce, 0x38, 0x80};
  assert(parser.configure(IHS_StreamVideoCodecH264, avcc, sizeof(avcc)) && parser.ready());
  const uint8_t lengthPrefixed[] = {0, 0, 0, 3, 0x65, 0x88, 0x84};
  assert(parser.accessUnit(lengthPrefixed, sizeof(lengthPrefixed), output, changed));
  assert(output == std::vector<uint8_t>(std::begin(lengthPrefixed), std::end(lengthPrefixed)));
  assert(parser.annexB(lengthPrefixed, sizeof(lengthPrefixed), output));
  const std::vector<uint8_t> normalized = {0, 0,    0,    1,    0x67, 0x42, 0, 0x1e, 0x80, 0,    0,    0,
                                           1, 0x68, 0xce, 0x38, 0x80, 0,    0, 0,    1,    0x65, 0x88, 0x84};
  assert(output == normalized);
  assert(parser.annexB(annex, sizeof(annex), output) && output == normalized);
  assert(!parser.annexB(broken, sizeof(broken), output) && output.empty());
  for (size_t n = 1; n < sizeof(avcc); ++n) assert(!parser.configure(IHS_StreamVideoCodecH264, avcc, n));
  assert(!parser.configure(9, nullptr, 0));
  assert(parser.configure(IHS_StreamVideoCodecHEVC, nullptr, 0));
  const uint8_t hevc[] = {0, 0, 1, 64, 1, 0x80, 0, 0, 1, 66, 1, 0x80, 0, 0, 1, 68, 1, 0x80, 0, 0, 1, 38, 1, 0x80};
  assert(parser.accessUnit(hevc, sizeof(hevc), output, changed) && parser.ready() && changed);
  assert(parser.annexB(hevc, sizeof(hevc), output));
  H26xParser roundTrip;
  assert(roundTrip.configure(IHS_StreamVideoCodecHEVC, nullptr, 0));
  std::vector<uint8_t> decoded;
  assert(roundTrip.accessUnit(output.data(), output.size(), decoded, changed));
  assert(roundTrip.parameters() == parser.parameters());
  assert((decoded == std::vector<uint8_t>{0, 0, 0, 3, 38, 1, 0x80}));
  const uint8_t badTemporal[] = {0, 0, 1, 38, 0, 0x80};
  assert(!parser.accessUnit(badTemporal, sizeof(badTemporal), output, changed));
  std::vector<uint8_t> many;
  for (int i = 0; i < 257; ++i) many.insert(many.end(), {0, 0, 1, 38, 1, 0x80});
  assert(!parser.accessUnit(many.data(), many.size(), output, changed));
  std::mt19937 rng(17);
  for (int i = 0; i < 10000; ++i) {
    std::vector<uint8_t> fuzz(rng() % 512);
    for (auto& b : fuzz) b = uint8_t(rng());
    parser.configure(i % 2 ? IHS_StreamVideoCodecH264 : IHS_StreamVideoCodecHEVC, fuzz.data(), fuzz.size());
    parser.accessUnit(fuzz.data(), fuzz.size(), output, changed);
    assert(output.size() <= 2 * 1024 * 1024 + 1024);
    parser.annexB(fuzz.data(), fuzz.size(), output);
    assert(output.size() <= 2 * 1024 * 1024 + 1024 + 3 * (65536 + 4));
  }
}
