// SPDX-License-Identifier: GPL-3.0-or-later
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cassert>
#include <chrono>
#include <cstring>
#include <future>
#include <thread>

#include "steam_runtime.h"
extern "C" {
#include "protobuf/discovery.pb-c.h"
#include "session/frame_tracker.h"
}
using namespace plezy::steam;
namespace plezy::steam {
struct RuntimeTest {
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
}
uint32_t le(const uint8_t* p) {
  return uint32_t(p[0]) | uint32_t(p[1]) << 8 | uint32_t(p[2]) << 16 | uint32_t(p[3]) << 24;
}
int main() {
  frameOwnership();
  Credentials c{};
  c.device = 123;
  c.user = 456;
  c.key.fill(42);
  Runtime invalid;
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
    return stream.run({"127.0.0.1", ntohs(addr.sin_port), 9}, c, 620, false, false, std::make_shared<NullSink>());
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
  assert(!request->stream_desktop && request->audio_channel_count == 2);
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
