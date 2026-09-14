#pragma once

#include <android/log.h>

#define LOG_TAG "mpv"
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

void die(const char* msg);
