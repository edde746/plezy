package androidx.media3.decoder.ffmpeg

import android.os.Handler
import android.os.Looper
import androidx.media3.common.MimeTypes
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.audio.AudioRendererEventListener
import androidx.media3.exoplayer.video.VideoRendererEventListener
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.exoplayer.PlezyRenderersFactory
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Asserts the bundled FFmpeg audio decoder is reachable the way production reaches it.
 *
 * Every path here is name-based, so R8 can sever it while the code still compiles and
 * every debug check passes. #1703 shipped exactly that: the shrinker dropped
 * FfmpegAudioRenderer and FfmpegAudioDecoder.growOutputBuffer, TrueHD and DTS-HD lost
 * their only decoder, and 4K Dolby Vision files bailed to the mpv fallback.
 *
 * Run this against the `minified` build type (`-Pplezy.testBuildType=minified`); on an
 * unminified variant it can only ever pass. Deliberately touches no ExoPlayer builder
 * API, so no keep rule beyond the ones under test has to exist for it to run.
 *
 * Emptying `proguard-rules.pro` was verified to fail
 * [nativeLibraryLoadsAndReportsTheCodecsOnlyItCanDecode]; the renderer-list assertion
 * kept passing, because something else in this variant still retains that class. Treat
 * the JNI assertion as the load-bearing one, and `scripts/check_shrinker_rules.py` as the
 * guard for the renderer's own keep.
 */
@RunWith(AndroidJUnit4::class)
class FfmpegDecoderReachabilityTest {

  @Test
  fun productionRendererListIncludesTheFfmpegAudioRenderer() {
    // Goes through the app's own factory rather than repeating media3's Class.forName:
    // the instrumentation APK shares a class loader with the app, so a direct reflective
    // lookup can resolve a copy the harness carries even when the app APK lost its own.
    // DefaultRenderersFactory swallows ClassNotFoundException as "built without the
    // extension", so a shrunk renderer leaves no trace but missing codecs.
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val factory = PlezyRenderersFactory(context)
      .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
    val handler = Handler(Looper.getMainLooper())

    val names = factory.createRenderers(
      handler,
      object : VideoRendererEventListener {},
      object : AudioRendererEventListener {},
      { },
      { }
    ).map { it.name }

    assertTrue("FfmpegAudioRenderer missing from $names", names.contains("FfmpegAudioRenderer"))
  }

  @Test
  fun nativeLibraryLoadsAndReportsTheCodecsOnlyItCanDecode() {
    // isAvailable() covers the whole JNI handshake: the shared library loads, JNI_OnLoad
    // resolves FfmpegAudioDecoder by name, and GetMethodID finds growOutputBuffer with a
    // descriptor naming SimpleDecoderOutputBuffer. Any of those renamed or shrunk away
    // makes this false.
    assertTrue("FFmpeg JNI library is unavailable", FfmpegLibrary.isAvailable())

    // The formats MediaCodec has no decoder for on the affected devices.
    assertTrue("no truehd decoder", FfmpegLibrary.supportsFormat(MimeTypes.AUDIO_TRUEHD))
    assertTrue("no dts-hd decoder", FfmpegLibrary.supportsFormat(MimeTypes.AUDIO_DTS_HD))
  }
}
