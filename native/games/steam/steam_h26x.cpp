// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_h26x.h"

#include <algorithm>

namespace plezy::steam {
namespace {
constexpr size_t maxUnit = 2 * 1024 * 1024, maxParameter = 65536;
size_t prefix(const uint8_t* b, size_t n, size_t i) {
  if (n - i >= 3 && b[i] == 0 && b[i + 1] == 0) {
    if (b[i + 2] == 1) return 3;
    if (n - i >= 4 && b[i + 2] == 0 && b[i + 3] == 1) return 4;
  }
  return 0;
}
uint16_t be16(const uint8_t* b) { return uint16_t((uint16_t(b[0]) << 8) | b[1]); }
}  // namespace
bool H26xParser::nal(const uint8_t* b, size_t n, std::vector<uint8_t>* out, bool& changed, bool& picture) {
  if (!b || n == 0 || n > maxUnit || (b[0] & 0x80)) return false;
  const int type = codec_ == 4 ? b[0] & 31 : (b[0] >> 1) & 63;
  if (codec_ == 5 && (n < 2 || (b[1] & 7) == 0 || (b[0] & 1) || (b[1] & 0xf8))) return false;
  if (codec_ == 4 && (type == 0 || type >= 24)) return false;
  const int parameter = codec_ == 4 ? (type == 7   ? 0
                                       : type == 8 ? 1
                                                   : -1)
                                    : (type >= 32 && type <= 34 ? type - 32 : -1);
  if (parameter >= 0) {
    if (n > maxParameter) return false;
    auto& stored = parameters_[parameter];
    if (stored.size() != n || !std::equal(stored.begin(), stored.end(), b)) {
      stored.assign(b, b + n);
      changed = true;
    }
    return true;
  }
  if ((codec_ == 4 && type >= 1 && type <= 5) || (codec_ == 5 && type <= 31)) picture = true;
  if (out) {
    if (out->size() + n + 4 > maxUnit + 1024) return false;
    for (int shift : {24, 16, 8, 0}) out->push_back(uint8_t(n >> shift));
    out->insert(out->end(), b, b + n);
  }
  return true;
}
bool H26xParser::split(const uint8_t* b, size_t n, std::vector<uint8_t>* out, bool& changed, bool& picture) {
  if (!b || !n || n > maxUnit || !codec_) return false;
  size_t count = 0, offset = 0;
  // Annex-B takes precedence even when an avcC/hvcC record supplied a length size.
  if (prefix(b, n, 0)) {
    while (offset < n) {
      if (++count > 256) return false;
      const size_t p = prefix(b, n, offset);
      if (!p) return false;
      const size_t begin = offset + p;
      offset = begin;
      while (offset < n && !prefix(b, n, offset)) ++offset;
      size_t end = offset;
      while (end > begin && b[end - 1] == 0) --end;  // Annex-B trailing_zero_8bits.
      if (!nal(b + begin, end - begin, out, changed, picture)) return false;
    }
  } else {
    if (!lengthSize_) return false;
    while (offset < n) {
      if (++count > 256 || n - offset < size_t(lengthSize_)) return false;
      uint32_t size = 0;
      for (int i = 0; i < lengthSize_; ++i) size = (size << 8) | b[offset++];
      if (size == 0 || size > n - offset || !nal(b + offset, size, out, changed, picture)) return false;
      offset += size;
    }
  }
  return count != 0;
}
bool H26xParser::configure(int codec, const uint8_t* b, size_t n) {
  codec_ = 0;
  lengthSize_ = 0;
  for (auto& p : parameters_) p.clear();
  if ((codec != 4 && codec != 5) || n > maxParameter || (n && !b)) return false;
  codec_ = codec;
  if (n == 0) return true;
  bool changed = false, picture = false, valid = true;
  if (b[0] != 1)
    valid = split(b, n, nullptr, changed, picture);
  else if (codec == 4) {
    if (n < 7 || (b[4] & 3) == 2)
      valid = false;
    else {
      lengthSize_ = (b[4] & 3) + 1;
      size_t offset = 6;
      for (int group = 0; group < 2 && valid; ++group) {
        if (group && offset >= n) {
          valid = false;
          break;
        }
        size_t count = group == 0 ? b[5] & 31 : b[offset++];
        if (count > 32) {
          valid = false;
          break;
        }
        for (size_t i = 0; i < count && valid; ++i) {
          if (n - offset < 2) {
            valid = false;
            break;
          }
          const size_t size = be16(b + offset);
          offset += 2;
          if (!size || size > n - offset || (b[offset] & 31) != (group == 0 ? 7 : 8)) {
            valid = false;
            break;
          }
          valid = nal(b + offset, size, nullptr, changed, picture);
          offset += size;
        }
      }
      // Optional high-profile avcC extension bytes aren't needed by the decoder.
      valid = valid && ready();
    }
  } else {
    if (n < 23 || (b[21] & 3) == 2 || b[22] > 16)
      valid = false;
    else {
      lengthSize_ = (b[21] & 3) + 1;
      size_t offset = 23;
      for (size_t group = 0; group < b[22] && valid; ++group) {
        if (n - offset < 3) {
          valid = false;
          break;
        }
        int type = b[offset++] & 63;
        size_t count = be16(b + offset);
        offset += 2;
        if (count > 32) {
          valid = false;
          break;
        }
        for (size_t i = 0; i < count && valid; ++i) {
          if (n - offset < 2) {
            valid = false;
            break;
          }
          size_t size = be16(b + offset);
          offset += 2;
          if (!size || size > n - offset || ((b[offset] >> 1) & 63) != type) {
            valid = false;
            break;
          }
          valid = nal(b + offset, size, nullptr, changed, picture);
          offset += size;
        }
      }
      valid = valid && offset == n && ready();
    }
  }
  if (!valid) {
    codec_ = 0;
    for (auto& p : parameters_) p.clear();
  }
  return valid;
}
bool H26xParser::ready() const {
  return codec_ && !parameters_[0].empty() && !parameters_[1].empty() && (codec_ != 5 || !parameters_[2].empty());
}
bool H26xParser::accessUnit(const uint8_t* b, size_t n, std::vector<uint8_t>& out, bool& changed) {
  out.clear();
  changed = false;
  bool picture = false;
  // Malformed packets must not partially replace the active parameter sets.
  auto before = parameters_;
  if (!split(b, n, &out, changed, picture)) {
    parameters_ = std::move(before);
    out.clear();
    changed = false;
    return false;
  }
  if (!picture) out.clear();
  return true;
}
}  // namespace plezy::steam
