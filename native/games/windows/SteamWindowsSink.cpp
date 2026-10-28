// SPDX-License-Identifier: GPL-3.0-or-later
#include "SteamWindowsSink.h"

#include "steam_h26x.h"
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

// Media Foundation and KS declarations depend on the Windows base types.
#include <codecapi.h>
#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mftransform.h>
#include <wrl/client.h>
#include <xaudio2.h>

// KS must follow Media Foundation/DirectShow to avoid duplicate SDK layouts.
#include <ks.h>
#include <ksmedia.h>

#include <algorithm>
#include <deque>
#include <map>
#include <thread>

using Microsoft::WRL::ComPtr;
namespace plezy::steam {
namespace {
bool mediaFramework() {
  // On Windows N, absent Media Feature Pack components must leave Games in
  // library mode. The MSVC app delay-loads mfplat; probe before its first call.
  static const HMODULE module = LoadLibraryExW(L"mfplat.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
  return module != nullptr;
}
struct MediaScope {
  HRESULT com = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  bool ready = mediaFramework() && (SUCCEEDED(com) || com == RPC_E_CHANGED_MODE) &&
               SUCCEEDED(MFStartup(MF_VERSION, MFSTARTUP_LITE));
  ~MediaScope() {
    if (ready) MFShutdown();
    if (SUCCEEDED(com)) CoUninitialize();
  }
};
ComPtr<IMFTransform> decoder(bool hevc) {
  MFT_REGISTER_TYPE_INFO input{MFMediaType_Video, hevc ? MFVideoFormat_HEVC : MFVideoFormat_H264};
  MFT_REGISTER_TYPE_INFO output{MFMediaType_Video, MFVideoFormat_NV12};
  IMFActivate** candidates = nullptr;
  UINT32 count = 0;
  ComPtr<IMFTransform> result;
  if (SUCCEEDED(MFTEnumEx(
          MFT_CATEGORY_VIDEO_DECODER, MFT_ENUM_FLAG_SYNCMFT | MFT_ENUM_FLAG_SORTANDFILTER, &input, &output, &candidates,
          &count))) {
    for (UINT32 i = 0; i < count; ++i) {
      if (!result) candidates[i]->ActivateObject(IID_PPV_ARGS(&result));
      candidates[i]->Release();
    }
  }
  CoTaskMemFree(candidates);
  return result;
}
// Source PCM has the Windows speaker order, established by the shared Opus
// mapping validator: FL, FR, FC, LFE, BL, BR (quad omits FC/LFE).
struct AudioBuffer {
  std::vector<int16_t> pcm;
  std::atomic<bool> done{false};
};
struct AudioCallbacks final : IXAudio2VoiceCallback {
  std::atomic<bool> failed{false};
  void STDMETHODCALLTYPE OnVoiceProcessingPassStart(UINT32) override {}
  void STDMETHODCALLTYPE OnVoiceProcessingPassEnd() override {}
  void STDMETHODCALLTYPE OnStreamEnd() override {}
  void STDMETHODCALLTYPE OnBufferStart(void*) override {}
  void STDMETHODCALLTYPE OnBufferEnd(void* context) override { static_cast<AudioBuffer*>(context)->done = true; }
  void STDMETHODCALLTYPE OnLoopEnd(void*) override {}
  void STDMETHODCALLTYPE OnVoiceError(void*, HRESULT) override { failed = true; }
};
}  // namespace
struct WindowsSink::Impl {
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
  struct Audio {
    uint64_t epoch = 0;
    std::vector<int16_t> pcm;
  };
  std::mutex mutex;
  std::condition_variable ready;
  std::deque<Video> videos;
  std::deque<Audio> audioPackets;
  Config config;
  uint64_t videoEpoch = 0, audioEpoch = 0;
  int audioChannels = 0;
  bool stopping = false, audible = false;
  std::atomic<bool> stopped{false};
  std::thread worker;
  ComPtr<IMFTransform> transform;
  H26xParser parser;
  ComPtr<IMFMediaType> outputType;
  struct Pending {
    uint32_t id;
    std::chrono::steady_clock::time_point start;
  };
  std::map<LONGLONG, Pending> pending;
  LONGLONG nextPts = 1;
  ComPtr<IXAudio2> audioEngine;
  IXAudio2MasteringVoice* mastering = nullptr;
  IXAudio2SourceVoice* voice = nullptr;
  AudioCallbacks callbacks;
  std::deque<std::unique_ptr<AudioBuffer>> submittedAudio;

  Impl(Present p, Complete c, Failed f) : present(std::move(p)), complete(std::move(c)), failed(std::move(f)) {
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
    if (transform) transform->ProcessMessage(MFT_MESSAGE_COMMAND_FLUSH, 0);
    outputType.Reset();
    transform.Reset();
    for (auto& item : pending) complete(item.second.id, false);
    pending.clear();
  }
  bool selectOutput() {
    for (DWORD i = 0; i < 64; ++i) {
      ComPtr<IMFMediaType> type;
      if (FAILED(transform->GetOutputAvailableType(0, i, &type))) break;
      GUID subtype{};
      if (FAILED(type->GetGUID(MF_MT_SUBTYPE, &subtype)) || subtype != MFVideoFormat_NV12) continue;
      UINT32 w = 0, h = 0;
      if (FAILED(MFGetAttributeSize(type.Get(), MF_MT_FRAME_SIZE, &w, &h)) || !w || !h || w > 1920 || h > 1080 ||
          w % 2 || h % 2)
        continue;
      UINT32 transfer = 0, primaries = 0;
      type->GetUINT32(MF_MT_TRANSFER_FUNCTION, &transfer);
      type->GetUINT32(MF_MT_VIDEO_PRIMARIES, &primaries);
      // This is an eight-bit SDR Flutter texture, not an HDR surface.
      if (transfer == MFVideoTransFunc_2084 || transfer == MFVideoTransFunc_HLG || primaries == MFVideoPrimaries_BT2020)
        return false;
      if (SUCCEEDED(transform->SetOutputType(0, type.Get(), 0))) {
        outputType = type;
        return true;
      }
    }
    return false;
  }
  bool configureVideo(const Config& c) {
    resetVideo();
    if (!parser.configure(c.codec, c.extra.data(), c.extra.size())) return false;
    transform = decoder(c.codec == 5);
    if (!transform) return false;
    ComPtr<IMFAttributes> attributes;
    if (SUCCEEDED(transform->GetAttributes(&attributes))) {
      attributes->SetUINT32(CODECAPI_AVLowLatencyMode, TRUE);
      attributes->SetUINT32(CODECAPI_AVDecNumWorkerThreads, 2);
      attributes->SetUINT32(CODECAPI_AVDecVideoMaxCodedWidth, 1920);
      attributes->SetUINT32(CODECAPI_AVDecVideoMaxCodedHeight, 1088);
    }
    ComPtr<IMFMediaType> type;
    if (FAILED(MFCreateMediaType(&type))) return false;
    type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    type->SetGUID(MF_MT_SUBTYPE, c.codec == 5 ? MFVideoFormat_HEVC : MFVideoFormat_H264);
    MFSetAttributeSize(type.Get(), MF_MT_FRAME_SIZE, UINT32(c.width), UINT32(c.height));
    MFSetAttributeRatio(type.Get(), MF_MT_FRAME_RATE, 60, 1);
    MFSetAttributeRatio(type.Get(), MF_MT_PIXEL_ASPECT_RATIO, 1, 1);
    type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
    if (FAILED(transform->SetInputType(0, type.Get(), 0)) || !selectOutput()) return false;
    if (FAILED(transform->ProcessMessage(MFT_MESSAGE_NOTIFY_BEGIN_STREAMING, 0)) ||
        FAILED(transform->ProcessMessage(MFT_MESSAGE_NOTIFY_START_OF_STREAM, 0)))
      return false;
    return true;
  }
  bool submit(const std::vector<uint8_t>& bytes, LONGLONG pts, bool key) {
    ComPtr<IMFSample> sample;
    ComPtr<IMFMediaBuffer> buffer;
    if (FAILED(MFCreateSample(&sample)) || FAILED(MFCreateMemoryBuffer(DWORD(bytes.size()), &buffer))) return false;
    BYTE* data = nullptr;
    if (FAILED(buffer->Lock(&data, nullptr, nullptr))) return false;
    std::copy(bytes.begin(), bytes.end(), data);
    buffer->Unlock();
    if (FAILED(buffer->SetCurrentLength(DWORD(bytes.size()))) || FAILED(sample->AddBuffer(buffer.Get()))) return false;
    sample->SetSampleTime(pts);
    sample->SetSampleDuration(166667);
    sample->SetUINT32(MFSampleExtension_CleanPoint, key ? TRUE : FALSE);
    HRESULT status = transform->ProcessInput(0, sample.Get(), 0);
    if (status == MF_E_NOTACCEPTING) {
      if (!drain()) return false;
      status = transform->ProcessInput(0, sample.Get(), 0);
    }
    return SUCCEEDED(status);
  }
  bool pixels(IMFSample* sample, uint32_t id) {
    UINT32 w = 0, h = 0;
    if (FAILED(MFGetAttributeSize(outputType.Get(), MF_MT_FRAME_SIZE, &w, &h)) || !w || !h || w > 1920 || h > 1080)
      return false;
    UINT32 matrix = MFVideoTransferMatrix_BT709, range = MFNominalRange_16_235;
    outputType->GetUINT32(MF_MT_YUV_MATRIX, &matrix);
    outputType->GetUINT32(MF_MT_VIDEO_NOMINAL_RANGE, &range);
    if (matrix != MFVideoTransferMatrix_BT709 && matrix != MFVideoTransferMatrix_BT601 && matrix != 0) return false;
    if (range != MFNominalRange_16_235 && range != MFNominalRange_0_255 && range != 0) return false;
    ComPtr<IMFMediaBuffer> buffer;
    if (FAILED(sample->ConvertToContiguousBuffer(&buffer))) return false;
    ComPtr<IMF2DBuffer> plane;
    std::vector<uint8_t> bytes;
    size_t stride = w;
    if (SUCCEEDED(buffer.As(&plane))) {
      DWORD length = 0;
      if (FAILED(plane->GetContiguousLength(&length)) || length != w * h * 3 / 2) return false;
      bytes.resize(length);
      if (FAILED(plane->ContiguousCopyTo(bytes.data(), length))) return false;
    } else {
      UINT32 pitch = w;
      outputType->GetUINT32(MF_MT_DEFAULT_STRIDE, &pitch);
      if (pitch < w || pitch > 8192) return false;
      stride = pitch;
      BYTE* data = nullptr;
      DWORD length = 0;
      if (FAILED(buffer->Lock(&data, nullptr, &length))) return false;
      const size_t needed = stride * h * 3 / 2;
      if (length >= needed && length <= 16 * 1024 * 1024) bytes.assign(data, data + needed);
      buffer->Unlock();
      if (bytes.empty()) return false;
    }
    DecodedPixels result;
    result.id = id;
    result.width = w;
    result.height = h;
    result.rgba.resize(size_t(w) * h * 4);
    const bool full = range == MFNominalRange_0_255;
    const bool bt601 = matrix == MFVideoTransferMatrix_BT601;
    auto clamp = [](float v) { return uint8_t(std::clamp(v + 0.5f, 0.0f, 255.0f)); };
    for (UINT32 y = 0; y < h; ++y)
      for (UINT32 x = 0; x < w; ++x) {
        const size_t uv = stride * h + stride * (y / 2) + (x & ~1u);
        const float luma = (float(bytes[stride * y + x]) - (full ? 0.0f : 16.0f)) * (full ? 1.0f : 255.0f / 219.0f);
        const float u = (float(bytes[uv]) - 128.0f) * (full ? 1.0f : 255.0f / 224.0f);
        const float v = (float(bytes[uv + 1]) - 128.0f) * (full ? 1.0f : 255.0f / 224.0f);
        auto* rgb = result.rgba.data() + (size_t(y) * w + x) * 4;
        rgb[0] = clamp(luma + (bt601 ? 1.402f : 1.5748f) * v);
        rgb[1] = clamp(luma - (bt601 ? 0.344136f : 0.187324f) * u - (bt601 ? 0.714136f : 0.468124f) * v);
        rgb[2] = clamp(luma + (bt601 ? 1.772f : 1.8556f) * u);
        rgb[3] = 255;
      }
    return present(std::move(result));
  }
  bool drain() {
    for (int iteration = 0; iteration < 8; ++iteration) {
      MFT_OUTPUT_STREAM_INFO info{};
      if (FAILED(transform->GetOutputStreamInfo(0, &info))) return false;
      ComPtr<IMFSample> allocated;
      if (!(info.dwFlags & MFT_OUTPUT_STREAM_PROVIDES_SAMPLES)) {
        ComPtr<IMFMediaBuffer> buffer;
        if (!info.cbSize || info.cbSize > 16 * 1024 * 1024 || FAILED(MFCreateSample(&allocated)) ||
            FAILED(MFCreateAlignedMemoryBuffer(info.cbSize, info.cbAlignment ? info.cbAlignment - 1 : 0, &buffer)) ||
            FAILED(allocated->AddBuffer(buffer.Get())))
          return false;
      }
      MFT_OUTPUT_DATA_BUFFER data{0, allocated.Get(), 0, nullptr};
      DWORD status = 0;
      HRESULT hr = transform->ProcessOutput(0, 1, &data, &status);
      ComPtr<IMFSample> output = allocated;
      if (data.pSample != allocated.Get()) output.Attach(data.pSample);
      if (data.pEvents) data.pEvents->Release();
      if (hr == MF_E_TRANSFORM_NEED_MORE_INPUT) return true;
      if (hr == MF_E_TRANSFORM_STREAM_CHANGE) {
        if (!selectOutput()) return false;
        continue;
      }
      if (FAILED(hr) || !output) return false;
      LONGLONG pts = 0;
      if (FAILED(output->GetSampleTime(&pts))) return false;
      auto it = pending.find(pts);
      if (it == pending.end()) continue;
      uint32_t id = it->second.id;
      pending.erase(it);
      if (!pixels(output.Get(), id)) complete(id, false);
    }
    return true;
  }
  void resetAudio() {
    if (voice) {
      voice->DestroyVoice();
      voice = nullptr;
    }
    // DestroyVoice waits for the callbacks, so contexts can now be reclaimed.
    submittedAudio.clear();
    if (mastering) {
      mastering->DestroyVoice();
      mastering = nullptr;
    }
    audioEngine.Reset();
    callbacks.failed = false;
  }
  bool configureAudio(int channels) {
    resetAudio();
    if (FAILED(XAudio2Create(&audioEngine, 0, XAUDIO2_DEFAULT_PROCESSOR)) ||
        FAILED(audioEngine->CreateMasteringVoice(&mastering)))
      return false;
    WAVEFORMATEXTENSIBLE format{};
    format.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
    format.Format.nChannels = WORD(channels);
    format.Format.nSamplesPerSec = 48000;
    format.Format.wBitsPerSample = 16;
    format.Format.nBlockAlign = WORD(channels * 2);
    format.Format.nAvgBytesPerSec = 48000 * format.Format.nBlockAlign;
    format.Format.cbSize = sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
    format.Samples.wValidBitsPerSample = 16;
    format.SubFormat = KSDATAFORMAT_SUBTYPE_PCM;
    format.dwChannelMask = channels == 6 ? 0x3f : channels == 4 ? 0x33 : channels == 2 ? 3 : 4;
    if (FAILED(audioEngine->CreateSourceVoice(&voice, &format.Format, 0, XAUDIO2_DEFAULT_FREQ_RATIO, &callbacks)))
      return false;
    voice->SetVolume(0);
    return SUCCEEDED(voice->Start());
  }
  bool play(Audio&& packet, bool enabled) {
    if (!voice) return packet.pcm.empty();
    voice->SetVolume(enabled ? 1.0f : 0.0f);
    while (!submittedAudio.empty() && submittedAudio.front()->done) submittedAudio.pop_front();
    if (callbacks.failed) return false;
    if (packet.pcm.empty() || submittedAudio.size() >= 8) return true;
    auto item = std::make_unique<AudioBuffer>();
    item->pcm = std::move(packet.pcm);
    XAUDIO2_BUFFER buffer{};
    buffer.AudioBytes = UINT32(item->pcm.size() * sizeof(int16_t));
    buffer.pAudioData = reinterpret_cast<const BYTE*>(item->pcm.data());
    buffer.pContext = item.get();
    if (FAILED(voice->SubmitSourceBuffer(&buffer))) return false;
    submittedAudio.push_back(std::move(item));
    return true;
  }
  void loop() {
    MediaScope media;
    uint64_t configuredVideo = 0, configuredAudio = 0;
    try {
      if (!media.ready) {
        failed(false);
        stopped = true;
      }
      while (!stopped) {
        Config next;
        Video video;
        Audio audio;
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
        if (video.id) {
          std::vector<uint8_t> normalized;
          if (!parser.annexB(video.bytes.data(), video.bytes.size(), normalized)) {
            complete(video.id, false);
            failed(false);
            break;
          }
          if (normalized.empty()) {
            complete(video.id, false);
            video.id = 0;
          }
          video.bytes = std::move(normalized);
        }
        if (video.id) {
          const auto now = std::chrono::steady_clock::now();
          for (auto it = pending.begin(); it != pending.end();) {
            if (now - it->second.start > std::chrono::seconds(2)) {
              complete(it->second.id, false);
              it = pending.erase(it);
            } else
              ++it;
          }
          if (pending.size() >= 8)
            complete(video.id, false);
          else {
            const LONGLONG pts = nextPts++ * 166667;
            pending.emplace(pts, Pending{video.id, now});
            if (!submit(video.bytes, pts, video.key)) {
              failed(false);
              break;
            }
          }
        }
        if (transform && !drain()) {
          failed(false);
          break;
        }
        if (audio.epoch != configuredAudio) audio.pcm.clear();
        if (!play(std::move(audio), enabled)) {
          failed(true);
          break;
        }
      }
    } catch (...) {
      failed(false);
    }
    stopped = true;
    resetVideo();
    resetAudio();
    std::lock_guard<std::mutex> lock(mutex);
    for (auto& v : videos) complete(v.id, false);
    videos.clear();
    audioPackets.clear();
  }
};

WindowsSink::WindowsSink(Present p, Complete c, Failed f)
    : impl_(std::make_unique<Impl>(std::move(p), std::move(c), std::move(f))) {}
WindowsSink::~WindowsSink() = default;
bool WindowsSink::supported(bool hevc) {
  MediaScope media;
  return media.ready && decoder(hevc) != nullptr;
}
bool WindowsSink::video(int codec, int w, int h, const uint8_t* extra, size_t length) {
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
bool WindowsSink::frame(const uint8_t* bytes, size_t length, uint32_t id, bool key) {
  if (!bytes || !length || length > 2 * 1024 * 1024 || !id || impl_->stopped) return false;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping || !impl_->videoEpoch || impl_->videos.size() >= 4) return false;
  impl_->videos.push_back({{bytes, bytes + length}, id, key});
  impl_->ready.notify_one();
  return true;
}
bool WindowsSink::audio(int channels, int rate) {
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
void WindowsSink::audioUnavailable() { impl_->failed(true); }
void WindowsSink::samples(const int16_t* pcm, size_t count) {
  if (!pcm || !count || count > AudioDecoder::maxSamples || impl_->stopped) return;
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->stopping || !impl_->audioChannels || count % impl_->audioChannels) return;
  if (impl_->audioPackets.size() >= 8) impl_->audioPackets.pop_front();
  impl_->audioPackets.push_back({impl_->audioEpoch, {pcm, pcm + count}});
  impl_->ready.notify_one();
}
void WindowsSink::volume(bool enabled) {
  std::lock_guard<std::mutex> lock(impl_->mutex);
  impl_->audible = enabled;
}
void WindowsSink::close() { impl_->close(); }
}  // namespace plezy::steam
