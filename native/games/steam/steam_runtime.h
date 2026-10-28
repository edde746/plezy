// SPDX-License-Identifier: GPL-3.0-or-later
#pragma once
#include <array>
#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "steam_audio.h"
#include "steam_pyrowave.h"
#include "steam_stream_options.h"
extern "C" {
#include <ihslib.h>
#include <ihslib/frame_ticket.h>
#include <opus.h>
}

namespace plezy::steam {
struct Credentials {
  uint64_t device = 0, user = 0;
  std::array<uint8_t, 32> key{};
  ~Credentials() {
    volatile uint8_t* secret = key.data();
    for (size_t i = 0; i < key.size(); ++i) secret[i] = 0;
  }
};
struct Host {
  std::string address;
  uint16_t port = 27036;
  uint64_t id = 0;
};
struct PadState {
  std::mutex mutex;
  std::array<int16_t, 6> axes{};
  uint32_t buttons = 0;
};
struct StreamMetrics {
  uint64_t epoch = 0;  // Local measurement epoch, never a host/account identity.
  uint64_t sampledAtUs = 0, receivedFrames = 0, presentedFrames = 0, droppedFrames = 0, resetFrames = 0;
  uint64_t videoBytes = 0, completionTotalUs = 0, completedFrames = 0;
  uint32_t width = 0, height = 0, codec = 0, audioChannels = 0;
  uint32_t fpsNumerator = 0, fpsDenominator = 0, fpsReasons = 0, targetBitrate = 0;
  IHS_SessionReliabilityStats reliability{};
};
IHS_HIDProvider* makeController(const std::shared_ptr<PadState>& state, unsigned seat = 0);

// All frame callbacks run on transport threads. Implementations must enqueue
// bounded copies, never retain the transport buffer or block on rendering.
struct Sink {
  virtual ~Sink() = default;
  virtual bool video(int codec, int width, int height, const uint8_t* extra, size_t length) = 0;
  virtual bool frame(const uint8_t* bytes, size_t length, uint32_t id, bool key) = 0;
  virtual bool audio(int channels, int rate) = 0;
  virtual void audioUnavailable() {}
  virtual void samples(const int16_t* pcm, size_t count) = 0;
};

class Runtime {
 public:
  Runtime();
  ~Runtime();
  // One operation per Runtime. pair/run execute on a worker; cancel is immediate.
  // Return 0 on success, -2 on cancellation, -3 on timeout, positive host error.
  int pair(const Host&, Credentials&, const std::string& pin);
  int run(
      const Host&, const Credentials&, uint64_t game, bool hevc, bool pyrowave, std::shared_ptr<Sink>,
      StreamOptions options = {});
  bool startPyrowave(int width, int height, const uint8_t* initial, size_t initialLength);
  PyrowaveDecodeStatus decodePyrowave(const uint8_t* bytes, size_t length, std::vector<uint8_t>& argb);
  void stopPyrowave();
  void cancel();
  void pad(const std::array<int16_t, 6>& axes, uint32_t buttons);
  void padSeat(unsigned seat, const std::array<int16_t, 6>& axes, uint32_t buttons);
  void key(uint32_t usage, bool down);
  void mouse(float x, float y, int button, bool down);
  void mouseWheel(int direction);
  void text(const std::string& value);
  void frameComplete(uint32_t id, bool displayed);
  StreamMetrics metrics();

 private:
  friend struct RuntimeTest;
  bool hostInfo(const Host&, IHS_HostInfo&);
  int wait(std::chrono::seconds timeout);
  void finish(int result);
  void closeClient(IHS_Client*);
  static int videoStart(IHS_Session*, const IHS_StreamVideoConfig*, void*);
  static void videoFramerate(IHS_Session*, uint32_t numerator, uint32_t denominator, uint32_t reasons, void*);
  static void videoBitrate(IHS_Session*, int32_t bitrate, void*);
  static IHS_StreamVideoSubmitResult videoSubmit(
      IHS_Session*, const IHS_VideoEpochInfo*, uint16_t, IHS_FrameTicket*, IHS_Buffer*, IHS_StreamVideoFrameFlag, bool*,
      void*);
  void clearFrames();
  static int audioStart(IHS_Session*, const IHS_StreamAudioConfig*, void*);
  static int audioSubmit(IHS_Session*, IHS_Buffer*, void*);
  static void audioStop(IHS_Session*, void*);
  std::atomic<bool> cancelled_{false};
  std::mutex mutex_, apiMutex_;
  std::condition_variable condition_;
  bool done_ = false, connected_ = false, disconnected_ = false;
  int result_ = -1;
  IHS_Session* session_ = nullptr;  // apiMutex_; cleared before joining/destroying
  IHS_SessionInfo info_{};
  Credentials paired_{};
  std::shared_ptr<Sink> sink_;
  std::array<std::shared_ptr<PadState>, 4> pads_;
  AudioDecoder audio_;
  int requestedAudioChannels_ = 2;
  bool pyrowaveEnabled_ = false;
  PyrowaveDecoder pyrowave_;
  std::mutex frameMutex_;
  uint32_t nextFrame_ = 1;
  struct PendingFrame {
    IHS_FrameTicket* ticket;
    uint64_t receivedUs;
  };
  std::unordered_map<uint32_t, PendingFrame> frames_;
  StreamMetrics metrics_;  // frameMutex_; contains no host/account/device identifiers.
};
}  // namespace plezy::steam
