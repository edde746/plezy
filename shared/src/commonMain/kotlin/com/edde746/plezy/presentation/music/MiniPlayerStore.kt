package com.edde746.plezy.presentation.music

import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.music.MusicPlaybackStatus
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.RoutePresentation
import com.edde746.plezy.servers.childScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlin.time.Duration

/**
 * The docked mini-player and, on TV, the rail's Now Playing item.
 *
 * @param track the session's track; null when nothing plays.
 * @param visible the bar shows: a track, not a TV, not dismissed, and neither Now Playing nor the player on top nor a
 *   sheet open.
 * @param railItem the TV rail shows Now Playing (a TV, online, a track).
 * @param canGoPrevious Previous is enabled: the queue has an entry before the current one ([MusicState.canGoPrevious]).
 * @param canGoNext Next is enabled: the queue has an entry after the current one ([MusicState.canGoNext]).
 */
data class MiniPlayerUiState(
    val track: MusicTrackUi? = null,
    val isPlaying: Boolean = false,
    val visible: Boolean = false,
    val railItem: Boolean = false,
    val canGoPrevious: Boolean = false,
    val canGoNext: Boolean = false,
)

/**
 * Hides the mini-player for [backStack]'s top: a sheet open, or Now Playing or the player as the top screen.
 * Returns (hidden by a sheet, hidden by the screen).
 */
internal fun miniPlayerSuppression(backStack: List<Route>): Pair<Boolean, Boolean> {
    val top = backStack.lastOrNull() ?: return false to false
    val sheet = backStack.size > 1 && top.presentation == RoutePresentation.SHEET
    val screen = if (sheet) backStack[backStack.size - 2] else top
    return sheet to (screen == Route.NowPlaying || screen == Route.Player)
}

/**
 * The mini-player's store, one for the app: over every screen while the session has a track ([MiniPlayerUiState]).
 * A swipe away ([dismiss]) stops the session. [close] when the app goes.
 */
class MiniPlayerStore internal constructor(private val screens: MusicScreens, parentScope: CoroutineScope) {
    private val playback = screens.playback
    private val scope = parentScope.childScope()
    private val mutableState = MutableStateFlow(MiniPlayerUiState())
    private val mutableProgress = MutableStateFlow(0f)
    private val dismissedKey = MutableStateFlow<String?>(null)

    val state: StateFlow<MiniPlayerUiState> = mutableState.asStateFlow()

    /** The played fraction of the track, 0–1: the card's fill. Back to 0 as soon as the track changes. */
    val progress: StateFlow<Float> = mutableProgress.asStateFlow()

    private var track: MediaItem? = null

    /** The session's track: a long press opens its item menu. */
    val item: MediaItem? get() = track

    init {
        scope.launch {
            combine(playback.state, screens.backStack, screens.offline, dismissedKey) { music, backStack, offline, dismissedKey ->
                val current = music.currentTrack
                if (current?.globalKey != track?.globalKey) mutableProgress.value = 0f
                track = current
                // A dismissed card stays away for its track; the next session's track brings it back.
                if (current == null && dismissedKey != null) this@MiniPlayerStore.dismissedKey.value = null
                val (sheet, screen) = miniPlayerSuppression(backStack)
                val session = current != null && !screens.tv && !screen && current.globalKey != dismissedKey
                MiniPlayerUiState(
                    track = current?.toTrackUi(screens.backend(current.serverId)),
                    isPlaying = music.status == MusicPlaybackStatus.PLAYING,
                    visible = session && !sheet,
                    railItem = screens.tv && !offline && current != null,
                    canGoPrevious = music.canGoPrevious,
                    canGoNext = music.canGoNext,
                )
            }.collect { mutableState.value = it }
        }
        scope.launch {
            playback.position.collect { position ->
                val duration = playback.state.value.duration ?: Duration.ZERO
                if (track != null) mutableProgress.value = if (duration <= Duration.ZERO) 0f else (position / duration).toFloat().coerceIn(0f, 1f)
            }
        }
    }

    /** The card tapped: Now Playing opens. */
    fun open() = screens.openNowPlaying()

    fun togglePlayPause() {
        scope.launch { playback.togglePlayPause() }
    }

    fun next() {
        scope.launch { playback.next() }
    }

    fun previous() {
        scope.launch { playback.previous() }
    }

    /** Swiped away or closed: the card goes at once and the session stops. */
    fun dismiss() {
        dismissedKey.value = track?.globalKey ?: return
        scope.launch { playback.stop() }
    }

    fun close() = scope.cancel()
}
