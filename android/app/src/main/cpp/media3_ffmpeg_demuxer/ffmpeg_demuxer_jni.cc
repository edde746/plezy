/*
 * Copyright (c) 2026 Plezy
 *
 * libavformat demuxing for media3. Wraps an AVFormatContext whose AVIOContext
 * is served by a media3 ExtractorInput, so FFmpeg parses the container while
 * media3 keeps owning decoders, renderers, and the whole playback surface.
 *
 * The hard seam is seeking. media3's Extractor is a pull API: an extractor
 * cannot move the input; it returns RESULT_SEEK and the loader re-opens the
 * data source at the requested position. libavformat expects a random-access
 * AVIO layer and seeks whenever it pleases (MP4 moov at end of file, AVI idx1,
 * MKV Cues, avformat_find_stream_info read-ahead). The bridge reconciles the
 * two with a deferral protocol:
 *
 * - The read callback only serves when the AVIO logical position equals the
 *   ExtractorInput position. Any divergence aborts the in-flight libavformat
 *   call with AVERROR_NEED_SEEK and records the wanted position.
 * - Kotlin maps that to RESULT_SEEK (or, when the loader already moved the
 *   input to exactly that position, to a local resume). After the input is in
 *   place, resumeAfterSeek() runs avio_seek(), whose success invalidates the
 *   stale AVIO buffers, and the interrupted operation is retried.
 * - During avformat_open_input/avformat_find_stream_info a block cache serves
 *   header re-reads from memory so each distinct seek position costs at most
 *   one loader round trip even though open restarts from zero.
 */
#include <android/log.h>
#include <jni.h>

#include <cmath>
#include <cstring>
#include <deque>
#include <vector>

extern "C" {
#ifdef __cplusplus
#define __STDC_CONSTANT_MACROS
#ifdef _STDINT_H
#undef _STDINT_H
#endif
#include <stdint.h>
#endif
#include <libavcodec/avcodec.h>
#include <libavcodec/bsf.h>
#include <libavformat/avformat.h>
#include <libavutil/dict.h>
#include <libavutil/display.h>
#include <libavutil/dovi_meta.h>
#include <libavutil/error.h>
#include <libavutil/rational.h>
}

#define LOG_TAG "ffmpeg_demuxer"
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__))
#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__))

namespace {

// Returned by the AVIO callbacks to unwind into Java when the ExtractorInput
// cannot serve the requested position synchronously. FFERRTAG values are
// distinct from every real AVERROR code.
const int AVERROR_NEED_SEEK = FFERRTAG('P', 'L', 'Z', 'S');

// readPacket() result codes written to out[0]. Negative values are raw
// AVERROR codes; ERR_JAVA signals the ExtractorInput threw and Kotlin must
// rethrow the stored IOException.
const jint CODE_PACKET = 0;
const jint CODE_EOF = 1;
const jint CODE_NEED_SEEK = 2;
const jint CODE_GROW = 3;
const jint ERR_NOT_OPEN = -101;
const jint ERR_JAVA = -102;

// streamInfo() long[] layout. Keep in sync with FfmpegDemuxerJni.kt.
const int INFO_TRACK_TYPE = 0;  // 0 video, 1 audio, 2 text, -1 unsupported
const int INFO_WIDTH = 1;
const int INFO_HEIGHT = 2;
const int INFO_PAR_NUM = 3;
const int INFO_PAR_DEN = 4;
const int INFO_FPS_NUM = 5;
const int INFO_FPS_DEN = 6;
const int INFO_SAMPLE_RATE = 7;
const int INFO_CHANNELS = 8;
const int INFO_PCM_ENCODING = 9;  // media3 C.ENCODING_* value, -1 when n/a
const int INFO_ROTATION = 10;
const int INFO_SELECTION_FLAGS = 11;
const int INFO_ROLE_FLAGS = 12;
const int INFO_BITRATE = 13;
const int INFO_DOVI_PROFILE = 14;  // DV profile from dvcC/dvvC side data, -1 when none
const int INFO_DOVI_LEVEL = 15;
const int INFO_LATM = 16;  // 1 when the audio stream is LOAS/LATM-framed AAC
const int INFO_LENGTH = 17;

// Android AudioFormat encoding constants (media3 C.ENCODING_* mirror them).
const jint PCM_ENCODING_NONE = -1;
const jint PCM_ENCODING_8BIT = 3;
const jint PCM_ENCODING_16BIT = 2;
const jint PCM_ENCODING_FLOAT = 4;
const jint PCM_ENCODING_24BIT_PACKED = 21;
const jint PCM_ENCODING_32BIT = 22;
const jint PCM_ENCODING_ALAW = 11;
const jint PCM_ENCODING_ULAW = 12;

// media3 C.SELECTION_FLAG_* and C.ROLE_FLAG_* values.
const jint SELECTION_FLAG_DEFAULT = 1;
const jint SELECTION_FLAG_FORCED = 2;
const jint ROLE_FLAG_MAIN = 1;
const jint ROLE_FLAG_DESCRIPTION = 64;       // C.ROLE_FLAG_DESCRIPTION
const jint ROLE_FLAG_HARD_OF_HEARING = 512;  // C.ROLE_FLAG_HARD_OF_HEARING

constexpr int64_t kNoPendingSeek = -1;
constexpr int64_t kNoPendingTimeSeek = INT64_MIN;
constexpr size_t kMaxCacheBytes = 24u * 1024 * 1024;
constexpr jint kReadChunkBytes = 64 * 1024;

struct CacheBlock {
  int64_t pos;
  std::vector<uint8_t> data;
};

struct DemuxState {
  JavaVM* vm = nullptr;
  jobject input = nullptr;
  jmethodID midPosition = nullptr;
  jmethodID midRead = nullptr;
  jmethodID midLength = nullptr;
  jbyteArray readBuffer = nullptr;

  AVFormatContext* format = nullptr;
  AVIOContext* avio = nullptr;
  bool opened = false;

  int64_t logicalPos = 0;
  int64_t pendingSeek = kNoPendingSeek;
  // Presentation-time seek requested via Extractor.seek(); executed by the
  // next nativeReadPacket, where the input proxy is bound and deferrals can
  // round-trip through the loader.
  int64_t pendingTimeSeekUs = kNoPendingTimeSeek;
  // Loader round trips consumed by the pending time seek; a seek whose
  // avformat_seek_file keeps deferring past this budget is abandoned so
  // playback continues instead of ping-ponging forever.
  int seekAttempts = 0;
  // format->start_time in microseconds; subtracted from delivered pts so
  // media3's zero-based timeline matches the duration we report (MPEG-PS/TS
  // containers commonly start at a nonzero PCR).
  int64_t startTimeUs = 0;

  bool cacheActive = true;
  std::deque<CacheBlock> cache;
  size_t cacheBytes = 0;

  AVPacket* packet = nullptr;
  AVPacket* filteredPacket = nullptr;
  // A packet that outgrew the Java-side buffer: already read and filtered,
  // waiting for redelivery after CODE_GROW. Without this flag the retry's
  // av_read_frame would silently drop it.
  bool packetPending = false;

  // Annex-B conversion for H264/HEVC streams stored length-prefixed
  // (matroska/mp4 family); one context per stream, null when none needed.
  AVBSFContext** bsf = nullptr;
  unsigned nbStreams = 0;

  bool javaError = false;
};

// One demuxer at a time: a player session owns exactly one progressive source
// and the extractor releases its state before another can open.
DemuxState* gState = nullptr;
JavaVM* gVm = nullptr;

// Serializes JNI entry points against closeState: the fallback path can
// release the player while the loader thread is inside a native call, and
// deleting DemuxState under it is a use-after-free (observed as a scudo
// invalid-chunk abort during MPV fallback teardown).
pthread_mutex_t gStateMutex = PTHREAD_MUTEX_INITIALIZER;

struct StateLock {
  StateLock() { pthread_mutex_lock(&gStateMutex); }
  ~StateLock() { pthread_mutex_unlock(&gStateMutex); }
};

JNIEnv* envFor() {
  JNIEnv* env = nullptr;
  if (gVm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) return nullptr;
  return env;
}

bool javaPending(JNIEnv* env) { return env->ExceptionCheck() == JNI_TRUE; }

void javaClear(JNIEnv* env) {
  if (env->ExceptionCheck() == JNI_TRUE) env->ExceptionClear();
}

jlong callPosition(JNIEnv* env, DemuxState* s) { return env->CallLongMethod(s->input, s->midPosition); }

jlong callLength(JNIEnv* env, DemuxState* s) { return env->CallLongMethod(s->input, s->midLength); }

// Returns bytes read, 0 at end of input, or -1 when the input failed (the
// Kotlin proxy stored the IOException message).
jint callRead(JNIEnv* env, DemuxState* s, jint length) {
  jint n = env->CallIntMethod(s->input, s->midRead, s->readBuffer, length);
  if (javaPending(env)) {
    javaClear(env);
    s->javaError = true;
    return -1;
  }
  return n;
}

void cacheClear(DemuxState* s) {
  s->cache.clear();
  s->cacheBytes = 0;
}

void cacheAppend(DemuxState* s, int64_t pos, const uint8_t* data, size_t size) {
  if (!s->cacheActive) return;
  s->cache.push_back(CacheBlock{pos, std::vector<uint8_t>(data, data + size)});
  s->cacheBytes += size;
  while (s->cacheBytes > kMaxCacheBytes && !s->cache.empty()) {
    s->cacheBytes -= s->cache.front().data.size();
    s->cache.pop_front();
  }
}

const CacheBlock* cacheFind(const DemuxState* s, int64_t pos) {
  for (const CacheBlock& block : s->cache) {
    if (pos >= block.pos && pos < block.pos + static_cast<int64_t>(block.data.size())) {
      return &block;
    }
  }
  return nullptr;
}

int avioReadPacket(void* opaque, uint8_t* buf, int bufSize) {
  DemuxState* s = static_cast<DemuxState*>(opaque);
  JNIEnv* env = envFor();
  if (env == nullptr) return AVERROR(EIO);
  if (bufSize <= 0) return 0;

  // Cache-first: bytes already read are served at any logical position,
  // which lets restarted header phases (probe → hdrl → idx1 at end of file
  // → back to movi) replay through seeks that never touch the loader.
  const CacheBlock* block = cacheFind(s, s->logicalPos);
  if (block != nullptr) {
    size_t offset = static_cast<size_t>(s->logicalPos - block->pos);
    size_t n = std::min<size_t>(bufSize, block->data.size() - offset);
    std::memcpy(buf, block->data.data() + offset, n);
    s->logicalPos += static_cast<int64_t>(n);
    return static_cast<int>(n);
  }

  // A read at or beyond the known end of file is EOF regardless of where the
  // loader sits. EOF yields no bytes, so it can never enter the block cache;
  // deferring it would let an open that alternates between low offsets and an
  // end-of-file probe (avi idx1/ODML index scans) ping-pong against the
  // loader forever, one round trip per attempt.
  int64_t knownLength = callLength(env, s);
  if (javaPending(env)) {
    javaClear(env);
    s->javaError = true;
    return AVERROR(EIO);
  }
  if (knownLength >= 0 && s->logicalPos >= knownLength) return AVERROR_EOF;

  // Uncached read: the input must be exactly where libavformat thinks it is.
  // Any divergence aborts the in-flight call so Kotlin reconciles through
  // avio_seek, which also invalidates the stale AVIO buffers.
  if (s->logicalPos != callPosition(env, s)) {
    if (javaPending(env)) {
      javaClear(env);
      s->javaError = true;
      return AVERROR(EIO);
    }
    LOGW(
        "read defer: logical=%lld input=%lld active=%d cacheBlocks=%zu cacheBytes=%zu first=%lld last=%lld",
        (long long)s->logicalPos, (long long)callPosition(env, s), s->cacheActive ? 1 : 0, s->cache.size(),
        s->cacheBytes, s->cache.empty() ? -1 : (long long)s->cache.front().pos,
        s->cache.empty() ? -1 : (long long)s->cache.back().pos);
    s->pendingSeek = s->logicalPos;
    return AVERROR_NEED_SEEK;
  }

  jint n = callRead(env, s, bufSize < kReadChunkBytes ? bufSize : kReadChunkBytes);
  if (s->javaError) return AVERROR(EIO);
  if (n <= 0) return AVERROR_EOF;

  env->GetByteArrayRegion(s->readBuffer, 0, n, reinterpret_cast<jbyte*>(buf));
  cacheAppend(s, s->logicalPos, buf, static_cast<size_t>(n));
  s->logicalPos += n;
  return n;
}

int64_t avioSeek(void* opaque, int64_t offset, int whence) {
  DemuxState* s = static_cast<DemuxState*>(opaque);
  JNIEnv* env = envFor();
  if (env == nullptr) return AVERROR(EIO);

  whence &= ~AVSEEK_FORCE;
  if (whence == AVSEEK_SIZE) {
    int64_t length = callLength(env, s);
    if (javaPending(env)) {
      javaClear(env);
      s->javaError = true;
      return -1;
    }
    return length < 0 ? -1 : length;
  }

  int64_t target;
  if (whence == SEEK_CUR) {
    target = s->logicalPos + offset;
  } else if (whence == SEEK_END) {
    int64_t length = callLength(env, s);
    if (javaPending(env)) {
      javaClear(env);
      s->javaError = true;
      return AVERROR(EIO);
    }
    if (length < 0) return AVERROR(EIO);
    target = length + offset;
  } else {
    target = offset;
  }

  // Seeks are pure bookkeeping and never touch the loader. Restarted header
  // replays hop through cached regions for free; a seek into an uncached
  // region surfaces as a deferral on the next uncached read, with the input
  // still where the loader left it. avio invalidates its buffers after this
  // successful callback.
  //
  // Deliberately does NOT touch s->pendingSeek: an unconsumed deferral target
  // must survive the avformat unwind until Kotlin consumes it.
  s->logicalPos = target;
  // A deferral leaves AVIOContext::error sticky; once a seek has been adopted
  // it must not replay into later reads.
  if (s->avio != nullptr) s->avio->error = 0;
  return target;
}

void closeState() {
  DemuxState* s = gState;
  if (s == nullptr) return;  // Close without (or after) an open is a no-op.
  JNIEnv* env = envFor();
  if (s->filteredPacket != nullptr) {
    av_packet_free(&s->filteredPacket);
  }
  if (s->bsf != nullptr) {
    for (unsigned i = 0; i < s->nbStreams; i++) {
      if (s->bsf[i] != nullptr) av_bsf_free(&s->bsf[i]);
    }
    av_freep(&s->bsf);
  }
  if (s->packet != nullptr) {
    av_packet_free(&s->packet);
  }
  if (s->format != nullptr) {
    avformat_close_input(&s->format);
  }
  if (s->avio != nullptr) {
    // Probing (ffio_ensure_seekback) can swap the AVIO buffer for a larger
    // allocation and free the original, so the pointer handed to
    // avio_alloc_context may be stale. Free whichever buffer the context
    // currently holds, exactly once.
    av_freep(&s->avio->buffer);
    avio_context_free(&s->avio);
  }
  if (env != nullptr && s->input != nullptr) {
    if (s->readBuffer != nullptr) env->DeleteGlobalRef(s->readBuffer);
    env->DeleteGlobalRef(s->input);
  }
  delete s;
  gState = nullptr;
}

bool deferred(DemuxState* s, int err) { return err == AVERROR_NEED_SEEK || s->pendingSeek != kNoPendingSeek; }

const char* videoMime(AVCodecID id) {
  switch (id) {
    case AV_CODEC_ID_H264:
      return "video/avc";
    case AV_CODEC_ID_HEVC:
      return "video/hevc";
    case AV_CODEC_ID_MPEG4:
      return "video/mp4v-es";
    case AV_CODEC_ID_MPEG2VIDEO:
      return "video/mpeg2";
    case AV_CODEC_ID_MJPEG:
      return "video/mjpeg";
    case AV_CODEC_ID_VP8:
      return "video/x-vnd.on2.vp8";
    case AV_CODEC_ID_VP9:
      return "video/x-vnd.on2.vp9";
    case AV_CODEC_ID_AV1:
      return "video/av01";
    case AV_CODEC_ID_H263:
      return "video/3gpp";
    default:
      return nullptr;
  }
}

const char* audioMime(AVCodecID id, jint* pcmEncoding) {
  *pcmEncoding = PCM_ENCODING_NONE;
  switch (id) {
    case AV_CODEC_ID_AAC:
      return "audio/mp4a-latm";
    case AV_CODEC_ID_AAC_LATM:
      // LOAS/LATM framing. Kotlin wraps the track with LatmTrackOutput, which
      // unwraps to raw AAC access units and emits the real decoder Format;
      // this mime only marks the stream as supported.
      return "audio/mp4a-latm";
    case AV_CODEC_ID_MP3:
      return "audio/mpeg";
    case AV_CODEC_ID_MP2:
      return "audio/mpeg-L2";
    case AV_CODEC_ID_AC3:
      return "audio/ac3";
    case AV_CODEC_ID_EAC3:
      return "audio/eac3";
    case AV_CODEC_ID_DTS:
      return "audio/vnd.dts";
    case AV_CODEC_ID_TRUEHD:
      return "audio/true-hd";
    case AV_CODEC_ID_FLAC:
      return "audio/flac";
    case AV_CODEC_ID_OPUS:
      return "audio/opus";
    case AV_CODEC_ID_VORBIS:
      return "audio/vorbis";
    case AV_CODEC_ID_ALAC:
      return "audio/alac";
    case AV_CODEC_ID_AMR_NB:
      return "audio/amr";
    case AV_CODEC_ID_AMR_WB:
      return "audio/amr-wb";
    case AV_CODEC_ID_PCM_S16LE:
      *pcmEncoding = PCM_ENCODING_16BIT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_S16BE:
      *pcmEncoding = PCM_ENCODING_16BIT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_S8:
      *pcmEncoding = PCM_ENCODING_8BIT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_U8:
      *pcmEncoding = PCM_ENCODING_8BIT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_S24LE:
      *pcmEncoding = PCM_ENCODING_24BIT_PACKED;
      return "audio/raw";
    case AV_CODEC_ID_PCM_S32LE:
      *pcmEncoding = PCM_ENCODING_32BIT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_F32LE:
      *pcmEncoding = PCM_ENCODING_FLOAT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_F32BE:
      *pcmEncoding = PCM_ENCODING_FLOAT;
      return "audio/raw";
    case AV_CODEC_ID_PCM_ALAW:
      *pcmEncoding = PCM_ENCODING_ALAW;
      return "audio/raw";
    case AV_CODEC_ID_PCM_MULAW:
      *pcmEncoding = PCM_ENCODING_ULAW;
      return "audio/raw";
    default:
      return nullptr;
  }
}

const char* subtitleMime(AVCodecID id) {
  switch (id) {
    case AV_CODEC_ID_SUBRIP:
      return "application/x-subrip";
    case AV_CODEC_ID_ASS:
    case AV_CODEC_ID_SSA:
      return "text/x-ssa";
    case AV_CODEC_ID_WEBVTT:
      return "text/vtt";
    case AV_CODEC_ID_HDMV_PGS_SUBTITLE:
      return "application/pgs";
    case AV_CODEC_ID_DVD_SUBTITLE:
      // media3's VobsubParser takes the .idx text (Matroska CodecPrivate,
      // surfaced verbatim as extradata) as initialization data and the raw
      // SPU payloads as samples — exactly what this path delivers.
      return "application/vobsub";
    default:
      // DVB subtitles are deliberately dropped: media3's DvbParser expects
      // the TS/PMT 5-byte config, not Matroska CodecPrivate, and DVB rides
      // TS in practice — which stays on media3's extractor.
      return nullptr;
  }
}

// Maps an attachment ordinal to its stream index. Attachment payloads
// (embedded fonts) ride extradata and are fully parsed during
// avformat_open_input; these streams never produce packets.
int attachmentStreamIndex(AVFormatContext* format, jint ordinal) {
  jint seen = 0;
  for (unsigned i = 0; i < format->nb_streams; i++) {
    AVCodecParameters* params = format->streams[i]->codecpar;
    if (params->codec_type != AVMEDIA_TYPE_ATTACHMENT) continue;
    if (params->extradata == nullptr || params->extradata_size <= 0) continue;
    if (seen++ == ordinal) return static_cast<int>(i);
  }
  return -1;
}

}  // namespace

extern "C" {

JNIEXPORT jstring JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeProbeFormat(JNIEnv* env, jobject thiz, jbyteArray header) {
  StateLock lock;
  jsize size = env->GetArrayLength(header);
  std::vector<uint8_t> padded(static_cast<size_t>(size) + AVPROBE_PADDING_SIZE, 0);
  env->GetByteArrayRegion(header, 0, size, reinterpret_cast<jbyte*>(padded.data()));

  AVProbeData probe{};
  probe.buf = padded.data();
  probe.buf_size = size;
  probe.filename = "";
  int score = 0;
  const AVInputFormat* format = av_probe_input_format2(&probe, 1, &score);
  if (format == nullptr || score <= 0) return nullptr;
  return env->NewStringUTF(format->name);
}

// Returns 0 on success, CODE_NEED_SEEK when a loader round trip is required,
// or a negative AVERROR. The stream count is NOT the return value: positive
// counts share the result-code namespace (CODE_NEED_SEEK == 2 would collide
// with every two-stream container), so callers use nativeStreamCount().
JNIEXPORT jint JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeOpen(JNIEnv* env, jobject thiz, jobject input) {
  StateLock lock;
  if (gVm == nullptr) {
    env->GetJavaVM(&gVm);
    av_log_set_level(AV_LOG_ERROR);
  }
  if (gState == nullptr) {
    gState = new DemuxState();
    gState->vm = gVm;
  }
  DemuxState* s = gState;
  if (s->avio != nullptr) s->avio->error = 0;

  // FindClass on the declared interface (not GetObjectClass on the concrete
  // proxy): JNI dispatches interface method IDs virtually, and the named
  // class is what the shrinker keep in proguard-rules.pro pins.
  jclass inputClass = env->FindClass("com/edde746/plezy/exoplayer/FfmpegDemuxerJni$Input");
  if (inputClass == nullptr) {
    javaClear(env);
    return ERR_NOT_OPEN;
  }
  jmethodID midPosition = env->GetMethodID(inputClass, "position", "()J");
  jmethodID midRead = env->GetMethodID(inputClass, "read", "([BI)I");
  jmethodID midLength = env->GetMethodID(inputClass, "length", "()J");
  env->DeleteLocalRef(inputClass);
  if (midPosition == nullptr || midRead == nullptr || midLength == nullptr) {
    javaClear(env);
    return ERR_NOT_OPEN;
  }

  // A fresh open replaces any previous proxy binding.
  if (s->input != nullptr) {
    if (s->readBuffer != nullptr) env->DeleteGlobalRef(s->readBuffer);
    env->DeleteGlobalRef(s->input);
    s->input = nullptr;
    s->readBuffer = nullptr;
  }
  s->input = env->NewGlobalRef(input);
  s->midPosition = midPosition;
  s->midRead = midRead;
  s->midLength = midLength;
  jbyteArray readBuffer = env->NewByteArray(kReadChunkBytes);
  s->readBuffer = static_cast<jbyteArray>(env->NewGlobalRef(readBuffer));
  env->DeleteLocalRef(readBuffer);

  if (s->packet == nullptr) {
    s->packet = av_packet_alloc();
    s->filteredPacket = av_packet_alloc();
    if (s->packet == nullptr || s->filteredPacket == nullptr) return AVERROR(ENOMEM);
  }

  if (s->avio == nullptr) {
    constexpr int kAvioBufferSize = 64 * 1024;
    unsigned char* avioBuffer = static_cast<unsigned char*>(av_malloc(kAvioBufferSize));
    s->avio = avio_alloc_context(
        avioBuffer, kAvioBufferSize, /*write_flag=*/0, s, avioReadPacket,
        /*write_packet=*/nullptr, avioSeek);
    if (s->avio == nullptr) return AVERROR(ENOMEM);
  }

  s->javaError = false;
  s->pendingSeek = kNoPendingSeek;
  s->pendingTimeSeekUs = kNoPendingTimeSeek;
  s->seekAttempts = 0;
  s->packetPending = false;
  // Every open attempt restarts from scratch and replays the header phase
  // through the block cache. Resuming avformat_find_stream_info across
  // synthetic IO aborts is not something libavformat contracts to survive
  // (observed as a NULL deref inside avformat_find_stream_info), and with the
  // cache a full replay costs nothing on the wire.
  //
  // The cache must survive retries within one open: matroska's header phase
  // jumps backward twice (SeekHead -> Cues -> clusters), and clearing here —
  // per attempt — makes every retry replay against an empty cache and
  // ping-pong against the loader until the reconcile cap kills the open.
  // Invalidation is per media item and lives in nativeResetCache, called
  // from FfmpegExtractor.init when media3 binds a new source.
  avformat_close_input(&s->format);
  s->opened = false;
  s->cacheActive = true;

  int64_t seekResult = avio_seek(s->avio, 0, SEEK_SET);
  if (s->pendingSeek != kNoPendingSeek) {
    return CODE_NEED_SEEK;
  }
  if (seekResult < 0) {
    LOGW("open seek0 failed=%lld sticky=%d", (long long)seekResult, s->avio != nullptr ? s->avio->error : 0);
    return static_cast<jint>(seekResult);
  }

  s->format = avformat_alloc_context();
  if (s->format == nullptr) return AVERROR(ENOMEM);
  s->format->pb = s->avio;
  // Generate missing PTS: some raw streams (MPEG-TS after a seek) present
  // packets without timestamps that media3 cannot schedule.
  s->format->flags |= AVFMT_FLAG_GENPTS;

  int err = avformat_open_input(&s->format, "", nullptr, nullptr);
  if (deferred(s, err)) {
    LOGW("open_input defer pending=%lld err=%d", (long long)s->pendingSeek, err);
    return CODE_NEED_SEEK;
  }
  if (err < 0) {
    LOGW("avformat_open_input failed: %d", err);
    return err;
  }

  err = avformat_find_stream_info(s->format, nullptr);
  if (deferred(s, err)) {
    LOGW("find_info defer pending=%lld err=%d", (long long)s->pendingSeek, err);
    return CODE_NEED_SEEK;
  }
  if (err < 0) {
    LOGW("avformat_find_stream_info failed: %d", err);
    return err;
  }
  s->opened = true;
  // Zero-base the timeline: delivered pts subtract this so media3 sees
  // [0, duration] even when the container starts at a nonzero PCR/PTS.
  s->startTimeUs = s->format->start_time != AV_NOPTS_VALUE ? s->format->start_time : 0;

  // Header work is done: packet reads are sequential and every backward move
  // goes through a real loader seek.
  s->cacheActive = false;
  cacheClear(s);

  bool anySupported = false;
  for (unsigned i = 0; i < s->format->nb_streams; i++) {
    AVStream* stream = s->format->streams[i];
    AVCodecID codecId = stream->codecpar->codec_id;
    jint pcmEncoding;
    bool supported = videoMime(codecId) != nullptr || audioMime(codecId, &pcmEncoding) != nullptr ||
                     subtitleMime(codecId) != nullptr;
    // ID3/MKV attached pictures surface as video streams; media3 cannot
    // render them as tracks.
    if (stream->attached_pic.size > 0) supported = false;
    if (!supported) {
      LOGW("Dropping stream %u: unsupported codec %s", i, avcodec_get_name(codecId));
      stream->discard = AVDISCARD_ALL;
    } else {
      anySupported = true;
    }
  }
  if (!anySupported) {
    // Fail fast so the session falls back (mpv decodes WMV and friends)
    // instead of buffering an empty track list forever.
    LOGW("No supported streams; refusing container");
    avformat_close_input(&s->format);
    s->opened = false;
    return AVERROR(ENOSYS);
  }
  // MediaCodec requires Annex-B start-code framing for H264/HEVC, while the
  // matroska/mp4 family stores length-prefixed NAL units and libavformat
  // hands those through verbatim (ffmpeg muxers insert the same
  // *_mp4toannexb bitstream filters in this situation). Filter those streams
  // here so every packet leaving the shim is decoder-ready, and adopt the
  // filter's rewritten parameters so extradata surfaces as Annex-B csd too.
  if (s->bsf != nullptr) {
    for (unsigned i = 0; i < s->nbStreams; i++) {
      if (s->bsf[i] != nullptr) av_bsf_free(&s->bsf[i]);
    }
    av_freep(&s->bsf);
  }
  s->nbStreams = s->format->nb_streams;
  s->bsf = static_cast<AVBSFContext**>(av_calloc(s->nbStreams, sizeof(*s->bsf)));
  if (s->bsf == nullptr) return AVERROR(ENOMEM);
  for (unsigned i = 0; i < s->nbStreams; i++) {
    AVCodecID codecId = s->format->streams[i]->codecpar->codec_id;
    const char* filterName = codecId == AV_CODEC_ID_H264   ? "h264_mp4toannexb"
                             : codecId == AV_CODEC_ID_HEVC ? "hevc_mp4toannexb"
                             // AVI-family MPEG-4 ASP commonly packs several VOPs into one chunk;
                             // hardware decoders silently drop those stacks (observed as a decoder
                             // hang with zero output), so unpack them like every ffmpeg pipeline.
                             : codecId == AV_CODEC_ID_MPEG4 ? "mpeg4_unpack_bframes"
                                                            : nullptr;
    const AVBitStreamFilter* filter = av_bsf_get_by_name(filterName);
    AVBSFContext* ctx = nullptr;
    if (filter == nullptr || av_bsf_alloc(filter, &ctx) < 0 ||
        avcodec_parameters_copy(ctx->par_in, s->format->streams[i]->codecpar) < 0) {
      if (ctx != nullptr) av_bsf_free(&ctx);
      continue;
    }
    ctx->time_base_in = s->format->streams[i]->time_base;
    if (av_bsf_init(ctx) < 0) {
      av_bsf_free(&ctx);
      continue;
    }
    avcodec_parameters_copy(s->format->streams[i]->codecpar, ctx->par_out);
    s->format->streams[i]->time_base = ctx->time_base_out;
    s->bsf[i] = ctx;
  }

  return 0;  // Success; prepareTracks() reads the count via nativeStreamCount().
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeClose(JNIEnv* env, jobject thiz) {
  StateLock lock;
  closeState();
}

JNIEXPORT void JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeResetCache(JNIEnv* env, jobject thiz) {
  StateLock lock;
  // Per-item boundary: media3 reuses extractor instances across sources, and
  // a new item's header occupies the same low offsets as the previous item's.
  // Serving those stale bytes would corrupt the new open, so drop everything;
  // nativeOpen re-arms the active flag for its retry phase.
  DemuxState* s = gState;
  if (s == nullptr) return;
  cacheClear(s);
  s->cacheActive = true;
}

JNIEXPORT jint JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeStreamCount(JNIEnv* env, jobject thiz) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr) return ERR_NOT_OPEN;
  return static_cast<jint>(gState->format->nb_streams);
}

JNIEXPORT jlong JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeDurationUs(JNIEnv* env, jobject thiz) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr) return -1;
  int64_t duration = gState->format->duration;
  return duration == AV_NOPTS_VALUE ? -1 : duration;
}

// Returns true when the stream is usable and filled the out arrays.
JNIEXPORT jboolean JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeStreamInfo(
    JNIEnv* env, jobject thiz, jint index, jlongArray numbers, jobjectArray strings) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr || index < 0 ||
      index >= static_cast<jint>(gState->format->nb_streams)) {
    return JNI_FALSE;
  }
  AVStream* stream = gState->format->streams[index];
  AVCodecParameters* params = stream->codecpar;

  jint trackType;
  const char* mime = nullptr;
  jint pcmEncoding = PCM_ENCODING_NONE;
  switch (params->codec_type) {
    case AVMEDIA_TYPE_VIDEO:
      trackType = 0;
      mime = videoMime(params->codec_id);
      break;
    case AVMEDIA_TYPE_AUDIO:
      trackType = 1;
      mime = audioMime(params->codec_id, &pcmEncoding);
      break;
    case AVMEDIA_TYPE_SUBTITLE:
      trackType = 2;
      mime = subtitleMime(params->codec_id);
      break;
    default:
      return JNI_FALSE;
  }
  if (mime == nullptr) return JNI_FALSE;

  jlong info[INFO_LENGTH] = {};
  info[INFO_TRACK_TYPE] = trackType;
  info[INFO_WIDTH] = params->width;
  info[INFO_HEIGHT] = params->height;
  AVRational par = params->sample_aspect_ratio;
  if (par.num <= 0 || par.den <= 0) par = stream->sample_aspect_ratio;
  info[INFO_PAR_NUM] = par.num > 0 ? par.num : 1;
  info[INFO_PAR_DEN] = par.num > 0 ? par.den : 1;
  AVRational fps = stream->avg_frame_rate;
  info[INFO_FPS_NUM] = fps.num > 0 ? fps.num : 0;
  info[INFO_FPS_DEN] = fps.num > 0 ? fps.den : 0;
  info[INFO_SAMPLE_RATE] = params->sample_rate > 0 ? params->sample_rate : -1;
  info[INFO_CHANNELS] = params->ch_layout.nb_channels > 0 ? params->ch_layout.nb_channels : -1;
  info[INFO_PCM_ENCODING] = pcmEncoding;
  info[INFO_LATM] = params->codec_id == AV_CODEC_ID_AAC_LATM ? 1 : 0;

  jint rotation = 0;
  AVPacketSideData* sideData = nullptr;
  for (int i = 0; i < params->nb_coded_side_data; i++) {
    if (params->coded_side_data[i].type == AV_PKT_DATA_DISPLAYMATRIX) {
      sideData = &params->coded_side_data[i];
      break;
    }
  }
  if (sideData != nullptr) {
    double angle = av_display_rotation_get(reinterpret_cast<const int32_t*>(sideData->data));
    if (!std::isnan(angle)) rotation = static_cast<jint>(-lround(angle));
  }
  info[INFO_ROTATION] = rotation;

  jint selectionFlags = 0;
  jint roleFlags = 0;
  if (stream->disposition & AV_DISPOSITION_DEFAULT) selectionFlags |= SELECTION_FLAG_DEFAULT;
  if (stream->disposition & AV_DISPOSITION_FORCED) selectionFlags |= SELECTION_FLAG_FORCED;
  if (stream->disposition & AV_DISPOSITION_HEARING_IMPAIRED) roleFlags |= ROLE_FLAG_HARD_OF_HEARING;
  if (stream->disposition & AV_DISPOSITION_VISUAL_IMPAIRED) roleFlags |= ROLE_FLAG_DESCRIPTION;
  if (selectionFlags == 0 && trackType != 2) roleFlags |= ROLE_FLAG_MAIN;
  info[INFO_SELECTION_FLAGS] = selectionFlags;
  info[INFO_ROLE_FLAGS] = roleFlags;
  info[INFO_BITRATE] = params->bit_rate > 0 ? params->bit_rate : -1;

  // Dolby Vision configuration (dvcC/dvvC), surfaced by libavformat as an
  // unpacked AVDOVIDecoderConfigurationRecord — one byte per field, not the
  // bit-packed ISOBMFF box layout. Kotlin mirrors media3's DolbyVisionConfig
  // to publish video/dolby-vision plus the RFC 6381 codecs string.
  info[INFO_DOVI_PROFILE] = -1;
  info[INFO_DOVI_LEVEL] = -1;
  for (int i = 0; i < params->nb_coded_side_data; i++) {
    AVPacketSideData* sd = &params->coded_side_data[i];
    if (sd->type == AV_PKT_DATA_DOVI_CONF && sd->size >= sizeof(AVDOVIDecoderConfigurationRecord)) {
      const AVDOVIDecoderConfigurationRecord* dovi =
          reinterpret_cast<const AVDOVIDecoderConfigurationRecord*>(sd->data);
      info[INFO_DOVI_PROFILE] = dovi->dv_profile;
      info[INFO_DOVI_LEVEL] = dovi->dv_level;
      break;
    }
  }

  env->SetLongArrayRegion(numbers, 0, INFO_LENGTH, info);

  const char* language = nullptr;
  const char* label = nullptr;
  if (stream->metadata != nullptr) {
    AVDictionaryEntry* entry = av_dict_get(stream->metadata, "language", nullptr, 0);
    if (entry != nullptr) language = entry->value;
    entry = av_dict_get(stream->metadata, "title", nullptr, 0);
    if (entry != nullptr) label = entry->value;
  }
  env->SetObjectArrayElement(strings, 0, env->NewStringUTF(mime));
  env->SetObjectArrayElement(strings, 1, language != nullptr ? env->NewStringUTF(language) : nullptr);
  env->SetObjectArrayElement(strings, 2, label != nullptr ? env->NewStringUTF(label) : nullptr);
  return JNI_TRUE;
}

JNIEXPORT jbyteArray JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeStreamExtradata(JNIEnv* env, jobject thiz, jint index) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr || index < 0 ||
      index >= static_cast<jint>(gState->format->nb_streams)) {
    return nullptr;
  }
  AVCodecParameters* params = gState->format->streams[index]->codecpar;
  // libavformat carries the AVI stream's WAVEFORMATEX header as MP3
  // extradata. MediaCodec mp3 decoders expect either no csd or the two-byte
  // ISO header, and report a WAVEFORMATEX blob as corrupt input
  // (C2_CORRUPTED on the first work item), so drop it.
  if (params->codec_id == AV_CODEC_ID_MP3) return nullptr;
  if (params->extradata == nullptr || params->extradata_size <= 0) return nullptr;
  jbyteArray result = env->NewByteArray(params->extradata_size);
  env->SetByteArrayRegion(result, 0, params->extradata_size, reinterpret_cast<const jbyte*>(params->extradata));
  return result;
}

JNIEXPORT jint JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeAttachmentCount(JNIEnv* env, jobject thiz) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr) return 0;
  jint count = 0;
  while (attachmentStreamIndex(gState->format, count) >= 0) count++;
  return count;
}

// Fills strings with [filename, mimetype] and returns the payload size in
// bytes, or -1 when the ordinal is out of range.
JNIEXPORT jlong JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeAttachmentInfo(
    JNIEnv* env, jobject thiz, jint ordinal, jobjectArray strings) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr) return -1;
  int index = attachmentStreamIndex(gState->format, ordinal);
  if (index < 0) return -1;
  AVStream* stream = gState->format->streams[index];
  const char* filename = nullptr;
  const char* mimetype = nullptr;
  if (stream->metadata != nullptr) {
    AVDictionaryEntry* entry = av_dict_get(stream->metadata, "filename", nullptr, 0);
    if (entry != nullptr) filename = entry->value;
    entry = av_dict_get(stream->metadata, "mimetype", nullptr, 0);
    if (entry != nullptr) mimetype = entry->value;
  }
  env->SetObjectArrayElement(strings, 0, filename != nullptr ? env->NewStringUTF(filename) : nullptr);
  env->SetObjectArrayElement(strings, 1, mimetype != nullptr ? env->NewStringUTF(mimetype) : nullptr);
  return stream->codecpar->extradata_size;
}

JNIEXPORT jbyteArray JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeAttachmentData(JNIEnv* env, jobject thiz, jint ordinal) {
  StateLock lock;
  if (gState == nullptr || gState->format == nullptr) return nullptr;
  int index = attachmentStreamIndex(gState->format, ordinal);
  if (index < 0) return nullptr;
  AVCodecParameters* params = gState->format->streams[index]->codecpar;
  jbyteArray result = env->NewByteArray(params->extradata_size);
  if (result == nullptr) return nullptr;
  env->SetByteArrayRegion(result, 0, params->extradata_size, reinterpret_cast<const jbyte*>(params->extradata));
  return result;
}

// Reads one packet. out[0] carries the result code; on CODE_PACKET the packet
// bytes were written into the byte array and out carries
// [1]=streamIndex [2]=ptsUs (start-time normalized; packets without any
// timestamp are dropped, media3 cannot schedule them) [3]=flags [4]=size
// [5]=packet position in input coordinates [6]=durationUs (-1 unknown).
// Deferral targets travel through nativeConsumePendingSeek, not this array.
JNIEXPORT jint JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeReadPacket(
    JNIEnv* env, jobject thiz, jbyteArray buffer, jlongArray out) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || !s->opened || s->format == nullptr) return ERR_NOT_OPEN;

  jint capacity = env->GetArrayLength(buffer);
  jlong result[7] = {};
  s->javaError = false;
  s->pendingSeek = kNoPendingSeek;

  int stickyRecovers = 0;
  while (true) {
    // A presentation-time seek from Extractor.seek() runs here, where the
    // input proxy is bound and a deferral can round-trip through the loader.
    // The demuxer picks the byte position and resets its own parse state —
    // jumping the AVIO position under it would leave demuxer-private state
    // (avi->remaining, PES continuations) pointing into the old stream.
    // avformat_seek_file restarts from scratch on every retry; the block
    // cache is re-armed so index/probe reads replayed across loader round
    // trips (matroska Cues, mpegps binary search) stay free on the wire.
    if (s->pendingTimeSeekUs != kNoPendingTimeSeek) {
      if (++s->seekAttempts > 64) {
        // Non-converging seek (each attempt = one loader round trip):
        // abandon it and keep delivering from the current position rather
        // than ping-ponging forever.
        LOGW(
            "time seek to %lld abandoned after %d loader round trips", (long long)s->pendingTimeSeekUs,
            s->seekAttempts - 1);
        s->pendingTimeSeekUs = kNoPendingTimeSeek;
        s->cacheActive = false;
        cacheClear(s);
      } else {
        if (s->bsf != nullptr) {
          for (unsigned i = 0; i < s->nbStreams; i++) {
            if (s->bsf[i] != nullptr) av_bsf_flush(s->bsf[i]);
          }
        }
        s->packetPending = false;
        s->cacheActive = true;
        int64_t ts = s->pendingTimeSeekUs + s->startTimeUs;
        int err = avformat_seek_file(s->format, -1, INT64_MIN, ts, ts, 0);
        LOGD(
            "time seek to %lld: err=%d logical=%lld attempts=%d", (long long)ts, err, (long long)s->logicalPos,
            s->seekAttempts);
        if (deferred(s, err)) {
          if (s->pendingSeek == kNoPendingSeek) {
            if (++stickyRecovers > 16 || s->avio == nullptr) return ERR_JAVA;
            s->avio->error = 0;
            continue;
          }
          // pendingTimeSeekUs stays set: the retry after the loader round
          // trip re-runs the whole seek.
          result[0] = CODE_NEED_SEEK;
          env->SetLongArrayRegion(out, 0, 7, result);
          return CODE_NEED_SEEK;
        }
        if (s->javaError) {
          result[0] = ERR_JAVA;
          env->SetLongArrayRegion(out, 0, 7, result);
          return ERR_JAVA;
        }
        s->pendingTimeSeekUs = kNoPendingTimeSeek;
        if (err < 0) {
          // Unseekable stream or demuxer refusal: keep playing from the
          // current position instead of killing the session; media3 will
          // decode-discard toward the target if it can.
          LOGW("avformat_seek_file to %lld failed: %d", (long long)ts, err);
        } else {
          // Align the loader with the demuxer's chosen byte position BEFORE
          // the first read. avformat_seek_file resolves in memory (cues) and
          // typically leaves the AVIO position behind the loader's SeekMap
          // guess; letting av_read_frame discover that and unwind with a
          // synthetic IO error poisons matroskadec into resync, which skips
          // the keyframe cluster — the video renderer then starves until the
          // next keyframe while audio keeps advancing, and the resume-stall
          // watchdog seeks in a loop. The cache stays armed across this round
          // trip (until the first packet delivers) so replayed header bytes
          // stay free.
          int64_t inputPos = callPosition(env, s);
          if (javaPending(env)) {
            javaClear(env);
            s->javaError = true;
            result[0] = ERR_JAVA;
            env->SetLongArrayRegion(out, 0, 7, result);
            return ERR_JAVA;
          }
          if (inputPos >= 0 && inputPos != s->logicalPos) {
            s->pendingSeek = s->logicalPos;
            result[0] = CODE_NEED_SEEK;
            env->SetLongArrayRegion(out, 0, 7, result);
            return CODE_NEED_SEEK;
          }
        }
      }
    }

    if (s->packetPending) {
      // Oversized packet held across a CODE_GROW round trip: deliver it now
      // instead of reading (and losing) a new frame.
      s->packetPending = false;
    } else {
      av_packet_unref(s->packet);
      int err = av_read_frame(s->format, s->packet);
      if (deferred(s, err)) {
        if (s->pendingSeek == kNoPendingSeek) {
          // Sticky AVIO error replayed from a deferral Kotlin already
          // reconciled: clear it and retry instead of surfacing a targetless
          // seek.
          if (++stickyRecovers > 16 || s->avio == nullptr) return ERR_JAVA;
          s->avio->error = 0;
          continue;
        }
        result[0] = CODE_NEED_SEEK;
        env->SetLongArrayRegion(out, 0, 7, result);
        return CODE_NEED_SEEK;
      }
      if (err == AVERROR_EOF) {
        result[0] = CODE_EOF;
        env->SetLongArrayRegion(out, 0, 7, result);
        return CODE_EOF;
      }
      if (err < 0 || s->javaError) {
        result[0] = s->javaError ? ERR_JAVA : err;
        env->SetLongArrayRegion(out, 0, 7, result);
        return s->javaError ? ERR_JAVA : err;
      }
      if (s->packet->size <= 0) continue;

      if (s->format->streams[s->packet->stream_index]->discard >= AVDISCARD_ALL) continue;

      AVBSFContext* bsf = s->bsf != nullptr && s->packet->stream_index < static_cast<int>(s->nbStreams)
                              ? s->bsf[s->packet->stream_index]
                              : nullptr;
      if (bsf != nullptr) {
        // send consumes the packet reference; move the filtered result back so
        // the delivery code below keeps a single code path.
        int filterErr = av_bsf_send_packet(bsf, s->packet);
        if (filterErr >= 0) {
          av_packet_unref(s->packet);
          filterErr = av_bsf_receive_packet(bsf, s->filteredPacket);
          if (filterErr == AVERROR(EAGAIN)) continue;
          if (filterErr < 0) {
            result[0] = filterErr;
            env->SetLongArrayRegion(out, 0, 7, result);
            return filterErr;
          }
          av_packet_move_ref(s->packet, s->filteredPacket);
        } else {
          result[0] = filterErr;
          env->SetLongArrayRegion(out, 0, 7, result);
          return filterErr;
        }
      }
    }
    int size = s->packet->size;
    if (size > capacity) {
      s->packetPending = true;
      result[0] = CODE_GROW;
      result[4] = size;
      env->SetLongArrayRegion(out, 0, 7, result);
      return CODE_GROW;
    }
    env->SetByteArrayRegion(buffer, 0, size, reinterpret_cast<const jbyte*>(s->packet->data));

    AVStream* stream = s->format->streams[s->packet->stream_index];
    int64_t ptsUs;
    if (s->packet->pts != AV_NOPTS_VALUE) {
      ptsUs = av_rescale_q(s->packet->pts, stream->time_base, AVRational{1, 1000000});
    } else if (s->packet->dts != AV_NOPTS_VALUE) {
      ptsUs = av_rescale_q(s->packet->dts, stream->time_base, AVRational{1, 1000000});
    } else {
      // No timestamp even after GENPTS: media3 cannot schedule the sample,
      // and delivering data without metadata would corrupt the sample queue.
      continue;
    }
    ptsUs -= s->startTimeUs;

    // Post-seek convergence is over once a packet flows; steady-state packet
    // reads are sequential, so drop the replay cache until the next seek.
    if (s->cacheActive) {
      s->cacheActive = false;
      cacheClear(s);
    }

    result[0] = CODE_PACKET;
    result[1] = s->packet->stream_index;
    result[2] = ptsUs;
    result[3] = (s->packet->flags & AV_PKT_FLAG_KEY) != 0 ? 1 : 0;
    result[4] = size;
    result[5] = s->packet->pos >= 0 ? s->packet->pos : 0;
    result[6] =
        s->packet->duration > 0 ? av_rescale_q(s->packet->duration, stream->time_base, AVRational{1, 1000000}) : -1;
    env->SetLongArrayRegion(out, 0, 7, result);
    return CODE_PACKET;
  }
}

JNIEXPORT jlong JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeConsumePendingSeek(JNIEnv* env, jobject thiz) {
  StateLock lock;
  if (gState == nullptr) return -9223372036854775807L - 1;  // Long.MIN_VALUE
  int64_t pending = gState->pendingSeek;
  gState->pendingSeek = kNoPendingSeek;
  return pending;
}

// Re-establishes the AVIO position after the loader moved the input to
// `position`. Must only be called when the ExtractorInput is already there.
JNIEXPORT jint JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeResumeAfterSeek(JNIEnv* env, jobject thiz, jlong position) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || s->avio == nullptr) return ERR_NOT_OPEN;
  s->pendingSeek = kNoPendingSeek;
  s->javaError = false;
  int64_t result = avio_seek(s->avio, position, SEEK_SET);
  if (result >= 0) return 0;
  if (s->pendingSeek != kNoPendingSeek) return CODE_NEED_SEEK;
  return static_cast<jint>(result);
}

// Records a presentation-time seek (media3 timeline microseconds, i.e.
// start-time normalized). Executed by the next nativeReadPacket, which owns
// a bound input proxy and can defer through the loader; running
// avformat_seek_file here would read against a dead input.
JNIEXPORT void JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeSeekTo(JNIEnv* env, jobject thiz, jlong timeUs) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || !s->opened) return;
  s->pendingTimeSeekUs = timeUs;
  s->seekAttempts = 0;
  // Any packet parked for a CODE_GROW retry belongs to the pre-seek stream.
  s->packetPending = false;
}

}  // extern "C"
