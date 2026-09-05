#pragma once

#include <jni.h>

#include <string>

#define jni_func_name(name) Java_com_edde746_plezy_libmpv_MpvPlayer_##name
#define jni_func(return_type, name, ...) \
  JNIEXPORT return_type JNICALL jni_func_name(name)(JNIEnv * env, jobject obj, ##__VA_ARGS__)

bool acquire_jni_env(JavaVM* vm, JNIEnv** env);
void init_methods_cache(JNIEnv* env);

// Standard-UTF-8 string crossings; see utf8_convert.h for why NewStringUTF /
// GetStringUTFChars are wrong for mpv data. `utf8` may be NULL (-> NULL).
jstring new_java_string(JNIEnv* env, const char* utf8);
// `jstr` may be NULL (-> empty).
std::string java_string_to_utf8(JNIEnv* env, jstring jstr);

#ifndef UTIL_EXTERN
#define UTIL_EXTERN extern
#endif

UTIL_EXTERN jclass java_Integer, java_Double, java_Boolean;
UTIL_EXTERN jmethodID java_Integer_init, java_Double_init, java_Boolean_init;

UTIL_EXTERN jclass mpv_MpvPlayer;
UTIL_EXTERN jmethodID mpv_MpvPlayer_onPropertyChanged_SJZ, mpv_MpvPlayer_onPropertyChanged_SZJZ,
    mpv_MpvPlayer_onPropertyChanged_SJJZ, mpv_MpvPlayer_onPropertyChanged_SDJZ, mpv_MpvPlayer_onPropertyChanged_SSJZ,
    mpv_MpvPlayer_onEvent, mpv_MpvPlayer_onEndFile, mpv_MpvPlayer_onLogMessage, mpv_MpvPlayer_onHook;
