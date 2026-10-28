// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.MediaCodec;
import android.media.MediaCodecList;
import android.media.MediaFormat;
import android.os.Build;
import android.os.SystemClock;
import android.view.Surface;
import android.view.SurfaceHolder;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/** Bounded queues separate the network receiver from platform decoder latency. */
final class SteamDecoder implements AutoCloseable {
  interface Events {
    void size(int width, int height);
    void failed();
    void pyrowaveFailed();
    void hevcFailed();
    void audioFailed();
    void firstFrame();
  }
  private static final class Video {
    byte[] bytes;
    int id, codec, width, height;
    boolean key;
  }
  private static final class Audio {
    final short[] samples;
    final AudioTrack output;
    Audio(short[] samples, AudioTrack output) {
      this.samples = samples;
      this.output = output;
    }
  }
  private final long handle;
  private final Surface surface;
  private final SurfaceHolder surfaceHolder;
  private final Events events;
  private final ArrayBlockingQueue<Video> video = new ArrayBlockingQueue<>(4);
  private final ArrayBlockingQueue<Audio> audio = new ArrayBlockingQueue<>(8);
  private final AtomicBoolean lost = new AtomicBoolean();
  private final AtomicBoolean pyrowaveFallback = new AtomicBoolean();
  private final AtomicBoolean hevcFallback = new AtomicBoolean();
  private final AtomicBoolean audioFallback = new AtomicBoolean();
  private volatile boolean closed;
  private final Thread videoThread, audioThread;
  private final Object audioLock = new Object();
  private AudioTrack track;
  private volatile float audioVolume = 1.0f;
  private boolean shown;
  private volatile boolean pyrowaveActive;
  private volatile int videoCodec;
  private volatile int decoderKind; // 0 unknown, 1 hardware, 2 software, 3 Vulkan readback.
  private Bitmap pyrowaveBitmap;
  private final Paint pyrowavePaint = new Paint(Paint.FILTER_BITMAP_FLAG);
  SteamDecoder(long handle, SurfaceHolder surfaceHolder, Events events) {
    this.handle = handle;
    this.surfaceHolder = surfaceHolder;
    this.surface = surfaceHolder.getSurface();
    this.events = events;
    videoThread = new Thread(this::videoLoop, "PlezySteamVideo");
    audioThread = new Thread(this::audioLoop, "PlezySteamAudio");
    videoThread.start();
    audioThread.start();
  }
  static boolean supportsHevc() {
    MediaFormat format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_HEVC, 1920, 1080);
    return new MediaCodecList(MediaCodecList.REGULAR_CODECS).findDecoderForFormat(format) != null;
  }
  void appendMetrics(Map<String, Object> metrics) {
    metrics.put("decoderKind", decoderKind);
    metrics.put("videoQueue", video.size());
    metrics.put("audioQueue", audio.size());
  }
  public boolean onVideo(int codec, int width, int height, byte[] extra) {
    if (closed)
      return false;
    if ((codec != 4 && codec != 5 && codec != 9) || width < 1 || height < 1 || width > 1920 || height > 1080
        || extra == null || extra.length > 65536) {
      if (codec == 9)
        rejectPyrowave();
      return false;
    }
    Video config = new Video();
    config.codec = codec;
    config.width = width;
    config.height = height;
    config.bytes = extra;
    discardQueuedVideo();
    lost.set(false);
    boolean accepted = video.offer(config);
    if (!accepted && codec == 9)
      rejectPyrowave();
    return accepted;
  }
  public boolean onFrame(byte[] bytes, int id, boolean key) {
    if (closed || bytes.length > 2 * 1024 * 1024 || lost.getAndSet(false))
      return false;
    Video frame = new Video();
    frame.bytes = bytes;
    frame.id = id;
    frame.key = key;
    return video.offer(frame);
  }
  public boolean onAudio(int channels, int rate) {
    if (closed || rate != 48000 || (channels != 1 && channels != 2 && channels != 4 && channels != 6))
      return false;
    try {
      synchronized (audioLock) {
        releaseAudio();
        int mask = channels == 6 ? AudioFormat.CHANNEL_OUT_5POINT1
            : channels == 4      ? AudioFormat.CHANNEL_OUT_QUAD
            : channels == 2      ? AudioFormat.CHANNEL_OUT_STEREO
                                 : AudioFormat.CHANNEL_OUT_MONO;
        int minimum = AudioTrack.getMinBufferSize(rate, mask, AudioFormat.ENCODING_PCM_16BIT);
        if (minimum <= 0)
          return false;
        int buffer = Math.max(minimum, rate * channels / 25 * 2);
        AudioTrack.Builder builder = new AudioTrack.Builder()
                                         .setAudioAttributes(new AudioAttributes.Builder()
                                                                 .setUsage(AudioAttributes.USAGE_GAME)
                                                                 .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                                                 .build())
                                         .setAudioFormat(new AudioFormat.Builder()
                                                             .setSampleRate(rate)
                                                             .setChannelMask(mask)
                                                             .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                                             .build())
                                         .setBufferSizeInBytes(buffer)
                                         .setTransferMode(AudioTrack.MODE_STREAM);
        if (Build.VERSION.SDK_INT >= 26)
          builder.setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY);
        track = builder.build();
        if (track.getState() != AudioTrack.STATE_INITIALIZED) {
          releaseAudio();
          return false;
        }
        track.setVolume(audioVolume);
        track.play();
        return true;
      }
    } catch (RuntimeException e) {
      synchronized (audioLock) {
        releaseAudio();
      }
      return false;
    }
  }
  public void onAudioUnavailable() {
    if (!closed && audioFallback.compareAndSet(false, true))
      events.audioFailed();
  }
  boolean consumeAudioFallback() {
    return audioFallback.getAndSet(false);
  }
  void setVolume(float volume) {
    audioVolume = Math.max(0.0f, Math.min(1.0f, volume));
    synchronized (audioLock) {
      if (track != null)
        track.setVolume(audioVolume);
    }
  }
  public void onSamples(short[] samples) {
    if (closed || samples.length > 5760 * 6)
      return;
    synchronized (audioLock) {
      if (track == null)
        return;
      Audio packet = new Audio(samples, track);
      if (!audio.offer(packet)) {
        audio.poll();
        audio.offer(packet);
      }
    }
  }
  private void audioLoop() {
    try {
      while (!closed) {
        Audio packet = audio.poll(20, TimeUnit.MILLISECONDS);
        if (packet == null)
          continue;
        short[] samples = packet.samples;
        AudioTrack selected = packet.output;
        // AudioTrack may consume only part of a packet. Retry on this worker,
        // without holding the reconfiguration lock while waiting for capacity.
        // A stalled device must not accumulate unlimited latency or block stop.
        long deadline = SystemClock.elapsedRealtime() + 160;
        int offset = 0;
        while (!closed && selected != null && offset < samples.length) {
          int written;
          synchronized (audioLock) {
            if (track != selected)
              break;
            written = selected.write(samples, offset, samples.length - offset, AudioTrack.WRITE_NON_BLOCKING);
          }
          if (written < 0)
            throw new IllegalStateException("Audio output failed");
          offset += written;
          if (offset < samples.length) {
            if (SystemClock.elapsedRealtime() >= deadline)
              break;
            Thread.sleep(2);
          }
        }
      }
    } catch (InterruptedException ignored) {
      Thread.currentThread().interrupt();
    } catch (RuntimeException e) {
      onAudioUnavailable();
    } finally {
      synchronized (audioLock) {
        releaseAudio();
      }
    }
  }
  private void releaseAudio() {
    audio.clear();
    if (track != null) {
      try {
        track.pause();
        track.flush();
      } finally {
        track.release();
        track = null;
      }
    }
  }
  private void videoLoop() {
    MediaCodec decoder = null;
    Map<Long, Integer> pending = new HashMap<>();
    long sequence = 1;
    MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
    try {
      while (!closed) {
        Video item = video.poll(3, TimeUnit.MILLISECONDS);
        if (item != null && item.codec != 0) {
          videoCodec = item.codec;
          if (decoder != null) {
            decoder.stop();
            decoder.release();
            decoder = null;
          }
          for (int id : pending.values()) NativeSteam.frameComplete(handle, id, false);
          pending.clear();
          if (pyrowaveActive) {
            NativeSteam.pyrowaveStop(handle);
            pyrowaveActive = false;
          }
          if (pyrowaveBitmap != null) {
            pyrowaveBitmap.recycle();
            pyrowaveBitmap = null;
          }
          if (item.codec == 9) {
            pyrowaveActive = true;
            if (!NativeSteam.pyrowaveStart(handle, item.width, item.height, item.bytes))
              throw new IllegalStateException("Pyrowave decoder initialization failed");
            pyrowaveBitmap = Bitmap.createBitmap(item.width, item.height, Bitmap.Config.ARGB_8888);
            decoderKind = 3;
            events.size(item.width, item.height);
            continue;
          }
          String mime = item.codec == 5 ? MediaFormat.MIMETYPE_VIDEO_HEVC : MediaFormat.MIMETYPE_VIDEO_AVC;
          MediaFormat format = MediaFormat.createVideoFormat(mime, item.width, item.height);
          format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 2 * 1024 * 1024);
          format.setInteger(MediaFormat.KEY_MAX_WIDTH, 1920);
          format.setInteger(MediaFormat.KEY_MAX_HEIGHT, 1080);
          if (Build.VERSION.SDK_INT >= 30)
            format.setInteger(MediaFormat.KEY_LOW_LATENCY, 1);
          byte[][] parameters = NativeSteam.h26xStart(handle, item.codec, item.bytes);
          if (parameters == null || parameters.length != 3)
            throw new IllegalStateException("Invalid video configuration");
          if (item.codec == 4) {
            // Android requires separate SPS/PPS buffers, including start codes.
            if (parameters[0].length > 0)
              format.setByteBuffer("csd-0", ByteBuffer.wrap(parameters[0]));
            if (parameters[1].length > 0)
              format.setByteBuffer("csd-1", ByteBuffer.wrap(parameters[1]));
          } else {
            int size = parameters[0].length + parameters[1].length + parameters[2].length;
            if (size > 0) {
              ByteBuffer data = ByteBuffer.allocate(size);
              for (byte[] parameter : parameters) data.put(parameter);
              data.flip();
              format.setByteBuffer("csd-0", data);
            }
          }
          decoder = MediaCodec.createDecoderByType(mime);
          decoder.configure(format, surface, null, 0);
          decoder.start();
          decoderKind = Build.VERSION.SDK_INT >= 29 ? (decoder.getCodecInfo().isHardwareAccelerated() ? 1 : 2) : 0;
          events.size(item.width, item.height);
        } else if (item != null && pyrowaveActive) {
          byte[] argb = NativeSteam.pyrowaveDecode(handle, item.bytes);
          if (argb == null)
            throw new IllegalStateException("Pyrowave frame decode failed");
          if (argb.length == 0) {
            NativeSteam.frameComplete(handle, item.id, false);
            continue;
          }
          if (pyrowaveBitmap == null || argb.length != pyrowaveBitmap.getByteCount())
            throw new IllegalStateException("Pyrowave output size changed");
          pyrowaveBitmap.copyPixelsFromBuffer(ByteBuffer.wrap(argb));
          Canvas canvas = surfaceHolder.lockCanvas();
          if (canvas == null)
            throw new IllegalStateException("Video surface is unavailable");
          try {
            canvas.drawBitmap(pyrowaveBitmap, null, canvas.getClipBounds(), pyrowavePaint);
          } finally {
            surfaceHolder.unlockCanvasAndPost(canvas);
          }
          NativeSteam.frameComplete(handle, item.id, true);
          if (!shown) {
            shown = true;
            events.firstFrame();
          }
        } else if (item != null) {
          item.bytes = NativeSteam.h26xFrame(handle, item.bytes);
          if (item.bytes == null)
            throw new IllegalStateException("Invalid video frame");
          if (item.bytes.length == 0) {
            NativeSteam.frameComplete(handle, item.id, false);
            continue;
          }
          int input = decoder == null ? -1 : decoder.dequeueInputBuffer(2000);
          if (input < 0) {
            NativeSteam.frameComplete(handle, item.id, false);
            lost.set(true);
          } else {
            ByteBuffer buffer = decoder.getInputBuffer(input);
            if (buffer == null || buffer.capacity() < item.bytes.length)
              throw new IllegalStateException("Video frame too large");
            buffer.clear();
            buffer.put(item.bytes);
            long timestamp = sequence++ * 16667;
            pending.put(timestamp, item.id);
            decoder.queueInputBuffer(
                input, 0, item.bytes.length, timestamp, item.key ? MediaCodec.BUFFER_FLAG_KEY_FRAME : 0);
            if (pending.size() > 32)
              throw new IllegalStateException("Video decoder stalled");
          }
        }
        if (decoder != null) {
          int output;
          while ((output = decoder.dequeueOutputBuffer(info, 0)) >= 0) {
            Integer id = pending.remove(info.presentationTimeUs);
            decoder.releaseOutputBuffer(output, true);
            // This confirms submission to the display surface, not measured scanout.
            if (id != null)
              NativeSteam.frameComplete(handle, id, true);
            if (id != null && !shown) {
              shown = true;
              events.firstFrame();
            }
          }
          if (output == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
            MediaFormat actual = decoder.getOutputFormat();
            int width = actual.getInteger(MediaFormat.KEY_WIDTH);
            int height = actual.getInteger(MediaFormat.KEY_HEIGHT);
            if (width < 1 || width > 1920 || height < 1 || height > 1088)
              throw new IllegalStateException("Decoder dimensions exceed the receiver limit");
            if (Build.VERSION.SDK_INT >= 24) {
              int transfer = actual.containsKey(MediaFormat.KEY_COLOR_TRANSFER)
                  ? actual.getInteger(MediaFormat.KEY_COLOR_TRANSFER)
                  : 0;
              int standard = actual.containsKey(MediaFormat.KEY_COLOR_STANDARD)
                  ? actual.getInteger(MediaFormat.KEY_COLOR_STANDARD)
                  : 0;
              if (transfer == MediaFormat.COLOR_TRANSFER_ST2084 || transfer == MediaFormat.COLOR_TRANSFER_HLG
                  || standard == MediaFormat.COLOR_STANDARD_BT2020)
                throw new IllegalStateException("HDR was not negotiated for this surface");
            }
          }
        }
      }
    } catch (InterruptedException ignored) {
      Thread.currentThread().interrupt();
    } catch (OutOfMemoryError e) {
      videoFailure();
    } catch (Exception e) {
      videoFailure();
    } finally {
      if (decoder != null) {
        try {
          decoder.stop();
        } catch (RuntimeException ignored) {
        }
        decoder.release();
      }
      for (int id : pending.values()) NativeSteam.frameComplete(handle, id, false);
      if (pyrowaveActive) {
        NativeSteam.pyrowaveStop(handle);
        pyrowaveActive = false;
      }
      if (pyrowaveBitmap != null) {
        pyrowaveBitmap.recycle();
        pyrowaveBitmap = null;
      }
      discardQueuedVideo();
    }
  }
  private void discardQueuedVideo() {
    Video item;
    while ((item = video.poll()) != null)
      if (item.codec == 0)
        NativeSteam.frameComplete(handle, item.id, false);
  }
  private void videoFailure() {
    if (closed)
      return;
    if (pyrowaveActive) {
      rejectPyrowave();
      return;
    } else if (videoCodec == 5) {
      if (hevcFallback.compareAndSet(false, true))
        events.hevcFailed();
      return;
    } else {
      events.failed();
    }
    NativeSteam.cancel(handle);
  }
  private void rejectPyrowave() {
    if (pyrowaveFallback.compareAndSet(false, true))
      events.pyrowaveFailed();
  }
  boolean consumePyrowaveFallback() {
    return pyrowaveFallback.getAndSet(false);
  }
  boolean consumeHevcFallback() {
    return hevcFallback.getAndSet(false);
  }
  void requestPyrowaveFallback() {
    if (closed || !pyrowaveActive || !pyrowaveFallback.compareAndSet(false, true))
      return;
    events.pyrowaveFailed();
  }
  @Override
  public void close() {
    closed = true;
    videoThread.interrupt();
    audioThread.interrupt();
  }
  // Never called on the UI thread. A replacement must not acquire the old
  // Surface or destroy the native runtime while its decoder still uses them.
  void awaitTermination() {
    SteamWorker.await(videoThread);
    SteamWorker.await(audioThread);
  }
}
