/* SPDX-License-Identifier: AGPL-3.0-only */
#ifndef MILKRUST_NATIVE_H
#define MILKRUST_NATIVE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
#define MILKRUST_ABI_VERSION 1
/* 0 success; negative values are failures. Copy last_error on the same thread. */
#define MILKRUST_ERROR (-1)
#define MILKRUST_INVALID_HANDLE (-2)
#define MILKRUST_PANIC (-3)
typedef uint64_t milkrust_handle;
typedef const void* (*milkrust_gl_loader)(const char* name);
uint32_t milkrust_abi_version(void);
/* All calls for a session, including destroy, require its creating thread and
 * a current host-owned GL context. gles=1: GLES 3.0; gles=0: desktop GL 3.2.
 * Renderer owns GL state within that context; give it a dedicated context.
 * Loader and GL context must outlive the session. Handle 0 means create failed.
 */
milkrust_handle milkrust_create(milkrust_gl_loader loader, int gles);
int milkrust_load(milkrust_handle handle, const uint8_t* utf8, size_t length);
/* Newline-separated UTF-8 texture dependencies. Query size with null/0, then
 * provide that capacity. Returns required bytes including NUL, or 0 on error.
 */
size_t milkrust_texture_names(milkrust_handle handle, uint8_t* output, size_t capacity);
/* Host resolves/decodes relative assets under its verified pack root. Uploads
 * are tightly packed, top-down RGBA8. No files or URLs are opened by the engine.
 */
int milkrust_texture(milkrust_handle handle, const uint8_t* name, size_t name_length,
                     uint32_t width, uint32_t height, const uint8_t* rgba, size_t length);
/* Interleaved float stereo at 44100 Hz. At most 4096 frames/call. A new generation
 * discards pre-seek audio. Call from the render consumer, never the real-time AO.
 */
int milkrust_pcm(milkrust_handle handle, const float* stereo, size_t frames, uint32_t generation);
/* Draw into caller-owned FBO (0 allowed for an onscreen context). Width/height
 * are capped at 4096 and total pixels at 8 Mi. Time must be finite, monotonic,
 * and paused by the host while hidden. Output is not implicitly presented.
 */
int milkrust_render(milkrust_handle handle, uint32_t framebuffer, uint32_t width,
                    uint32_t height, double elapsed_seconds);
/* Equivalent offscreen render with engine-owned FBO and synchronous readback.
 * output is exactly width*height*4 writable bytes, returned top-down RGBA8.
 */
int milkrust_render_rgba(milkrust_handle handle, uint32_t width, uint32_t height,
                         double elapsed_seconds, uint8_t* output, size_t length);
int milkrust_destroy(milkrust_handle handle);
/* Returns required UTF-8 bytes including NUL, copies at most capacity-1 bytes.
 * A null output is valid only with capacity=0. Error text is thread-local.
 */
size_t milkrust_last_error(uint8_t* output, size_t capacity);
#ifdef __cplusplus
}
#endif
#endif
