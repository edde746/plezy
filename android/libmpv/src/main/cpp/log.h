#pragma once

#include <android/log.h>

#define LOG_TAG "mpv"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

void die(const char* msg);

#define CHECK_MPV_INIT()                \
  do {                                  \
    if (__builtin_expect(!g_mpv, 0)) {  \
      die("libmpv is not initialized"); \
      return;                           \
    }                                   \
  } while (0)

#define CHECK_MPV_INIT_RET(val)         \
  do {                                  \
    if (__builtin_expect(!g_mpv, 0)) {  \
      die("libmpv is not initialized"); \
      return val;                       \
    }                                   \
  } while (0)
