// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;
import android.media.MediaCodec;
import android.media.MediaCodecList;
import android.media.MediaFormat;
import android.os.Build;
import android.os.SystemClock;
import android.view.Surface;
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
    void firstFrame();
  }
  private static final class Video {
    byte[] bytes;
    int id, codec, width, height;
    boolean key;
  }
  private final long handle;
  private final Surface surface;
  private final Events events;
  private final ArrayBlockingQueue<Video> video = new ArrayBlockingQueue<>(4);
  private final ArrayBlockingQueue<short[]> audio = new ArrayBlockingQueue<>(8);
  private final AtomicBoolean lost = new AtomicBoolean();
  private volatile boolean closed;
  private final Thread videoThread, audioThread;
  private final Object audioLock = new Object();
  private AudioTrack track;
  private boolean shown;
  SteamDecoder(long handle, Surface surface, Events events) {
    this.handle = handle;
    this.surface = surface;
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
  public boolean onVideo(int codec, int width, int height, byte[] extra) {
    if (closed || (codec != 4 && codec != 5) || width < 1 || height < 1 || width > 4096 || height > 2160
        || extra.length > 65536)
      return false;
    Video config = new Video();
    config.codec = codec;
    config.width = width;
    config.height = height;
    config.bytes = extra;
    discardQueuedVideo();
    lost.set(false);
    return video.offer(config);
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
    if (closed || rate != 48000 || channels < 1 || channels > 2)
      return false;
    try {
      synchronized (audioLock) {
        releaseAudio();
        int mask = channels == 2 ? AudioFormat.CHANNEL_OUT_STEREO : AudioFormat.CHANNEL_OUT_MONO;
        int buffer =
            Math.max(AudioTrack.getMinBufferSize(rate, mask, AudioFormat.ENCODING_PCM_16BIT), rate * channels / 25 * 2);
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
        track.play();
        return true;
      }
    } catch (RuntimeException e) {
      return false;
    }
  }
  public void onSamples(short[] samples) {
    if (closed || samples.length > 11520)
      return;
    if (!audio.offer(samples)) {
      audio.poll();
      audio.offer(samples);
    }
  }
  private void audioLoop() {
    try {
      while (!closed) {
        short[] samples = audio.poll(20, TimeUnit.MILLISECONDS);
        if (samples == null)
          continue;
        AudioTrack selected;
        synchronized (audioLock) {
          selected = track;
        }
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
      failure();
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
          if (decoder != null) {
            decoder.stop();
            decoder.release();
            decoder = null;
          }
          for (int id : pending.values()) NativeSteam.frameComplete(handle, id, false);
          pending.clear();
          String mime = item.codec == 5 ? MediaFormat.MIMETYPE_VIDEO_HEVC : MediaFormat.MIMETYPE_VIDEO_AVC;
          MediaFormat format = MediaFormat.createVideoFormat(mime, item.width, item.height);
          format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 2 * 1024 * 1024);
          if (Build.VERSION.SDK_INT >= 30)
            format.setInteger(MediaFormat.KEY_LOW_LATENCY, 1);
          if (item.bytes.length > 0)
            format.setByteBuffer("csd-0", ByteBuffer.wrap(item.bytes));
          decoder = MediaCodec.createDecoderByType(mime);
          decoder.configure(format, surface, null, 0);
          decoder.start();
          events.size(item.width, item.height);
        } else if (item != null) {
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
            if (!shown) {
              shown = true;
              events.firstFrame();
            }
          }
        }
      }
    } catch (InterruptedException ignored) {
      Thread.currentThread().interrupt();
    } catch (Exception e) {
      failure();
    } finally {
      if (decoder != null) {
        try {
          decoder.stop();
        } catch (RuntimeException ignored) {
        }
        decoder.release();
      }
      for (int id : pending.values()) NativeSteam.frameComplete(handle, id, false);
      discardQueuedVideo();
    }
  }
  private void discardQueuedVideo() {
    Video item;
    while ((item = video.poll()) != null)
      if (item.codec == 0)
        NativeSteam.frameComplete(handle, item.id, false);
  }
  private void failure() {
    if (!closed) {
      events.failed();
      NativeSteam.cancel(handle);
    }
  }
  @Override
  public void close() {
    closed = true;
    videoThread.interrupt();
    audioThread.interrupt();
  }
}
