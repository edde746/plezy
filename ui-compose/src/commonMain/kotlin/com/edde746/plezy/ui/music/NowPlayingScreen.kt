package com.edde746.plezy.ui.music

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.EaseOutCubic
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animate
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.focusable
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.gestures.animateScrollBy
import androidx.compose.foundation.gestures.detectVerticalDragGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsDraggedAsState
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.music.MusicRepeatMode
import com.edde746.plezy.presentation.browse.MediaMenu
import com.edde746.plezy.presentation.browse.MenuExtra
import com.edde746.plezy.presentation.browse.MenuIcon
import com.edde746.plezy.presentation.music.LyricsUi
import com.edde746.plezy.presentation.music.NowPlayingLayout
import com.edde746.plezy.presentation.music.NowPlayingStore
import com.edde746.plezy.presentation.music.NowPlayingUiState
import com.edde746.plezy.presentation.music.QueueUi
import com.edde746.plezy.presentation.music.SleepTimerChoice
import com.edde746.plezy.presentation.music.SleepTimerOptionUi
import com.edde746.plezy.presentation.music.TrackRowUi
import com.edde746.plezy.presentation.music.VolumeLevel
import com.edde746.plezy.presentation.music.nowPlayingArtworkSide
import com.edde746.plezy.presentation.music.nowPlayingLayout
import com.edde746.plezy.presentation.music.volumeLevel
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import com.edde746.plezy.ui.cast.CastingFromLine
import com.edde746.plezy.ui.cast.LocalCastSender
import com.edde746.plezy.ui.cast.castIcon
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupGap
import com.edde746.plezy.ui.components.IconButtonStyle
import com.edde746.plezy.ui.components.OrderedRow
import com.edde746.plezy.ui.components.OrderedRowActions
import com.edde746.plezy.ui.components.PlezyIconButton
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.SwipeToRemove
import com.edde746.plezy.ui.components.groupShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.CompositionLocalProvider
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.largeFontScale
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.ItemMenuSection
import com.edde746.plezy.ui.components.SectionedItemMenu
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.overlayOpener
import com.edde746.plezy.ui.components.scaleDownToFit
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.focus.sliderKeys
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.image.reducedEffects
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.settings.DragHandleIcon
import com.edde746.plezy.ui.components.rememberReorderState
import com.edde746.plezy.ui.components.reorderHandle
import com.edde746.plezy.ui.components.reorderItem
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.launch
import kotlin.math.roundToInt
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource
import kotlinx.coroutines.Job

/**
 * Now Playing: the blurred artwork behind the TV layout, the wide two-pane one (from 800 across in landscape, with the
 * queue inline) or the portrait one. Space toggles play on the desktop; on a touch screen, swiping down past a quarter
 * of the height (or flung down) closes it, a shorter swipe settles back. Its ⋮ opens the track's item [menu]; the cast
 * button beside it opens the device picker as the player's does. While a cast plays here, [castingFrom] ("Casting from
 * <device>") shows under "Playing from".
 */
@Composable
fun NowPlayingScreen(store: NowPlayingStore, menu: MediaMenu, onClose: () -> Unit, modifier: Modifier = Modifier, castingFrom: String? = null) {
    val state by store.state.collectAsState()
    val formFactor = LocalWindowLayout.current.formFactor
    val tv = formFactor == FormFactor.TV
    val desktop = formFactor == FormFactor.DESKTOP
    var queueOpen by remember { mutableStateOf(false) }
    var drag by remember { mutableFloatStateOf(0f) }
    val scope = rememberCoroutineScope()
    var settle by remember { mutableStateOf<Job?>(null) }
    val playFocus = remember { FocusRequester() }
    val screenFocus = remember { FocusRequester() }
    val lyricsFocus = remember { LyricsFocus() }
    val track = state.track
    // On TV the queue card stands in the screen's middle: the screen behind it fades away meanwhile, so the card's edges
    // cut through none of its lines, however many rows it holds.
    val behind by animateFloatAsState(if (tv && queueOpen) 0f else 1f, tween(200), label = "behindQueue")
    Box(
        modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .layoutProbe("music.nowPlaying", reportsFocus = false)
            .onPreviewKeyEvent {
                if (desktop && it.type == KeyEventType.KeyDown && it.key == Key.Spacebar) {
                    store.togglePlayPause()
                    true
                } else {
                    false
                }
            }
            // The desktop's Space reaches the screen even where no control has the focus (it opened from a click).
            .focusRequester(screenFocus)
            .focusable(enabled = desktop),
    ) {
        if (track == null) return@Box
        // The blurred artwork, faint (fainter on TV); the plain background on the reduced effects tier.
        if (!reducedEffects) RemoteImage(track.artwork, null, Modifier.fillMaxSize().graphicsLayer { alpha = if (tv) 0.22f else 0.3f }, blurred = true)
        BoxWithConstraints(Modifier.fillMaxSize().offset { IntOffset(0, drag.roundToInt()) }) {
            val layout = nowPlayingLayout(tv, maxWidth.value.toDouble(), maxHeight.value.toDouble())
            val height = constraints.maxHeight.toFloat()
            val dismiss = if (layout == NowPlayingLayout.PORTRAIT && formFactor == FormFactor.HANDHELD) {
                Modifier.pointerInput(height) {
                    val velocity = VelocityTracker()
                    detectVerticalDragGestures(
                        onDragStart = {
                            settle?.cancel()
                            velocity.resetTracking()
                        },
                        onDragEnd = {
                            if (drag > height * 0.25f || velocity.calculateVelocity().y > 500f) {
                                onClose()
                            } else {
                                settle = scope.launch { animate(drag, 0f, animationSpec = tween(200, easing = EaseOutCubic)) { value, _ -> drag = value } }
                            }
                        },
                        onDragCancel = { drag = 0f },
                    ) { change, dy ->
                        drag = (drag + dy).coerceAtLeast(0f)
                        // The content moves with the drag, so the drag's own sum is the finger's track.
                        velocity.addPosition(change.uptimeMillis, Offset(0f, drag))
                    }
                }
            } else {
                Modifier
            }
            val pieces = Pieces(store, menu, state, onClose, playFocus, lyricsFocus, onQueue = { queueOpen = true }, tv = tv, desktop = desktop, castingFrom = castingFrom)
            when (layout) {
                NowPlayingLayout.TV -> TvLayout(pieces, Modifier.graphicsLayer { alpha = behind })
                NowPlayingLayout.WIDE -> WideLayout(pieces)
                NowPlayingLayout.PORTRAIT -> PortraitLayout(pieces, dismiss)
            }
        }
        LaunchedEffect(tv) { if (tv) runCatching { playFocus.requestFocus() } else if (desktop) runCatching { screenFocus.requestFocus() } }
    }
    if (queueOpen) {
        val current = remember { FocusRequester() }
        PlezySheet(
            onDismiss = { queueOpen = false },
            label = T.music.queue,
            probe = "music.queueSheet",
            bottom = true,
            initialFocus = current,
            header = { QueueHeader(state.queue, store) },
            dockInLandscape = true,
        ) {
            QueueList(state, store, Modifier.weight(1f, fill = false), current)
        }
    }
}

/** What every layout draws, bound to the store. */
private class Pieces(
    val store: NowPlayingStore,
    val menu: MediaMenu,
    val state: NowPlayingUiState,
    val onClose: () -> Unit,
    val playFocus: FocusRequester,
    val lyricsFocus: LyricsFocus,
    val onQueue: () -> Unit,
    val tv: Boolean,
    val desktop: Boolean,
    val castingFrom: String?,
)

@Composable
private fun PortraitLayout(p: Pieces, dismiss: Modifier) {
    Column(Modifier.fillMaxSize()) {
        Column(Modifier.weight(1f).then(dismiss)) {
            TopBar(p)
            Box(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp)) { ArtworkOrLyrics(p, NowPlayingLayout.PORTRAIT) }
            TrackInfo(p, centered = true, Modifier.padding(start = 32.dp, end = 32.dp, top = 8.dp))
        }
        SeekBar(p, Modifier.padding(start = 16.dp, end = 16.dp, top = 8.dp))
        Transport(p)
        UtilityRow(p, queue = true)
        Spacer(Modifier.height(8.dp))
    }
}

@Composable
private fun WideLayout(p: Pieces) {
    Column(Modifier.fillMaxSize()) {
        TopBar(p)
        Row(Modifier.weight(1f).padding(start = 24.dp, end = 24.dp, bottom = 20.dp)) {
            Box(Modifier.weight(9f).fillMaxHeight()) { ArtworkOrLyrics(p, NowPlayingLayout.WIDE) }
            Spacer(Modifier.width(32.dp))
            Column(Modifier.weight(11f).fillMaxHeight()) {
                TrackInfo(p, centered = false)
                Spacer(Modifier.height(8.dp))
                SeekBar(p)
                // The transport, Lyrics and the volume as one cluster at the end.
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Spacer(Modifier.weight(1f))
                    Transport(p, Modifier)
                    Spacer(Modifier.width(16.dp))
                    LyricsToggle(p)
                    if (p.desktop) VolumeCluster(p.store)
                }
                Spacer(Modifier.height(12.dp))
                Box(
                    Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .clip(MaterialTheme.shapes.large)
                        .background(PlezyColors.Surface)
                        .layoutProbe("music.np.queue", reportsFocus = false),
                ) { QueueList(p.state, p.store) }
            }
        }
    }
}

@Composable
private fun TvLayout(p: Pieces, modifier: Modifier) {
    Row(modifier.fillMaxSize().padding(horizontal = 56.dp, vertical = 40.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.weight(4f).fillMaxHeight()) { ArtworkOrLyrics(p, NowPlayingLayout.TV) }
        Spacer(Modifier.width(48.dp))
        Column(Modifier.weight(5f), verticalArrangement = Arrangement.Center) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(p.state.playingFrom.orEmpty(), Modifier.weight(1f), fontSize = 14.sp, color = secondaryText(), maxLines = 1, overflow = TextOverflow.Ellipsis)
                CastIcon()
                Overflow(p)
            }
            p.castingFrom?.let { CastingFromLine(it, "music.np.castingFrom", color = secondaryText()) }
            Spacer(Modifier.height(8.dp))
            Text(p.state.track?.title.orEmpty(), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.SemiBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
            p.state.track?.artist?.let {
                Spacer(Modifier.height(4.dp))
                Text(it, style = MaterialTheme.typography.bodyLarge, color = secondaryText(), maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
            Spacer(Modifier.height(28.dp))
            SeekBar(p)
            Spacer(Modifier.height(8.dp))
            Transport(p)
            UtilityRow(p, queue = true)
        }
    }
}

/** Close (chevron down), "Playing from …" centred (over "Casting from …" while a cast plays here), cast, ⋮. */
@Composable
private fun TopBar(p: Pieces) {
    Row(Modifier.fillMaxWidth().padding(start = 8.dp, end = 8.dp, top = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        TransportIcon(PlezyIcons.KeyboardArrowDown, T.common.close, true, 26, "music.np.close", onClick = p.onClose)
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                p.state.playingFrom.orEmpty(),
                Modifier.fillMaxWidth().layoutProbe("music.np.playingFrom"),
                fontSize = 13.sp,
                color = secondaryText(),
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            p.castingFrom?.let { CastingFromLine(it, "music.np.castingFrom", color = secondaryText()) }
        }
        CastIcon()
        Overflow(p)
    }
}

/**
 * Now Playing's cast button, as the transport's icons: the picker opened as from the player (a choice hands the track
 * over), the connected icon, in the text colour, while casting. Nothing without a [LocalCastSender].
 */
@Composable
private fun CastIcon() {
    val sender = LocalCastSender.current ?: return
    val casting = sender.state.collectAsState().value.casting
    TransportIcon(castIcon(casting), T.cast.title, casting, 24, "music.np.cast") { sender.openPicker(fromPlayer = true) }
}

/**
 * ⋮: the current track's item menu, Sleep timer last, whose choices open in their own menu at ⋮ (a dropdown under it on
 * the desktop, a sheet elsewhere) in the video player's groups, Stop at (Off, End of track) and Timer (the durations),
 * only the active one marked.
 */
@Composable
private fun Overflow(p: Pieces) {
    var sleepOpen by remember { mutableStateOf(false) }
    Box {
        TransportIcon(PlezyIcons.MoreVert, T.common.options, true, 24, "music.np.more") {
            val track = p.store.item ?: return@TransportIcon
            p.menu.open(track, extras = listOf(MenuExtra("music_sleep_timer", T.music.sleepTimer, MenuIcon.TIMER) { sleepOpen = true }))
        }
        val (durations, stopAt) = p.state.sleepTimer.partition { it.choice is SleepTimerChoice.Minutes }
        fun entry(option: SleepTimerOptionUi): ItemMenuEntry {
            val icon = when (option.choice) {
                SleepTimerChoice.Off -> PlezyIcons.TimerOff
                SleepTimerChoice.EndOfTrack -> PlezyIcons.MusicNote
                is SleepTimerChoice.Minutes -> PlezyIcons.Timer
            }
            return ItemMenuEntry(option.label, selected = option.selected, icon = icon) { p.store.setSleepTimer(option.choice) }
        }
        SectionedItemMenu(
            expanded = sleepOpen,
            onDismiss = { sleepOpen = false },
            sections = listOf(
                ItemMenuSection(T.videoControls.sleepTimerStopAtHeader, stopAt.map(::entry)),
                ItemMenuSection(T.videoControls.sleepTimerDurationHeader, durations.map(::entry)),
            ),
            probe = "music.sleepTimer",
            title = T.music.sleepTimer,
        )
    }
}

@Composable
private fun TrackInfo(p: Pieces, centered: Boolean, modifier: Modifier = Modifier) {
    val track = p.state.track ?: return
    Column(modifier.fillMaxWidth(), horizontalAlignment = if (centered) Alignment.CenterHorizontally else Alignment.Start) {
        Text(
            track.title,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            textAlign = if (centered) TextAlign.Center else TextAlign.Start,
            modifier = Modifier.layoutProbe("music.np.title"),
        )
        track.artist?.let {
            Text(
                it,
                style = MaterialTheme.typography.bodyMedium,
                color = secondaryText(),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(top = 2.dp).then(if (track.artistLinked) Modifier.clickable(onClick = p.store::openArtist) else Modifier),
            )
        }
    }
}

/** The artwork (rounder while paused) or, with lyrics on, the lyrics pane in its place. */
@Composable
private fun ArtworkOrLyrics(p: Pieces, layout: NowPlayingLayout) {
    AnimatedContent(p.state.showLyrics, transitionSpec = { fadeIn() togetherWith fadeOut() }, label = "artOrLyrics") { lyrics ->
        if (lyrics) {
            LyricsPane(p.state.lyrics, p.store, p.lyricsFocus, onExit = { runCatching { p.playFocus.requestFocus() } })
        } else {
            BoxWithConstraints(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                val side = nowPlayingArtworkSide(layout, maxWidth.value.toDouble(), maxHeight.value.toDouble()).dp
                val radius by animateDpAsState(if (p.state.isPlaying) 16.dp else 28.dp, label = "artRadius")
                RemoteImage(
                    p.state.track?.artwork,
                    null,
                    Modifier.size(side).clip(RoundedCornerShape(radius)).layoutProbe("music.np.artwork"),
                    blank = PlezyColors.SurfaceHigh,
                    error = { ArtworkPlaceholder(PlaceholderKind.TRACK) },
                )
            }
        }
    }
}

/**
 * The seek bar ([MusicSlider]): the played part and the timestamps; a drag seeks on release. Focused (a remote, the keyboard), Left and
 * Right step 10 s, faster while held, and seek once let go; Up and Down move on.
 */
@Composable
private fun SeekBar(p: Pieces, modifier: Modifier = Modifier) {
    val progress by p.store.progress.collectAsState()
    var dragging by remember { mutableStateOf<Float?>(null) }
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val showFocus = focused && isFocusVisible()
    val fraction = dragging ?: progress.fraction
    var heldKey by remember { mutableStateOf<Key?>(null) }
    Column(
        modifier
            .fillMaxWidth()
            .onFocusChanged { if (!it.isFocused) p.store.endStepSeek() }
            .onPreviewKeyEvent { event ->
                val forward = when (event.key) {
                    Key.DirectionRight -> true
                    Key.DirectionLeft -> false
                    else -> return@onPreviewKeyEvent false
                }
                when (event.type) {
                    KeyEventType.KeyDown -> {
                        // A key held down repeats its press without letting go in between.
                        p.store.stepSeek(forward, repeat = heldKey == event.key)
                        heldKey = event.key
                    }
                    KeyEventType.KeyUp -> {
                        heldKey = null
                        p.store.endStepSeek()
                    }
                }
                true
            }
            .focusable(interactionSource = interactions)
            .padding(vertical = 4.dp)
            .layoutProbe("music.np.seek"),
    ) {
        MusicSlider(
            value = fraction,
            onValueChange = { dragging = it },
            onValueChangeFinished = {
                dragging?.let { p.store.seekToFraction(it) }
                dragging = null
            },
            knob = dragging != null || showFocus,
            enabled = progress.duration.isPositive(),
            modifier = Modifier.fillMaxWidth().focusable(false),
        )
        Row(Modifier.padding(horizontal = 8.dp)) {
            val drag = dragging
            Text(drag?.let { progress.positionAt(it.toDouble()) } ?: progress.positionLabel, fontSize = 12.sp, color = secondaryText())
            Spacer(Modifier.weight(1f))
            Text(drag?.let { progress.remainingAt(it.toDouble()) } ?: progress.remainingLabel, fontSize = 12.sp, color = secondaryText())
        }
    }
}

/** Shuffle, previous, the round play button (a spinner while loading), next, repeat. */
@Composable
private fun Transport(p: Pieces, modifier: Modifier = Modifier.fillMaxWidth()) {
    TransportRow(LocalAppearance.current.automotive, modifier) {
        TransportIcon(PlezyIcons.Shuffle, T.common.shuffle, p.state.shuffled, 22, "music.np.shuffle", toggle = true, onClick = p.store::toggleShuffle)
        TransportIcon(PlezyIcons.SkipPrevious, T.music.previousTrack, true, 32, "music.np.previous", enabled = p.state.canGoPrevious, onClick = p.store::previous)
        PlayPause(p)
        TransportIcon(PlezyIcons.SkipNext, T.music.nextTrack, true, 32, "music.np.next", enabled = p.state.canGoNext, onClick = p.store::next)
        TransportIcon(p.state.repeatMode.icon, p.state.repeatMode.tooltip, p.state.repeatMode != MusicRepeatMode.OFF, 22, "music.np.repeat", toggle = true, onClick = p.store::cycleRepeat)
    }
}

/**
 * The transport's buttons in a centred row. On a car's display ([automotive]) they keep their full size, the enlarged
 * touch targets, however little room there is; elsewhere the row scales down to fit rather than overflowing a narrow
 * layout.
 */
@Composable
internal fun TransportRow(automotive: Boolean, modifier: Modifier, content: @Composable RowScope.() -> Unit) {
    Box(modifier.padding(vertical = 8.dp), contentAlignment = Alignment.Center) {
        Row(
            if (automotive) Modifier.wrapContentWidth(unbounded = true) else Modifier.scaleDownToFit(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
            content = content,
        )
    }
}

/** Play or pause: a 72 dp round button in the primary fill (focus grows it), a spinner while the track loads. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun PlayPause(p: Pieces) {
    PlezySurface(
        onClick = p.store::togglePlayPause,
        modifier = Modifier.size(72.dp).focusRequester(p.playFocus).layoutProbe("music.np.playPause"),
        shape = CircleShape,
        color = MaterialTheme.colorScheme.primary,
        contentColor = PlezyColors.OnPrimary,
        contentAlignment = Alignment.Center,
    ) {
        if (p.state.loading) {
            LoadingIndicator(Modifier.size(26.dp), color = LocalContentColor.current)
        } else {
            Icon(if (p.state.isPlaying) PlezyIcons.Pause else PlezyIcons.PlayArrow, if (p.state.isPlaying) T.common.pause else T.common.play, Modifier.size(36.dp))
        }
    }
}

/** Lyrics on or off; turned on from a remote or keyboard, the lyrics pane takes the focus once it has lines. */
@Composable
private fun LyricsToggle(p: Pieces) {
    val keyboard = isFocusVisible()
    TransportIcon(PlezyIcons.Lyrics, T.music.lyrics, p.state.showLyrics, 22, "music.np.lyrics", toggle = true) {
        p.lyricsFocus.pending = !p.state.showLyrics && keyboard
        p.store.toggleLyrics()
    }
}

/** The lyrics pane's focus: [pending] while a toggle from a remote or keyboard waits for the lines to take it. */
private class LyricsFocus {
    val requester = FocusRequester()
    var pending by mutableStateOf(false)
}

/** Lyrics and, where the queue isn't inline, Queue. */
@Composable
private fun UtilityRow(p: Pieces, queue: Boolean) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterHorizontally)) {
        LyricsToggle(p)
        if (queue) TransportIcon(PlezyIcons.QueueMusic, T.music.queue, false, 22, "music.np.queueButton", onClick = p.onQueue)
    }
}

/**
 * Secondary text over the artwork ("Playing from …", the artist, the times): the text colour at 75 %. The theme's muted
 * grey fell to about 3.5:1 over pastel artwork in the light theme; this reads at 4.5:1 or more over any artwork, light
 * theme or dark.
 */
@Composable
private fun secondaryText(): Color = PlezyColors.Text.copy(alpha = 0.75f)

/**
 * A transport button, a round plain icon button [size] + 24 across: the text colour while [active], muted
 * otherwise; focus the primary fill. A [toggle] (Shuffle, Repeat, Lyrics) that is on ([active]) rests in the accent
 * tint ([IconButtonStyle.SELECTED]), as a selected chip does on TV, and tells screen readers it is on (its selected
 * state). Not [enabled], it is drawn faint and takes no clicks. The queue sheet and the menus it opens give focus back
 * to it.
 */
@Composable
internal fun TransportIcon(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    active: Boolean,
    size: Int,
    probe: String,
    toggle: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    CompositionLocalProvider(LocalContentColor provides if (active) PlezyColors.Text else PlezyColors.TextMuted) {
        PlezyIconButton(
            icon,
            label,
            onClick,
            Modifier.overlayOpener().layoutProbe(probe),
            style = if (toggle && active) IconButtonStyle.SELECTED else IconButtonStyle.PLAIN,
            size = (size + 24).dp,
            selected = if (toggle) active else null,
            enabled = enabled,
        )
    }
}

/** The desktop volume: its icon (muted, low, high) and a slider, heard while dragged and kept on release. */
@Composable
private fun VolumeCluster(store: NowPlayingStore) {
    val volume by store.volume.collectAsState()
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.layoutProbe("music.np.volume")) {
        val icon = when (volumeLevel(volume)) {
            VolumeLevel.OFF -> PlezyIcons.VolumeOff
            VolumeLevel.LOW -> PlezyIcons.VolumeDown
            VolumeLevel.HIGH -> PlezyIcons.VolumeUp
        }
        Icon(icon, null, Modifier.size(20.dp), tint = PlezyColors.TextMuted)
        var dragged by remember { mutableStateOf<Float?>(null) }
        val hover = remember { MutableInteractionSource() }
        val hovered by hover.collectIsHoveredAsState()
        Spacer(Modifier.width(8.dp))
        MusicSlider(
            value = (dragged ?: volume.toFloat()) / 100f,
            onValueChange = {
                dragged = it * 100f
                store.previewVolume(it * 100.0)
            },
            onValueChangeFinished = {
                dragged?.let { store.commitVolume(it.toDouble()) }
                dragged = null
            },
            knob = dragged != null || hovered,
            // The arrow keys move it 5 % a press.
            modifier = Modifier.width(120.dp).hoverable(hover).sliderKeys((dragged ?: volume.toFloat()) / 100f, 0f..1f, onChange = { store.commitVolume(it * 100.0) }),
        )
    }
}

/**
 * Now Playing's slider, the seek bar's and the volume's one look: a 6 dp track, the part up to [value] in the text
 * colour over the text colour at 30 %; the round knob only while [knob] (a drag, the pointer over it, the focus).
 */
@Composable
private fun MusicSlider(
    value: Float,
    onValueChange: (Float) -> Unit,
    onValueChangeFinished: () -> Unit,
    knob: Boolean,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    val interactions = remember { MutableInteractionSource() }
    val colors = SliderDefaults.colors(
        thumbColor = PlezyColors.Text,
        activeTrackColor = PlezyColors.Text,
        inactiveTrackColor = PlezyColors.Text.copy(alpha = 0.3f),
        disabledActiveTrackColor = PlezyColors.Text,
        disabledInactiveTrackColor = PlezyColors.Text.copy(alpha = 0.3f),
    )
    Slider(
        value = value,
        onValueChange = onValueChange,
        onValueChangeFinished = onValueChangeFinished,
        enabled = enabled,
        colors = colors,
        modifier = modifier.height(24.dp),
        interactionSource = interactions,
        thumb = { if (knob) SliderDefaults.Thumb(interactions, colors = colors, thumbSize = DpSize(14.dp, 14.dp)) },
        track = { state -> SliderDefaults.Track(state, Modifier.height(6.dp), colors = colors, drawStopIndicator = null, thumbTrackGapSize = 0.dp) },
    )
}

/**
 * The lyrics: a spinner, "No lyrics available", or the lines (the playing one bold and kept in view; a tap seeks). The
 * pane is one focus stop for a remote or keyboard, kept while the next track's lyrics load: synced, Up and Down move a
 * highlighted line (from the playing one), Select seeks to it and Down past the last leaves; unsynced, Up and Down
 * scroll 64 dp. Back leaves ([onExit]), Left and Right stay.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun LyricsPane(lyrics: LyricsUi, store: NowPlayingStore, focus: LyricsFocus, onExit: () -> Unit) {
    val active by store.activeLyricLine.collectAsState()
    val list = remember(lyrics) { LazyListState() }
    val scope = rememberCoroutineScope()
    val step = with(LocalDensity.current) { 64.dp.toPx() }
    var paneFocused by remember { mutableStateOf(false) }
    var focusedLine by remember { mutableIntStateOf(-1) }
    fun reveal(index: Int) = scope.launch {
        list.animateScrollToItem(index, -(list.layoutInfo.viewportSize.height * 0.4f).roundToInt())
    }
    LaunchedEffect(focus.pending) {
        if (focus.pending) {
            runCatching { focus.requester.requestFocus() }
            focus.pending = false
        }
    }
    // Another track's lines start the highlight over on its playing line.
    LaunchedEffect(lyrics) { focusedLine = active }
    fun move(delta: Int) {
        val lines = lyrics as? LyricsUi.Lines ?: return
        if (!lines.synced) {
            scope.launch { list.animateScrollBy(delta * step, tween(150, easing = FastOutSlowInEasing)) }
            return
        }
        val next = focusedLine + delta
        when {
            next >= lines.lines.size -> onExit()
            next >= 0 -> {
                focusedLine = next
                reveal(next)
            }
        }
    }
    Box(
        Modifier
            .fillMaxSize()
            .focusRequester(focus.requester)
            .onFocusChanged {
                paneFocused = it.isFocused
                if (it.isFocused) focusedLine = active
            }
            .onPreviewKeyEvent { event ->
                val down = event.type == KeyEventType.KeyDown
                when (event.key) {
                    Key.Back, Key.Escape -> {
                        if (event.type == KeyEventType.KeyUp) onExit()
                        true
                    }
                    Key.DirectionUp -> {
                        if (down) move(-1)
                        true
                    }
                    Key.DirectionDown -> {
                        if (down) move(1)
                        true
                    }
                    Key.DirectionCenter, Key.Enter, Key.NumPadEnter -> {
                        val lines = lyrics as? LyricsUi.Lines
                        if (down && lines != null && lines.synced && focusedLine in lines.lines.indices) store.seekToLyric(focusedLine)
                        true
                    }
                    Key.DirectionLeft, Key.DirectionRight -> true
                    else -> false
                }
            }
            .focusable()
            .layoutProbe("music.np.lyricsPane"),
        contentAlignment = Alignment.Center,
    ) {
        when (lyrics) {
            LyricsUi.Loading -> LoadingIndicator(Modifier.size(40.dp), color = PlezyColors.TextMuted)
            LyricsUi.None -> EmptyState(T.music.noLyrics, Modifier.layoutProbe("music.np.noLyrics"), icon = PlezyIcons.Lyrics)
            is LyricsUi.Lines -> {
                val showFocus = paneFocused && isFocusVisible() && lyrics.synced
                // A scroll by hand holds the playing line's reveal off for 3 s.
                var manual by remember { mutableStateOf<TimeMark?>(null) }
                val dragged by list.interactionSource.collectIsDraggedAsState()
                LaunchedEffect(dragged) { if (dragged) manual = TimeSource.Monotonic.markNow() }
                LaunchedEffect(active, list) {
                    if (active >= 0 && manual?.let { it.elapsedNow() < 3.seconds } != true) reveal(active)
                }
                LazyColumn(Modifier.fillMaxSize(), state = list, contentPadding = PaddingValues(horizontal = 16.dp, vertical = 32.dp)) {
                    itemsIndexed(lyrics.lines) { index, line ->
                        val isActive = lyrics.synced && index == active
                        val highlighted = showFocus && index == focusedLine
                        Text(
                            line,
                            Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (highlighted) PlezyColors.Text.copy(alpha = 0.12f) else Color.Transparent)
                                .then(if (lyrics.synced) Modifier.clickable { store.seekToLyric(index) } else Modifier)
                                .padding(horizontal = 12.dp, vertical = 8.dp)
                                .then(if (highlighted) Modifier.layoutProbe("music.np.lyricFocus") else Modifier),
                            fontSize = 18.sp,
                            lineHeight = (18 * 1.4).sp,
                            textAlign = TextAlign.Center,
                            fontWeight = if (isActive) FontWeight.SemiBold else FontWeight.Normal,
                            color = if (isActive || !lyrics.synced) PlezyColors.Text else PlezyColors.TextMuted,
                        )
                    }
                }
            }
        }
    }
}

/**
 * The queue sheet's one header line ([PlezySheet]'s header, under the handle): its title in the sheets' title style,
 * "N tracks" beside it, then shuffle, repeat and clear upcoming. No close button: the handle, a swipe down, the scrim
 * and Back close the sheet. It starts where the rows' content does.
 */
@Composable
internal fun QueueHeader(queue: QueueUi, store: NowPlayingStore) {
    Row(Modifier.fillMaxWidth().padding(start = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(T.music.queue, style = MaterialTheme.typography.titleLarge, color = PlezyColors.Text, maxLines = 1)
        Text(
            queue.count,
            Modifier.weight(1f).padding(start = 12.dp).layoutProbe("music.queue.count"),
            style = MaterialTheme.typography.bodyMedium,
            color = PlezyColors.TextMuted,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        TransportIcon(PlezyIcons.Shuffle, T.common.shuffle, queue.shuffled, 20, "music.queue.shuffle", toggle = true, onClick = store::toggleShuffle)
        TransportIcon(queue.repeatMode.icon, queue.repeatMode.tooltip, queue.repeatMode != MusicRepeatMode.OFF, 20, "music.queue.repeat", toggle = true, onClick = store::cycleRepeat)
        TransportIcon(PlezyIcons.PlaylistRemove, T.music.clearQueue, false, 20, "music.queue.clear", onClick = store::clearUpcoming)
    }
}

/**
 * The whole queue in playback order, opened at the current row ([current] focuses it) and following it while the list
 * hasn't been scrolled away. Each row is an [OrderedRow]: a tap plays it; its menu (⋮, a right click, the Menu
 * key) moves it up or down or removes it. Off TV it starts with a drag handle and a swipe toward the start removes it;
 * on TV round ↑ and ↓ buttons beside the row move it.
 */
@Composable
internal fun QueueList(state: NowPlayingUiState, store: NowPlayingStore, modifier: Modifier = Modifier.fillMaxSize(), current: FocusRequester? = null) {
    val queue = state.queue
    if (queue.rows.isEmpty()) {
        EmptyState(T.messages.noItemsAvailable, modifier, icon = PlezyIcons.QueueMusic)
        return
    }
    val list = rememberLazyListState(initialFirstVisibleItemIndex = queue.currentIndex.coerceAtLeast(0))
    var last by remember { mutableStateOf(queue.currentIndex) }
    LaunchedEffect(queue.currentIndex) {
        val from = last
        last = queue.currentIndex
        // Follows the playing row only while the list is still where it was.
        if (from >= 0 && queue.currentIndex >= 0 && kotlin.math.abs(list.firstVisibleItemIndex - from) <= 1) list.animateScrollToItem(queue.currentIndex)
    }
    val touch = LocalWindowLayout.current.formFactor != FormFactor.TV
    val reorder = rememberReorderState(GroupGap)
    val count = queue.rows.size
    val move = { key: String, to: Int -> store.reorder(queue.rows.indexOfFirst { it.key == key }, to) }
    LazyColumn(
        modifier.layoutProbe("music.queue.list", reportsFocus = false),
        state = list,
        contentPadding = PaddingValues(12.dp),
        verticalArrangement = Arrangement.spacedBy(GroupGap),
    ) {
        itemsIndexed(queue.rows, key = { _, row -> row.key }) { index, row ->
            val playingRow = index == queue.currentIndex
            val name = isolate(row.title)
            val actions = OrderedRowActions(
                moveUp = ItemMenuEntry(T.libraries.moveUp, "up", icon = PlezyIcons.ArrowUpward) { store.reorder(index, index - 1) },
                moveDown = ItemMenuEntry(T.libraries.moveDown, "down", icon = PlezyIcons.ArrowDownward) { store.reorder(index, index + 1) },
                moveUpName = T.libraries.moveUpNamed(name),
                moveDownName = T.libraries.moveDownNamed(name),
                canMoveUp = index > 0,
                canMoveDown = index < count - 1,
                more = listOf(ItemMenuEntry(T.music.removeFromQueue, "remove", icon = PlezyIcons.Delete, destructive = true) { store.removeAt(index) }),
            )
            val probe = "music.queue.row.$index"
            val item = @Composable {
                OrderedRow(
                    actions = actions,
                    title = row.title,
                    moreLabel = T.libraries.moreActionsNamed(name),
                    probe = probe,
                    index = index,
                    shape = groupShape(index, count),
                    onClick = { store.jumpTo(index) },
                    surfaceModifier = (if (current != null && playingRow) Modifier.focusRequester(current) else Modifier)
                        .layoutProbe("music.track.${row.index}"),
                    contentTitle = true,
                ) {
                    if (touch && count > 1) {
                        DragHandleIcon(T.libraries.dragToReorderNamed(name), Modifier.layoutProbe("$probe.handle").reorderHandle(reorder, row.key, index, count, move))
                    }
                    QueueRowLine(row, playingRow, state.isPlaying)
                }
            }
            Box(Modifier.reorderItem(reorder, row.key, index)) {
                if (touch) SwipeToRemove("music.queue.${row.key}.swipe", onRemove = { store.removeAt(index) }, content = item) else item()
            }
        }
    }
}

/**
 * A queue row's line after its drag handle: the track's artwork ([TrackArtwork]: the album placeholder without it, the
 * now-playing mark over the playing row's), so every row's title starts in one place; the title, semibold on the
 * playing row, over "artist · length"; a played row's title in the muted colour too, which still reads 4.5:1. Harness
 * name of the title: `music.queue.title.<index>`.
 */
@Composable
internal fun RowScope.QueueRowLine(row: TrackRowUi, playingRow: Boolean, playing: Boolean) {
    TrackArtwork(row.artwork, playingRow, playing)
    // At a large font scale the texts wrap whole: the row keeps its handle, mark and ⋮ beside them.
    val lines = if (largeFontScale()) Int.MAX_VALUE else 1
    Column(Modifier.weight(1f)) {
        Text(
            row.title,
            Modifier.layoutProbe("music.queue.title.${row.index}", reportsFocus = false),
            style = MaterialTheme.typography.bodyLarge.copy(fontWeight = if (playingRow) FontWeight.SemiBold else FontWeight.Medium),
            color = if (row.dimmed && !playingRow) PlezyColors.MutedContent else Color.Unspecified,
            maxLines = lines,
            overflow = TextOverflow.Ellipsis,
        )
        val info = listOfNotNull(row.subtitle, row.duration).joinToString(" · ")
        if (info.isNotEmpty()) Text(info, style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent, maxLines = lines, overflow = TextOverflow.Ellipsis)
    }
}
