/* SPDX-License-Identifier: LGPL-2.1-or-later */
#pragma once
#include <stdint.h>

#define MPV_PLEZY_AUDIO_TAP_ABI 1
#define MPV_PLEZY_AUDIO_UNSUPPORTED (-1001)
#define MPV_PLEZY_AUDIO_TAP_FRAMES 512
#define MPV_PLEZY_AUDIO_TAP_CHANNELS 8

typedef struct mpv_plezy_audio_block {
    uint32_t generation;
    uint32_t frames;
    uint32_t sample_rate;
    uint32_t channels;
    uint32_t dropped_frames;
    uint8_t speaker_ids[MPV_PLEZY_AUDIO_TAP_CHANNELS];
    double pts;
    double seconds_per_frame;
    float samples[MPV_PLEZY_AUDIO_TAP_FRAMES * MPV_PLEZY_AUDIO_TAP_CHANNELS];
} mpv_plezy_audio_block;

