#include <android/log.h>
#include <jni.h>

#include <cstring>
#include <memory>
#include <new>
#include <vector>

#define TAG "DoviBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)

#if DOVI_REAL_LINKED
#include "include/libdovi/rpu_parser.h"
#endif

static const char* BRIDGE_VERSION = "1.0.0";
static constexpr jint CONVERT_FAILED = -1;
static constexpr jint DESTINATION_TOO_SMALL = -2;
static constexpr jint MAX_RPU_INPUT_SIZE = 8192;
static constexpr size_t MAX_RPU_OUTPUT_SIZE = 16384;
static constexpr int MAX_ERROR_LOG_LENGTH = 256;

extern "C" JNIEXPORT jint JNICALL Java_com_edde746_plezy_exoplayer_DoviBridge_nativeConvertDv7RpuToDv81(
    JNIEnv* env, jclass, jbyteArray payload, jint payload_offset, jint payload_length, jbyteArray output,
    jint output_offset, jint output_capacity, jint mode) {
#if !DOVI_REAL_LINKED
  return CONVERT_FAILED;
#else
  if (payload == nullptr || output == nullptr) return CONVERT_FAILED;
  if (payload_offset < 0 || payload_length <= 0 || output_offset < 0 || output_capacity < 0) {
    return CONVERT_FAILED;
  }

  const jsize payload_array_len = env->GetArrayLength(payload);
  const jsize output_array_len = env->GetArrayLength(output);
  if (payload_offset > payload_array_len || payload_length > payload_array_len - payload_offset) {
    return CONVERT_FAILED;
  }
  if (output_offset > output_array_len) return DESTINATION_TOO_SMALL;

  const jsize logical_output_len = output_capacity < output_array_len ? output_capacity : output_array_len;
  if (output_offset > logical_output_len) return DESTINATION_TOO_SMALL;

  // Valid RPU NALs are typically <2 KiB; reject unreasonable sizes
  if (payload_length > MAX_RPU_INPUT_SIZE) {
    LOGW("RPU payload too large (%d bytes), skipping", payload_length);
    return CONVERT_FAILED;
  }

  // Copy to native heap so libdovi never touches JVM heap memory.
  // Do not use GetPrimitiveArrayCritical here: it can block concurrent GC
  // compaction during sustained playback. A thread-local scratch buffer avoids
  // per-frame heap churn while keeping libdovi away from JVM heap memory.
  thread_local std::vector<uint8_t> scratch;
  try {
    scratch.resize(static_cast<size_t>(payload_length));
  } catch (...) {
    return CONVERT_FAILED;
  }

  env->GetByteArrayRegion(payload, payload_offset, payload_length, reinterpret_cast<jbyte*>(scratch.data()));
  if (env->ExceptionCheck()) {
    return CONVERT_FAILED;
  }

  // The input is a complete (possibly escaped) HEVC UNSPEC62 NAL. Parsing it as
  // a raw RPU after a framed-parser error can reinterpret malformed/truncated
  // NAL bytes as valid metadata.
  const auto rpu_len = static_cast<size_t>(payload_length);
  using RpuPtr = std::unique_ptr<DoviRpuOpaque, decltype(&dovi_rpu_free)>;
  RpuPtr rpu(dovi_parse_unspec62_nalu(scratch.data(), rpu_len), dovi_rpu_free);

  if (rpu == nullptr) {
    return CONVERT_FAILED;
  }

  const char* err = dovi_rpu_get_error(rpu.get());
  if (err != nullptr) {
    LOGW("RPU NAL parse failed: %.*s", MAX_ERROR_LOG_LENGTH, err);
    return CONVERT_FAILED;
  }

  // Mode 2 matches Kodi's P8.1 compatibility path and sets luma/chroma curves to no-op.
  int32_t ret = dovi_convert_rpu_with_mode(rpu.get(), static_cast<uint8_t>(mode));
  if (ret != 0) {
    err = dovi_rpu_get_error(rpu.get());
    LOGW("RPU conversion failed (mode %d): %.*s", mode, MAX_ERROR_LOG_LENGTH, err ? err : "unknown");
    return CONVERT_FAILED;
  }

  // Write back as UNSPEC62 NAL
  using DoviDataPtr = std::unique_ptr<const DoviData, decltype(&dovi_data_free)>;
  DoviDataPtr out(dovi_write_unspec62_nalu(rpu.get()), dovi_data_free);
  if (out == nullptr || out->data == nullptr || out->len == 0) {
    err = dovi_rpu_get_error(rpu.get());
    LOGW("RPU write failed: %.*s", MAX_ERROR_LOG_LENGTH, err ? err : "unknown");
    return CONVERT_FAILED;
  }

  if (out->len > MAX_RPU_OUTPUT_SIZE) {
    LOGW("RPU output unexpectedly large (%zu bytes), discarding", out->len);
    return CONVERT_FAILED;
  }

  const auto writable = static_cast<size_t>(logical_output_len - output_offset);
  if (out->len > writable) {
    return DESTINATION_TOO_SMALL;
  }

  env->SetByteArrayRegion(
      output, output_offset, static_cast<jsize>(out->len), reinterpret_cast<const jbyte*>(out->data));
  const bool write_failed = env->ExceptionCheck();
  const auto written = static_cast<jint>(out->len);

  return write_failed ? CONVERT_FAILED : written;
#endif
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_edde746_plezy_exoplayer_DoviBridge_nativeIsConversionPathReady(JNIEnv*, jclass) {
#if DOVI_REAL_LINKED
  return JNI_TRUE;
#else
  return JNI_FALSE;
#endif
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_edde746_plezy_exoplayer_DoviBridge_nativeGetBridgeVersion(JNIEnv* env, jclass) {
  return env->NewStringUTF(BRIDGE_VERSION);
}
