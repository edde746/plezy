package com.edde746.plezy.mpv

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import com.edde746.plezy.playback.EngineState
import java.util.concurrent.Executors

/**
 * What a video playback is doing, kept on disk while it plays, so a process that dies mid-playback (a native crash, the
 * low-memory killer) leaves the next launch's exit report ([read]) the audio it was playing (codec, channels, sample
 * rate), the video decoder, passthrough, downmix and normalization, and the engine. A playback's open clears the last
 * one's ([opened]); its release ([released]) clears it too and leaves the player disposed. Only allowlisted values
 * are stored ([Snapshot.of]). Writes go to one background thread, in call order, for every engine of the process.
 */
class PlaybackDiagnostics(context: Context, private val player: String) {
    private val preferences = context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
    private var normalization = false
    private var downmix = false
    private var last: Snapshot? = null
    private var playing = false

    /** A file opens: the last playback's values go, and the engine is this one. */
    @Synchronized
    fun opened() {
        playing = true
        last = null
        write { clearPlayback().putString(KEY_UI_STATE, UI_PLAYER).putString(KEY_PLAYER, player) }
    }

    /** The audio's loudness normalization and its mix down to stereo, as the engine applies them. */
    @Synchronized
    fun audio(normalization: Boolean, downmix: Boolean) {
        this.normalization = normalization
        this.downmix = downmix
        last?.let { record(it.copy(normalization = normalization, downmix = downmix)) }
    }

    /** The engine's latest state; stored when what it says about the playback changed. */
    @Synchronized
    fun update(state: EngineState) {
        if (!playing || !state.loaded) return
        record(Snapshot.of(state, normalization, downmix))
    }

    /** The playback ended: nothing plays, and the player is disposed. */
    @Synchronized
    fun released() {
        playing = false
        last = null
        write { clearPlayback().putString(KEY_UI_STATE, UI_PLAYER_DISPOSED) }
    }

    private fun record(snapshot: Snapshot) {
        if (!playing || snapshot == last) return
        last = snapshot
        write {
            snapshot.codecContext?.let { putString(KEY_CODEC_CONTEXT, it) }
            snapshot.channelCount?.let { putInt(KEY_CHANNEL_COUNT, it) }
            snapshot.sampleRate?.let { putInt(KEY_SAMPLE_RATE, it) }
            snapshot.decoder?.let { putString(KEY_SELECTED_DECODER, it) }
            putBoolean(KEY_PASSTHROUGH, snapshot.passthrough)
            putBoolean(KEY_DOWNMIX, snapshot.downmix)
            putBoolean(KEY_NORMALIZATION, snapshot.normalization)
            putString(KEY_UI_STATE, UI_PLAYER)
            putString(KEY_PLAYER, player)
        }
    }

    private fun write(change: SharedPreferences.Editor.() -> SharedPreferences.Editor) {
        writer.execute {
            if (!preferences.edit().change().commit()) Log.w(TAG, "Playback diagnostics not stored")
        }
    }

    private fun SharedPreferences.Editor.clearPlayback() = apply {
        for (key in PLAYBACK_KEYS) remove(key)
    }

    /** What a playback's state says about it, allowlisted. */
    data class Snapshot(
        val codecContext: String?,
        val channelCount: Int?,
        val sampleRate: Int?,
        val decoder: String?,
        val passthrough: Boolean,
        val downmix: Boolean,
        val normalization: Boolean,
    ) {
        companion object {
            fun of(state: EngineState, normalization: Boolean, downmix: Boolean) = Snapshot(
                codecContext = state.audio?.codec?.let(::codecContext),
                channelCount = state.audio?.channels?.takeIf { it in 1..32 },
                sampleRate = state.audio?.sampleRate?.takeIf { it in 1..768_000 },
                decoder = state.hwdec?.let { if (DECODER_NAME.matches(it)) it else "unknown" },
                passthrough = state.audioPassthrough,
                downmix = downmix,
                normalization = normalization,
            )

            /** An mpv codec name ([com.edde746.plezy.playback.AudioInfo.codec]) as one of a fixed set. */
            fun codecContext(codec: String): String = when {
                codec == "aac" -> "audio:aac"
                codec == "ac3" -> "audio:ac3"
                codec == "eac3" -> "audio:eac3"
                codec == "dts" || codec == "dca" -> "audio:dts"
                codec == "truehd" || codec == "mlp" -> "audio:truehd"
                codec == "flac" -> "audio:flac"
                codec.startsWith("pcm") -> "audio:pcm"
                else -> "audio:other"
            }

            private val DECODER_NAME = Regex("[A-Za-z0-9_.:-]{1,96}")
        }
    }

    companion object {
        private const val TAG = "PlaybackDiagnostics"
        const val PLAYER_MPV = "mpv"
        private const val UI_PLAYER = "player"
        private const val UI_PLAYER_DISPOSED = "player_disposed"

        private const val PREFERENCES = "plezy_runtime_diagnostics"
        private const val KEY_CODEC_CONTEXT = "codec_context"
        private const val KEY_CHANNEL_COUNT = "channel_count"
        private const val KEY_SAMPLE_RATE = "sample_rate"
        private const val KEY_SELECTED_DECODER = "selected_decoder"
        private const val KEY_PASSTHROUGH = "passthrough_enabled"
        private const val KEY_DOWNMIX = "downmix_enabled"
        private const val KEY_NORMALIZATION = "normalization_enabled"
        private const val KEY_UI_STATE = "ui_state"
        private const val KEY_PLAYER = "player"
        private val PLAYBACK_KEYS = listOf(
            KEY_CODEC_CONTEXT, KEY_CHANNEL_COUNT, KEY_SAMPLE_RATE, KEY_SELECTED_DECODER,
            KEY_PASSTHROUGH, KEY_DOWNMIX, KEY_NORMALIZATION, KEY_PLAYER,
        )

        private val writer = Executors.newSingleThreadExecutor { Thread(it, "playback-diagnostics").apply { isDaemon = true } }

        /**
         * The last process's playback as the exit report names it: `codecContext`, `channelCount`, `sampleRate`,
         * `selectedDecoder`, `passthroughEnabled`, `downmixEnabled`, `normalizationEnabled`, `uiState`, `player`; only
         * those stored. Read it before this process plays anything.
         */
        fun read(context: Context): Map<String, Any> {
            val stored = context.applicationContext.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).all
            return buildMap {
                (stored[KEY_CODEC_CONTEXT] as? String)?.let { put("codecContext", it) }
                (stored[KEY_CHANNEL_COUNT] as? Int)?.let { put("channelCount", it) }
                (stored[KEY_SAMPLE_RATE] as? Int)?.let { put("sampleRate", it) }
                (stored[KEY_SELECTED_DECODER] as? String)?.let { put("selectedDecoder", it) }
                (stored[KEY_PASSTHROUGH] as? Boolean)?.let { put("passthroughEnabled", it) }
                (stored[KEY_DOWNMIX] as? Boolean)?.let { put("downmixEnabled", it) }
                (stored[KEY_NORMALIZATION] as? Boolean)?.let { put("normalizationEnabled", it) }
                (stored[KEY_UI_STATE] as? String)?.let { put("uiState", it) }
                (stored[KEY_PLAYER] as? String)?.let { put("player", it) }
            }
        }
    }
}
