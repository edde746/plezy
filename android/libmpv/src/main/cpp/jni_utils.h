#pragma once

#include <jni.h>

#define jni_func_name(name) Java_com_edde746_plezy_libmpv_MpvPlayer_##name
#define jni_func(return_type, name, ...) \
  JNIEXPORT return_type JNICALL jni_func_name(name)(JNIEnv * env, jobject obj, ##__VA_ARGS__)

bool acquire_jni_env(JavaVM* vm, JNIEnv** env);
void init_methods_cache(JNIEnv* env);

#ifndef UTIL_EXTERN
#define UTIL_EXTERN extern
#endif

UTIL_EXTERN jclass java_Integer, java_Double, java_Boolean;
UTIL_EXTERN jmethodID java_Integer_init, java_Double_init, java_Boolean_init;

UTIL_EXTERN jclass mpv_MpvPlayer;
UTIL_EXTERN jmethodID mpv_MpvPlayer_onPropertyChanged_S, mpv_MpvPlayer_onPropertyChanged_Sb,
    mpv_MpvPlayer_onPropertyChanged_Sl, mpv_MpvPlayer_onPropertyChanged_Sd, mpv_MpvPlayer_onPropertyChanged_SS,
    mpv_MpvPlayer_onEvent, mpv_MpvPlayer_onEndFile, mpv_MpvPlayer_onLogMessage;
