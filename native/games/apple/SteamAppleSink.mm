// SPDX-License-Identifier: GPL-3.0-or-later
#include "SteamAppleSink.h"
#include "steam_h26x.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#include <cstring>
#include <deque>
#include <thread>

namespace plezy::steam {
struct AppleSink::Impl {
  struct Video { std::vector<uint8_t> bytes; uint32_t id; uint64_t epoch; };
  struct Audio { std::vector<int16_t> samples; uint64_t epoch; };
  struct Config { int codec = 0, width = 0, height = 0; std::vector<uint8_t> extra; };
  Present present;
  Complete complete;
  Failed failed;
  std::mutex mutex;
  std::condition_variable wake;
  std::thread worker;
  bool stopping = false;
  std::atomic<bool> audible{false};
  std::atomic<int> kind{0};
  Config config;
  int channels = 0;
  uint64_t videoEpoch = 0, audioEpoch = 0;
  std::deque<Video> frames;
  std::deque<Audio> pcm;
  // Everything below is decoder-worker owned, except atomic buffer availability.
  H26xParser parser;
  CMVideoFormatDescriptionRef format = nullptr;
  VTDecompressionSessionRef decoder = nullptr;
  AudioQueueRef audioQueue = nullptr;
  std::array<AudioQueueBufferRef,4> buffers{};
  std::array<std::atomic<bool>,4> free{};
  Config current;
  bool decodeSucceeded = false, videoFailed = false, audioFailed = false;
  Impl(Present p, Complete c, Failed f) : present(std::move(p)), complete(std::move(c)), failed(std::move(f)) {
    worker = std::thread([this] { run(); });
  }
  ~Impl() { close(); }
  void fail(bool audio) {
    auto& once = audio ? audioFailed : videoFailed;
    if (!once) { once = true; failed(audio); }
  }
  void closeVideo() {
    if (decoder) { VTDecompressionSessionWaitForAsynchronousFrames(decoder); VTDecompressionSessionInvalidate(decoder); CFRelease(decoder); }
    decoder = nullptr;
    if (format) CFRelease(format);
    format = nullptr; kind = 0;
  }
  void closeAudio() {
    if (audioQueue) { AudioQueueStop(audioQueue,true); AudioQueueDispose(audioQueue,true); }
    audioQueue = nullptr; buffers.fill(nullptr);
  }
  static void decoded(void* owner, void* ref, OSStatus status, VTDecodeInfoFlags, CVImageBufferRef image, CMTime, CMTime) {
    auto* self = static_cast<Impl*>(owner);
    const auto id = uint32_t(reinterpret_cast<uintptr_t>(ref));
    self->decodeSucceeded = status == noErr && image &&
      CVPixelBufferGetPixelFormatType(image) == kCVPixelFormatType_32BGRA &&
      CVPixelBufferGetWidth(image) <= 1920 && CVPixelBufferGetHeight(image) <= 1080;
    if (!self->decodeSucceeded || !self->present(image,id)) self->complete(id,false);
    if (status != noErr) self->fail(false);
  }
  bool openVideo() {
    closeVideo();
    const auto& params = parser.parameters();
    const uint8_t* ptrs[] = {params[0].data(),params[1].data(),params[2].data()};
    const size_t sizes[] = {params[0].size(),params[1].size(),params[2].size()};
    OSStatus result = current.codec == 4 ?
      CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,2,ptrs,sizes,4,&format) :
      CMVideoFormatDescriptionCreateFromHEVCParameterSets(kCFAllocatorDefault,3,ptrs,sizes,4,nullptr,&format);
    if (result != noErr || !format) return false;
    const auto dimensions = CMVideoFormatDescriptionGetDimensions(format);
    if (dimensions.width <= 0 || dimensions.height <= 0 || dimensions.width > current.width || dimensions.height > current.height) return false;
    // Flutter's BGRA texture contract is SDR. An unsolicited HDR stream cannot
    // silently be clipped to eight-bit SDR. HDR presentation is a separate path.
    auto transfer = CMFormatDescriptionGetExtension(format,kCMFormatDescriptionExtension_TransferFunction);
    if (transfer && (CFEqual(transfer,kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ) ||
                     CFEqual(transfer,kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG))) return false;
    NSDictionary* spec = nil;
    if (@available(iOS 17.0, tvOS 17.0, macOS 10.9, *)) {
      spec = @{(__bridge NSString*)kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder:@YES};
    }
    NSDictionary* attributes = @{
      (__bridge NSString*)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
      (__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey:@{},
      (__bridge NSString*)kCVPixelBufferMetalCompatibilityKey:@YES,
    };
    VTDecompressionOutputCallbackRecord callback{decoded,this};
    result = VTDecompressionSessionCreate(kCFAllocatorDefault,format,(__bridge CFDictionaryRef)spec,
        (__bridge CFDictionaryRef)attributes,&callback,&decoder);
    if (result != noErr || !decoder) return false;
    VTSessionSetProperty(decoder,kVTDecompressionPropertyKey_RealTime,kCFBooleanTrue);
    if (@available(iOS 17.0, tvOS 17.0, macOS 10.9, *)) {
      CFTypeRef hardware = nullptr;
      if (VTSessionCopyProperty(decoder,kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder,kCFAllocatorDefault,&hardware) == noErr && hardware) {
        kind = CFEqual(hardware,kCFBooleanTrue) ? 1 : 2; CFRelease(hardware);
      }
    }
    return true;
  }
  void decode(const Video& item) {
    if (videoFailed) { complete(item.id,false); return; }
    std::vector<uint8_t> bytes; bool changed = false;
    if (!parser.accessUnit(item.bytes.data(),item.bytes.size(),bytes,changed)) { complete(item.id,false); fail(false); return; }
    if (bytes.empty()) { complete(item.id,false); return; }
    if (!parser.ready()) { complete(item.id,false); return; }
    if ((changed || !decoder) && !openVideo()) { complete(item.id,false); fail(false); return; }
    CMBlockBufferRef block = nullptr;
    CMSampleBufferRef sample = nullptr;
    OSStatus result = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,nullptr,bytes.size(),kCFAllocatorDefault,nullptr,0,bytes.size(),0,&block);
    if (result == noErr) result = CMBlockBufferReplaceDataBytes(bytes.data(),block,0,bytes.size());
    const size_t sampleSize = bytes.size();
    if (result == noErr) result = CMSampleBufferCreateReady(kCFAllocatorDefault,block,format,1,0,nullptr,1,&sampleSize,&sample);
    decodeSucceeded = false;
    if (result == noErr) {
      // No asynchronous-decompression flag: the callback finishes before this
      // call returns, keeping format changes and teardown on this one worker.
      result = VTDecompressionSessionDecodeFrame(decoder,sample,0,reinterpret_cast<void*>(uintptr_t(item.id)),nullptr);
      if (result != noErr) complete(item.id,false);
    } else complete(item.id,false);
    if (sample) CFRelease(sample);
    if (block) CFRelease(block);
    if (result != noErr) fail(false);
  }
  bool openAudio(int count) {
    closeAudio();
    AudioStreamBasicDescription spec{};
    spec.mSampleRate = 48000; spec.mFormatID = kAudioFormatLinearPCM;
    spec.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    spec.mBytesPerPacket = spec.mBytesPerFrame = uint32_t(count * 2);
    spec.mFramesPerPacket = 1; spec.mChannelsPerFrame = uint32_t(count); spec.mBitsPerChannel = 16;
    if (AudioQueueNewOutput(&spec,[](void* context,AudioQueueRef,AudioQueueBufferRef buffer) {
      auto* self = static_cast<Impl*>(context);
      for (size_t i = 0; i < self->buffers.size(); ++i) if (self->buffers[i] == buffer) self->free[i] = true;
    },this,nullptr,nullptr,0,&audioQueue) != noErr) return false;
    AudioChannelLayout layout{};
    layout.mChannelLayoutTag = count == 1 ? kAudioChannelLayoutTag_Mono : count == 2 ? kAudioChannelLayoutTag_Stereo :
      count == 4 ? kAudioChannelLayoutTag_Quadraphonic : kAudioChannelLayoutTag_MPEG_5_1_A;
    if (AudioQueueSetProperty(audioQueue,kAudioQueueProperty_ChannelLayout,&layout,sizeof(layout)) != noErr) return false;
    for (size_t i = 0; i < buffers.size(); ++i) {
      if (AudioQueueAllocateBuffer(audioQueue,5760 * 6 * sizeof(int16_t),&buffers[i]) != noErr) return false;
      free[i] = true;
    }
    AudioQueueSetParameter(audioQueue,kAudioQueueParam_Volume,audible ? 1 : 0);
    return AudioQueueStart(audioQueue,nullptr) == noErr;
  }
  void play(const Audio& item) {
    if (!audioQueue || audioFailed) return;
    for (size_t i = 0; i < buffers.size(); ++i) if (free[i].exchange(false)) {
      auto* buffer = buffers[i];
      const auto size = item.samples.size() * sizeof(int16_t);
      if (size > buffer->mAudioDataBytesCapacity) { free[i] = true; fail(true); return; }
      std::memcpy(buffer->mAudioData,item.samples.data(),size); buffer->mAudioDataByteSize = uint32_t(size);
      if (AudioQueueEnqueueBuffer(audioQueue,buffer,0,nullptr) != noErr) { free[i] = true; fail(true); }
      return;
    }
  }
  void run() {
    uint64_t vEpoch = 0, aEpoch = 0;
    while (true) { @autoreleasepool {
      Video video{}; Audio audio{}; bool haveVideo = false, haveAudio = false, configureVideo = false, configureAudio = false;
      int newChannels = 0;
      {
        std::unique_lock<std::mutex> lock(mutex);
        wake.wait_for(lock,std::chrono::milliseconds(20),[&]{ return stopping || videoEpoch != vEpoch || audioEpoch != aEpoch || !frames.empty() || !pcm.empty(); });
        if (stopping) break;
        if (vEpoch != videoEpoch) { vEpoch = videoEpoch; current = config; configureVideo = true; }
        if (aEpoch != audioEpoch) { aEpoch = audioEpoch; newChannels = channels; configureAudio = true; }
        if (!frames.empty()) { video = std::move(frames.front()); frames.pop_front(); haveVideo = true; }
        if (!pcm.empty()) { audio = std::move(pcm.front()); pcm.pop_front(); haveAudio = true; }
      }
      if (configureVideo) { closeVideo(); if (!parser.configure(current.codec,current.extra.data(),current.extra.size())) fail(false); }
      if (configureAudio && !openAudio(newChannels)) fail(true);
      if (audioQueue) AudioQueueSetParameter(audioQueue,kAudioQueueParam_Volume,audible ? 1 : 0);
      if (haveVideo) { if (video.epoch == vEpoch) decode(video); else complete(video.id,false); }
      if (haveAudio && audio.epoch == aEpoch) play(audio);
    }}
    closeVideo(); closeAudio();
    std::deque<Video> remaining;
    { std::lock_guard<std::mutex> lock(mutex); remaining.swap(frames); pcm.clear(); }
    for (const auto& frame : remaining) complete(frame.id,false);
  }
  void close() {
    { std::lock_guard<std::mutex> lock(mutex); stopping = true; }
    wake.notify_all(); if (worker.joinable()) worker.join();
  }
};
AppleSink::AppleSink(Present p, Complete c, Failed f) : impl_(std::make_unique<Impl>(std::move(p),std::move(c),std::move(f))) {}
AppleSink::~AppleSink() = default;
bool AppleSink::supportsHevc() { return VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC); }
bool AppleSink::video(int codec,int width,int height,const uint8_t* extra,size_t length) {
  if ((codec != 4 && codec != 5) || width <= 0 || height <= 0 || width > 1920 || height > 1080 || length > 65536 || (length && !extra)) return false;
  std::deque<Impl::Video> old;
  { std::lock_guard<std::mutex> lock(impl_->mutex);
    if (impl_->stopping) return false;
    impl_->config = {codec,width,height,{}};
    if (length) impl_->config.extra.assign(extra,extra+length);
    ++impl_->videoEpoch; old.swap(impl_->frames);
  }
  for (const auto& f : old) impl_->complete(f.id,false);
  impl_->wake.notify_one(); return true;
}
bool AppleSink::frame(const uint8_t* bytes,size_t length,uint32_t id,bool) {
  if (!bytes || !length || length > 2*1024*1024) return false;
  uint32_t dropped = 0;
  { std::lock_guard<std::mutex> lock(impl_->mutex);
    if (impl_->stopping || !impl_->videoEpoch) return false;
    if (impl_->frames.size() >= 4) { dropped = impl_->frames.front().id; impl_->frames.pop_front(); }
    impl_->frames.push_back({{bytes,bytes+length},id,impl_->videoEpoch});
  }
  if (dropped) impl_->complete(dropped,false);
  impl_->wake.notify_one(); return true;
}
bool AppleSink::audio(int channels,int rate) {
  if (rate != 48000 || (channels != 1 && channels != 2 && channels != 4 && channels != 6)) return false;
  { std::lock_guard<std::mutex> lock(impl_->mutex); if (impl_->stopping) return false;
    impl_->channels = channels; ++impl_->audioEpoch; impl_->pcm.clear(); }
  impl_->wake.notify_one(); return true;
}
void AppleSink::audioUnavailable() { impl_->failed(true); }
void AppleSink::samples(const int16_t* bytes,size_t count) {
  if (!bytes || !count || count > 5760*6) return;
  { std::lock_guard<std::mutex> lock(impl_->mutex);
    if (impl_->stopping || !impl_->channels || count % size_t(impl_->channels)) return;
    if (impl_->pcm.size() >= 8) impl_->pcm.pop_front();
    impl_->pcm.push_back({{bytes,bytes+count},impl_->audioEpoch});
  }
  impl_->wake.notify_one();
}
void AppleSink::volume(bool enabled) { impl_->audible = enabled; }
int AppleSink::decoderKind() const { return impl_->kind; }
void AppleSink::close() { impl_->close(); }
}
