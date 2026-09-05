#ifndef MPV_HDR_PROBE_H_
#define MPV_HDR_PROBE_H_

#include <Windows.h>
#include <dxgi1_6.h>
#include <mpv/client.h>

#include <chrono>
#include <functional>
#include <string>

namespace mpv {

// Diagnostic for #2191: watches the two inputs libplacebo keys its tone-map and
// gamut-map LUTs on and reports sampled changes into the app log.
//
//  * mpv `video-target-params` (the destination colour space the renderer was
//    handed: derived per frame from DXGI_OUTPUT_DESC1 and the DisplayConfig SDR
//    white level) and `video-out-params` (the source frame's HDR metadata),
//    polled no more often than every 300 ms. Sampling can miss changes between
//    reads; the counts are not per-frame LUT invalidation counts.
//  * The raw DXGI output description and SDR white level of the monitor the
//    video window sits on, plus whether the DXGI factory still reports
//    IsCurrent(); mpv re-reads all of these on every drawn frame.
//
// Output is rate limited: each change stream logs its first entries verbatim,
// then only every 50th, and a summary line lands every ~10 s while playing.
class HdrProbe {
 public:
  using Logger = std::function<void(const std::string& text)>;

  HdrProbe(mpv_handle* mpv, HWND hwnd, Logger logger);
  ~HdrProbe();

  HdrProbe(const HdrProbe&) = delete;
  HdrProbe& operator=(const HdrProbe&) = delete;

  // Called after every dequeued event or wait timeout, with no fixed cadence.
  // Steady-clock deadlines bound the work independently of event traffic.
  void Tick();

  // Resets per-file state on file load so counts are per playback.
  void OnFileLoaded();

 private:
  struct Stream {
    const char* name;
    std::string last;
    int changes = 0;
    void Observe(const std::string& now, const Logger& log);
  };

  void ReadParams(const char* property, Stream& static_stream, Stream* dynamic_stream = nullptr);
  std::string ReadDisplay();
  void Summarize();

  mpv_handle* mpv_;
  HWND hwnd_;
  Logger logger_;
  IDXGIFactory1* factory_ = nullptr;
  int factory_recreations_ = 0;
  std::chrono::steady_clock::time_point next_sample_{};
  std::chrono::steady_clock::time_point next_display_{};
  std::chrono::steady_clock::time_point last_summary_;
  Stream target_{"target-params"};
  Stream source_static_{"source-params(static)"};
  Stream source_dynamic_{"source-params(dynamic)"};
  Stream display_{"display"};
};

}  // namespace mpv

#endif  // MPV_HDR_PROBE_H_
