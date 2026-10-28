#pragma once

#include <flutter_linux/flutter_linux.h>
#include <functional>
#include <memory>
#include <string>
#include "../../../shared/visualization/plezy_audio_tap.h"

namespace plezy::visualization {

// The worker owns its EGL context and projectM instance. Flutter receives a
// bounded native pixel-buffer texture; neither pixels nor PCM go through Dart.
class VisualizerSession {
 public:
  using AudioReader = std::function<int(mpv_plezy_audio_block*)>;
  static std::string DependencyError();
  VisualizerSession(FlTextureRegistrar* registrar, AudioReader reader);
  ~VisualizerSession();
  VisualizerSession(const VisualizerSession&) = delete;
  VisualizerSession& operator=(const VisualizerSession&) = delete;
  int64_t texture_id() const;
  bool LoadPreset(const std::string& path, const std::string& root, double transition_seconds, std::string* error);
  void Resize(int width, int height);
  void SetPaused(bool paused);
  FlValue* Status() const;

 private:
  struct Impl;
  std::unique_ptr<Impl> impl_;
};
} // namespace plezy::visualization
