#include <cstdarg>
#include <cstdio>
#include <string>
#include <vector>

#define DOVI_REAL_LINKED 1
#include "../../main/cpp/dovi_bridge.cpp"

struct DoviRpuOpaque {
  std::string error;
};

enum class ParseResult { kValid, kError, kNull };
enum class WriteResult { kValid, kNull, kEmpty, kOversized };

static ParseResult parse_result;
static WriteResult write_result;
static int conversion_result;
static std::string parser_error;
static std::string last_log;
static std::vector<uint8_t> last_unspec_input;
static std::vector<uint8_t> encoded_output;
static int unspec_parse_calls;
static int raw_parse_calls;
static int conversion_calls;
static int write_calls;
static int rpu_free_calls;
static int data_free_calls;

extern "C" int __android_log_print(int, const char*, const char* format, ...) {
  char buffer[2048];
  va_list args;
  va_start(args, format);
  std::vsnprintf(buffer, sizeof(buffer), format, args);
  va_end(args);
  last_log = buffer;
  return static_cast<int>(last_log.size());
}

extern "C" DoviRpuOpaque* dovi_parse_unspec62_nalu(const uint8_t* data, size_t len) {
  ++unspec_parse_calls;
  last_unspec_input.assign(data, data + len);
  if (parse_result == ParseResult::kNull) return nullptr;
  return new DoviRpuOpaque{parse_result == ParseResult::kError ? parser_error : ""};
}

// A raw parse deliberately succeeds so the malformed-NAL test detects any
// regression that retries framed input through dovi_parse_rpu.
extern "C" DoviRpuOpaque* dovi_parse_rpu(const uint8_t*, size_t) {
  ++raw_parse_calls;
  return new DoviRpuOpaque{};
}

extern "C" const char* dovi_rpu_get_error(const DoviRpuOpaque* rpu) {
  return rpu->error.empty() ? nullptr : rpu->error.c_str();
}

extern "C" void dovi_rpu_free(DoviRpuOpaque* rpu) {
  ++rpu_free_calls;
  delete rpu;
}

extern "C" int32_t dovi_convert_rpu_with_mode(DoviRpuOpaque* rpu, uint8_t) {
  ++conversion_calls;
  if (conversion_result != 0) rpu->error = "conversion error";
  return conversion_result;
}

extern "C" const DoviData* dovi_write_unspec62_nalu(DoviRpuOpaque*) {
  ++write_calls;
  if (write_result == WriteResult::kNull) return nullptr;
  if (write_result == WriteResult::kEmpty) return new DoviData{nullptr, 0};

  const size_t len = write_result == WriteResult::kOversized ? MAX_RPU_OUTPUT_SIZE + 1 : encoded_output.size();
  auto* bytes = new uint8_t[len];
  for (size_t i = 0; i < len; ++i) {
    bytes[i] = write_result == WriteResult::kOversized ? 0 : encoded_output[i];
  }
  return new DoviData{bytes, len};
}

extern "C" void dovi_data_free(const DoviData* data) {
  ++data_free_calls;
  delete[] data->data;
  delete data;
}

static void resetFakes() {
  parse_result = ParseResult::kValid;
  write_result = WriteResult::kValid;
  conversion_result = 0;
  parser_error.clear();
  last_log.clear();
  last_unspec_input.clear();
  encoded_output = {0x7c, 0x01, 0x19, 0x08, 0x55};
  unspec_parse_calls = 0;
  raw_parse_calls = 0;
  conversion_calls = 0;
  write_calls = 0;
  rpu_free_calls = 0;
  data_free_calls = 0;
}

static _jbyteArray byteArray(const std::vector<uint8_t>& bytes) {
  _jbyteArray array;
  array.bytes.reserve(bytes.size());
  for (uint8_t byte : bytes) array.bytes.push_back(static_cast<jbyte>(byte));
  return array;
}

static jint convert(
    JNIEnv& env, _jbyteArray& payload, _jbyteArray& output, jint output_offset = 0, jint output_capacity = -1) {
  if (output_capacity < 0) output_capacity = static_cast<jint>(output.bytes.size());
  return Java_com_edde746_plezy_exoplayer_DoviBridge_nativeConvertDv7RpuToDv81(
      &env, nullptr, &payload, 0, static_cast<jint>(payload.bytes.size()), &output, output_offset, output_capacity, 2);
}

#define CHECK(condition)                                                                 \
  do {                                                                                   \
    if (!(condition)) {                                                                  \
      std::fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__, #condition); \
      return false;                                                                      \
    }                                                                                    \
  } while (false)

static bool validUnspec62NalConvertsAndFreesAllocations() {
  resetFakes();
  const std::vector<uint8_t> framed_nal = {0x7c, 0x01, 0x19, 0x08, 0x22};
  auto payload = byteArray(framed_nal);
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;

  const jint result = convert(env, payload, output, 2);

  CHECK(result == static_cast<jint>(encoded_output.size()));
  CHECK(last_unspec_input == framed_nal);
  CHECK(raw_parse_calls == 0);
  CHECK(unspec_parse_calls == 1);
  CHECK(conversion_calls == 1);
  CHECK(write_calls == 1);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 1);
  for (size_t i = 0; i < encoded_output.size(); ++i) {
    CHECK(static_cast<uint8_t>(output.bytes[i + 2]) == encoded_output[i]);
  }
  return true;
}

static bool malformedTruncatedNalFailsWithoutRawFallback() {
  resetFakes();
  parse_result = ParseResult::kError;
  parser_error.assign(2048, 'x');
  auto payload = byteArray({0x7c, 0x01, 0x19});
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;

  const jint result = convert(env, payload, output);

  CHECK(result == CONVERT_FAILED);
  CHECK(unspec_parse_calls == 1);
  CHECK(raw_parse_calls == 0);
  CHECK(conversion_calls == 0);
  CHECK(write_calls == 0);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 0);
  const std::string prefix = "RPU NAL parse failed: ";
  CHECK(last_log == prefix + std::string(MAX_ERROR_LOG_LENGTH, 'x'));
  return true;
}

static bool nullParserResultFailsWithoutFreeingNonexistentAllocation() {
  resetFakes();
  parse_result = ParseResult::kNull;
  auto payload = byteArray({0x7c, 0x01});
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;

  CHECK(convert(env, payload, output) == CONVERT_FAILED);
  CHECK(raw_parse_calls == 0);
  CHECK(rpu_free_calls == 0);
  CHECK(data_free_calls == 0);
  return true;
}

static bool conversionFailureFreesRpu() {
  resetFakes();
  conversion_result = -1;
  auto payload = byteArray({0x7c, 0x01, 0x19, 0x08});
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;

  CHECK(convert(env, payload, output) == CONVERT_FAILED);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 0);
  return true;
}

static bool unusableWriterResultFreesBothAllocations() {
  resetFakes();
  write_result = WriteResult::kEmpty;
  auto payload = byteArray({0x7c, 0x01, 0x19, 0x08});
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;

  CHECK(convert(env, payload, output) == CONVERT_FAILED);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 1);
  return true;
}

static bool destinationTooSmallFreesBothAllocations() {
  resetFakes();
  auto payload = byteArray({0x7c, 0x01, 0x19, 0x08});
  auto output = byteArray(std::vector<uint8_t>(4, 0));
  JNIEnv env;

  CHECK(convert(env, payload, output) == DESTINATION_TOO_SMALL);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 1);
  return true;
}

static bool jniWriteFailureFreesBothAllocations() {
  resetFakes();
  auto payload = byteArray({0x7c, 0x01, 0x19, 0x08});
  auto output = byteArray(std::vector<uint8_t>(16, 0));
  JNIEnv env;
  env.fail_next_write = true;

  CHECK(convert(env, payload, output) == CONVERT_FAILED);
  CHECK(rpu_free_calls == 1);
  CHECK(data_free_calls == 1);
  return true;
}

int main() {
  struct TestCase {
    const char* name;
    bool (*run)();
  };
  const TestCase tests[] = {
      {"valid conversion", validUnspec62NalConvertsAndFreesAllocations},
      {"malformed truncated NAL", malformedTruncatedNalFailsWithoutRawFallback},
      {"null parser result", nullParserResultFailsWithoutFreeingNonexistentAllocation},
      {"conversion failure", conversionFailureFreesRpu},
      {"unusable writer result", unusableWriterResultFreesBothAllocations},
      {"destination too small", destinationTooSmallFreesBothAllocations},
      {"JNI write failure", jniWriteFailureFreesBothAllocations},
  };

  for (const TestCase& test : tests) {
    if (!test.run()) {
      std::fprintf(stderr, "FAILED: %s\n", test.name);
      return 1;
    }
  }
  std::printf("Passed %zu dovi_bridge tests\n", sizeof(tests) / sizeof(tests[0]));
  return 0;
}
