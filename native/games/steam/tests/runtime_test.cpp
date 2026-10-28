// SPDX-License-Identifier: GPL-3.0-or-later
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cassert>
#include <chrono>
#include <cstring>
#include <future>
#include <thread>

#include "steam_input.h"
#include "steam_runtime.h"
extern "C" {
#include "hid/provider.h"
#include "protobuf/discovery.pb-c.h"
#include "session/frame_tracker.h"
}
using namespace plezy::steam;
namespace plezy::steam {
struct RuntimeTest {
  static void target(Runtime& runtime, uint32_t numerator, uint32_t denominator, uint32_t reasons, int32_t bitrate) {
    Runtime::videoFramerate(nullptr, numerator, denominator, reasons, &runtime);
    Runtime::videoBitrate(nullptr, bitrate, &runtime);
  }
  static std::shared_ptr<PadState> pad(Runtime& runtime, unsigned seat) { return runtime.pads_[seat]; }
  static void renderer(Runtime& runtime, std::shared_ptr<Sink> sink) { runtime.sink_ = std::move(sink); }
  static bool submit(Runtime& runtime, IHS_FrameTicket* ticket) {
    uint8_t bytes[] = {0, 0, 1, 0x65};
    IHS_Buffer buffer{};
    buffer.data = bytes;
    buffer.size = buffer.capacity = buffer.maxCapacity = sizeof(bytes);
    bool taken = false;
    assert(
        Runtime::videoSubmit(nullptr, nullptr, 1, ticket, &buffer, IHS_StreamVideoFrameKeyFrame, &taken, &runtime) ==
        IHS_StreamVideoSubmitOK);
    return taken;
  }
  static void clear(Runtime& runtime) { runtime.clearFrames(); }
};
}  // namespace plezy::steam
struct NullSink : Sink {
  bool video(int, int, int, const uint8_t*, size_t) override { return false; }
  bool frame(const uint8_t*, size_t, uint32_t, bool) override { return false; }
  bool audio(int, int) override { return false; }
  void samples(const int16_t*, size_t) override {}
};
struct CompletingSink : NullSink {
  Runtime* runtime;
  uint32_t last = 0;
  bool immediate = false;
  bool frame(const uint8_t*, size_t, uint32_t id, bool) override {
    last = id;
    if (immediate) runtime->frameComplete(id, true);
    return true;
  }
};
void frameOwnership() {
  Runtime runtime;
  auto sink = std::make_shared<CompletingSink>();
  sink->runtime = &runtime;
  RuntimeTest::renderer(runtime, sink);
  auto* tracker = IHS_FrameTrackerCreate(123);
  assert(tracker);
  assert(IHS_FrameTrackerOpenEpoch(tracker, 1));
  IHS_FrameReceive receive{};
  receive.firstReceiveUs = receive.lastReceiveUs = 1;
  for (int i = 0; i < 3; ++i) {
    IHS_FrameTicket* ticket = nullptr;
    assert(IHS_FrameTrackerBegin(tracker, 1, i, &receive, &ticket) == IHS_FrameBeginOK);
    sink->immediate = i == 1;
    assert(RuntimeTest::submit(runtime, ticket));
    IHS_FrameTicketRelease(ticket);  // Transport relinquishes its assembly.
    if (i == 2)
      RuntimeTest::clear(runtime);
    else
      runtime.frameComplete(sink->last, true);
    IHS_TrackedFrame completed{};
    assert(IHS_FrameTrackerSettle(tracker, UINT64_MAX / 2, UINT64_MAX / 4, &completed, 1) == 1);
    assert(completed.outcome.result == (i == 2 ? IHS_VideoFrameResultDroppedReset : IHS_VideoFrameResultDisplayed));
    assert(completed.outcome.completionUs != 0);
    runtime.frameComplete(sink->last, true);  // Duplicate/late callbacks are ignored.
  }
  IHS_FrameTrackerClose(tracker);
  const auto metrics = runtime.metrics();
  assert(metrics.epoch != 0 && metrics.sampledAtUs != 0);
  assert(metrics.receivedFrames == 3 && metrics.presentedFrames == 2);
  assert(metrics.completedFrames == 2 && metrics.resetFrames == 1 && metrics.droppedFrames == 0);
  assert(metrics.videoBytes == 12);  // Duplicate completions must not inflate feedback.
  RuntimeTest::target(runtime, 30000, 1001, 0xffffffff, 12000000);
  auto target = runtime.metrics();
  assert(target.fpsNumerator == 30000 && target.fpsDenominator == 1001 && target.fpsReasons == 0x5f);
  assert(target.targetBitrate == 12000000);
  RuntimeTest::target(runtime, 60, 0, 0, -1);
  RuntimeTest::target(runtime, UINT32_MAX, 1, 0, 1000000001);
  target = runtime.metrics();
  assert(target.fpsDenominator == 1001 && target.targetBitrate == 12000000);
  Runtime second;
  assert(second.metrics().epoch != metrics.epoch);
}
uint32_t le(const uint8_t* p) {
  return uint32_t(p[0]) | uint32_t(p[1]) << 8 | uint32_t(p[2]) << 16 | uint32_t(p[3]) << 24;
}
int main() {
  frameOwnership();
  {
    Runtime controllers;
    std::array<int16_t, 6> axes{12000, -4000, 0, 0, 32767, 0};
    controllers.pad(axes, 0xffffffff);
    controllers.padSeat(3, {}, 4);
    controllers.padSeat(4, axes, 8);  // Rejected without writing outside the array.
    assert(RuntimeTest::pad(controllers, 0)->axes == axes);
    assert(RuntimeTest::pad(controllers, 0)->buttons == 0x7fff);
    assert(RuntimeTest::pad(controllers, 1)->buttons == 0);
    assert(RuntimeTest::pad(controllers, 3)->buttons == 4);
    controllers.padSeat(0, {}, 0);
    assert(RuntimeTest::pad(controllers, 3)->buttons == 4);
    for (unsigned seat = 0; seat < 4; ++seat) {
      auto* provider = makeController(RuntimeTest::pad(controllers, seat), seat);
      assert(provider);
      IHS_HIDDeviceInfo info{};
      IHS_HIDProviderDeviceInfo(provider, nullptr, &info);
      const std::string path = "plezy://controller/" + std::to_string(seat);
      const std::string serial = seat == 0 ? "02504C455A59" : "02504C455A5" + std::to_string(seat);
      assert(path == info.path && serial == info.serial_number);
      assert(IHS_HIDProviderSupportsDevice(provider, path.c_str()));
      const std::string other = "plezy://controller/" + std::to_string((seat + 1) % 4);
      assert(!IHS_HIDProviderSupportsDevice(provider, other.c_str()));
      assert(IHS_HIDProviderOpenDevice(provider, other.c_str()) == nullptr);
      IHS_SessionHIDProviderDestroy(provider);
    }
    assert(makeController(RuntimeTest::pad(controllers, 0), 4) == nullptr);
  }
  {
    Runtime r;
    InputState input(2);
    input.button(r, 1, "a", true);  // No lease, no input.
    assert(RuntimeTest::pad(r, 0)->buttons == 0);
    input.enabled(r, true);
    input.button(r, 10, "a", true);
    input.axis(r, 20, "leftStickX", 0.5);
    input.button(r, 30, "b", true);  // Third device cannot steal a seat.
    assert(RuntimeTest::pad(r, 0)->buttons == 1 && RuntimeTest::pad(r, 1)->axes[0] == 16383);
    input.disconnect(r, 10);
    assert(RuntimeTest::pad(r, 1)->axes[0] == 16383);
    input.button(r, 30, "b", true);
    assert(RuntimeTest::pad(r, 0)->buttons == 2);
    input.enabled(r, false);
    input.axis(r, 20, "leftStickX", 1);
    assert(RuntimeTest::pad(r, 0)->buttons == 0 && RuntimeTest::pad(r, 1)->axes[0] == 0);
  }
  Credentials c{};
  {
    Runtime r;
    InputState input(2);
    input.enabled(r, true);
    input.button(r, 10, "b", true);
    input.button(r, 20, "y", true);
    input.button(r, 0, "a", true, true);  // Touch shares seat one, never reserves seat three.
    input.axis(r, 10, "leftStickX", 0.75);
    input.axis(r, 0, "leftStickX", 0.5, true);
    assert(RuntimeTest::pad(r, 0)->buttons == 3 && RuntimeTest::pad(r, 1)->buttons == 8);
    assert(RuntimeTest::pad(r, 0)->axes[0] == 24575);
    input.releaseAssistance(r);
    assert(RuntimeTest::pad(r, 0)->buttons == 2 && RuntimeTest::pad(r, 0)->axes[0] == 24575);
    input.button(r, 0, "a", true, true);
    input.disconnect(r, 10);
    assert(RuntimeTest::pad(r, 0)->buttons == 1 && RuntimeTest::pad(r, 1)->buttons == 8);
    input.button(r, 30, "x", true);
    assert(RuntimeTest::pad(r, 0)->buttons == 5);
    input.enabled(r, false);
    input.button(r, 0, "a", true, true);
    input.enabled(r, true);
    assert(RuntimeTest::pad(r, 0)->buttons == 0 && RuntimeTest::pad(r, 1)->buttons == 0);
  }
  c.device = 123;
  c.user = 456;
  c.key.fill(42);
  Runtime invalid;
  for (const auto& options :
       {StreamOptions{0, 1080, 60, 30000},
        {1920, 1081, 60, 30000},
        {1920, 1080, 120, 30000},
        {1920, 1080, 60, 50001},
        {1920, 1080, 60, 30000, 0},
        {1920, 1080, 60, 30000, 5},
        {1920, 1080, 60, 30000, 1, 3}}) {
    assert(invalid.run({"127.0.0.1", 27036, 1}, c, 620, false, false, std::make_shared<NullSink>(), options) == -1);
  }
  assert(invalid.pair({"127.0.0.1", 0, 1}, c, "1234") == -1);
  assert(invalid.pair({"127.0.0.1", 27036, 1}, c, "xx12") == -1);
  Runtime pairing;
  auto pair = std::async(std::launch::async, [&] { return pairing.pair({"127.0.0.1", 27035, 1}, c, "1234"); });
  std::this_thread::sleep_for(std::chrono::milliseconds(80));
  pairing.cancel();
  assert(pair.wait_for(std::chrono::seconds(2)) == std::future_status::ready);
  assert(pair.get() == -2);

  int fd = socket(AF_INET, SOCK_DGRAM, 0);
  assert(fd >= 0);
  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
  assert(bind(fd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) == 0);
  socklen_t size = sizeof(addr);
  assert(getsockname(fd, reinterpret_cast<sockaddr*>(&addr), &size) == 0);
  timeval timeout{2, 0};
  setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
  Runtime stream;
  auto run = std::async(std::launch::async, [&] {
    return stream.run(
        {"127.0.0.1", ntohs(addr.sin_port), 9}, c, 620, false, false, std::make_shared<NullSink>(),
        {1280, 720, 30, 12000, 4, 6});
  });
  uint8_t bytes[4096];
  ssize_t length = recv(fd, bytes, sizeof(bytes), 0);
  assert(length > 16);
  uint32_t hs = le(bytes + 8);
  assert(hs < static_cast<size_t>(length) - 16);
  uint32_t ps = le(bytes + 12 + hs);
  assert(16 + hs + ps == static_cast<size_t>(length));
  auto* request = cmsg_remote_device_streaming_request__unpack(nullptr, ps, bytes + 16 + hs);
  assert(request && request->has_gameid && request->gameid == 620);
  assert(!request->stream_desktop && request->audio_channel_count == 6);
  assert(request->gamepad_count == 4);
  assert(request->maximum_resolution_x == 1280 && request->maximum_resolution_y == 720);
  cmsg_remote_device_streaming_request__free_unpacked(request, nullptr);
  stream.cancel();
  assert(run.wait_for(std::chrono::seconds(2)) == std::future_status::ready);
  assert(run.get() == -2);
  close(fd);
  // Completion/input after teardown must be harmless.
  stream.frameComplete(1, true);
  stream.key(4, false);
  stream.mouse(0, 0, 1, false);
}
