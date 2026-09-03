#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

// UTF-8 <-> UTF-16 transcoding for the JNI boundary.
//
// mpv speaks standard UTF-8. JNI's NewStringUTF/GetStringUTFChars speak
// *modified* UTF-8: supplementary-plane characters are CESU-8 surrogate pairs
// and NUL is 0xC0 0x80. Feeding one encoding to the other corrupts emoji in
// file names and titles, and malformed bytes from mpv (log lines, ID3 tags,
// system-encoded paths) abort under CheckJNI. Both directions therefore go
// through UTF-16 with NewString/GetStringChars; malformed input is replaced
// with U+FFFD one unit at a time, matching shared/cpp/sanitize_utf8.h on
// desktop. Header-only and JNI-free so the host test harness can exercise it.

namespace plezy {
namespace utf8 {

// Decodes one scalar value at `s`. Returns the number of bytes consumed, or 0
// when `s` does not start a well-formed sequence (Unicode Table 3-7).
inline size_t DecodeOne(const unsigned char* s, size_t len, uint32_t* cp) {
  const unsigned char c = s[0];
  if (c < 0x80) {
    *cp = c;
    return 1;
  }
  size_t need;
  unsigned char lo = 0x80, hi = 0xBF;
  if (c >= 0xC2 && c <= 0xDF) {
    need = 2;
    *cp = c & 0x1F;
  } else if (c >= 0xE0 && c <= 0xEF) {
    need = 3;
    *cp = c & 0x0F;
    if (c == 0xE0) lo = 0xA0;
    if (c == 0xED) hi = 0x9F;  // no surrogates
  } else if (c >= 0xF0 && c <= 0xF4) {
    need = 4;
    *cp = c & 0x07;
    if (c == 0xF0) lo = 0x90;
    if (c == 0xF4) hi = 0x8F;  // <= U+10FFFF
  } else {
    return 0;
  }
  if (len < need) return 0;
  for (size_t i = 1; i < need; ++i) {
    const unsigned char b = s[i];
    if (b < lo || b > hi) return 0;
    lo = 0x80;
    hi = 0xBF;
    *cp = (*cp << 6) | (b & 0x3F);
  }
  return need;
}

// Standard UTF-8 -> UTF-16. Malformed bytes become U+FFFD.
inline std::u16string ToUtf16(const char* input, size_t len) {
  std::u16string out;
  if (!input) return out;
  out.reserve(len);
  const unsigned char* s = reinterpret_cast<const unsigned char*>(input);
  size_t pos = 0;
  while (pos < len) {
    uint32_t cp;
    const size_t n = DecodeOne(s + pos, len - pos, &cp);
    if (n == 0) {
      out.push_back(u'\uFFFD');
      pos += 1;
      continue;
    }
    pos += n;
    if (cp < 0x10000) {
      out.push_back(static_cast<char16_t>(cp));
    } else {
      cp -= 0x10000;
      out.push_back(static_cast<char16_t>(0xD800 | (cp >> 10)));
      out.push_back(static_cast<char16_t>(0xDC00 | (cp & 0x3FF)));
    }
  }
  return out;
}

inline std::u16string ToUtf16(const char* input) {
  return input ? ToUtf16(input, std::char_traits<char>::length(input)) : std::u16string();
}

// UTF-16 -> standard UTF-8. Lone surrogates become U+FFFD.
inline std::string FromUtf16(const char16_t* input, size_t len) {
  std::string out;
  if (!input) return out;
  out.reserve(len * 3);
  for (size_t i = 0; i < len; ++i) {
    uint32_t cp = input[i];
    if (cp >= 0xD800 && cp <= 0xDBFF) {
      if (i + 1 < len && input[i + 1] >= 0xDC00 && input[i + 1] <= 0xDFFF) {
        cp = 0x10000 + ((cp - 0xD800) << 10) + (input[i + 1] - 0xDC00);
        ++i;
      } else {
        cp = 0xFFFD;
      }
    } else if (cp >= 0xDC00 && cp <= 0xDFFF) {
      cp = 0xFFFD;
    }
    if (cp < 0x80) {
      out.push_back(static_cast<char>(cp));
    } else if (cp < 0x800) {
      out.push_back(static_cast<char>(0xC0 | (cp >> 6)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
      out.push_back(static_cast<char>(0xE0 | (cp >> 12)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
      out.push_back(static_cast<char>(0xF0 | (cp >> 18)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      out.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
  }
  return out;
}

}  // namespace utf8
}  // namespace plezy
