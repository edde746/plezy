#ifndef SANITIZE_UTF8_H_
#define SANITIZE_UTF8_H_

#include <cstring>
#include <string>
#include <simdutf.h>

// Sanitize a C string that may contain invalid UTF-8 sequences.
// Uses simdutf for SIMD-accelerated validation (fast path for valid strings),
// then falls back to iterative replacement with U+FFFD on the rare invalid case.
// mpv does not guarantee UTF-8 for log messages, error strings, or
// system-encoded paths — sending these unsanitized through Flutter's
// StandardMessageCodec causes FormatException crashes.
static inline std::string SanitizeUtf8(const char* input) {
  if (!input) return std::string();
  size_t len = strlen(input);
  if (len == 0) return std::string();

  // Fast path: SIMD-accelerated validation — almost all strings pass this
  if (simdutf::validate_utf8(input, len)) {
    return std::string(input, len);
  }

  // Slow path: find each invalid position, copy valid prefix, insert U+FFFD,
  // skip the bad byte, and repeat.
  std::string result;
  result.reserve(len);
  size_t pos = 0;

  while (pos < len) {
    auto r = simdutf::validate_utf8_with_errors(input + pos, len - pos);
    // Copy the valid prefix up to the error
    if (r.count > 0) {
      result.append(input + pos, r.count);
    }
    pos += r.count;
    if (r.error == simdutf::error_code::SUCCESS) {
      break;  // remaining tail is valid
    }
    // Replace the invalid byte with U+FFFD and skip it
    result.append("\xEF\xBF\xBD");
    pos++;
  }

  return result;
}

#endif  // SANITIZE_UTF8_H_
