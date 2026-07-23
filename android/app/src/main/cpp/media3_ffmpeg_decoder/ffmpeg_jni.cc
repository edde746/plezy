/*
 * Copyright (C) 2016 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include <android/log.h>
#include <jni.h>

#include "ffmpeg_audio_buffer.h"

extern "C" {
#ifdef __cplusplus
#define __STDC_CONSTANT_MACROS
#ifdef _STDINT_H
#undef _STDINT_H
#endif
#include <stdint.h>
#endif
#include <libavcodec/avcodec.h>
#include <libavutil/channel_layout.h>
#include <libavutil/error.h>
#include <libavutil/opt.h>
#include <libswresample/swresample.h>
}

#define LOG_TAG "ffmpeg_jni"
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__))
#define LOGD(...) ((void)__android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__))

#define LIBRARY_FUNC(RETURN_TYPE, NAME, ...)                                                          \
  extern "C" {                                                                                        \
  JNIEXPORT RETURN_TYPE                                                                               \
  Java_androidx_media3_decoder_ffmpeg_FfmpegLibrary_##NAME(JNIEnv* env, jobject thiz, ##__VA_ARGS__); \
  }                                                                                                   \
  JNIEXPORT RETURN_TYPE Java_androidx_media3_decoder_ffmpeg_FfmpegLibrary_##NAME(                     \
      JNIEnv* env, jobject thiz, ##__VA_ARGS__)

#define AUDIO_DECODER_FUNC(RETURN_TYPE, NAME, ...)                                                         \
  extern "C" {                                                                                             \
  JNIEXPORT RETURN_TYPE                                                                                    \
  Java_androidx_media3_decoder_ffmpeg_FfmpegAudioDecoder_##NAME(JNIEnv* env, jobject thiz, ##__VA_ARGS__); \
  }                                                                                                        \
  JNIEXPORT RETURN_TYPE Java_androidx_media3_decoder_ffmpeg_FfmpegAudioDecoder_##NAME(                     \
      JNIEnv* env, jobject thiz, ##__VA_ARGS__)

#define ERROR_STRING_BUFFER_LENGTH 256

// Output format corresponding to AudioFormat.ENCODING_PCM_16BIT.
static const AVSampleFormat OUTPUT_FORMAT_PCM_16BIT = AV_SAMPLE_FMT_S16;
// Output format corresponding to AudioFormat.ENCODING_PCM_FLOAT.
static const AVSampleFormat OUTPUT_FORMAT_PCM_FLOAT = AV_SAMPLE_FMT_FLT;

// LINT.IfChange
static const int AUDIO_DECODER_ERROR_INVALID_DATA = -1;
static const int AUDIO_DECODER_ERROR_OTHER = -2;
// LINT.ThenChange(../java/androidx/media3/decoder/ffmpeg/FfmpegAudioDecoder.java)

namespace {
struct ResampleState {
  SwrContext* context;
  AVChannelLayout input_channel_layout;
  AVSampleFormat input_sample_format;
  AVSampleFormat output_sample_format;
  int sample_rate;
};
}  // namespace

static bool resampleConfigurationMatches(
    const ResampleState* state, const AVCodecContext* context, const AVFrame* frame);
static int configureResampler(ResampleState* state, const AVCodecContext* context, const AVFrame* frame);
static void releaseResampleState(ResampleState* state);

static jmethodID growOutputBufferMethod;

/**
 * Returns the AVCodec with the specified name, or NULL if it is not available.
 */
static const AVCodec* getCodecByName(JNIEnv* env, jstring codecName);

/**
 * Allocates and opens a new AVCodecContext for the specified codec, passing the
 * provided extraData as initialization data for the decoder if it is non-NULL.
 * Returns the created context.
 */
static AVCodecContext* createContext(
    JNIEnv* env, const AVCodec* codec, jbyteArray extraData, jboolean outputFloat, jint rawSampleRate,
    jint rawChannelCount);

namespace {
struct GrowOutputBufferCallback {
  uint8_t* operator()(int requiredSize) const;

  JNIEnv* env;
  jobject thiz;
  jobject decoderOutputBuffer;
};
}  // namespace

/**
 * Decodes the packet into the output buffer, returning the number of bytes
 * written, or a negative AUDIO_DECODER_ERROR constant value in the case of an
 * error.
 */
static int decodePacket(
    AVCodecContext* context, AVPacket* packet, uint8_t* outputBuffer, int outputSize,
    GrowOutputBufferCallback growBuffer);

/**
 * Transforms ffmpeg AVERROR into a negative AUDIO_DECODER_ERROR constant value.
 */
static int transformError(int errorNumber);

/**
 * Outputs a log message describing the avcodec error number.
 */
static void logError(const char* functionName, int errorNumber);

/**
 * Releases the specified context.
 */
static void releaseContext(AVCodecContext* context);

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  JNIEnv* env;
  if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
    LOGE("JNI_OnLoad: GetEnv failed");
    return -1;
  }
  jclass clazz = env->FindClass("androidx/media3/decoder/ffmpeg/FfmpegAudioDecoder");
  if (!clazz) {
    LOGE("JNI_OnLoad: FindClass failed");
    return -1;
  }
  growOutputBufferMethod = env->GetMethodID(
      clazz, "growOutputBuffer",
      "(Landroidx/media3/decoder/"
      "SimpleDecoderOutputBuffer;I)Ljava/nio/ByteBuffer;");
  if (!growOutputBufferMethod) {
    LOGE("JNI_OnLoad: GetMethodID failed");
    return -1;
  }
  return JNI_VERSION_1_6;
}

LIBRARY_FUNC(jstring, ffmpegGetVersion) { return env->NewStringUTF(LIBAVCODEC_IDENT); }

LIBRARY_FUNC(jint, ffmpegGetInputBufferPaddingSize) { return (jint)AV_INPUT_BUFFER_PADDING_SIZE; }

LIBRARY_FUNC(jboolean, ffmpegHasDecoder, jstring codecName) { return getCodecByName(env, codecName) != nullptr; }

AUDIO_DECODER_FUNC(
    jlong, ffmpegInitialize, jstring codecName, jbyteArray extraData, jboolean outputFloat, jint rawSampleRate,
    jint rawChannelCount) {
  const AVCodec* codec = getCodecByName(env, codecName);
  if (!codec) {
    LOGE("Codec not found.");
    return 0L;
  }
  return (jlong)createContext(env, codec, extraData, outputFloat, rawSampleRate, rawChannelCount);
}

AUDIO_DECODER_FUNC(
    jint, ffmpegDecode, jlong context, jobject inputData, jint inputSize, jobject decoderOutputBuffer,
    jobject outputData, jint outputSize) {
  if (!context) {
    LOGE("Context must be non-NULL.");
    return -1;
  }
  if (!inputData || !decoderOutputBuffer || !outputData) {
    LOGE("Input and output buffers must be non-NULL.");
    return -1;
  }
  if (inputSize < 0) {
    LOGE("Invalid input buffer size: %d.", inputSize);
    return -1;
  }
  if (outputSize < 0) {
    LOGE("Invalid output buffer length: %d", outputSize);
    return -1;
  }
  const jlong inputCapacity = env->GetDirectBufferCapacity(inputData);
  const jlong outputCapacity = env->GetDirectBufferCapacity(outputData);
  if (inputCapacity < inputSize || outputCapacity < outputSize) {
    LOGE("Buffer size exceeds direct buffer capacity.");
    return -1;
  }
  uint8_t* inputBuffer = (uint8_t*)env->GetDirectBufferAddress(inputData);
  uint8_t* outputBuffer = (uint8_t*)env->GetDirectBufferAddress(outputData);
  AVPacket* packet = av_packet_alloc();
  if (!packet) {
    LOGE("Failed to allocate packet.");
    return -1;
  }
  packet->data = inputBuffer;
  packet->size = inputSize;
  const int ret = decodePacket(
      (AVCodecContext*)context, packet, outputBuffer, outputSize,
      GrowOutputBufferCallback{env, thiz, decoderOutputBuffer});
  av_packet_free(&packet);
  return ret;
}

uint8_t* GrowOutputBufferCallback::operator()(int requiredSize) const {
  jobject newOutputData = env->CallObjectMethod(thiz, growOutputBufferMethod, decoderOutputBuffer, requiredSize);
  if (env->ExceptionCheck()) {
    LOGE("growOutputBuffer() failed");
    env->ExceptionDescribe();
    return nullptr;
  }
  if (env->GetDirectBufferCapacity(newOutputData) < requiredSize) {
    LOGE("growOutputBuffer() returned an undersized or non-direct buffer.");
    return nullptr;
  }
  return static_cast<uint8_t*>(env->GetDirectBufferAddress(newOutputData));
}

AUDIO_DECODER_FUNC(jint, ffmpegGetChannelCount, jlong context) {
  if (!context) {
    LOGE("Context must be non-NULL.");
    return -1;
  }
  return ((AVCodecContext*)context)->ch_layout.nb_channels;
}

AUDIO_DECODER_FUNC(jint, ffmpegGetSampleRate, jlong context) {
  if (!context) {
    LOGE("Context must be non-NULL.");
    return -1;
  }
  return ((AVCodecContext*)context)->sample_rate;
}

AUDIO_DECODER_FUNC(jlong, ffmpegReset, jlong jContext, jbyteArray extraData) {
  AVCodecContext* context = (AVCodecContext*)jContext;
  if (!context) {
    LOGE("Tried to reset without a context.");
    return 0L;
  }

  AVCodecID codecId = context->codec_id;
  if (codecId == AV_CODEC_ID_TRUEHD) {
    jboolean outputFloat = (jboolean)(context->request_sample_fmt == OUTPUT_FORMAT_PCM_FLOAT);
    // Release and recreate the context if the codec is TrueHD.
    // TODO: Figure out why flushing doesn't work for this codec.
    releaseContext(context);
    const AVCodec* codec = avcodec_find_decoder(codecId);
    if (!codec) {
      LOGE("Unexpected error finding codec %d.", codecId);
      return 0L;
    }
    return (jlong)createContext(
        env, codec, extraData, outputFloat,
        /* rawSampleRate= */ -1,
        /* rawChannelCount= */ -1);
  }

  avcodec_flush_buffers(context);
  return (jlong)context;
}

AUDIO_DECODER_FUNC(void, ffmpegRelease, jlong context) {
  if (context) {
    releaseContext((AVCodecContext*)context);
  }
}

static const AVCodec* getCodecByName(JNIEnv* env, jstring codecName) {
  if (!codecName) {
    return nullptr;
  }
  const char* codecNameChars = env->GetStringUTFChars(codecName, nullptr);
  const AVCodec* codec = avcodec_find_decoder_by_name(codecNameChars);
  env->ReleaseStringUTFChars(codecName, codecNameChars);
  return codec;
}

static AVCodecContext* createContext(
    JNIEnv* env, const AVCodec* codec, jbyteArray extraData, jboolean outputFloat, jint rawSampleRate,
    jint rawChannelCount) {
  AVCodecContext* context = avcodec_alloc_context3(codec);
  if (!context) {
    LOGE("Failed to allocate context.");
    return nullptr;
  }
  context->request_sample_fmt = outputFloat ? OUTPUT_FORMAT_PCM_FLOAT : OUTPUT_FORMAT_PCM_16BIT;
  if (extraData) {
    jsize size = env->GetArrayLength(extraData);
    if (size > INT_MAX - AV_INPUT_BUFFER_PADDING_SIZE) {
      LOGE("Extradata is too large.");
      releaseContext(context);
      return nullptr;
    }
    context->extradata_size = size;
    context->extradata = (uint8_t*)av_mallocz(static_cast<size_t>(size) + AV_INPUT_BUFFER_PADDING_SIZE);
    if (!context->extradata) {
      LOGE("Failed to allocate extradata.");
      releaseContext(context);
      return nullptr;
    }
    env->GetByteArrayRegion(extraData, 0, size, (jbyte*)context->extradata);
  }
  if (context->codec_id == AV_CODEC_ID_PCM_MULAW || context->codec_id == AV_CODEC_ID_PCM_ALAW) {
    context->sample_rate = rawSampleRate;
    av_channel_layout_default(&context->ch_layout, rawChannelCount);
  }
  context->err_recognition = AV_EF_IGNORE_ERR;
  int result = avcodec_open2(context, codec, nullptr);
  if (result < 0) {
    logError("avcodec_open2", result);
    releaseContext(context);
    return nullptr;
  }
  return context;
}

static bool resampleConfigurationMatches(
    const ResampleState* state, const AVCodecContext* context, const AVFrame* frame) {
  return state && state->context && state->input_sample_format == static_cast<AVSampleFormat>(frame->format) &&
         state->output_sample_format == context->request_sample_fmt && state->sample_rate == frame->sample_rate &&
         av_channel_layout_compare(&state->input_channel_layout, &frame->ch_layout) == 0;
}

static int configureResampler(ResampleState* state, const AVCodecContext* context, const AVFrame* frame) {
  SwrContext* nextContext = nullptr;
  const AVSampleFormat inputSampleFormat = static_cast<AVSampleFormat>(frame->format);
  int result = swr_alloc_set_opts2(
      &nextContext,                 // ps
      &frame->ch_layout,            // out_ch_layout
      context->request_sample_fmt,  // out_sample_fmt
      frame->sample_rate,           // out_sample_rate
      &frame->ch_layout,            // in_ch_layout
      inputSampleFormat,            // in_sample_fmt
      frame->sample_rate,           // in_sample_rate
      0,                            // log_offset
      nullptr                       // log_ctx
  );
  if (result < 0) {
    logError("swr_alloc_set_opts2", result);
    return result;
  }
  result = swr_init(nextContext);
  if (result < 0) {
    logError("swr_init", result);
    swr_free(&nextContext);
    return result;
  }

  AVChannelLayout nextInputChannelLayout = {};
  result = av_channel_layout_copy(&nextInputChannelLayout, &frame->ch_layout);
  if (result < 0) {
    logError("av_channel_layout_copy", result);
    swr_free(&nextContext);
    return result;
  }

  swr_free(&state->context);
  av_channel_layout_uninit(&state->input_channel_layout);
  state->context = nextContext;
  state->input_channel_layout = nextInputChannelLayout;
  state->input_sample_format = inputSampleFormat;
  state->output_sample_format = context->request_sample_fmt;
  state->sample_rate = frame->sample_rate;
  return 0;
}

static void releaseResampleState(ResampleState* state) {
  if (!state) {
    return;
  }
  swr_free(&state->context);
  av_channel_layout_uninit(&state->input_channel_layout);
  av_free(state);
}

static int decodePacket(
    AVCodecContext* context, AVPacket* packet, uint8_t* outputBuffer, int outputSize,
    GrowOutputBufferCallback growBuffer) {
  int result = avcodec_send_packet(context, packet);
  if (result) {
    logError("avcodec_send_packet", result);
    return transformError(result);
  }

  int outSize = 0;
  while (true) {
    AVFrame* frame = av_frame_alloc();
    if (!frame) {
      LOGE("Failed to allocate output frame.");
      return AUDIO_DECODER_ERROR_INVALID_DATA;
    }
    result = avcodec_receive_frame(context, frame);
    if (result) {
      av_frame_free(&frame);
      if (result == AVERROR(EAGAIN)) {
        break;
      }
      logError("avcodec_receive_frame", result);
      return transformError(result);
    }

    const AVSampleFormat sampleFormat = static_cast<AVSampleFormat>(frame->format);
    const int channelCount = frame->ch_layout.nb_channels;
    const int sampleRate = frame->sample_rate;
    const int sampleCount = frame->nb_samples;
    if (sampleFormat == AV_SAMPLE_FMT_NONE || channelCount <= 0 || sampleRate <= 0 || sampleCount < 0 ||
        !frame->extended_data || !av_channel_layout_check(&frame->ch_layout)) {
      LOGE("Decoder returned an invalid audio frame.");
      av_frame_free(&frame);
      return AUDIO_DECODER_ERROR_INVALID_DATA;
    }

    ResampleState* resampleState = static_cast<ResampleState*>(context->opaque);
    if (!resampleState) {
      resampleState = static_cast<ResampleState*>(av_mallocz(sizeof(ResampleState)));
      if (!resampleState) {
        LOGE("Failed to allocate resampler state.");
        av_frame_free(&frame);
        return AUDIO_DECODER_ERROR_OTHER;
      }
      context->opaque = resampleState;
    }
    if (!resampleConfigurationMatches(resampleState, context, frame)) {
      result = configureResampler(resampleState, context, frame);
      if (result < 0) {
        av_frame_free(&frame);
        return transformError(result);
      }
    }

    const int bytesPerSample = av_get_bytes_per_sample(context->request_sample_fmt);
    const int outputSampleCapacity = swr_get_out_samples(resampleState->context, sampleCount);
    int outputByteCapacity;
    int requiredOutputSize;
    if (!plezy::ffmpeg::CheckedAudioByteCount(
            outputSampleCapacity, channelCount, bytesPerSample, &outputByteCapacity) ||
        !plezy::ffmpeg::CheckedAddByteCount(outSize, outputByteCapacity, &requiredOutputSize)) {
      LOGE("Decoded audio output size is invalid or too large.");
      av_frame_free(&frame);
      return AUDIO_DECODER_ERROR_INVALID_DATA;
    }
    if (requiredOutputSize > outputSize) {
      LOGD(
          "Output buffer size (%d) too small for output data (%d), "
          "reallocating buffer.",
          outputSize, requiredOutputSize);
      outputSize = requiredOutputSize;
      outputBuffer = growBuffer(outputSize);
      if (!outputBuffer) {
        LOGE("Failed to reallocate output buffer.");
        av_frame_free(&frame);
        return AUDIO_DECODER_ERROR_OTHER;
      }
    }

    uint8_t* frameOutput = outputBuffer + outSize;
    uint8_t* outputPlanes[] = {frameOutput};
    result = swr_convert(
        resampleState->context, outputPlanes, outputSampleCapacity, (const uint8_t**)frame->extended_data, sampleCount);
    av_frame_free(&frame);
    if (result < 0) {
      logError("swr_convert", result);
      return AUDIO_DECODER_ERROR_INVALID_DATA;
    }

    int writtenByteCount;
    int nextOutSize;
    if (!plezy::ffmpeg::CheckedAudioByteCount(result, channelCount, bytesPerSample, &writtenByteCount) ||
        writtenByteCount > outputByteCapacity ||
        !plezy::ffmpeg::CheckedAddByteCount(outSize, writtenByteCount, &nextOutSize)) {
      LOGE("Resampler returned an invalid output sample count.");
      return AUDIO_DECODER_ERROR_INVALID_DATA;
    }
    outSize = nextOutSize;
  }
  return outSize;
}

static int transformError(int errorNumber) {
  return errorNumber == AVERROR_INVALIDDATA ? AUDIO_DECODER_ERROR_INVALID_DATA : AUDIO_DECODER_ERROR_OTHER;
}

static void logError(const char* functionName, int errorNumber) {
  char buffer[ERROR_STRING_BUFFER_LENGTH];
  av_strerror(errorNumber, buffer, sizeof(buffer));
  LOGE("Error in %s: %s", functionName, buffer);
}

static void releaseContext(AVCodecContext* context) {
  if (!context) {
    return;
  }
  releaseResampleState(static_cast<ResampleState*>(context->opaque));
  context->opaque = nullptr;
  avcodec_free_context(&context);
}
