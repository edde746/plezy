// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace plezy::steam {
// Converts a bounded Annex-B access unit into the length-prefixed form required
// by VideoToolbox. Parameter sets may arrive in codec data or in-band. No NAL
// bytes are interpreted as paths, commands or container metadata.
class H26xParser {
 public:
  // IHS wire codec identifiers: H.264 = 4, HEVC = 5.
  bool configure(int codec, const uint8_t* bytes, size_t length);
  bool accessUnit(const uint8_t* bytes, size_t length, std::vector<uint8_t>& output, bool& changed);
  bool ready() const;
  int codec() const { return codec_; }
  const std::array<std::vector<uint8_t>, 3>& parameters() const { return parameters_; }
 private:
  bool nal(const uint8_t*, size_t, std::vector<uint8_t>*, bool& changed, bool& picture);
  bool split(const uint8_t*, size_t, std::vector<uint8_t>*, bool& changed, bool& picture);
  int codec_ = 0, lengthSize_ = 0;
  std::array<std::vector<uint8_t>, 3> parameters_;
};
} // namespace plezy::steam
