// SPDX-License-Identifier: GPL-3.0-or-later
#include <cassert>
#include <condition_variable>

#include "SteamWindowsSink.h"
#include "red_h264.h"

int main() {
  using namespace plezy::steam;
  // Windows N without the Media Feature Pack is an unsupported deployment,
  // not a passing receiver test. CI must actually have a decoder installed.
  assert(WindowsSink::supported());
  for (int iteration = 0; iteration < 3; ++iteration) {
    std::mutex mutex;
    std::condition_variable ready;
    bool failed = false, presented = false, red = false;
    WindowsSink sink(
        [&](DecodedPixels&& image) {
          const bool valid = image.id == 7 && image.width == 64 && image.height == 64 &&
                             image.rgba.size() == 64 * 64 * 4 && image.rgba[0] > 200 && image.rgba[1] < 50 &&
                             image.rgba[2] < 50 && image.rgba[3] == 255;
          {
            std::lock_guard<std::mutex> lock(mutex);
            presented = true;
            red = valid;
          }
          ready.notify_all();
          return true;
        },
        [](uint32_t, bool) {},
        [&](bool) {
          {
            std::lock_guard<std::mutex> lock(mutex);
            failed = true;
          }
          ready.notify_all();
        });
    assert(!sink.video(99, 64, 64, nullptr, 0));
    assert(!sink.video(4, 100000, 64, nullptr, 0));
    assert(!sink.frame(redH264, 2 * 1024 * 1024 + 1, 1, true));
    assert(!sink.audio(8, 48000));
    assert(sink.video(4, 64, 64, nullptr, 0));
    assert(sink.frame(redH264, sizeof(redH264), 7, true));
    {
      std::unique_lock<std::mutex> lock(mutex);
      ready.wait_for(lock, std::chrono::seconds(5), [&] { return presented || failed; });
      assert(!failed && presented && red);
    }
    sink.close();
    sink.close();
    assert(!sink.frame(redH264, sizeof(redH264), 8, true));
  }
}
