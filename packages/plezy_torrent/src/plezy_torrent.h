#pragma once
#include <stdint.h>
#if defined(_WIN32)
#define PT_EXPORT __declspec(dllexport)
#else
#define PT_EXPORT __attribute__((visibility("default")))
#endif
#ifdef __cplusplus
extern "C" {
#endif
// All calls for a handle belong to one isolate. No exceptions cross this ABI.
// read: -2 = waiting for verified data, -1 = failure, 0 = EOF.
PT_EXPORT int32_t pt_abi_version(void);
PT_EXPORT void* pt_open(const char* magnet, const char* directory, int32_t file_index,
                        int64_t quota_bytes, int32_t upload_bytes_per_second);
PT_EXPORT int64_t pt_size(void* handle);
PT_EXPORT int32_t pt_name(void* handle, char* destination, int32_t capacity);
PT_EXPORT int32_t pt_read(void* handle, int64_t offset, uint8_t* destination, int32_t capacity);
PT_EXPORT void pt_close(void* handle);
#ifdef __cplusplus
}
#endif
