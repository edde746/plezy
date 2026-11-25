package com.edde746.plezy.mpv

import android.content.Context
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.util.Log
import com.edde746.mpv.EndFileReason
import com.edde746.mpv.MpvEvent
import com.edde746.mpv.MpvPlayer
import com.edde746.mpv.PropertyChange
import com.edde746.mpv.PropertyFormat
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.music.engine.ContentFds
import com.edde746.plezy.music.engine.MpvAudioCore
import com.edde746.plezy.music.engine.MpvAudioCoreListener
import com.edde746.plezy.music.engine.MpvAudioPlayer
import com.edde746.plezy.playback.mpv.MpvLog
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * The music player on Android: a dedicated audio-only mpv (its own handle, never a video engine's) on Android's audio
 * outputs, with `content://` documents opened as descriptors. [extraOptions] come last (a test run's `mute=yes`).
 */
fun androidAudioPlayer(context: Context, extraOptions: Map<String, String> = emptyMap()): AudioPlayer = MpvAudioPlayer(
    AndroidMpvAudioCore(context),
    platformOptions = mapOf("ao" to "audiotrack,opensles") + extraOptions,
    contentFds = AndroidContentFds(context),
)

/**
 * [MpvAudioCore] over mpv-android's [MpvPlayer]. Every call into mpv runs on one thread of its own, in call order
 * (mpv-android refuses the main thread, and `close` blocks through the audio output's teardown); answers come on it,
 * mpv's reports on mpv-android's dispatcher.
 */
internal class AndroidMpvAudioCore(context: Context) : MpvAudioCore {
    private val appContext = context.applicationContext
    private val executor: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "mpv-audio") }

    @Volatile private var player: MpvPlayer? = null
    @Volatile private var listener: MpvAudioCoreListener? = null

    private val callbacks = object : MpvPlayer.Listener {
        override fun onPropertyChange(change: PropertyChange) {
            val value = when (change) {
                is PropertyChange.Str -> change.value
                is PropertyChange.Flag -> if (change.value) "yes" else "no"
                is PropertyChange.Double -> change.value.toString()
                is PropertyChange.Int64 -> change.value.toString()
                else -> null
            }
            listener?.onProperty(change.name, value)
        }

        override fun onEvent(event: MpvEvent) {
            when (event) {
                is MpvEvent.FileLoaded -> listener?.onFileLoaded()
                is MpvEvent.EndFile -> listener?.onEndFile(
                    if (event.reason == EndFileReason.Error) event.errorMessage ?: event.error?.name ?: "error" else null,
                )
                is MpvEvent.LogMessage -> MpvLog.write(MpvLog.level(event.level.name), event.prefix, event.text)
                else -> Unit
            }
        }
    }

    override fun start(options: Map<String, String>, observed: List<String>, listener: MpvAudioCoreListener): String? =
        executor.submit<String?> {
            this.listener = listener
            try {
                val p = MpvPlayer.create(appContext, callbacks) {
                    setLogLevel("warn")
                    for ((name, value) in options) setOption(name, value)
                }
                for (name in observed) p.observeProperty(name, PropertyFormat.String)
                player = p
                MpvNativeLibraries.loaded()
                null
            } catch (e: Throwable) {
                // A native library that doesn't load (an ABI the AAR lacks) is a LinkageError: the same failure here.
                if (e !is Exception && e !is LinkageError) throw e
                this.listener = null
                Log.e(TAG, "mpv audio core failed to start", e)
                e.message ?: e.toString()
            }
        }.get()

    override fun command(args: List<String>, done: (String?) -> Unit) = run(done) { it.command(*args.toTypedArray()) }

    override fun setProperty(name: String, value: String, done: (String?) -> Unit) = run(done) { it.setProperty(name, value) }

    override fun getProperty(name: String, done: (String?, String?) -> Unit) {
        submit({ done(null, "the audio core is gone") }) {
            val p = player ?: return@submit done(null, "the audio core is gone")
            val value = try {
                p.getString(name)
            } catch (e: Exception) {
                return@submit done(null, e.message ?: e.toString())
            }
            done(value, null)
        }
    }

    override fun setLogLevel(level: String) {
        submit({}) { player?.setLogLevel(level) }
    }

    override fun destroy() {
        listener = null
        submit({}) {
            val p = player
            player = null
            try {
                p?.close()
            } catch (e: Exception) {
                Log.w(TAG, "mpv audio core close failed", e)
            }
        }
        executor.shutdown()
    }

    /** Runs [block] on mpv's thread; [done] gets null when mpv took it, else why not. */
    private fun run(done: (String?) -> Unit, block: (MpvPlayer) -> Unit) {
        submit({ done("the audio core is gone") }) {
            val p = player ?: return@submit done("the audio core is gone")
            val error = try {
                block(p)
                null
            } catch (e: Exception) {
                // mpv-build's MpvException carries mpv's reason as its message.
                e.message ?: e.toString()
            }
            done(error)
        }
    }

    private fun submit(rejected: () -> Unit, block: () -> Unit) {
        try {
            executor.execute(block)
        } catch (e: RejectedExecutionException) {
            rejected()
        }
    }

    private companion object {
        const val TAG = "MpvAudioCore"
    }
}

/** `content://` documents as detached descriptors for mpv's `fdclose://`. */
internal class AndroidContentFds(context: Context) : ContentFds {
    private val resolver = context.applicationContext.contentResolver

    override fun open(uri: String): Int {
        val descriptor = checkNotNull(resolver.openFileDescriptor(Uri.parse(uri), "r")) { "no provider opens $uri" }
        return descriptor.detachFd()
    }

    override fun close(fd: Int) {
        ParcelFileDescriptor.adoptFd(fd).close()
    }
}
