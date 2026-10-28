/* SPDX-License-Identifier: LGPL-2.1-or-later
 * PlezyNG optional visualization extension. This is not an upstream mpv API.
 */
#ifndef MPV_PLEZY_AUDIO_TAP_H
#define MPV_PLEZY_AUDIO_TAP_H
#include <stddef.h>
#include <stdint.h>
#include <mpv/client.h>
#ifdef __cplusplus
extern "C" {
#endif

#include "plezy_audio_tap_types.h"

MPV_EXPORT int mpv_plezy_audio_tap_version(void);
/* One owner per playback core. Allocate only when enabling; disable before
 * disposing the reader. All functions are safe against concurrent reads.
 * Normal mpv handle destruction also detaches the tap.
 */
MPV_EXPORT int mpv_plezy_audio_tap_enable(mpv_handle *ctx, int enabled);
/* Native consumer supplies the current playback PTS, not decoder PTS. Return
 * 1 for a block due for presentation, 0 while waiting, MPV_PLEZY_AUDIO_UNSUPPORTED for an unsupported
 * output format/layout, or a negative mpv error. Never waits for the producer.
 * Reads are serialized per handle. No samples cross the Dart channel.
 */
MPV_EXPORT int mpv_plezy_audio_tap_read(mpv_handle *ctx, double playback_pts,
                                      mpv_plezy_audio_block *out, size_t size);
#ifdef __cplusplus
}
#endif
#endif
