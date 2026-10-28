// SPDX-License-Identifier: AGPL-3.0-only
#pragma once
#include <flutter/texture_registrar.h>
#include "../../../shared/visualization/native_worker.h"

namespace plezy::visualization {
class WindowsVisualizerSession {
 public:
  WindowsVisualizerSession(flutter::TextureRegistrar* registrar, NativeWorker::AudioReader reader);
  ~WindowsVisualizerSession();
  int64_t texture_id() const { return texture_id_; }
  NativeWorker& worker() { return *worker_; }
 private:
  flutter::TextureRegistrar* registrar_;
  int64_t texture_id_ = -1;
  std::shared_ptr<flutter::TextureVariant> texture_;
  std::unique_ptr<NativeWorker> worker_;
};
} // namespace plezy::visualization
