package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaFileInfo
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackFailure
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngine
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.SubtitleStyle
import com.edde746.plezy.playback.withoutSecrets
import com.edde746.plezy.servers.childScope
import io.ktor.http.URLDecodeException
import io.ktor.http.decodeURLPart
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

/**
 * Plays one URL with no server behind it: the app's `--url` launch, which the harness's device runs use. The title is
 * the URL's file name; it plays from its start with this device's decoding and cache options ([playbackOptions], read
 * as the file loads) and subtitle style; nothing is reported or remembered. An engine error is the failure, and
 * [retry] loads the URL again at the last position. Starts playing as it is made, unless [playbackAllowed] says video
 * may not play now (a car's driving restrictions): then it opens paused.
 */
class UrlPlaybackSession(
    private val engine: PlayerEngine,
    private val url: String,
    private val playbackOptions: suspend () -> PlaybackOptions,
    subtitleStyle: Flow<SubtitleStyle>,
    parentScope: CoroutineScope,
    private val playbackAllowed: () -> Boolean = { true },
) : PlayerSession {
    private val scope = parentScope.childScope()
    private val mutableEngineState = MutableStateFlow(EngineState())
    override val engineState: StateFlow<EngineState> = mutableEngineState.asStateFlow()
    private val mutableInfo = MutableStateFlow(SessionInfo(title = fileName(url)))
    override val info: StateFlow<SessionInfo> = mutableInfo.asStateFlow()
    private val states = Channel<EngineState>(Channel.UNLIMITED)

    /** The load whose reports count; 0 before the first. */
    private var loadId = 0L
    private var position = 0.0
    private var closed = false

    init {
        engine.setListener(object : PlayerEngineListener {
            override fun onState(state: EngineState) {
                states.trySend(state)
            }
        })
        scope.launch {
            for (state in states) {
                mutableEngineState.value = state
                follow(state)
            }
        }
        scope.launch { subtitleStyle.distinctUntilChanged().collect(engine::setSubtitleStyle) }
        load(0.0)
    }

    private fun load(startAt: Double) {
        scope.launch {
            val options = playbackOptions()
            if (closed) return@launch
            mutableInfo.value = mutableInfo.value.copy(failure = null)
            loadId = engine.load(LoadRequest(url = url, options = options, title = mutableInfo.value.title, startSeconds = startAt))
            engine.setPaused(!playbackAllowed())
        }
    }

    private fun follow(state: EngineState) {
        if (state.loadId != loadId || closed) return
        val error = state.error
        if (error != null) {
            if (mutableInfo.value.failure == null) {
                val shown = error.withoutSecrets()
                Log.w(TAG) { "engine error (${shown.kind}, HTTP ${shown.httpStatus}): ${shown.message}" }
                mutableInfo.value = mutableInfo.value.copy(failure = PlaybackFailure.Engine(shown))
            }
            return
        }
        if (state.loaded && state.positionSeconds.isFinite()) position = state.positionSeconds
    }

    override fun retry() {
        if (closed || mutableInfo.value.failure == null) return
        load(position)
    }

    override fun close() {
        if (closed) return
        closed = true
        engine.setListener(null)
        states.close()
        scope.cancel()
        engine.release()
    }

    /** Nothing comes before a URL's video: previous restarts it. */
    override fun playPreviousEpisode() = engine.seek(0.0, exact = false)

    override fun simulateHttpError(status: Int) {
        if (closed || mutableInfo.value.failure != null) return
        mutableInfo.value = mutableInfo.value.copy(failure = PlaybackFailure.Engine(SimulatedHttpError.of(status)))
    }

    override suspend fun searchSubtitles(language: String, title: String?): List<SubtitleSearchHit> =
        error("a URL has no server to search subtitles on")

    override suspend fun downloadSubtitle(key: String): SubtitleDownloadOutcome = error("a URL has no server to download subtitles from")

    override suspend fun loadFileInfo(): MediaFileInfo? = null

    internal companion object {
        private const val TAG = "url-session"

        /** The URL's last path segment, percent-decoded (as it is when malformed); the whole URL when it has none. */
        fun fileName(url: String): String {
            val name = url.substringBefore('#').substringBefore('?').trimEnd('/').substringAfterLast('/')
            val decoded = try {
                name.decodeURLPart()
            } catch (e: URLDecodeException) {
                Log.d(TAG) { "the file name isn't percent-encoded right (${e.message}); shown as it is" }
                name
            }
            return decoded.ifBlank { url }
        }
    }
}
