package com.edde746.plezy

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowManager
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DefaultAllocator
import com.google.android.exoplayer2.DefaultLoadControl
import com.google.android.exoplayer2.ext.okhttp.OkHttpDataSource
import okhttp3.OkHttpClient
import okhttp3.Request

class PlayerActivity : Activity() {
    private var player: ExoPlayer? = null
    private var ended = false
    private var playbackError: String? = null
    private val timelineHandler = Handler(Looper.getMainLooper())
    private var requestHeaders: Map<String, String> = emptyMap()
    private var timelineUrl = ""
    private var ratingKey = ""
    private var mediaDurationMs = 0L
    private var playbackHttpClient: OkHttpClient? = null
    private val timelineRunnable = object : Runnable {
        override fun run() {
            val exo = player ?: return
            if (exo.isPlaying) reportTimeline(exo.currentPosition, "playing")
            timelineHandler.postDelayed(this, 10_000L)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        hideSystemUi()

        val url = intent.getStringExtra(EXTRA_URL)
        if (url.isNullOrBlank()) {
            finishWithResult("Missing playback URL")
            return
        }

        val keys = intent.getStringArrayExtra(EXTRA_HEADERS_KEYS) ?: emptyArray()
        val values = intent.getStringArrayExtra(EXTRA_HEADERS_VALUES) ?: emptyArray()
        val headers = linkedMapOf<String, String>()
        for (index in 0 until minOf(keys.size, values.size)) headers[keys[index]] = values[index]
        requestHeaders = headers
        timelineUrl = intent.getStringExtra(EXTRA_TIMELINE_URL) ?: ""
        ratingKey = intent.getStringExtra(EXTRA_RATING_KEY) ?: ""
        mediaDurationMs = intent.getLongExtra(EXTRA_DURATION_MS, 0L)

        val okHttpClient = LegacyTls.createClient(this)
        playbackHttpClient = okHttpClient
        val httpFactory = OkHttpDataSource.Factory(okHttpClient)
            .setDefaultRequestProperties(headers)

        // Small buffers are intentional: this head unit reports a 64 MiB app heap.
        val loadControl = DefaultLoadControl.Builder()
            .setAllocator(DefaultAllocator(true, C.DEFAULT_BUFFER_SEGMENT_SIZE))
            .setBufferDurationsMs(5_000, 18_000, 1_000, 2_500)
            .setTargetBufferBytes(12 * 1024 * 1024)
            .setPrioritizeTimeOverSizeThresholds(false)
            .build()
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()
        val exo = ExoPlayer.Builder(this)
            .setMediaSourceFactory(DefaultMediaSourceFactory(httpFactory))
            .setLoadControl(loadControl)
            .setAudioAttributes(audioAttributes, true)
            .build()
        player = exo

        val view = StyledPlayerView(this).apply {
            useController = true
            setShowSubtitleButton(true)
            controllerShowTimeoutMs = 4_000
            controllerAutoShow = true
            keepScreenOn = true
            player = exo
            contentDescription = intent.getStringExtra(EXTRA_TITLE) ?: "Plezy player"
        }
        setContentView(view)

        exo.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                if (state == Player.STATE_ENDED) ended = true
            }

            override fun onPlayerError(error: com.google.android.exoplayer2.PlaybackException) {
                playbackError = "${error.errorCodeName}: ${error.message ?: "Playback failed"}"
                window.decorView.post { finishWithResult(playbackError) }
            }
        })
        exo.setMediaItem(MediaItem.fromUri(Uri.parse(url)))
        val startMs = intent.getLongExtra(EXTRA_START_MS, 0L)
        if (startMs > 0L) exo.seekTo(startMs)
        exo.prepare()
        exo.playWhenReady = true
        timelineHandler.postDelayed(timelineRunnable, 10_000L)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemUi()
    }

    @Suppress("DEPRECATION")
    private fun hideSystemUi() {
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            )
    }

    override fun onBackPressed() {
        finishWithResult(playbackError)
    }

    private fun finishWithResult(error: String?) {
        val exo = player
        timelineHandler.removeCallbacks(timelineRunnable)
        reportTimeline(exo?.currentPosition ?: 0L, if (ended) "stopped" else "paused")
        setResult(Activity.RESULT_OK, Intent().apply {
            putExtra(RESULT_POSITION_MS, exo?.currentPosition ?: 0L)
            putExtra(RESULT_DURATION_MS, exo?.duration?.takeIf { it > 0L } ?: 0L)
            putExtra(RESULT_ENDED, ended)
            putExtra(RESULT_ERROR, error)
        })
        finish()
    }

    override fun onDestroy() {
        timelineHandler.removeCallbacks(timelineRunnable)
        if (!isFinishing) finishWithResult(playbackError)
        player?.release()
        player = null
        super.onDestroy()
    }

    private fun reportTimeline(positionMs: Long, state: String) {
        if (!timelineUrl.startsWith("https://") || ratingKey.isBlank()) return
        val target = Uri.parse(timelineUrl).buildUpon()
            .appendQueryParameter("ratingKey", ratingKey)
            .appendQueryParameter("key", "/library/metadata/$ratingKey")
            .appendQueryParameter("state", state)
            .appendQueryParameter("time", positionMs.toString())
            .appendQueryParameter("duration", mediaDurationMs.toString())
            .build().toString()
        val client = playbackHttpClient ?: return
        Thread {
            try {
                val builder = Request.Builder().url(target)
                for ((key, value) in requestHeaders) builder.header(key, value)
                client.newCall(builder.build()).execute().use { response -> response.code() }
            } catch (_: Exception) {
                // Dart-side bounded diagnostics records the final progress failure if needed.
            }
        }.start()
    }

    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_TITLE = "title"
        const val EXTRA_START_MS = "startMs"
        const val EXTRA_HEADERS_KEYS = "headerKeys"
        const val EXTRA_HEADERS_VALUES = "headerValues"
        const val EXTRA_RATING_KEY = "ratingKey"
        const val EXTRA_DURATION_MS = "durationMs"
        const val EXTRA_TIMELINE_URL = "timelineUrl"
        const val RESULT_POSITION_MS = "positionMs"
        const val RESULT_DURATION_MS = "durationMs"
        const val RESULT_ENDED = "ended"
        const val RESULT_ERROR = "error"
    }
}
