// SPDX-License-Identifier: GPL-3.0-or-later
#include "steam_gstreamer.h"

#include <gst/app/gstappsink.h>
#include <gst/app/gstappsrc.h>
#include <gst/video/video.h>

#include <algorithm>
#include <deque>
#include <map>
#include <thread>

#include "steam_h26x.h"

namespace plezy::steam {
namespace {
bool initialize() {
  static bool ok = gst_init_check(nullptr, nullptr, nullptr);
  return ok;
}
bool factory(const char* name) {
  auto* f = gst_element_factory_find(name);
  if (f) gst_object_unref(f);
  return f != nullptr;
}
void destroy(GstElement*& pipeline, GstElement*& src, GstElement*& sink) {
  if (pipeline) gst_element_set_state(pipeline, GST_STATE_NULL);
  if (src) gst_object_unref(src);
  if (sink) gst_object_unref(sink);
  if (pipeline) gst_object_unref(pipeline);
  pipeline = src = sink = nullptr;
}
bool healthy(GstElement* pipeline) {
  if (!pipeline) return true;
  auto* bus = gst_element_get_bus(pipeline);
  auto* message = gst_bus_pop_filtered(bus, GstMessageType(GST_MESSAGE_ERROR | GST_MESSAGE_EOS));
  bool ok = message == nullptr;
  if (message) gst_message_unref(message);
  gst_object_unref(bus);
  return ok;
}
}  // namespace

struct GStreamerSink::Impl {
  Present present;
  Complete complete;
  Failed failed;
  struct Video {
    std::vector<uint8_t> bytes;
    uint32_t id = 0;
    bool key = false;
  };
  struct Config {
    int codec = 0, width = 0, height = 0;
    std::vector<uint8_t> extra;
  };
  std::mutex mutex;
  std::condition_variable ready;
  std::deque<Video> videos;
  struct Audio {
    uint64_t epoch;
    std::vector<int16_t> pcm;
  };
  std::deque<Audio> audioPackets;
  Config config;
  uint64_t videoEpoch = 0, audioEpoch = 0;
  int audioChannels = 0;
  bool stopping = false, audible = false, testAudio = false;
  std::atomic<bool> stopped{false};
  std::thread worker;

  GstElement *videoPipeline = nullptr, *videoSrc = nullptr, *videoSink = nullptr;
  GstElement *audioPipeline = nullptr, *audioSrc = nullptr, *audioVolume = nullptr;
  // Timestamps are identifiers, not fabricated latency measurements.
  struct Pending {
    uint32_t id;
    std::chrono::steady_clock::time_point start;
  };
  std::map<GstClockTime, Pending> pending;
  GstClockTime nextPts = 1;
  H26xParser parser;  // Decoder worker only; normalize every host framing mode.

  Impl(Present p, Complete c, Failed f, bool test)
      : present(std::move(p)), complete(std::move(c)), failed(std::move(f)), testAudio(test) {
    if (!initialize()) {
      stopped = true;
      failed(false);
      return;
    }
    worker = std::thread([this] { loop(); });
  }
  ~Impl() { close(); }
  void close() {
    {
      std::lock_guard<std::mutex> lock(mutex);
      stopping = true;
      ready.notify_all();
    }
    if (worker.joinable()) worker.join();
  }
  void resetVideo() {
    destroy(videoPipeline, videoSrc, videoSink);
    for (auto& item : pending) complete(item.second.id, false);
    pending.clear();
  }
  bool configureVideo(const Config& c) {
    resetVideo();
    if (!parser.configure(c.codec, c.extra.data(), c.extra.size())) return false;
    const char* description =
        c.codec == 4 ? "appsrc name=input is-live=true format=time block=false max-bytes=8388608 max-buffers=4 ! "
                       "h264parse ! video/x-h264,width=(int)[1,1920],height=(int)[1,1080] ! avdec_h264 max-threads=2 ! "
                       "videoconvert ! video/x-raw,format=RGBA ! "
                       "appsink name=output sync=false max-buffers=2 drop=true"
                     : "appsrc name=input is-live=true format=time block=false max-bytes=8388608 max-buffers=4 ! "
                       "h265parse ! video/x-h265,width=(int)[1,1920],height=(int)[1,1080] ! avdec_h265 max-threads=2 ! "
                       "videoconvert ! video/x-raw,format=RGBA ! "
                       "appsink name=output sync=false max-buffers=2 drop=true";
    GError* error = nullptr;
    videoPipeline = gst_parse_launch(description, &error);
    if (error) {
      g_error_free(error);
      resetVideo();
      return false;
    }
    if (!videoPipeline) return false;
    videoSrc = gst_bin_get_by_name(GST_BIN(videoPipeline), "input");
    videoSink = gst_bin_get_by_name(GST_BIN(videoPipeline), "output");
    auto* caps = gst_caps_new_simple(
        c.codec == 4 ? "video/x-h264" : "video/x-h265", "stream-format", G_TYPE_STRING, "byte-stream", "alignment",
        G_TYPE_STRING, "au", nullptr);
    gst_app_src_set_caps(GST_APP_SRC(videoSrc), caps);
    gst_caps_unref(caps);
    if (gst_element_set_state(videoPipeline, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) return false;
    return true;
  }
  bool configureAudio(int channels) {
    destroy(audioPipeline, audioSrc, audioVolume);
    GError* error = nullptr;
    const char* description = testAudio
                                  ? "appsrc name=input is-live=true format=time do-timestamp=true block=false "
                                    "max-bytes=115200 leaky-type=downstream ! "
                                    "volume name=volume ! audioconvert ! audioresample ! fakesink sync=false"
                                  : "appsrc name=input is-live=true format=time do-timestamp=true block=false "
                                    "max-bytes=115200 leaky-type=downstream ! "
                                    "volume name=volume ! audioconvert ! audioresample ! autoaudiosink sync=false";
    audioPipeline = gst_parse_launch(description, &error);
    if (error) {
      g_error_free(error);
      destroy(audioPipeline, audioSrc, audioVolume);
      return false;
    }
    if (!audioPipeline) return false;
    audioSrc = gst_bin_get_by_name(GST_BIN(audioPipeline), "input");
    audioVolume = gst_bin_get_by_name(GST_BIN(audioPipeline), "volume");
    auto* caps = gst_caps_new_simple(
        "audio/x-raw", "format", G_TYPE_STRING, "S16LE", "layout", G_TYPE_STRING, "interleaved", "rate", G_TYPE_INT,
        48000, "channels", G_TYPE_INT, channels, nullptr);
    const guint64 mask = channels == 6 ? 0x3f : channels == 4 ? 0x33 : channels == 2 ? 3 : 0;
    gst_caps_set_simple(caps, "channel-mask", GST_TYPE_BITMASK, mask, nullptr);
    gst_app_src_set_caps(GST_APP_SRC(audioSrc), caps);
    gst_caps_unref(caps);
    // Muted before playback, including an audio reconfiguration.
    g_object_set(audioVolume, "mute", TRUE, nullptr);
    return gst_element_set_state(audioPipeline, GST_STATE_PLAYING) != GST_STATE_CHANGE_FAILURE;
  }
  void decode(Video&& frame) {
    if (!videoSrc || pending.size() >= 8) {
      complete(frame.id, false);
      return;
    }
    std::vector<uint8_t> normalized;
    if (!parser.annexB(frame.bytes.data(), frame.bytes.size(), normalized) || normalized.size() > 2 * 1024 * 1024) {
      complete(frame.id, false);
      failed(false);
      return;
    }
    if (normalized.empty()) {
      complete(frame.id, false);
      return;
    }
    auto* buffer = gst_buffer_new_allocate(nullptr, normalized.size(), nullptr);
    if (!buffer) {
      complete(frame.id, false);
      return;
    }
    gst_buffer_fill(buffer, 0, normalized.data(), normalized.size());
    const auto pts = nextPts++ * GST_MSECOND;
    GST_BUFFER_PTS(buffer) = pts;
    if (!frame.key) GST_BUFFER_FLAG_SET(buffer, GST_BUFFER_FLAG_DELTA_UNIT);
    pending.emplace(pts, Pending{frame.id, std::chrono::steady_clock::now()});
    if (gst_app_src_push_buffer(GST_APP_SRC(videoSrc), buffer) != GST_FLOW_OK) {
      pending.erase(pts);
      complete(frame.id, false);
    }
  }
  void drain() {
    if (!videoSink) return;
    for (int count = 0; count < 4; ++count) {
      auto* sample = gst_app_sink_try_pull_sample(GST_APP_SINK(videoSink), 0);
      if (!sample) break;
      auto* buffer = gst_sample_get_buffer(sample);
      auto it = pending.find(GST_BUFFER_PTS(buffer));
      if (it != pending.end()) {
        auto id = it->second.id;
        pending.erase(it);
        GstVideoInfo info{};
        GstVideoFrame image{};
        bool accepted = false;
        const bool parsed = gst_video_info_from_caps(&info, gst_sample_get_caps(sample));
        const bool hdr = parsed && (info.colorimetry.transfer == GST_VIDEO_TRANSFER_SMPTE2084 ||
                                    info.colorimetry.transfer == GST_VIDEO_TRANSFER_ARIB_STD_B67);
        if (hdr) failed(false);  // This Flutter texture is SDR; never relabel HDR pixels.
        if (parsed && !hdr && GST_VIDEO_INFO_WIDTH(&info) > 0 && GST_VIDEO_INFO_HEIGHT(&info) > 0 &&
            GST_VIDEO_INFO_WIDTH(&info) <= 1920 && GST_VIDEO_INFO_HEIGHT(&info) <= 1080 &&
            GST_VIDEO_INFO_FORMAT(&info) == GST_VIDEO_FORMAT_RGBA &&
            gst_video_frame_map(&image, &info, buffer, GST_MAP_READ)) {
          DecodedPixels pixels;
          pixels.id = id;
          pixels.width = info.width;
          pixels.height = info.height;
          pixels.rgba.resize(size_t(pixels.width) * pixels.height * 4);
          const auto* source = static_cast<const uint8_t*>(GST_VIDEO_FRAME_PLANE_DATA(&image, 0));
          const int stride = GST_VIDEO_FRAME_PLANE_STRIDE(&image, 0);
          if (stride >= int(pixels.width * 4)) {
            for (unsigned y = 0; y < pixels.height; ++y)
              std::copy_n(
                  source + size_t(y) * stride, pixels.width * 4, pixels.rgba.data() + size_t(y) * pixels.width * 4);
            accepted = present(std::move(pixels));
          }
          gst_video_frame_unmap(&image);
        }
        if (!accepted) complete(id, false);
      }
      gst_sample_unref(sample);
    }
    const auto now = std::chrono::steady_clock::now();
    for (auto it = pending.begin(); it != pending.end();) {
      if (now - it->second.start > std::chrono::seconds(2)) {
        complete(it->second.id, false);
        it = pending.erase(it);
      } else
        ++it;
    }
  }
  void loop() {
    uint64_t configuredVideo = 0, configuredAudio = 0;
    try {
      for (;;) {
        Config next;
        Video video;
        Audio audio{};
        uint64_t ve, ae;
        int channels;
        bool enabled;
        {
          std::unique_lock<std::mutex> lock(mutex);
          ready.wait_for(lock, std::chrono::milliseconds(2), [&] {
            return stopping || !videos.empty() || !audioPackets.empty() || videoEpoch != configuredVideo ||
                   audioEpoch != configuredAudio;
          });
          if (stopping) break;
          ve = videoEpoch;
          ae = audioEpoch;
          channels = audioChannels;
          enabled = audible;
          if (ve != configuredVideo) next = config;
          if (!videos.empty()) {
            video = std::move(videos.front());
            videos.pop_front();
          }
          if (!audioPackets.empty()) {
            audio = std::move(audioPackets.front());
            audioPackets.pop_front();
          }
        }
        if (ve != configuredVideo) {
          if (!configureVideo(next)) {
            if (video.id) complete(video.id, false);
            failed(false);
            break;
          }
          configuredVideo = ve;
        }
        if (ae != configuredAudio) {
          if (!configureAudio(channels)) {
            if (video.id) complete(video.id, false);
            failed(true);
            break;
          }
          configuredAudio = ae;
        }
        if (audioVolume) g_object_set(audioVolume, "mute", !enabled, nullptr);
        if (audioSrc && audio.epoch == configuredAudio && !audio.pcm.empty()) {
          auto* buffer = gst_buffer_new_allocate(nullptr, audio.pcm.size() * sizeof(int16_t), nullptr);
          if (!buffer) {
            failed(true);
            break;
          }
          gst_buffer_fill(buffer, 0, audio.pcm.data(), audio.pcm.size() * sizeof(int16_t));
          gst_app_src_push_buffer(GST_APP_SRC(audioSrc), buffer);
        }
        if (video.id) decode(std::move(video));
        drain();
        if (!healthy(videoPipeline)) {
          failed(false);
          break;
        }
        if (!healthy(audioPipeline)) {
          failed(true);
          break;
        }
      }
    } catch (...) {
      failed(false);
    }
    stopped = true;
    resetVideo();
    destroy(audioPipeline, audioSrc, audioVolume);
    std::lock_guard<std::mutex> lock(mutex);
    for (auto& v : videos) complete(v.id, false);
    videos.clear();
    audioPackets.clear();
  }
};

GStreamerSink::GStreamerSink(Present p, Complete c, Failed f, bool test)
    : impl_(std::make_unique<Impl>(std::move(p), std::move(c), std::move(f), test)) {}
GStreamerSink::~GStreamerSink() = default;
bool GStreamerSink::supported(bool hevc) {
  return initialize() && factory("appsrc") && factory("appsink") && factory("videoconvert") &&
         factory(hevc ? "h265parse" : "h264parse") && factory(hevc ? "avdec_h265" : "avdec_h264") &&
         factory("volume") && factory("audioconvert") && factory("audioresample") && factory("autoaudiosink");
}
bool GStreamerSink::video(int codec, int w, int h, const uint8_t* extra, size_t length) {
  if ((codec != 4 && codec != 5) || w < 1 || h < 1 || w > 1920 || h > 1080 || length > 65536 || (length && !extra) ||
      impl_->stopped)
    return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping) return false;
  for (auto& v : impl_->videos) impl_->complete(v.id, false);
  impl_->videos.clear();
  impl_->config = {codec, w, h, {}};
  if (length) impl_->config.extra.assign(extra, extra + length);
  ++impl_->videoEpoch;
  impl_->ready.notify_one();
  return true;
}
bool GStreamerSink::frame(const uint8_t* bytes, size_t length, uint32_t id, bool key) {
  if (!bytes || !length || length > 2 * 1024 * 1024 || !id || impl_->stopped) return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping || !impl_->videoEpoch || impl_->videos.size() >= 4) return false;
  impl_->videos.push_back({{bytes, bytes + length}, id, key});
  impl_->ready.notify_one();
  return true;
}
bool GStreamerSink::audio(int channels, int rate) {
  if ((channels != 1 && channels != 2 && channels != 4 && channels != 6) || rate != 48000 || impl_->stopped)
    return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping) return false;
  impl_->audioChannels = channels;
  impl_->audioPackets.clear();
  ++impl_->audioEpoch;
  impl_->ready.notify_one();
  return true;
}
void GStreamerSink::audioUnavailable() { impl_->failed(true); }
void GStreamerSink::samples(const int16_t* pcm, size_t count) {
  if (!pcm || !count || count > AudioDecoder::maxSamples || impl_->stopped) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping || !impl_->audioChannels || count % impl_->audioChannels) return;
  if (impl_->audioPackets.size() >= 8) impl_->audioPackets.pop_front();
  impl_->audioPackets.push_back({impl_->audioEpoch, {pcm, pcm + count}});
  impl_->ready.notify_one();
}
void GStreamerSink::volume(bool enabled) {
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->audible = enabled;
}
void GStreamerSink::close() { impl_->close(); }
}  // namespace plezy::steam
