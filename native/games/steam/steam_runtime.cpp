// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_runtime.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace plezy::steam {
static uint64_t nowUs() {
  return std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now().time_since_epoch())
      .count();
}
Runtime::Runtime() {
  static std::atomic<uint64_t> nextEpoch{1};
  metrics_.epoch = nextEpoch++;
  for (auto& pad : pads_) pad = std::make_shared<PadState>();
  static std::once_flag init;
  std::call_once(init, [] { IHS_Init(); });
}
Runtime::~Runtime() {
  clearFrames();
  audio_.reset();
  // Keys never enter logs, Dart preferences, or an activity intent.
  volatile uint8_t* key = paired_.key.data();
  for (size_t i = 0; i < paired_.key.size(); ++i) key[i] = 0;
  volatile uint8_t* sessionKey = info_.sessionKey;
  for (size_t i = 0; i < sizeof(info_.sessionKey); ++i) sessionKey[i] = 0;
}
bool Runtime::hostInfo(const Host& host, IHS_HostInfo& out) {
  if (!host.port || !IHS_IPAddressFromString(&out.address.ip, host.address.c_str())) return false;
  out.address.port = host.port;
  out.clientId = host.id;
  out.universe = IHS_SteamUniversePublic;
  std::strncpy(out.hostname, "Steam", sizeof(out.hostname) - 1);
  return true;
}
void Runtime::cancel() {
  cancelled_ = true;
  condition_.notify_all();
}
void Runtime::finish(int result) {
  std::lock_guard<std::mutex> lock(mutex_);
  result_ = result;
  done_ = true;
  condition_.notify_all();
}
int Runtime::wait(std::chrono::seconds timeout) {
  std::unique_lock<std::mutex> lock(mutex_);
  if (!condition_.wait_for(lock, timeout, [&] { return done_ || cancelled_; })) return -3;
  return cancelled_ ? -2 : result_;
}
void Runtime::closeClient(IHS_Client* client) {
  IHS_ClientStop(client);
  IHS_ClientThreadedJoin(client);
  IHS_ClientDestroy(client);
}
int Runtime::pair(const Host& host, Credentials& credentials, const std::string& pin) {
  if (pin.size() != 4 || pin.find_first_not_of("0123456789") != std::string::npos || !credentials.device) return -1;
  if (cancelled_) return -2;
  IHS_HostInfo target{};
  if (!hostInfo(host, target)) return -1;
  IHS_ClientConfig config{credentials.device, credentials.key.data(), "PlezyNG"};
  IHS_Client* client = IHS_ClientCreate(&config);
  if (!client) return -1;
  static const IHS_ClientAuthorizationCallbacks callbacks{
      nullptr,
      [](IHS_Client* c, const IHS_HostInfo*, uint64_t user, void* ctx) {
        auto* self = static_cast<Runtime*>(ctx);
        self->paired_.user = user;
        IHS_ClientGetSecretKey(c, self->paired_.key.data());
        self->finish(0);
      },
      [](IHS_Client*, const IHS_HostInfo*, IHS_AuthorizationResult result, void* ctx) {
        static_cast<Runtime*>(ctx)->finish(static_cast<int>(result));
      }};
  IHS_ClientSetAuthorizationCallbacks(client, &callbacks, this);
  int result = IHS_ClientAuthorizationRequest(client, &target, pin.c_str()) ? wait(std::chrono::seconds(85)) : -1;
  if (result != 0) IHS_ClientAuthorizationCancel(client);
  closeClient(client);
  if (result == 0) {
    credentials.user = paired_.user;
    credentials.key = paired_.key;
  }
  return result;
}

int Runtime::run(
    const Host& host, const Credentials& credentials, uint64_t game, bool hevc, bool pyrowave,
    std::shared_ptr<Sink> sink, StreamOptions options) {
  if (!sink || !credentials.device || !credentials.user || cancelled_ || !options.valid()) return -1;
  IHS_HostInfo target{};
  if (!hostInfo(host, target)) return -1;
  sink_ = std::move(sink);
  pyrowaveEnabled_ = pyrowave;
  IHS_ClientConfig config{credentials.device, credentials.key.data(), "PlezyNG"};
  IHS_Client* client = IHS_ClientCreate(&config);
  if (!client) return -1;
  static const IHS_ClientStreamingCallbacks streamCallbacks{
      nullptr,
      [](IHS_Client*, const IHS_HostInfo*, const IHS_SocketAddress* address, const uint8_t* key, size_t length,
         void* ctx) {
        auto* self = static_cast<Runtime*>(ctx);
        if (length != sizeof(self->info_.sessionKey)) {
          self->finish(-1);
          return;
        }
        self->info_.address = *address;
        self->info_.sessionKeyLen = length;
        std::memcpy(self->info_.sessionKey, key, length);
        self->finish(0);
      },
      [](IHS_Client*, const IHS_HostInfo*, IHS_StreamingResult result, void* ctx) {
        static_cast<Runtime*>(ctx)->finish(static_cast<int>(result));
      }};
  IHS_ClientSetStreamingCallbacks(client, &streamCallbacks, this);
  IHS_StreamingRequest request{};
  request.streamingEnable = {true, true, true};
  request.maxResolution = {options.width, options.height};
  requestedAudioChannels_ = options.audioChannels;
  request.audioChannelCount = options.audioChannels;
  request.streamingInterface = IHS_StreamInterfaceBigPicture;
  request.gameId = game;
  request.gamepadCount = options.controllerCount;
  request.streamDesktop = false;
  int result = IHS_ClientStreamingRequest(client, &target, &request) ? wait(std::chrono::seconds(30)) : -1;
  if (result == 0 && !cancelled_)
    IHS_ClientStreamingEstablished(client);
  else
    IHS_ClientStreamingCancel(client);
  closeClient(client);
  if (result != 0) return result;
  if (cancelled_) return -2;
  info_.steamId = credentials.user;
  IHS_Session* session = IHS_SessionCreate(&config, &info_);
  if (!session) return -1;
  struct SessionContext {
    Runtime* owner;
    bool hevc;
    bool pyrowave;
    StreamOptions options;
  } context{this, hevc, pyrowave, options};
  static const IHS_StreamSessionCallbacks sessionCallbacks{
      nullptr,
      nullptr,
      [](IHS_Session*, IHS_SessionConfig* c, void* ctx) {
        auto* state = static_cast<SessionContext*>(ctx);
        c->enableAudio = true;
        c->audioChannels = state->options.audioChannels;
        c->enableHevc = state->hevc;
        c->enablePyrowave = state->pyrowave;
        c->maxBitrateKbps = state->options.bitrateKbps;
        c->quality = IHS_StreamQualityBalanced;
        c->maxWidth = state->options.width;
        c->maxHeight = state->options.height;
        c->maxFps = state->options.fps;
      },
      [](IHS_Session*, void* ctx) {
        auto* self = static_cast<SessionContext*>(ctx)->owner;
        std::lock_guard<std::mutex> lock(self->mutex_);
        self->connected_ = true;
        self->condition_.notify_all();
      },
      [](IHS_Session*, void* ctx) {
        auto* self = static_cast<SessionContext*>(ctx)->owner;
        std::lock_guard<std::mutex> lock(self->mutex_);
        self->disconnected_ = true;
        self->condition_.notify_all();
      },
      nullptr};
  static const IHS_StreamVideoCallbacks videoCallbacks{
      nullptr,
      nullptr,
      nullptr,
      nullptr,
      videoFramerate,
      videoBitrate,
      nullptr,
      nullptr,
      [](IHS_Session* s, const IHS_VideoEpochInfo*, const IHS_StreamVideoConfig* c, void* ctx) {
        static_cast<Runtime*>(ctx)->clearFrames();
        return videoStart(s, c, ctx);
      },
      videoSubmit,
      [](IHS_Session*, const IHS_VideoEpochInfo*, void* ctx) { static_cast<Runtime*>(ctx)->clearFrames(); }};
  static const IHS_StreamAudioCallbacks audioCallbacks{audioStart, audioSubmit, audioStop};
  IHS_SessionSetSessionCallbacks(session, &sessionCallbacks, &context);
  IHS_SessionSetVideoCallbacks(session, &videoCallbacks, this);
  IHS_SessionSetVideoTrackingIdentity(session, credentials.device);
  IHS_SessionSetAudioCallbacks(session, &audioCallbacks, this);
  for (int seat = 0; seat < options.controllerCount; ++seat)
    IHS_SessionHIDAddProvider(session, makeController(pads_[seat], static_cast<unsigned>(seat)));
  {
    std::lock_guard<std::mutex> lock(apiMutex_);
    session_ = session;
  }
  if (IHS_SessionConnect(session)) {
    std::unique_lock<std::mutex> lock(mutex_);
    bool ready =
        condition_.wait_for(lock, std::chrono::seconds(30), [&] { return connected_ || disconnected_ || cancelled_; });
    if (!ready)
      result = -3;
    else if (connected_)
      condition_.wait(lock, [&] { return disconnected_ || cancelled_; });
    else
      result = -1;
    if (cancelled_) result = -2;
  } else
    result = -1;
  // Stop accepting input before teardown, but never hold apiMutex_ while joining
  // a callback thread: renderer completion can arrive during shutdown.
  {
    std::lock_guard<std::mutex> lock(apiMutex_);
    session_ = nullptr;
  }
  IHS_SessionDisconnect(session);
  IHS_SessionThreadedJoin(session);
  IHS_SessionDestroy(session);
  sink_.reset();
  return result;
}
int Runtime::videoStart(IHS_Session*, const IHS_StreamVideoConfig* c, void* ctx) {
  auto* self = static_cast<Runtime*>(ctx);
  if (!c || c->width == 0 || c->height == 0 || c->width > 4096 || c->height > 2160 || c->codecDataLen > 65536)
    return -1;
  if (c->codec != IHS_StreamVideoCodecH264 && c->codec != IHS_StreamVideoCodecHEVC &&
      (c->codec != IHS_StreamVideoCodecPyrowave || !self->pyrowaveEnabled_))
    return -1;
  if (!self->sink_->video(c->codec, c->width, c->height, c->codecData, c->codecDataLen)) return -1;
  std::lock_guard<std::mutex> lock(self->frameMutex_);
  self->metrics_.codec = c->codec;
  self->metrics_.width = c->width;
  self->metrics_.height = c->height;
  return 0;
}
void Runtime::videoFramerate(IHS_Session*, uint32_t numerator, uint32_t denominator, uint32_t reasons, void* ctx) {
  if (denominator == 0 || numerator == 0 || uint64_t(numerator) > uint64_t(denominator) * 240) return;
  auto* self = static_cast<Runtime*>(ctx);
  std::lock_guard<std::mutex> lock(self->frameMutex_);
  self->metrics_.fpsNumerator = numerator;
  self->metrics_.fpsDenominator = denominator;
  self->metrics_.fpsReasons = reasons & 0x5f;  // Ignore unknown host flags and private game timing.
}
void Runtime::videoBitrate(IHS_Session*, int32_t bitrate, void* ctx) {
  if (bitrate < 0 || bitrate > 1000000000) return;
  auto* self = static_cast<Runtime*>(ctx);
  std::lock_guard<std::mutex> lock(self->frameMutex_);
  self->metrics_.targetBitrate = static_cast<uint32_t>(bitrate);
}
bool Runtime::startPyrowave(int width, int height, const uint8_t* initial, size_t initialLength) {
  return pyrowave_.start(width, height, initial, initialLength);
}
PyrowaveDecodeStatus Runtime::decodePyrowave(const uint8_t* bytes, size_t length, std::vector<uint8_t>& argb) {
  return pyrowave_.decode(bytes, length, argb);
}
void Runtime::stopPyrowave() { pyrowave_.reset(); }
IHS_StreamVideoSubmitResult Runtime::videoSubmit(
    IHS_Session*, const IHS_VideoEpochInfo*, uint16_t, IHS_FrameTicket* ticket, IHS_Buffer* b,
    IHS_StreamVideoFrameFlag flags, bool* taken, void* ctx) {
  auto* self = static_cast<Runtime*>(ctx);
  if (self->cancelled_ || !b || b->size > 2 * 1024 * 1024 || !ticket) return IHS_StreamVideoSubmitReportLost;
  uint32_t id;
  {
    std::lock_guard<std::mutex> lock(self->frameMutex_);
    ++self->metrics_.receivedFrames;
    self->metrics_.videoBytes += b->size;
    if (self->frames_.size() >= 64) {
      ++self->metrics_.droppedFrames;
      return IHS_StreamVideoSubmitReportLost;
    }
    do {
      id = self->nextFrame_++;
    } while (id == 0 || self->frames_.count(id));
    // Keep our own reference. The callback's reference remains owned by ihslib.
    if (!IHS_FrameTicketRetain(ticket)) {
      ++self->metrics_.droppedFrames;
      return IHS_StreamVideoSubmitReportLost;
    }
    self->frames_.emplace(id, PendingFrame{ticket, nowUs()});
  }
  IHS_FrameTicketDecodeStage(ticket, false, nowUs());
  if (self->sink_->frame(IHS_BufferPointer(b), b->size, id, flags & IHS_StreamVideoFrameKeyFrame)) {
    *taken = true;
    // ihslib releases its assembly reference after return; our retained reference
    // remains owned by frames_ until completion or epoch shutdown.
    return IHS_StreamVideoSubmitOK;
  }
  self->frameComplete(id, false);
  return IHS_StreamVideoSubmitReportLost;
}
int Runtime::audioStart(IHS_Session*, const IHS_StreamAudioConfig* c, void* ctx) {
  auto* self = static_cast<Runtime*>(ctx);
  audioStop(nullptr, ctx);
  if (!c || c->codec != IHS_StreamAudioCodecOpus || c->channels > unsigned(self->requestedAudioChannels_) ||
      !self->audio_.start(c->channels, c->frequency, c->codecData, c->codecDataLen) ||
      !self->sink_->audio(c->channels, c->frequency)) {
    self->audio_.reset();
    self->sink_->audioUnavailable();
    return -1;
  }
  std::lock_guard<std::mutex> lock(self->frameMutex_);
  self->metrics_.audioChannels = c->channels;
  return 0;
}
int Runtime::audioSubmit(IHS_Session*, IHS_Buffer* b, void* ctx) {
  auto* self = static_cast<Runtime*>(ctx);
  if (!b || self->cancelled_) return -1;
  std::array<int16_t, AudioDecoder::maxSamples> pcm{};
  int samples = self->audio_.decode(IHS_BufferPointer(b), b->size, pcm.data());
  if (samples < 0) return -1;
  if (samples) self->sink_->samples(pcm.data(), samples);
  return 0;
}
void Runtime::audioStop(IHS_Session*, void* ctx) {
  auto* self = static_cast<Runtime*>(ctx);
  self->audio_.reset();
  std::lock_guard<std::mutex> lock(self->frameMutex_);
  self->metrics_.audioChannels = 0;
}
void Runtime::pad(const std::array<int16_t, 6>& axes, uint32_t buttons) { padSeat(0, axes, buttons); }
void Runtime::padSeat(unsigned seat, const std::array<int16_t, 6>& axes, uint32_t buttons) {
  if (seat >= pads_.size()) return;
  const auto& pad = pads_[seat];
  std::lock_guard<std::mutex> lock(pad->mutex);
  pad->axes = axes;
  pad->buttons = buttons & 0x7fff;
}
void Runtime::key(uint32_t usage, bool down) {
  if (usage > 255) return;
  std::lock_guard<std::mutex> lock(apiMutex_);
  if (session_) {
    if (down)
      IHS_SessionSendKeyDown(session_, usage);
    else
      IHS_SessionSendKeyUp(session_, usage);
  }
}
void Runtime::mouse(float x, float y, int button, bool down) {
  if (!std::isfinite(x) || !std::isfinite(y)) return;
  std::lock_guard<std::mutex> lock(apiMutex_);
  if (!session_) return;
  IHS_SessionSendMousePosition(session_, std::clamp(x, 0.f, 1.f), std::clamp(y, 0.f, 1.f));
  if (button == 1 || button == 2 || button == 16) {
    if (down)
      IHS_SessionSendMouseDown(session_, static_cast<IHS_StreamInputMouseButton>(button));
    else
      IHS_SessionSendMouseUp(session_, static_cast<IHS_StreamInputMouseButton>(button));
  }
}
void Runtime::mouseWheel(int direction) {
  if (direction < IHS_MOUSE_WHEEL_UP || direction > IHS_MOUSE_WHEEL_RIGHT) return;
  std::lock_guard<std::mutex> lock(apiMutex_);
  if (session_) IHS_SessionSendMouseWheel(session_, static_cast<IHS_StreamInputMouseWheelDirection>(direction));
}
void Runtime::text(const std::string& text) {
  std::lock_guard<std::mutex> lock(apiMutex_);
  if (session_ && text.size() <= 4096) IHS_SessionSendText(session_, text.c_str());
}
void Runtime::frameComplete(uint32_t id, bool displayed) {
  IHS_FrameTicket* ticket;
  {
    std::lock_guard<std::mutex> lock(frameMutex_);
    auto it = frames_.find(id);
    if (it == frames_.end()) return;
    ticket = it->second.ticket;
    metrics_.completionTotalUs += nowUs() - it->second.receivedUs;
    ++metrics_.completedFrames;
    if (displayed)
      ++metrics_.presentedFrames;
    else
      ++metrics_.droppedFrames;
    frames_.erase(it);
  }
  IHS_FrameTicketDecodeStage(ticket, true, nowUs());
  IHS_FrameOutcome outcome{};
  outcome.completionUs = nowUs();
  outcome.presentationSerial = displayed ? id : 0;
  outcome.result = displayed ? IHS_VideoFrameResultDisplayed : IHS_VideoFrameResultDroppedDecodeSlow;
  IHS_FrameTicketComplete(ticket, &outcome);
  IHS_FrameTicketRelease(ticket);
}
void Runtime::clearFrames() {
  std::lock_guard<std::mutex> lock(frameMutex_);
  for (const auto& item : frames_) {
    IHS_FrameOutcome outcome{};
    outcome.completionUs = nowUs();
    outcome.result = IHS_VideoFrameResultDroppedReset;
    IHS_FrameTicketComplete(item.second.ticket, &outcome);
    IHS_FrameTicketRelease(item.second.ticket);
    ++metrics_.resetFrames;
  }
  frames_.clear();
}
StreamMetrics Runtime::metrics() {
  StreamMetrics snapshot;
  {
    std::lock_guard<std::mutex> lock(frameMutex_);
    snapshot = metrics_;
    snapshot.sampledAtUs = nowUs();
  }
  {
    std::lock_guard<std::mutex> lock(apiMutex_);
    if (session_) IHS_SessionGetReliabilityStats(session_, &snapshot.reliability);
  }
  return snapshot;
}
}  // namespace plezy::steam
