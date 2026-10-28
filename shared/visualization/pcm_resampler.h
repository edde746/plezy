#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <vector>

#include "plezy_audio_tap_types.h"

namespace plezy::visualization {

// projectM 4.1's analysis assumes 44.1 kHz stereo. Conversion belongs on the
// renderer worker; the playback tap retains actual PCM rate and speaker IDs.
class PcmResampler {
 public:
  bool Convert(const mpv_plezy_audio_block& block, std::vector<float>* output) {
    output->clear();
    if (block.frames > MPV_PLEZY_AUDIO_TAP_FRAMES || block.channels < 1 ||
        block.channels > MPV_PLEZY_AUDIO_TAP_CHANNELS || block.sample_rate < 8000 || block.sample_rate > 384000)
      return false;
    if (!std::isfinite(block.pts) || !std::isfinite(block.seconds_per_frame) || block.seconds_per_frame <= 0)
      return false;
    const bool discontinuity =
        have_previous_ && std::abs(block.pts - expected_pts_) > std::max(0.001, block.seconds_per_frame * 2);
    if (generation_ != block.generation || rate_ != block.sample_rate || discontinuity) {
      generation_ = block.generation;
      rate_ = block.sample_rate;
      index_ = 0;
      next_ = 0;
      have_previous_ = false;
    }
    expected_pts_ = block.pts + block.frames * block.seconds_per_frame;
    // At 8 kHz one block expands to fewer than 3000 stereo frames.
    output->reserve(6000);
    for (uint32_t n = 0; n < block.frames; ++n) {
      float left = 0, right = 0;
      if (!Downmix(block, n, &left, &right)) return false;
      if (!have_previous_) {
        previous_left_ = left;
        previous_right_ = right;
        have_previous_ = true;
      }
      while (next_ <= static_cast<double>(index_)) {
        const double blend = index_ ? next_ - (index_ - 1) : 1;
        output->push_back(previous_left_ + (left - previous_left_) * blend);
        output->push_back(previous_right_ + (right - previous_right_) * blend);
        next_ += static_cast<double>(rate_) / 44100.0;
      }
      previous_left_ = left;
      previous_right_ = right;
      ++index_;
    }
    return true;
  }

 private:
  static bool Downmix(const mpv_plezy_audio_block& block, uint32_t frame, float* left, float* right) {
    const float* samples = block.samples + frame * block.channels;
    if (block.channels == 1) {
      *left = *right = samples[0];
      return true;
    }
    double l = 0, r = 0, lw = 0, rw = 0;
    for (uint32_t c = 0; c < block.channels; ++c) {
      double a = 0, b = 0;
      switch (block.speaker_ids[c]) {
        case 0:
        case 6:
          a = 1;
          break;  // FL / FLC
        case 1:
        case 7:
          b = 1;
          break;  // FR / FRC
        case 2:
          a = b = 0.70710678;
          break;  // FC
        case 3:
          break;  // LFE omitted from analysis downmix.
        case 4:
        case 9:
          a = 0.70710678;
          break;  // BL / SL
        case 5:
        case 10:
          b = 0.70710678;
          break;  // BR / SR
        case 8:
          a = b = 0.5;
          break;  // BC
        default:
          // Unspecified stereo is conventional LR; do not invent a multichannel layout.
          if (block.channels != 2) return false;
          a = c == 0;
          b = c == 1;
      }
      const double sample = std::isfinite(samples[c]) ? std::clamp(samples[c], -1.0f, 1.0f) : 0;
      l += sample * a;
      r += sample * b;
      lw += a;
      rw += b;
    }
    *left = static_cast<float>(l / std::max(1.0, lw));
    *right = static_cast<float>(r / std::max(1.0, rw));
    return true;
  }

  uint32_t generation_ = 0, rate_ = 0;
  uint64_t index_ = 0;
  double next_ = 0;
  double expected_pts_ = 0;
  bool have_previous_ = false;
  float previous_left_ = 0, previous_right_ = 0;
};
}  // namespace plezy::visualization
