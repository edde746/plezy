#include "../../main/cpp/media3_ffmpeg_decoder/ffmpeg_audio_buffer.h"

#include <climits>
#include <cstdio>

namespace {

bool check(bool condition, const char* message) {
  if (!condition) std::fprintf(stderr, "%s\n", message);
  return condition;
}

bool computesPackedPcmSizes() {
  int bytes = -1;
  return check(plezy::ffmpeg::CheckedAudioByteCount(1024, 2, 2, &bytes), "stereo PCM size rejected") &&
         check(bytes == 4096, "wrong stereo PCM size") &&
         check(plezy::ffmpeg::CheckedAudioByteCount(1024, 6, 4, &bytes), "5.1 float PCM size rejected") &&
         check(bytes == 24576, "wrong 5.1 float PCM size") &&
         check(plezy::ffmpeg::CheckedAudioByteCount(1024, 8, 2, &bytes), "7.1 PCM size rejected") &&
         check(bytes == 16384, "wrong 7.1 PCM size");
}

bool usesConvertedSampleCount() {
  int capacity = -1;
  int written = -1;
  return check(plezy::ffmpeg::CheckedAudioByteCount(2048, 6, 2, &capacity), "output capacity rejected") &&
         check(plezy::ffmpeg::CheckedAudioByteCount(1536, 6, 2, &written), "converted sample count rejected") &&
         check(capacity == 24576, "wrong output capacity") && check(written == 18432, "wrong converted byte count") &&
         check(written < capacity, "converted bytes must not equal an unused upper bound");
}

bool rejectsInvalidAndOverflowingSizes() {
  int bytes = 7;
  const int largestSafeStereoSampleCount = INT_MAX / 4;
  return check(!plezy::ffmpeg::CheckedAudioByteCount(-1, 2, 2, &bytes), "negative samples accepted") &&
         check(!plezy::ffmpeg::CheckedAudioByteCount(1, 0, 2, &bytes), "zero channels accepted") &&
         check(!plezy::ffmpeg::CheckedAudioByteCount(1, 2, 0, &bytes), "zero sample size accepted") &&
         check(
             !plezy::ffmpeg::CheckedAudioByteCount(largestSafeStereoSampleCount + 1, 2, 2, &bytes),
             "multiplication overflow accepted") &&
         check(!plezy::ffmpeg::CheckedAddByteCount(INT_MAX, 1, &bytes), "addition overflow accepted") &&
         check(!plezy::ffmpeg::CheckedAddByteCount(-1, 1, &bytes), "negative accumulated size accepted");
}

bool acceptsEmptyOutputAndIntBoundary() {
  int bytes = -1;
  int total = -1;
  return check(plezy::ffmpeg::CheckedAudioByteCount(0, 8, 4, &bytes), "empty output rejected") &&
         check(bytes == 0, "empty output is not zero bytes") &&
         check(plezy::ffmpeg::CheckedAddByteCount(INT_MAX - 4, 4, &total), "INT_MAX boundary rejected") &&
         check(total == INT_MAX, "wrong INT_MAX boundary sum");
}

}  // namespace

int main() {
  struct TestCase {
    const char* name;
    bool (*run)();
  };
  const TestCase tests[] = {
      {"packed PCM sizes", computesPackedPcmSizes},
      {"converted sample count", usesConvertedSampleCount},
      {"invalid and overflowing sizes", rejectsInvalidAndOverflowingSizes},
      {"empty output and boundary", acceptsEmptyOutputAndIntBoundary},
  };

  for (const TestCase& test : tests) {
    if (!test.run()) {
      std::fprintf(stderr, "FAILED: %s\n", test.name);
      return 1;
    }
  }
  std::printf("Passed %zu ffmpeg_audio_buffer tests\n", sizeof(tests) / sizeof(tests[0]));
  return 0;
}
