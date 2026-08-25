/*
 * Copyright (c) 2026 Plezy
 *
 * libavformat demuxing for media3. Wraps an AVFormatContext whose AVIOContext
 * is served by a media3 ExtractorInput, so FFmpeg parses the container while
 * media3 keeps owning decoders, renderers, and the whole playback surface.
 *
 * The seam used to be seeking. media3's Extractor is a pull API: an extractor
 * cannot move the input; it returns RESULT_SEEK and the loader re-opens the
 * data source. libavformat expects random access and seeks whenever it pleases
 * (MP4 moov at end of file, AVI idx1, MKV Cues, MPEG-PS binary search), so
 * serving it from the loader alone meant unwinding the in-flight libavformat
 * call on every backward jump and replaying the whole open — which a
 * one-shot lazy parse like matroska's Cues cannot survive (#2096).
 *
 * libavformat now gets what it actually requires: the Kotlin side hands this
 * shim a random-access byte source (FfmpegRandomAccessSource), so every AVIO
 * read succeeds at the position libavformat asked for and nothing is ever
 * unwound. Two paths serve reads, chosen per read:
 *
 * - The loader's ExtractorInput when it already stands at that position. This
 *   is the steady state for sample delivery, and it keeps media3's byte
 *   accounting, back-pressure and load-error policy in charge of streaming.
 * - The random-access source otherwise (header, index, post-seek jumps).
 *
 * Kotlin nudges the loader back into step after a jump by returning
 * RESULT_SEEK to nativeLogicalPosition(); that is an optimization, never a
 * correctness requirement, so no budgets or retries guard it.
 */
#include <android/log.h>
#include <jni.h>

#include <cmath>
#include <cstring>
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

// readPacket() result codes written to out[0]. Negative values are raw
// AVERROR codes; ERR_JAVA signals the byte source threw and Kotlin must
// rethrow the stored IOException.
const jint CODE_PACKET = 0;
const jint CODE_EOF = 1;
const jint CODE_GROW = 2;
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

constexpr jint kReadChunkBytes = 64 * 1024;

struct DemuxState {
  JavaVM* vm = nullptr;
  jobject input = nullptr;
  jmethodID midPosition = nullptr;
  jmethodID midRead = nullptr;
  jmethodID midReadAt = nullptr;
  jmethodID midLength = nullptr;
  jbyteArray readBuffer = nullptr;

  AVFormatContext* format = nullptr;
  AVIOContext* avio = nullptr;
  bool opened = false;

  // Byte position libavformat will read next. Authoritative: the AVIO seek
  // callback moves it, and both read paths serve exactly this offset.
  int64_t logicalPos = 0;
  // format->start_time in microseconds; subtracted from delivered pts so
  // media3's zero-based timeline matches the duration we report (MPEG-PS/TS
  // containers commonly start at a nonzero PCR).
  int64_t startTimeUs = 0;

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

// Same contract as callRead, but at an absolute position: the Kotlin source
// reopens its handle when the position is not where it stands.
jint callReadAt(JNIEnv* env, DemuxState* s, int64_t position, jint length) {
  jint n = env->CallIntMethod(s->input, s->midReadAt, static_cast<jlong>(position), s->readBuffer, length);
  if (javaPending(env)) {
    javaClear(env);
    s->javaError = true;
    return -1;
  }
  return n;
}

int avioReadPacket(void* opaque, uint8_t* buf, int bufSize) {
  DemuxState* s = static_cast<DemuxState*>(opaque);
  JNIEnv* env = envFor();
  if (env == nullptr) return AVERROR(EIO);
  if (bufSize <= 0) return 0;
  // After the byte source has failed once in this native call, fail every
  // further read immediately: libavformat's internal recovery (matroska
  // resync) would drive the dead source again, clobbering the stored
  // IOException message — and were the source half-alive, could silently
  // resync past the failed range. Failing fast makes the whole entry return
  // ERR_JAVA, and media3's retry resumes at the exact failed position.
  if (s->javaError) return AVERROR(EIO);

  const jint want = bufSize < kReadChunkBytes ? bufSize : kReadChunkBytes;
  // Prefer the loader's input when it already stands here: those bytes then
  // count as media3's own load progress, which is what drives its buffering
  // and back-pressure. Anywhere else, read at the absolute position.
  const int64_t inputPos = callPosition(env, s);
  if (javaPending(env)) {
    javaClear(env);
    s->javaError = true;
    return AVERROR(EIO);
  }
  const jint n = inputPos == s->logicalPos ? callRead(env, s, want) : callReadAt(env, s, s->logicalPos, want);
  if (n < 0 || s->javaError) {
    // A negative count is the Input contract for a byte source that threw:
    // the Kotlin proxy caught the IOException and stored its message. Mark
    // javaError so the JNI entry point returns ERR_JAVA and media3's
    // load-error policy retries the load; a bare AVERROR would read as a
    // malformed container, which media3 never retries (#2113).
    s->javaError = true;
    return AVERROR(EIO);
  }
  if (n == 0) return AVERROR_EOF;

  env->GetByteArrayRegion(s->readBuffer, 0, n, reinterpret_cast<jbyte*>(buf));
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

  // Pure bookkeeping: the next read serves this position from whichever path
  // can, so a seek can no longer fail or need reconciling. avio invalidates
  // its own buffers after this successful callback.
  s->logicalPos = target;
  return target;
}

// A failed byte-source read latches AVIOContext error state: fill_buffer
// stores the AVERROR in pb->error, sets pb->eof_reached, and never drives the
// read callback again while either is set (aviobuf.c). The Kotlin side maps
// ERR_JAVA to an IOException that media3's load-error policy retries with the
// source reopened, so the latch must be dropped when the retry re-enters —
// otherwise the first retry re-fails on the stale error without ever reaching
// the byte source (#2113). A genuine end of file latches eof_reached with
// error == 0 and is deliberately left alone.
void clearLatchedIoError(DemuxState* s) {
  if (s->format == nullptr || s->format->pb == nullptr) return;
  if (s->format->pb->error >= 0) return;
  s->format->pb->error = 0;
  s->format->pb->eof_reached = 0;
}

// Probing (ffio_ensure_seekback) can swap the AVIO buffer for a larger
// allocation and free the original, so the pointer handed to
// avio_alloc_context may be stale. Free whichever buffer the context
// currently holds, exactly once.
void freeAvio(DemuxState* s) {
  if (s->avio == nullptr) return;
  av_freep(&s->avio->buffer);
  avio_context_free(&s->avio);
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
  freeAvio(s);
  if (env != nullptr && s->input != nullptr) {
    if (s->readBuffer != nullptr) env->DeleteGlobalRef(s->readBuffer);
    env->DeleteGlobalRef(s->input);
  }
  delete s;
  gState = nullptr;
}

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

// Returns 0 on success or a negative AVERROR (ERR_JAVA when the byte source
// itself threw). The stream count is NOT the return value: positive counts
// would share the result-code namespace, so callers use nativeStreamCount().
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
  jmethodID midReadAt = env->GetMethodID(inputClass, "readAt", "(J[BI)I");
  jmethodID midLength = env->GetMethodID(inputClass, "length", "()J");
  env->DeleteLocalRef(inputClass);
  if (midPosition == nullptr || midRead == nullptr || midReadAt == nullptr || midLength == nullptr) {
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
  s->midReadAt = midReadAt;
  s->midLength = midLength;
  jbyteArray readBuffer = env->NewByteArray(kReadChunkBytes);
  s->readBuffer = static_cast<jbyteArray>(env->NewGlobalRef(readBuffer));
  env->DeleteLocalRef(readBuffer);

  if (s->packet == nullptr) {
    s->packet = av_packet_alloc();
    s->filteredPacket = av_packet_alloc();
    if (s->packet == nullptr || s->filteredPacket == nullptr) return AVERROR(ENOMEM);
  }

  // One AVIOContext per item: a stale buffer or a sticky error from the
  // previous item must not leak into this open, and reallocating is cheaper
  // than reasoning about which of libavformat's internal fields to reset.
  freeAvio(s);
  constexpr int kAvioBufferSize = 64 * 1024;
  unsigned char* avioBuffer = static_cast<unsigned char*>(av_malloc(kAvioBufferSize));
  if (avioBuffer == nullptr) return AVERROR(ENOMEM);
  s->avio = avio_alloc_context(
      avioBuffer, kAvioBufferSize, /*write_flag=*/0, s, avioReadPacket,
      /*write_packet=*/nullptr, avioSeek);
  if (s->avio == nullptr) {
    av_freep(&avioBuffer);
    return AVERROR(ENOMEM);
  }

  s->javaError = false;
  s->packetPending = false;
  s->logicalPos = 0;
  // Nothing is ever resumed across calls now: every read succeeds at the
  // position libavformat asked for, so open_input and find_stream_info each
  // run once, to completion.
  avformat_close_input(&s->format);
  s->opened = false;

  s->format = avformat_alloc_context();
  if (s->format == nullptr) return AVERROR(ENOMEM);
  s->format->pb = s->avio;
  // Generate missing PTS: some raw streams (MPEG-TS after a seek) present
  // packets without timestamps that media3 cannot schedule.
  s->format->flags |= AVFMT_FLAG_GENPTS;

  int err = avformat_open_input(&s->format, "", nullptr, nullptr);
  if (s->javaError) return ERR_JAVA;
  if (err < 0) {
    LOGW("avformat_open_input failed: %d", err);
    return err;
  }

  err = avformat_find_stream_info(s->format, nullptr);
  if (s->javaError) return ERR_JAVA;
  if (err < 0) {
    LOGW("avformat_find_stream_info failed: %d", err);
    return err;
  }
  // Zero-base the timeline: delivered pts subtract this so media3 sees
  // [0, duration] even when the container starts at a nonzero PCR/PTS.
  s->startTimeUs = s->format->start_time != AV_NOPTS_VALUE ? s->format->start_time : 0;
  s->opened = true;

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
JNIEXPORT jint JNICALL Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeReadPacket(
    JNIEnv* env, jobject thiz, jbyteArray buffer, jlongArray out) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || !s->opened || s->format == nullptr) return ERR_NOT_OPEN;

  jint capacity = env->GetArrayLength(buffer);
  jlong result[7] = {};
  s->javaError = false;
  clearLatchedIoError(s);
  while (true) {
    if (s->packetPending) {
      // Oversized packet held across a CODE_GROW round trip: deliver it now
      // instead of reading (and losing) a new frame.
      s->packetPending = false;
    } else {
      av_packet_unref(s->packet);
      int err = av_read_frame(s->format, s->packet);
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
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeLogicalPosition(JNIEnv* env, jobject thiz) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || !s->opened) return -1;
  return static_cast<jlong>(s->logicalPos);
}

// Seeks to a presentation time (media3 timeline microseconds, start-time
// normalized). Called on the loader thread, where blocking IO belongs:
// libavformat reads its own index through the random-access source, so this
// either lands on the target keyframe or reports that the container has no
// usable index.
JNIEXPORT jint JNICALL
Java_com_edde746_plezy_exoplayer_FfmpegDemuxerJni_nativeSeek(JNIEnv* env, jobject thiz, jlong timeUs) {
  StateLock lock;
  DemuxState* s = gState;
  if (s == nullptr || !s->opened || s->format == nullptr) return ERR_NOT_OPEN;
  s->javaError = false;
  clearLatchedIoError(s);
  // Any packet parked for a CODE_GROW retry belongs to the pre-seek stream.
  s->packetPending = false;
  if (s->bsf != nullptr) {
    for (unsigned i = 0; i < s->nbStreams; i++) {
      if (s->bsf[i] != nullptr) av_bsf_flush(s->bsf[i]);
    }
  }
  const int64_t ts = timeUs + s->startTimeUs;
  const int err = avformat_seek_file(s->format, -1, INT64_MIN, ts, ts, 0);
  if (s->javaError) return ERR_JAVA;
  if (err < 0) {
    LOGW("seek to %lld failed: %d", (long long)ts, err);
    return err;
  }
  LOGD("seek to %lld: logical=%lld", (long long)ts, (long long)s->logicalPos);
  return 0;
}

}  // extern "C"
