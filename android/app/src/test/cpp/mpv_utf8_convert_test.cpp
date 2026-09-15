#include <cstdio>
#include <string>

#include "../../../../libmpv/src/main/cpp/utf8_convert.h"

namespace {

using plezy::utf8::FromUtf16;
using plezy::utf8::ToUtf16;

bool check(bool condition, const char* message) {
  if (!condition) std::fprintf(stderr, "%s\n", message);
  return condition;
}

bool roundTripsAsciiBmpAndSupplementary() {
  // "a" U+00E9 U+4E2D U+1F3AC (clapper board) — 1/2/3/4-byte sequences.
  const std::string utf8 = "a\xC3\xA9\xE4\xB8\xAD\xF0\x9F\x8E\xAC";
  const std::u16string utf16 = ToUtf16(utf8.c_str());
  return check(utf16 == u"a\u00E9\u4E2D\U0001F3AC", "UTF-8 -> UTF-16 mismatch") &&
         check(FromUtf16(utf16.data(), utf16.size()) == utf8, "UTF-16 -> UTF-8 mismatch");
}

bool doesNotEmitModifiedUtf8() {
  // JNI's modified UTF-8 would encode U+1F3AC as a 6-byte CESU-8 surrogate
  // pair; mpv/open() need the real 4-byte form.
  const std::u16string clapper = u"\U0001F3AC";
  return check(FromUtf16(clapper.data(), clapper.size()) == "\xF0\x9F\x8E\xAC", "supplementary char not 4 bytes") &&
         check(
             ToUtf16("\xED\xA0\xBC\xED\xBE\xAC") == u"\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD",
             "CESU-8 surrogate bytes accepted as UTF-8");
}

bool replacesMalformedBytesOneAtATime() {
  return check(ToUtf16("ok\xFF\xFEz") == u"ok\uFFFD\uFFFDz", "stray bytes not replaced individually") &&
         check(ToUtf16("\xC0\x80") == u"\uFFFD\uFFFD", "overlong NUL accepted") &&
         check(ToUtf16("\xE2\x82") == u"\uFFFD\uFFFD", "truncated sequence not replaced") &&
         check(ToUtf16("\xF4\x90\x80\x80") == u"\uFFFD\uFFFD\uFFFD\uFFFD", "code point above U+10FFFF accepted") &&
         check(ToUtf16("\xE0\x80\xAF") == u"\uFFFD\uFFFD\uFFFD", "overlong 3-byte form accepted");
}

bool replacesLoneSurrogates() {
  const std::u16string lone = u"x\xD83Cy\xDFACz";
  return check(FromUtf16(lone.data(), lone.size()) == "x\xEF\xBF\xBDy\xEF\xBF\xBDz", "lone surrogates not replaced");
}

bool handlesNullAndEmpty() {
  return check(ToUtf16(nullptr).empty(), "NULL input not empty") &&
         check(ToUtf16("").empty(), "empty input not empty") &&
         check(FromUtf16(nullptr, 0).empty(), "NULL UTF-16 not empty");
}

}  // namespace

int main() {
  const bool ok = roundTripsAsciiBmpAndSupplementary() && doesNotEmitModifiedUtf8() &&
                  replacesMalformedBytesOneAtATime() && replacesLoneSurrogates() && handlesNullAndEmpty();
  return ok ? 0 : 1;
}
