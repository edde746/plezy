#pragma once

#define ANDROID_LOG_INFO 4
#define ANDROID_LOG_WARN 5

#ifdef __cplusplus
extern "C" {
#endif

int __android_log_print(int priority, const char* tag, const char* format, ...);

#ifdef __cplusplus
}
#endif
