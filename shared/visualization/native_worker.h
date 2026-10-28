// SPDX-License-Identifier: AGPL-3.0-only
#pragma once
#include "milkrust_engine.h"
#include "pcm_resampler.h"
#include <chrono>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <thread>

namespace plezy::visualization {
struct NativeFrame {
  uint32_t width = 0, height = 0;
  uint64_t preset_serial = 0;
  std::vector<uint8_t> rgba;
};
struct NativeStatus {
  std::string state = "starting", reason;
  uint64_t preset_serial = 0, frame_serial = 0;
  uint32_t dropped = 0;
  int width = 0, height = 0;
  bool has_frame = false;
};
// Platform context creation/destruction and all engine calls stay on one
// worker. Hosts retain frame ownership until Flutter releases its pixel lease.
class NativeContext {
 public:
  virtual ~NativeContext() = default;
  virtual milkrust_gl_loader Loader() const = 0;
  virtual bool IsGles() const = 0;
};
class NativeWorker {
 public:
  using AudioReader = std::function<int(mpv_plezy_audio_block*)>;
  using ContextFactory = std::function<std::unique_ptr<NativeContext>()>;
  using Publish = std::function<void(std::shared_ptr<const NativeFrame>)>;
  NativeWorker(ContextFactory context, MilkRustImageDecoder decoder, AudioReader audio, Publish publish)
      : context_(std::move(context)), decoder_(std::move(decoder)), audio_(std::move(audio)),
        publish_(std::move(publish)), worker_([this] { Run(); }) {}
  ~NativeWorker() { Stop(); }
  NativeWorker(const NativeWorker&) = delete;
  NativeWorker& operator=(const NativeWorker&) = delete;
  void Stop() {
    { std::lock_guard<std::mutex> lock(mutex_); stopping_ = true; }
    condition_.notify_all();
    if (worker_.joinable()) worker_.join();
  }
  void Load(const std::string& path, const std::string& root) {
    if (path.empty() || root.empty() || path.size() > 32768 || root.size() > 32768)
      throw std::runtime_error("A bounded preset path and pack root are required.");
    const auto ext = std::filesystem::path(path).extension().string();
    if (ext != ".milk" && ext != ".MILK" && ext != ".milk2" && ext != ".MILK2")
      throw std::runtime_error("Native MilkRust accepts .milk and supported .milk2 presets.");
    { std::lock_guard<std::mutex> lock(mutex_);
      if (stopping_ || status_.state == "failed") throw std::runtime_error("Create a new visualization session to retry.");
      path_ = path; root_ = root; ++serial_; status_.state = "loading"; status_.reason.clear(); }
    condition_.notify_all();
  }
  void Resize(int width, int height) {
    if (width < 1 || height < 1 || width > 16384 || height > 16384)
      throw std::runtime_error("Invalid visualization dimensions.");
    const double scale = std::min({1.0, 1280.0/width, 720.0/height});
    std::lock_guard<std::mutex> lock(mutex_);
    width_ = std::max(1, static_cast<int>(width*scale));
    height_ = std::max(1, static_cast<int>(height*scale));
  }
  void Pause(bool paused) {
    { std::lock_guard<std::mutex> lock(mutex_); paused_ = paused;
      if (paused && status_.state != "failed") status_.state = "paused"; }
    condition_.notify_all();
  }
  NativeStatus Status() const {
    std::lock_guard<std::mutex> lock(mutex_); auto result = status_;
    result.width = width_; result.height = height_;
    result.has_frame = result.frame_serial != 0 && result.preset_serial == serial_;
    if (paused_ && result.state != "failed" && result.state != "unavailable") result.state = "paused";
    return result;
  }
 private:
  using Clock = std::chrono::steady_clock;
  ContextFactory context_;
  MilkRustImageDecoder decoder_;
  AudioReader audio_;
  Publish publish_;
  mutable std::mutex mutex_;
  std::condition_variable condition_;
  bool stopping_ = false, paused_ = true;
  int width_ = 768, height_ = 432;
  uint64_t serial_ = 0;
  std::string path_, root_;
  NativeStatus status_;
  std::thread worker_; // Starts only after every field used by Run is initialized.
  void State(const char* state, const std::string& reason = {}) {
    std::lock_guard<std::mutex> lock(mutex_); status_.state = state; status_.reason = reason;
  }
  void Run() noexcept {
    try {
      auto context = context_();
      if (!context) throw std::runtime_error("No native graphics context.");
      std::unique_ptr<MilkRustEngine> engine; // Destroy before its context.
      PcmResampler resampler;
      std::vector<float> stereo;
      uint32_t generation = 0;
      uint64_t loaded = 0;
      double elapsed = 0;
      auto tick = Clock::time_point{}, audio_at = Clock::time_point{};
      for (;;) {
        std::string path, root; uint64_t serial; int width, height;
        {
          std::unique_lock<std::mutex> lock(mutex_);
          if (paused_) { tick = {}; audio_at = {}; }
          condition_.wait(lock, [this] { return stopping_ || (!paused_ && serial_); });
          if (stopping_) break;
          path = path_; root = root_; serial = serial_; width = width_; height = height_;
        }
        const auto started = Clock::now();
        bool received = false, unsupported = false;
        for (int reads = 0; reads < 32; ++reads) {
          mpv_plezy_audio_block block{};
          const int result = audio_(&block);
          if (result == MPV_PLEZY_AUDIO_UNSUPPORTED) { unsupported = true; break; }
          if (result < 0) throw std::runtime_error("The music PCM tap was lost.");
          if (result == 0) break;
          if (!engine || generation != block.generation) {
            engine = std::make_unique<MilkRustEngine>(context->Loader(), context->IsGles());
            generation = block.generation; loaded = 0; resampler = PcmResampler();
          }
          if (loaded != serial) {
            engine->Load(std::filesystem::u8path(path), std::filesystem::u8path(root), decoder_);
            loaded = serial; elapsed = 0; tick = {};
          }
          if (!resampler.Convert(block, &stereo)) { unsupported = true; break; }
          engine->Pcm(stereo.data(), stereo.size()/2, generation);
          received = true;
          { std::lock_guard<std::mutex> lock(mutex_); status_.dropped = block.dropped_frames; }
        }
        if (unsupported) {
          audio_at = {}; tick = {};
          State("unavailable", "The active audio output or speaker layout cannot provide visualization PCM.");
        } else {
          if (received) audio_at = Clock::now();
          if (engine && loaded == serial && Clock::now()-audio_at < std::chrono::milliseconds(250)) {
            const auto now = Clock::now();
            if (tick != Clock::time_point{}) elapsed += std::chrono::duration<double>(now-tick).count();
            tick = now;
            auto frame = std::make_shared<NativeFrame>();
            frame->width = width; frame->height = height; frame->preset_serial = serial;
            engine->Capture(width, height, elapsed, frame->rgba);
            bool current;
            { std::lock_guard<std::mutex> lock(mutex_);
              current = !paused_ && !stopping_ && serial_ == serial;
              if (current) { status_.state = "rendering"; status_.reason.clear();
                status_.preset_serial = serial; ++status_.frame_serial; } }
            if (current) publish_(std::move(frame));
          } else { tick = {}; State("waiting-audio"); }
        }
        std::unique_lock<std::mutex> lock(mutex_);
        condition_.wait_until(lock, started+std::chrono::milliseconds(33),
            [this, serial] { return stopping_ || paused_ || serial_ != serial; });
        if (stopping_) break;
      }
    } catch (const std::exception& error) { State("failed", error.what()); }
      catch (...) { State("failed", "The native renderer stopped unexpectedly."); }
  }
};
} // namespace plezy::visualization
