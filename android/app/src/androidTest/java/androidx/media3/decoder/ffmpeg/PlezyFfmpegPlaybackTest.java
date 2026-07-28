/*
 * Copyright (C) 2026 Plezy contributors
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
package androidx.media3.decoder.ffmpeg;

import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.HandlerThread;
import androidx.annotation.Nullable;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.datasource.DefaultDataSource;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.RenderersFactory;
import androidx.media3.exoplayer.audio.DefaultAudioSink;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.extractor.DefaultExtractorsFactory;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(AndroidJUnit4.class)
public final class PlezyFfmpegPlaybackTest {
  private static final String[] FIXTURES = {
    "ffmpeg/stereo.flac",
    "ffmpeg/surround_5_1.flac",
    "ffmpeg/surround_7_1.flac",
    "ffmpeg/planar_5_1.m4a",
    "ffmpeg/surround_5_1_eac3.mka",
    "ffmpeg/surround_5_1_dts.mka",
    "ffmpeg/surround_5_1_truehd.mka"
  };

  @Test
  public void sharedDecoderUsesLibmpvFfmpegAndPlaysAllFixtures() throws Exception {
    assertTrue("FFmpeg JNI library is unavailable", FfmpegLibrary.isAvailable());
    String version = FfmpegLibrary.getVersion();
    assertTrue("Expected libmpv's FFmpeg 8, got " + version, version != null && version.startsWith("Lavc62."));
    for (String fixture : FIXTURES) {
      playToEnd(fixture);
    }
  }

  private static void playToEnd(String fixture) throws Exception {
    Context instrumentationContext = InstrumentationRegistry.getInstrumentation().getContext();
    Context context = InstrumentationRegistry.getInstrumentation().getTargetContext();
    File fixtureFile = copyFixture(instrumentationContext, context, fixture);
    HandlerThread playbackThread = new HandlerThread("ffmpeg-test-player");
    playbackThread.start();
    Handler handler = new Handler(playbackThread.getLooper());
    CountDownLatch completed = new CountDownLatch(1);
    AtomicReference<ExoPlayer> playerReference = new AtomicReference<>();
    AtomicReference<Throwable> errorReference = new AtomicReference<>();

    handler.post(
        () -> {
          try {
            RenderersFactory renderersFactory =
                (eventHandler,
                        videoRendererEventListener,
                        audioRendererEventListener,
                        textRendererOutput,
                        metadataRendererOutput) ->
                    new Renderer[] {
                      new FfmpegAudioRenderer(
                          eventHandler, audioRendererEventListener, new DefaultAudioSink.Builder().build())
                    };
            ExoPlayer player =
                new ExoPlayer.Builder(context, renderersFactory)
                    .setLooper(playbackThread.getLooper())
                    .build();
            playerReference.set(player);
            player.addListener(
                new Player.Listener() {
                  @Override
                  public void onPlayerError(PlaybackException error) {
                    errorReference.set(error);
                    completed.countDown();
                  }

                  @Override
                  public void onPlaybackStateChanged(@Player.State int playbackState) {
                    if (playbackState == Player.STATE_ENDED) {
                      completed.countDown();
                    }
                  }
                });
            MediaSource source =
                new ProgressiveMediaSource.Factory(
                        new DefaultDataSource.Factory(context), new DefaultExtractorsFactory())
                    .createMediaSource(MediaItem.fromUri(Uri.fromFile(fixtureFile)));
            player.setMediaSource(source);
            player.prepare();
            player.play();
          } catch (Throwable error) {
            errorReference.set(error);
            completed.countDown();
          }
        });

    boolean finished = completed.await(20, TimeUnit.SECONDS);
    CountDownLatch released = new CountDownLatch(1);
    handler.post(
        () -> {
          @Nullable ExoPlayer player = playerReference.get();
          if (player != null) player.release();
          playbackThread.quitSafely();
          released.countDown();
        });
    boolean teardownFinished = released.await(5, TimeUnit.SECONDS);
    playbackThread.join(5000);
    boolean fixtureDeleted = fixtureFile.delete();

    assertTrue("Player teardown timed out for " + fixture, teardownFinished);
    assertTrue("Playback timed out for " + fixture, finished);
    assertNull("Playback failed for " + fixture, errorReference.get());
    assertTrue("Fixture cleanup failed for " + fixture, fixtureDeleted);
  }

  private static File copyFixture(
      Context instrumentationContext, Context targetContext, String fixture) throws Exception {
    File output = File.createTempFile("ffmpeg-fixture-", null, targetContext.getCacheDir());
    try (InputStream input = instrumentationContext.getAssets().open(fixture);
        OutputStream sink = new FileOutputStream(output)) {
      byte[] buffer = new byte[8192];
      int count;
      while ((count = input.read(buffer)) != -1) {
        sink.write(buffer, 0, count);
      }
    }
    return output;
  }
}
