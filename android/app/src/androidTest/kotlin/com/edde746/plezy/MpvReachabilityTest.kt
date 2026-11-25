package com.edde746.plezy

import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.mpv.MpvPlayerEngine
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Collections
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * The app's mpv engine, built as the app builds it (every constructor argument, as AndroidPlatform.createPlayback
 * passes them), loads libmpv, starts mpv and plays a file: mpv's first playback restart comes back to Kotlin through
 * the JNI callbacks native code finds by name, and a released engine terminates mpv. Run against the harness build
 * (-Pplezy.testBuildType=harness), it fails where R8 strips or renames what native code reaches. The file is 10 s of
 * silent WAV written here (no media server), played without audio output (ao=null).
 */
class MpvReachabilityTest {
    @Test
    fun theEngineStartsMpvAndNativeCallbacksReachKotlin() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val file = File(context.cacheDir, "reachability.wav")
        file.outputStream().use { it.write(silentWav(seconds = 10)) }
        val playing = CountDownLatch(1)
        val terminating = CountDownLatch(1)
        val events: (String) -> Unit = { event ->
            if (event == "playing") playing.countDown()
            if (event == "terminate") terminating.countDown()
        }
        val settings = DeviceSettings.DEFAULT
        val engine = MpvPlayerEngine(context, Collections.singletonMap("ao", "null"), events, settings)
        try {
            engine.load(LoadRequest(url = file.path, options = PlaybackOptions.of(settings, HardwareDecoder.ANDROID)))
            assertTrue("mpv's first playback restart never reached Kotlin", playing.await(TIMEOUT_SECONDS, TimeUnit.SECONDS))
        } finally {
            engine.release()
        }
        assertTrue("the released engine never terminated mpv", terminating.await(TIMEOUT_SECONDS, TimeUnit.SECONDS))
        file.delete()
    }

    /** A mono 8 kHz 16-bit PCM WAV of [seconds] of silence. */
    private fun silentWav(seconds: Int): ByteArray {
        val rate = 8_000
        val data = rate * 2 * seconds
        val wav = ByteBuffer.allocate(44 + data).order(ByteOrder.LITTLE_ENDIAN)
        wav.put("RIFF".toByteArray()).putInt(36 + data).put("WAVE".toByteArray())
        wav.put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(1).putInt(rate).putInt(rate * 2).putShort(2).putShort(16)
        wav.put("data".toByteArray()).putInt(data)
        return wav.array()
    }

    private companion object {
        const val TIMEOUT_SECONDS = 20L
    }
}
