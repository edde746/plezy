package com.edde746.plezy

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.Format
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.analytics.AnalyticsListener
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DefaultAllocator
import com.google.android.exoplayer2.DefaultLoadControl
import com.google.android.exoplayer2.ext.okhttp.OkHttpDataSource
import com.google.android.exoplayer2.upstream.HttpDataSource
import okhttp3.OkHttpClient
import okhttp3.Request

class PlayerActivity : Activity() {
    private data class Marker(val type: String, val startMs: Long, val endMs: Long)

    private var player: ExoPlayer? = null
    private var ended = false
    private var playbackError: String? = null
    private val diagnostics = PlaybackDiagnostics()
    private var failureKind: String? = null
    private var completed = false
    private var renderedFirstFrame = false
    private var firstFrameMs = -1L
    private var decoderName: String? = null
    private var videoFormat: String? = null
    private var playerStartedAtMs = 0L
    private var automaticRetries = 0
    private var wasPlayingBeforePause = false
    private var activityPaused = false
    private var playerView: StyledPlayerView? = null
    private var skipButton: Button? = null
    private var markers: List<Marker> = emptyList()
    private var skipMode = "button"
    private val skippedMarkerIndexes = mutableSetOf<Int>()
    private var seekBackMs = 10_000L
    private var seekForwardMs = 30_000L
    private var pendingSeekPositionMs: Long? = null
    private var startupHardTimeoutMs = 120_000L
    private var lastStartupProgressAtMs = 0L
    private var lastBufferedPositionMs = -1L
    private var readyWithoutFrameAtMs = 0L
    private val seekRunnable = Runnable {
        val target = pendingSeekPositionMs
        pendingSeekPositionMs = null
        if (target != null && !completed) player?.seekTo(target)
    }
    private val startupHardTimeout = Runnable {
        if (!renderedFirstFrame && !completed) {
            failureKind = "startup_timeout"
            val seconds = startupHardTimeoutMs / 1_000L
            diagnostics.add("Player: startup reached the $seconds-second safety limit")
            finishWithResult("STARTUP_TIMEOUT: no video frame within $seconds seconds")
        }
    }
    private val timelineHandler = Handler(Looper.getMainLooper())
    private var requestHeaders: Map<String, String> = emptyMap()
    private var timelineUrl = ""
    private var sessionId = ""
    private var ratingKey = ""
    private var mediaDurationMs = 0L
    private var playbackHttpClient: OkHttpClient? = null
    private var lastTimelineReportAt = 0L
    private val timelineRunnable = object : Runnable {
        override fun run() {
            val exo = player ?: return
            val now = SystemClock.elapsedRealtime()
            if (exo.isPlaying && now - lastTimelineReportAt >= 10_000L) {
                lastTimelineReportAt = now
                reportTimeline(exo.currentPosition, "playing")
            }
            checkStartupProgress(exo, now)
            if (completed) return
            updateSkipButton(exo.currentPosition)
            timelineHandler.postDelayed(this, 500L)
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
        sessionId = intent.getStringExtra(EXTRA_SESSION_ID) ?: ""
        ratingKey = intent.getStringExtra(EXTRA_RATING_KEY) ?: ""
        mediaDurationMs = intent.getLongExtra(EXTRA_DURATION_MS, 0L)
        seekBackMs = intent.getLongExtra(EXTRA_SEEK_BACK_MS, 10_000L)
        seekForwardMs = intent.getLongExtra(EXTRA_SEEK_FORWARD_MS, 30_000L)
        skipMode = intent.getStringExtra(EXTRA_SKIP_MODE) ?: "button"
        startupHardTimeoutMs = intent.getLongExtra(EXTRA_STARTUP_HARD_TIMEOUT_MS, 120_000L)
        val markerTypes = intent.getStringArrayListExtra(EXTRA_MARKER_TYPES) ?: arrayListOf()
        val markerStarts = intent.getLongArrayExtra(EXTRA_MARKER_STARTS) ?: longArrayOf()
        val markerEnds = intent.getLongArrayExtra(EXTRA_MARKER_ENDS) ?: longArrayOf()
        markers = (0 until minOf(markerTypes.size, markerStarts.size, markerEnds.size)).map {
            Marker(markerTypes[it], markerStarts[it], markerEnds[it])
        }

        try {
            initializePlayer(url, headers)
        } catch (error: Exception) {
            failureKind = "initialization"
            finishWithResult("PLAYER_INITIALIZATION: ${PlaybackDiagnostics.describe(error)}")
        } catch (error: LinkageError) {
            failureKind = "initialization"
            finishWithResult("PLAYER_LINKAGE: ${PlaybackDiagnostics.describe(error)}")
        }
    }

    private fun initializePlayer(url: String, headers: Map<String, String>) {
        require(Uri.parse(url).scheme == "https") { "Playback requires HTTPS" }
        diagnostics.add("Player: native HTTPS, TLS 1.2, Plex Generation-Y trust")
        val okHttpClient = LegacyTls.createClient(this, diagnostics)
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
        val trackSelector = DefaultTrackSelector(this)
        val trackParameters = trackSelector.buildUponParameters()
        val audioLanguage = intent.getStringExtra(EXTRA_AUDIO_LANGUAGE).orEmpty()
        val subtitleLanguage = intent.getStringExtra(EXTRA_SUBTITLE_LANGUAGE).orEmpty()
        if (audioLanguage.isNotBlank()) trackParameters.setPreferredAudioLanguage(audioLanguage)
        if (subtitleLanguage == "off") {
            trackParameters.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
        } else if (subtitleLanguage.isNotBlank()) {
            trackParameters.setPreferredTextLanguage(subtitleLanguage)
        }
        val audioTrackId = intent.getStringExtra(EXTRA_AUDIO_TRACK_ID).orEmpty()
        val subtitleTrackId = intent.getStringExtra(EXTRA_SUBTITLE_TRACK_ID).orEmpty()
        if (audioTrackId.isNotBlank()) diagnostics.add("Audio selection: Plex track $audioTrackId")
        if (subtitleTrackId.isNotBlank()) diagnostics.add("Subtitle selection: Plex track $subtitleTrackId")
        trackSelector.parameters = trackParameters.build()
        val exo = ExoPlayer.Builder(this)
            .setMediaSourceFactory(DefaultMediaSourceFactory(httpFactory))
            .setLoadControl(loadControl)
            .setTrackSelector(trackSelector)
            .setSeekBackIncrementMs(seekBackMs)
            .setSeekForwardIncrementMs(seekForwardMs)
            .setAudioAttributes(audioAttributes, true)
            .setHandleAudioBecomingNoisy(true)
            .build()
        player = exo

        val view = StyledPlayerView(this).apply {
            useController = true
            setShowSubtitleButton(true)
            setShowBuffering(StyledPlayerView.SHOW_BUFFERING_ALWAYS)
            controllerShowTimeoutMs = 4_000
            controllerAutoShow = true
            keepScreenOn = true
            player = exo
            contentDescription = intent.getStringExtra(EXTRA_TITLE) ?: "Plezy player"
        }
        playerView = view
        val root = FrameLayout(this)
        root.addView(view, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
        ))
        val skip = Button(this).apply {
            visibility = View.GONE
            textSize = 17f
            minHeight = 56
            minWidth = 150
            setOnClickListener {
                val active = activeMarker(player?.currentPosition ?: -1L)
                if (active != null) player?.seekTo(active.endMs)
            }
        }
        skipButton = skip
        root.addView(skip, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.END or Gravity.CENTER_VERTICAL,
        ).apply { marginEnd = 28 })
        setContentView(root)

        exo.addAnalyticsListener(object : AnalyticsListener {
            override fun onVideoDecoderInitialized(
                eventTime: AnalyticsListener.EventTime,
                decoderNameValue: String,
                initializedTimestampMs: Long,
                initializationDurationMs: Long,
            ) {
                decoderName = decoderNameValue
                diagnostics.add("Decoder: $decoderNameValue")
            }
        })

        exo.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                if (!renderedFirstFrame) {
                    lastStartupProgressAtMs = SystemClock.elapsedRealtime()
                    if (state != Player.STATE_READY) readyWithoutFrameAtMs = 0L
                }
                diagnostics.add("Player state: " + when (state) {
                    Player.STATE_IDLE -> "idle"
                    Player.STATE_BUFFERING -> "buffering"
                    Player.STATE_READY -> "ready"
                    Player.STATE_ENDED -> "ended"
                    else -> "unknown"
                })
                if (state == Player.STATE_ENDED) {
                    ended = true
                    window.decorView.postDelayed({ finishWithResult(null) }, 350L)
                }
            }

            override fun onRenderedFirstFrame() {
                renderedFirstFrame = true
                firstFrameMs = SystemClock.elapsedRealtime() - playerStartedAtMs
                timelineHandler.removeCallbacks(startupHardTimeout)
                videoFormat = describeVideoFormat(exo.videoFormat)
                diagnostics.add("Player: first video frame in ${firstFrameMs}ms")
                if (videoFormat != null) diagnostics.add("Video format: $videoFormat")
            }

            override fun onPlayerError(error: com.google.android.exoplayer2.PlaybackException) {
                val http = PlaybackDiagnostics.causes(error)
                    .filterIsInstance<HttpDataSource.InvalidResponseCodeException>().firstOrNull()
                failureKind = when {
                    PlaybackDiagnostics.isConnectionFailure(error) || error.errorCode == 2001 -> "network"
                    http != null -> "http"
                    error.errorCode in 4000..4999 -> "decoder"
                    else -> "source"
                }
                playbackError = "${error.errorCodeName}: ${PlaybackDiagnostics.describe(error)}" +
                    (http?.let { "; HTTP ${it.responseCode}" } ?: "")
                diagnostics.add("Player failed: $playbackError")
                if (failureKind == "network" && automaticRetries < 2 && !completed) {
                    automaticRetries += 1
                    diagnostics.add("Player: reconnect retry $automaticRetries of 2")
                    window.decorView.postDelayed({
                        if (!completed) {
                            playbackError = null
                            lastStartupProgressAtMs = SystemClock.elapsedRealtime()
                            lastBufferedPositionMs = exo.bufferedPosition
                            readyWithoutFrameAtMs = 0L
                            exo.prepare()
                            exo.playWhenReady = true
                        }
                    }, 1_500L * automaticRetries)
                    return
                }
                window.decorView.post { finishWithResult(playbackError) }
            }
        })
        exo.setMediaItem(MediaItem.fromUri(Uri.parse(url)))
        val startMs = intent.getLongExtra(EXTRA_START_MS, 0L)
        if (startMs > 0L) exo.seekTo(startMs)
        playerStartedAtMs = SystemClock.elapsedRealtime()
        lastStartupProgressAtMs = playerStartedAtMs
        lastBufferedPositionMs = exo.bufferedPosition
        diagnostics.add("Startup watchdog: 30s without buffer progress / ${startupHardTimeoutMs / 1_000L}s maximum")
        exo.prepare()
        exo.playWhenReady = true
        timelineHandler.post(timelineRunnable)
        timelineHandler.postDelayed(startupHardTimeout, startupHardTimeoutMs)
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

    override fun onPause() {
        val exo = player
        activityPaused = true
        timelineHandler.removeCallbacks(startupHardTimeout)
        wasPlayingBeforePause = exo?.isPlaying == true
        if (!completed && wasPlayingBeforePause) exo?.pause()
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        activityPaused = false
        if (!completed && !renderedFirstFrame) {
            lastStartupProgressAtMs = SystemClock.elapsedRealtime()
            readyWithoutFrameAtMs = 0L
            timelineHandler.removeCallbacks(startupHardTimeout)
            timelineHandler.postDelayed(startupHardTimeout, startupHardTimeoutMs)
        }
        if (!completed && wasPlayingBeforePause) player?.play()
        wasPlayingBeforePause = false
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        val exo = player
        when (keyCode) {
            KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_MEDIA_REWIND -> {
                queueSeek(-seekBackMs)
                return true
            }
            KeyEvent.KEYCODE_DPAD_RIGHT,
            KeyEvent.KEYCODE_MEDIA_FAST_FORWARD -> {
                queueSeek(seekForwardMs)
                return true
            }
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                if (exo?.isPlaying == true) exo.pause() else exo?.play()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun activeMarker(positionMs: Long): Marker? = markers.firstOrNull {
        positionMs >= it.startMs && positionMs < it.endMs
    }

    private fun queueSeek(deltaMs: Long) {
        val exo = player ?: return
        val base = pendingSeekPositionMs ?: exo.currentPosition
        val maximum = exo.duration.takeIf { it > 0L } ?: Long.MAX_VALUE
        pendingSeekPositionMs = (base + deltaMs).coerceIn(0L, maximum)
        timelineHandler.removeCallbacks(seekRunnable)
        timelineHandler.postDelayed(seekRunnable, 120L)
    }

    private fun checkStartupProgress(exo: ExoPlayer, now: Long) {
        if (renderedFirstFrame || completed || activityPaused) return

        val buffered = exo.bufferedPosition.coerceAtLeast(0L)
        if (buffered >= lastBufferedPositionMs + 250L) {
            lastBufferedPositionMs = buffered
            lastStartupProgressAtMs = now
        }

        if (exo.playbackState == Player.STATE_READY) {
            if (readyWithoutFrameAtMs == 0L) readyWithoutFrameAtMs = now
            if (now - readyWithoutFrameAtMs >= READY_WITHOUT_FRAME_TIMEOUT_MS) {
                failureKind = "startup_timeout"
                diagnostics.add("Player: ready for 10 seconds but rendered no video frame")
                finishWithResult("RENDER_TIMEOUT: player ready but no video frame within 10 seconds")
            }
            return
        }

        readyWithoutFrameAtMs = 0L
        if (now - lastStartupProgressAtMs >= STARTUP_STALL_TIMEOUT_MS) {
            failureKind = "startup_timeout"
            diagnostics.add("Player: no buffer progress for 30 seconds")
            finishWithResult("STARTUP_STALLED: no loading progress for 30 seconds")
        }
    }

    private fun updateSkipButton(positionMs: Long) {
        val markerIndex = markers.indexOfFirst {
            positionMs >= it.startMs && positionMs < it.endMs
        }
        val marker = markers.getOrNull(markerIndex)
        if (skipMode == "automatic" && marker != null && skippedMarkerIndexes.add(markerIndex)) {
            diagnostics.add("Player: automatically skipped ${marker.type}")
            player?.seekTo(marker.endMs)
        }
        skipButton?.apply {
            text = when (marker?.type?.lowercase()) {
                "intro" -> "Skip intro"
                "credits" -> "Skip credits"
                else -> "Skip"
            }
            visibility = if (skipMode == "button" && marker != null) View.VISIBLE else View.GONE
        }
    }

    private fun describeVideoFormat(format: Format?): String? {
        if (format == null) return null
        val size = if (format.width > 0 && format.height > 0) "${format.width}x${format.height}" else "unknown size"
        val codec = format.codecs ?: format.sampleMimeType ?: "unknown codec"
        return "$size / $codec"
    }

    private fun finishWithResult(error: String?) {
        if (completed) return
        completed = true
        val exo = player
        val position = exo?.currentPosition ?: intent.getLongExtra(EXTRA_START_MS, 0L)
        val duration = exo?.duration?.takeIf { it > 0L } ?: 0L
        timelineHandler.removeCallbacks(timelineRunnable)
        timelineHandler.removeCallbacks(startupHardTimeout)
        timelineHandler.removeCallbacks(seekRunnable)
        if (renderedFirstFrame) reportTimeline(position, if (ended) "stopped" else "paused")
        playerView?.player = null
        player?.release()
        player = null
        releaseHttpClient()
        setResult(Activity.RESULT_OK, Intent().apply {
            putExtra(RESULT_POSITION_MS, position)
            putExtra(RESULT_DURATION_MS, duration)
            putExtra(RESULT_ENDED, ended)
            putExtra(RESULT_ERROR, error)
            putExtra(RESULT_FAILURE_KIND, failureKind)
            putExtra(RESULT_RENDERED_FRAME, renderedFirstFrame)
            putExtra(RESULT_FIRST_FRAME_MS, firstFrameMs)
            putExtra(RESULT_DECODER, decoderName)
            putExtra(RESULT_VIDEO_FORMAT, videoFormat)
            putStringArrayListExtra(RESULT_DIAGNOSTICS, diagnostics.snapshot())
        })
        finish()
    }

    override fun onDestroy() {
        timelineHandler.removeCallbacks(timelineRunnable)
        timelineHandler.removeCallbacks(startupHardTimeout)
        timelineHandler.removeCallbacks(seekRunnable)
        playerView?.player = null
        player?.release()
        player = null
        releaseHttpClient()
        super.onDestroy()
    }

    private fun releaseHttpClient() {
        val client = playbackHttpClient ?: return
        playbackHttpClient = null
        client.dispatcher().cancelAll()
        client.connectionPool().evictAll()
        client.dispatcher().executorService().shutdown()
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
                if (sessionId.isNotBlank()) builder.header("X-Plex-Session-Identifier", sessionId)
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
        const val EXTRA_SESSION_ID = "sessionId"
        const val EXTRA_AUDIO_LANGUAGE = "audioLanguage"
        const val EXTRA_SUBTITLE_LANGUAGE = "subtitleLanguage"
        const val EXTRA_AUDIO_TRACK_ID = "audioTrackId"
        const val EXTRA_SUBTITLE_TRACK_ID = "subtitleTrackId"
        const val EXTRA_SKIP_MODE = "skipMode"
        const val EXTRA_STARTUP_HARD_TIMEOUT_MS = "startupHardTimeoutMs"
        const val EXTRA_SEEK_BACK_MS = "seekBackMs"
        const val EXTRA_SEEK_FORWARD_MS = "seekForwardMs"
        const val EXTRA_MARKER_TYPES = "markerTypes"
        const val EXTRA_MARKER_STARTS = "markerStarts"
        const val EXTRA_MARKER_ENDS = "markerEnds"
        const val RESULT_POSITION_MS = "positionMs"
        const val RESULT_DURATION_MS = "durationMs"
        const val RESULT_ENDED = "ended"
        const val RESULT_ERROR = "error"
        const val RESULT_FAILURE_KIND = "failureKind"
        const val RESULT_RENDERED_FRAME = "renderedFrame"
        const val RESULT_FIRST_FRAME_MS = "firstFrameMs"
        const val RESULT_DECODER = "decoder"
        const val RESULT_VIDEO_FORMAT = "videoFormat"
        const val RESULT_DIAGNOSTICS = "diagnostics"
        private const val STARTUP_STALL_TIMEOUT_MS = 30_000L
        private const val READY_WITHOUT_FRAME_TIMEOUT_MS = 10_000L
    }
}
