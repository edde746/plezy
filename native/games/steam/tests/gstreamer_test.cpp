// SPDX-License-Identifier: GPL-3.0-or-later
#include <gst/app/gstappsink.h>

#include <cassert>
#include <set>
#include <thread>

#include "steam_gstreamer.h"
using namespace plezy::steam;
int main() {
  if (!GStreamerSink::supported()) return 1;
  std::mutex mutex;
  std::condition_variable ready;
  std::set<uint32_t> presented, completed;
  bool failed = false;
  GStreamerSink receiver(
      [&](DecodedPixels&& pixels) {
        assert(pixels.width == 320 && pixels.height == 240 && pixels.rgba.size() == 320 * 240 * 4);
        // Source is solid red: prove we decoded actual pixels, not just headers.
        assert(pixels.rgba[0] > 200 && pixels.rgba[1] < 50 && pixels.rgba[2] < 50 && pixels.rgba[3] == 255);
        std::lock_guard<std::mutex> lock(mutex);
        assert(presented.insert(pixels.id).second);
        ready.notify_all();
        return true;
      },
      [&](uint32_t id, bool) {
        std::lock_guard<std::mutex> lock(mutex);
        assert(completed.insert(id).second);
        ready.notify_all();
      },
      [&](bool) {
        std::lock_guard<std::mutex> lock(mutex);
        failed = true;
        ready.notify_all();
      },
      true);
  GError* error = nullptr;
  auto* source = gst_parse_launch(
      "videotestsrc num-buffers=12 pattern=red ! "
      "video/x-raw,width=320,height=240,framerate=30/1 ! openh264enc gop-size=1 ! "
      "h264parse ! video/x-h264,stream-format=byte-stream,alignment=au ! appsink name=encoded sync=false",
      &error);
  if (error) {
    g_error_free(error);
    if (source) gst_object_unref(source);
    return 1;
  }
  assert(source);
  auto* encoded = gst_bin_get_by_name(GST_BIN(source), "encoded");
  assert(gst_element_set_state(source, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE);
  assert(!receiver.video(9, 320, 240, nullptr, 0));
  assert(!receiver.video(4, 100000, 240, nullptr, 0));
  assert(receiver.video(4, 320, 240, nullptr, 0));
  assert(!receiver.audio(8, 48000));
  assert(receiver.audio(6, 48000));
  std::array<int16_t, 960 * 6> pcm{};
  receiver.volume(true);
  for (uint32_t id = 1; id <= 12; ++id) {
    auto* sample = gst_app_sink_try_pull_sample(GST_APP_SINK(encoded), 3 * GST_SECOND);
    assert(sample);
    GstMapInfo map{};
    auto* buffer = gst_sample_get_buffer(sample);
    assert(gst_buffer_map(buffer, &map, GST_MAP_READ));
    assert(receiver.frame(map.data, map.size, id, true));
    receiver.samples(pcm.data(), pcm.size());
    gst_buffer_unmap(buffer, &map);
    gst_sample_unref(sample);
    std::unique_lock<std::mutex> lock(mutex);
    ready.wait_for(lock, std::chrono::seconds(3), [&] { return failed || presented.count(id) || completed.count(id); });
    assert(!failed && presented.count(id));
  }
  // Reconfigure a decoder without retaining stale pending tickets/PCM formats.
  assert(receiver.video(4, 640, 360, nullptr, 0));
  assert(receiver.audio(2, 48000));
  receiver.close();
  uint8_t dummy[4]{};
  assert(!receiver.frame(dummy, sizeof(dummy), 100, true));
  receiver.close();  // Idempotent teardown.
  gst_element_set_state(source, GST_STATE_NULL);
  gst_object_unref(encoded);
  gst_object_unref(source);
  assert(!failed && presented.size() == 12);
}
