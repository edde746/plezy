#include <jni.h>
#include <android/log.h>
#include <cstring>

#define TAG "DoviBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)

#if DOVI_REAL_LINKED
#include "include/libdovi/rpu_parser.h"
#endif

static const char* BRIDGE_VERSION = "1.0.0";

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_edde746_plezy_exoplayer_DoviBridge_nativeConvertDv7RpuToDv81(
    JNIEnv *env, jclass, jbyteArray payload, jint mode) {
#if !DOVI_REAL_LINKED
    return nullptr;
#else
    if (payload == nullptr) return nullptr;

    jsize len = env->GetArrayLength(payload);
    if (len <= 0) return nullptr;

    jbyte *buf = env->GetByteArrayElements(payload, nullptr);
    if (buf == nullptr) return nullptr;

    // Try dovi_parse_unspec62_nalu first (handles escaped NALs), fallback to dovi_parse_rpu
    DoviRpuOpaque *rpu = dovi_parse_unspec62_nalu(
        reinterpret_cast<const uint8_t *>(buf), static_cast<size_t>(len));

    if (rpu == nullptr) {
        env->ReleaseByteArrayElements(payload, buf, JNI_ABORT);
        return nullptr;
    }

    const char *err = dovi_rpu_get_error(rpu);
    if (err != nullptr) {
        // Fallback: try dovi_parse_rpu (raw RPU without NAL framing)
        dovi_rpu_free(rpu);
        rpu = dovi_parse_rpu(
            reinterpret_cast<const uint8_t *>(buf), static_cast<size_t>(len));
        if (rpu == nullptr) {
            env->ReleaseByteArrayElements(payload, buf, JNI_ABORT);
            return nullptr;
        }
        err = dovi_rpu_get_error(rpu);
        if (err != nullptr) {
            LOGW("RPU parse failed: %s", err);
            dovi_rpu_free(rpu);
            env->ReleaseByteArrayElements(payload, buf, JNI_ABORT);
            return nullptr;
        }
    }

    env->ReleaseByteArrayElements(payload, buf, JNI_ABORT);

    // Convert to target profile (mode 2 = P8.1 with no-op curves)
    int32_t ret = dovi_convert_rpu_with_mode(rpu, static_cast<uint8_t>(mode));
    if (ret != 0) {
        err = dovi_rpu_get_error(rpu);
        LOGW("RPU conversion failed (mode %d): %s", mode, err ? err : "unknown");
        dovi_rpu_free(rpu);
        return nullptr;
    }

    // Write back as UNSPEC62 NAL
    const DoviData *out = dovi_write_unspec62_nalu(rpu);
    if (out == nullptr || out->data == nullptr || out->len == 0) {
        err = dovi_rpu_get_error(rpu);
        LOGW("RPU write failed: %s", err ? err : "unknown");
        if (out != nullptr) dovi_data_free(out);
        dovi_rpu_free(rpu);
        return nullptr;
    }

    jbyteArray result = env->NewByteArray(static_cast<jsize>(out->len));
    if (result != nullptr) {
        env->SetByteArrayRegion(result, 0, static_cast<jsize>(out->len),
            reinterpret_cast<const jbyte *>(out->data));
    }

    dovi_data_free(out);
    dovi_rpu_free(rpu);

    return result;
#endif
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_edde746_plezy_exoplayer_DoviBridge_nativeIsConversionPathReady(
    JNIEnv *, jclass) {
#if DOVI_REAL_LINKED
    return JNI_TRUE;
#else
    return JNI_FALSE;
#endif
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_edde746_plezy_exoplayer_DoviBridge_nativeGetBridgeVersion(
    JNIEnv *env, jclass) {
    return env->NewStringUTF(BRIDGE_VERSION);
}
