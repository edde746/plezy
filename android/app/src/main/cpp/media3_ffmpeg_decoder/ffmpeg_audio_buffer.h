/*
 * Copyright (C) 2026 Plezy contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef PLEZY_FFMPEG_AUDIO_BUFFER_H_
#define PLEZY_FFMPEG_AUDIO_BUFFER_H_

#include <limits.h>
#include <stdint.h>

namespace plezy {
namespace ffmpeg {

inline bool CheckedAudioByteCount(int sample_count, int channel_count, int bytes_per_sample, int* byte_count) {
  if (sample_count < 0 || channel_count <= 0 || bytes_per_sample <= 0 || byte_count == nullptr) {
    return false;
  }
  const int64_t size = static_cast<int64_t>(sample_count) * channel_count * bytes_per_sample;
  if (size > INT_MAX) {
    return false;
  }
  *byte_count = static_cast<int>(size);
  return true;
}

inline bool CheckedAddByteCount(int current_size, int additional_size, int* total_size) {
  if (current_size < 0 || additional_size < 0 || total_size == nullptr || current_size > INT_MAX - additional_size) {
    return false;
  }
  *total_size = current_size + additional_size;
  return true;
}

}  // namespace ffmpeg
}  // namespace plezy

#endif  // PLEZY_FFMPEG_AUDIO_BUFFER_H_
