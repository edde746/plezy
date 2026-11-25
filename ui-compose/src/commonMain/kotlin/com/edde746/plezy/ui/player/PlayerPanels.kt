package com.edde746.plezy.ui.player

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import com.edde746.plezy.presentation.player.OsdIcon
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.absoluteOffset
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.AbsoluteAlignment
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.DpRect
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.sp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.presentation.player.ControlsScrim
import com.edde746.plezy.presentation.player.ErrorAction
import com.edde746.plezy.presentation.player.ErrorState
import com.edde746.plezy.presentation.player.InfoCardLayout
import com.edde746.plezy.presentation.player.InfoCardMetrics
import com.edde746.plezy.presentation.player.InfoRoom
import com.edde746.plezy.presentation.player.InfoSection
import com.edde746.plezy.presentation.player.InfoWidth
import com.edde746.plezy.presentation.player.LevelIndicator
import com.edde746.plezy.presentation.player.LevelKind
import com.edde746.plezy.presentation.player.PlaybackInfoLayout
import com.edde746.plezy.presentation.player.PlayerPrompt
import com.edde746.plezy.presentation.player.PromptKind
import com.edde746.plezy.presentation.player.StillWatchingState
import com.edde746.plezy.presentation.player.UnlockButton
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.beyond
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import kotlin.math.min

/**
 * The playback info, sections from the store ([InfoSection], read while it shows: `PlayerStore.playbackInfo`): a card
 * that takes nothing from the video and the controls: no touch, no focus, and screen readers pass it by (its figures
 * are for looking at while the video plays).
 *
 * [rooms] are the free rectangles of the player it may take (from the player's top left, clear of the top bar, the
 * transport, the bottom bar, the corner's card and an open menu). [PlaybackInfoLayout.arrange] picks the room and
 * what goes in it: as many sections as fit, the least useful left out first, in at most a third of the [picture], no
 * data value cut (its columns narrow in a narrow room, beside a phone's transport or a narrow window's menu, only as
 * far as the data of the sections they hold reads whole; free text, a file's name or a track's title, ends in an
 * ellipsis); with no room even for the first, there is no card. The card sits in its room's top trailing corner and
 * moves there in 200 ms. Its text keeps one size, never under the idiom's floor ([InfoMetrics]). Rows are one line, so
 * the card's size is known before it lays out.
 *
 * Under its title the sections stand in columns, each under its heading. A column's labels are as wide as its longest
 * (measured, [InfoMetrics.MaxLabel] at most), the values take the rest, and digits are of one width, so a live value
 * that changes (a bitrate, a count) moves nothing but its own digits. Harness names `player.playbackInfo`,
 * `player.info.<section>`.
 */
@Composable
internal fun BoxScope.PlaybackInfoCard(sections: List<InfoSection>, rooms: List<DpRect>, picture: DpSize, visible: Boolean) {
    val tv = rememberPlayerMetrics().tv
    val typography = MaterialTheme.typography
    val metrics = if (tv) InfoMetrics.Tv else InfoMetrics.Default
    val text = InfoText(
        title = if (tv) typography.titleMedium else typography.titleSmall,
        heading = typography.labelLarge.copy(fontWeight = FontWeight.SemiBold),
        row = typography.bodySmall.merge(TabularDigits),
    )
    val measurer = rememberTextMeasurer()
    val density = LocalDensity.current
    val measures = remember(text, metrics, measurer, density) {
        fun line(style: TextStyle) = with(density) { measurer.measure("Ag", style, maxLines = 1).size.height.toDp().value }
        InfoCardMetrics(
            column = metrics.column.value,
            columnGap = metrics.gap.value,
            maxColumns = metrics.maxColumns,
            labelGap = metrics.labelGap.value,
            padding = metrics.padding.value,
            title = line(text.title) + metrics.sectionGap.value,
            heading = line(text.heading),
            row = line(text.row),
            rowGap = metrics.rowGap.value,
            sectionGap = metrics.sectionGap.value,
        )
    }
    // Each section's widest label (to [InfoMetrics.MaxLabel]) and widest data value in the rows' style, the value a dp
    // wider for the rounding to pixels.
    val widths = remember(sections, text.row, measurer, density) {
        fun width(value: String) = with(density) { measurer.measure(value, text.row, softWrap = false, maxLines = 1).size.width.toDp() }
        sections.associate { section ->
            val label = minOf(section.rows.maxOfOrNull { width(it.label) } ?: 0.dp, InfoMetrics.MaxLabel)
            val data = section.rows.filterNot { it.freeText }.maxOfOrNull { width(it.value) + 1.dp } ?: 0.dp
            section.id to InfoWidth(label.value, data.value)
        }
    }
    val arranged = PlaybackInfoLayout.arrange(
        sections,
        rooms.map { InfoRoom((it.right - it.left).value, (it.bottom - it.top).value) },
        picture.width.value * picture.height.value,
        measures,
    ) { widths.getValue(it.id) }
    // The last card stays while it fades out. A column's labels as wide as its longest.
    val last = remember { arrayOfNulls<Triple<InfoCardLayout, DpRect, List<Dp>>>(1) }
    arranged?.let { card -> last[0] = Triple(card, rooms[card.room], card.columns.map { column -> column.maxOf { widths.getValue(it.id).label }.dp }) }
    val (card, room, labels) = last[0] ?: return
    val ltr = LocalLayoutDirection.current == LayoutDirection.Ltr
    val x by animateDpAsState(if (ltr) room.right - card.width.dp else room.left, tween(200), label = "infoX")
    val y by animateDpAsState(room.top, tween(200), label = "infoY")
    AnimatedVisibility(
        visible && arranged != null,
        Modifier.align(AbsoluteAlignment.TopLeft).absoluteOffset(x, y),
        enter = fadeIn(tween(200)),
        exit = fadeOut(tween(200)),
    ) {
        InfoCard(card, labels, text, metrics)
    }
}

@Composable
private fun InfoCard(card: InfoCardLayout, labels: List<Dp>, text: InfoText, metrics: InfoMetrics) {
    CompositionLocalProvider(LocalContentColor provides PlezyColors.OnVideo) {
        Column(
            Modifier.layoutProbe("player.playbackInfo")
                .clearAndSetSemantics { }
                .requiredWidth(card.width.dp)
                .background(PlezyColors.Surface, PanelShape)
                .padding(metrics.padding),
            verticalArrangement = Arrangement.spacedBy(metrics.sectionGap),
        ) {
            Text(T.player.info.title, style = text.title, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Row(horizontalArrangement = Arrangement.spacedBy(metrics.gap)) {
                card.columns.forEachIndexed { index, column ->
                    Column(Modifier.width(card.column.dp), verticalArrangement = Arrangement.spacedBy(metrics.sectionGap)) {
                        for (section in column) InfoSectionRows(section, labels[index], text, metrics)
                    }
                }
            }
        }
    }
}

@Composable
private fun InfoSectionRows(section: InfoSection, labelWidth: Dp, text: InfoText, metrics: InfoMetrics) {
    Column(Modifier.layoutProbe("player.info.${section.id.probeName}"), verticalArrangement = Arrangement.spacedBy(metrics.rowGap)) {
        Text(section.title, style = text.heading, maxLines = 1, overflow = TextOverflow.Ellipsis)
        // The file's name is content text; the other values are ours.
        val content = setOf(T.player.info.file)
        for (row in section.rows) {
            Row(horizontalArrangement = Arrangement.spacedBy(metrics.labelGap)) {
                Text(
                    row.label,
                    style = text.row,
                    color = PlezyColors.OnVideoMuted,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.width(labelWidth),
                )
                Text(
                    row.value,
                    style = if (row.label in content) text.row.contentDirection() else text.row,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

/** Digits of one width: a live value's digits change in place. */
private val TabularDigits = TextStyle(fontFeatureSettings = "tnum")

/** The info card's text: its title, a section's heading, and a row's label and value alike. */
@Immutable
private data class InfoText(val title: TextStyle, val heading: TextStyle, val row: TextStyle)

/**
 * The info card's measures: [padding] inside it; columns [column] wide (wider where their data needs it, narrower in a
 * narrow room down to what their data needs: [PlaybackInfoLayout.arrange]), at most [maxColumns] side by side and
 * [gap] apart; a row's label and value [labelGap] apart, rows [rowGap] and sections [sectionGap]. Tight enough that a
 * phone's card holds Stream and Video within a third of its screen.
 *
 * Its rows' text (the body's small size, 12 sp, alike on every form factor) is never under the idiom's floor: 11 sp on
 * a phone, 12 on a tablet or the desktop, and on TV what reads from across the room, about 22 px of a 1080-line
 * screen: 11 dp, Android TV being 540 dp tall at any resolution.
 */
private class InfoMetrics(
    val padding: Dp,
    val column: Dp,
    val gap: Dp,
    val labelGap: Dp,
    val rowGap: Dp,
    val sectionGap: Dp,
    val maxColumns: Int,
) {
    companion object {
        /** The widest a column's labels get: a longer label ends in an ellipsis. */
        val MaxLabel = 140.dp

        val Default = InfoMetrics(padding = 10.dp, column = 260.dp, gap = 16.dp, labelGap = 12.dp, rowGap = 2.dp, sectionGap = 8.dp, maxColumns = 2)
        val Tv = InfoMetrics(padding = 16.dp, column = 300.dp, gap = 24.dp, labelGap = 10.dp, rowGap = 2.dp, sectionGap = 12.dp, maxColumns = 3)
    }
}

/**
 * The prompt button ([PlayerPrompt]): the skip button ("Skip Intro", a fast-forward icon) or up next ("S1E2 · Please
 * Remain Calm", a skip-next icon, and the shuffle icon after its text while the queue is shuffled), one pill in the
 * bottom trailing corner. Its countdown fills it from its leading edge ([PlayerPrompt.progress], stepped every tenth of
 * a second and drawn moving between the steps). It hugs its label up to [CornerWidth] ([CornerTvWidth] on TV; a
 * narrower window gives it its whole width), past which the label is cut short after the episode's code
 * ([PlayerPrompt.lead]); screen readers hear the whole label, which says what up next does, and the countdown's seconds
 * left as its state ([PlayerPrompt.countdown]). On TV it takes focus as it shows (the player gives it:
 * [PlayerFocus.prompt]). Harness names `player.skip`, `player.upNext`.
 */
@Composable
internal fun PromptButton(prompt: PlayerPrompt, focus: PlayerFocus, onCommand: (PlayerCommand) -> Unit, modifier: Modifier = Modifier) {
    val tv = rememberPlayerMetrics().tv
    val countdown = prompt.progress
    val fill by animateFloatAsState(
        countdown ?: 0f,
        if (countdown == null) snap() else tween(PROMPT_FILL_STEP_MILLIS, easing = LinearEasing),
        label = "prompt",
    )
    val upNext = prompt.kind == PromptKind.UP_NEXT
    PlezyButton(
        prompt.text,
        onClick = { onCommand(prompt.command) },
        modifier = modifier
            .widthIn(max = if (tv) CornerTvWidth else CornerWidth)
            .focusRequester(focus.prompt)
            .semantics {
                contentDescription = prompt.label
                prompt.countdown?.let { stateDescription = it }
            }
            .layoutProbe(if (upNext) "player.upNext" else "player.skip"),
        icon = if (upNext || prompt.command == PlayerCommand.NextEpisode) PlezyIcons.SkipNext else PlezyIcons.FastForward,
        progress = if (countdown != null) fill else null,
        trailingIcon = if (upNext && prompt.shuffled) PlezyIcons.Shuffle else null,
        lead = prompt.lead,
        // Up next's text is the episode's name (its code alone where it has none, which opens on a letter of the
        // interface's own script in every language we ship); a skip's is ours.
        contentText = upNext,
    )
}

/** How often the store steps a prompt's countdown: the fill moves on between its steps over this long. */
private const val PROMPT_FILL_STEP_MILLIS = 100

/**
 * The bottom trailing corner's width on phones, tablets and desktop: the sleep timer's card's, and the prompt button's
 * at most (a narrower window gives them its whole width).
 */
private val CornerWidth = 320.dp

/** The bottom trailing corner's width on TV. */
private val CornerTvWidth = 420.dp

/**
 * The sleep timer's question, compact ([CornerWidth], TV [CornerTvWidth]), in the bottom trailing corner above the
 * prompt button: "Still watching?", the countdown ("Pausing in 25 seconds"), then Continue and Pause. Continue's fill
 * grows as the countdown runs out ([StillWatchingState.progress]); the playback pauses when it does. On TV Continue
 * has focus while the card shows (the player gives it). TalkBack speaks the question as the card shows, wherever its
 * focus is; not the countdown, which changes every second.
 *
 * Continue and Pause stay one height under focus: neither grows nor wears a ring outside it. Focus shows by the fill
 * alone: while it is in the card (and shows: keys, not a pointer or touch) the focused button wears the primary fill
 * and Continue rests in the secondary one like Pause; otherwise Continue wears it as the card's main action.
 */
@Composable
internal fun StillWatchingCard(stillWatching: StillWatchingState, focus: PlayerFocus, onCommand: (PlayerCommand) -> Unit, modifier: Modifier = Modifier) {
    val tv = rememberPlayerMetrics().tv
    val typography = MaterialTheme.typography
    var focusInside by remember { mutableStateOf(false) }
    val focusVisible = isFocusVisible()
    val keyFocus = focusInside && focusVisible
    Surface(
        modifier.width(if (tv) CornerTvWidth else CornerWidth),
        shape = PanelShape,
        color = PlezyColors.Surface,
        contentColor = PlezyColors.OnVideo,
    ) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                T.player.stillWatching.title,
                Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                style = if (tv) typography.labelLarge else typography.labelMedium,
                color = PlezyColors.OnVideoMuted,
                maxLines = 1,
            )
            Text(
                stillWatching.countdown,
                style = (if (tv) typography.titleLarge else typography.titleMedium).copy(fontFeatureSettings = "tnum"),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Row(
                Modifier.padding(top = 12.dp).height(IntrinsicSize.Min).onFocusChanged { focusInside = it.hasFocus },
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                PlezyButton(
                    T.player.stillWatching.keepWatching,
                    onClick = { onCommand(PlayerCommand.KeepWatching) },
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .focusRequester(focus.stillWatching)
                        .layoutProbe("player.stillWatching.continue"),
                    style = if (keyFocus) ButtonStyle.SECONDARY else ButtonStyle.PRIMARY,
                    icon = PlezyIcons.PlayArrow,
                    progress = stillWatching.progress,
                    grows = false,
                )
                PlezyButton(
                    T.player.stillWatching.pause,
                    onClick = { onCommand(PlayerCommand.Pause) },
                    modifier = Modifier.fillMaxHeight().layoutProbe("player.stillWatching.pause"),
                    style = ButtonStyle.SECONDARY,
                    grows = false,
                )
            }
        }
    }
}

/**
 * The failure, full screen: black from edge to edge (out past the player by [videoInsets], under the system bars, as
 * the video reaches), over the video, the subtitles and every panel; the player keeps the top bar's Back and title over
 * it. On the black, centred: the icon, the title, the message (the texts within 460 dp, 640 dp on TV), then the buttons
 * ([ErrorState.buttons], in order; harness names `player.error.<action>`: retry, close). It keeps [topBar] clear above
 * and below, so it never meets Back or the title, and scrolls where it is taller than the room left (the largest text on
 * a phone on its side). The buttons sit side by side where they fit the player's width, else one above the other, as
 * wide as one another ([ErrorButtons]). The primary button
 * ([ErrorState.primary]) is filled and carries [PlayerFocus.error]: the player gives it focus, and on TV the D-pad moves
 * along the row or the stack from there; Close is a text button. TalkBack speaks the title and the message as they show
 * and change, wherever its focus is. Harness name: `player.error` (the whole player).
 */
@Composable
internal fun ErrorPanel(
    error: ErrorState,
    focus: PlayerFocus,
    onCommand: (PlayerCommand) -> Unit,
    topBar: Dp,
    videoInsets: WindowInsets,
    modifier: Modifier = Modifier,
) {
    val tv = rememberPlayerMetrics().tv
    Box(modifier.fillMaxSize().layoutProbe("player.error", reportsFocus = false)) {
        Box(Modifier.matchParentSize().beyond(videoInsets).background(Color.Black))
        Box(Modifier.fillMaxSize().padding(vertical = topBar), contentAlignment = Alignment.Center) {
            CompositionLocalProvider(LocalContentColor provides PlezyColors.OnVideo) {
                Column(
                    Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 24.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    val texts = Modifier.widthIn(max = if (tv) 640.dp else 460.dp)
                    Icon(PlezyIcons.ErrorOutline, contentDescription = null, Modifier.size(40.dp), tint = PlezyColors.Error)
                    Text(
                        error.title,
                        texts.semantics { liveRegion = LiveRegionMode.Polite },
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center,
                    )
                    Text(
                        error.message,
                        texts.semantics { liveRegion = LiveRegionMode.Polite },
                        style = MaterialTheme.typography.bodyMedium,
                        textAlign = TextAlign.Center,
                        color = PlezyColors.OnVideoMuted,
                    )
                    // 18 dp below the texts, with the column's spacing.
                    ErrorButtons(stacked = if (tv) 400.dp else 300.dp, Modifier.padding(top = 8.dp)) {
                        for (button in error.buttons) {
                            PlezyButton(
                                button.label,
                                onClick = { onCommand(button.command) },
                                modifier = (if (button.primary) Modifier.focusRequester(focus.error) else Modifier).layoutProbe("player.error.${button.action.probeName}"),
                                style = when {
                                    button.primary -> ButtonStyle.PRIMARY
                                    button.action == ErrorAction.CLOSE -> ButtonStyle.TEXT
                                    else -> ButtonStyle.SECONDARY
                                },
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * The error's buttons: side by side, centred and 10 dp apart, where they fit the width at their own sizes; else one
 * above the other, 10 dp apart, each as wide as the width allows up to [stacked].
 */
@Composable
private fun ErrorButtons(stacked: Dp, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Layout(content, modifier) { measurables, constraints ->
        val gap = 10.dp.roundToPx()
        val gaps = gap * (measurables.size - 1).coerceAtLeast(0)
        val widths = measurables.map { it.maxIntrinsicWidth(Constraints.Infinity) }
        if (widths.sum() + gaps <= constraints.maxWidth) {
            val buttons = measurables.mapIndexed { i, button -> button.measure(Constraints(maxWidth = widths[i])) }
            val height = buttons.maxOfOrNull { it.height } ?: 0
            layout(buttons.sumOf { it.width } + gaps, height) {
                var x = 0
                for (button in buttons) {
                    button.placeRelative(x, (height - button.height) / 2)
                    x += button.width + gap
                }
            }
        } else {
            val width = min(constraints.maxWidth, stacked.roundToPx())
            val buttons = measurables.map { it.measure(Constraints.fixedWidth(width)) }
            layout(width, buttons.sumOf { it.height } + gaps) {
                var y = 0
                for (button in buttons) {
                    button.placeRelative(0, y)
                    y += button.height + gap
                }
            }
        }
    }
}

/**
 * A transient message (volume, speed, a track change by key, a seek's seconds, a play or pause with the controls down)
 * with its [icon] on black, darker over an HDR picture ([hdr], [ControlsScrim]). TalkBack speaks it as it shows and
 * changes, wherever its focus is. Harness name: [probe] (`player.osd`).
 */
@Composable
internal fun OsdMessage(text: String, icon: ImageVector?, hdr: Boolean, modifier: Modifier = Modifier, probe: String = "player.osd") {
    Surface(modifier.layoutProbe(probe), shape = CircleShape, color = Color.Black.copy(alpha = ControlsScrim.alpha(0.6f, hdr)), contentColor = PlezyColors.OnVideo) {
        Row(
            Modifier.semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite }.padding(horizontal = 18.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            icon?.let { Icon(it, contentDescription = null, Modifier.size(20.dp)) }
            Text(text, style = MaterialTheme.typography.titleMedium, maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** A toast's icon. */
internal val OsdIcon.vector: ImageVector
    get() = when (this) {
        OsdIcon.FAST_FORWARD -> PlezyIcons.FastForward
        OsdIcon.SLOW_MOTION -> PlezyIcons.Speed
        OsdIcon.VOLUME_UP -> PlezyIcons.VolumeUp
        OsdIcon.VOLUME_DOWN -> PlezyIcons.VolumeDown
        OsdIcon.VOLUME_OFF -> PlezyIcons.VolumeOff
        OsdIcon.SCREENSHOT -> PlezyIcons.PhotoCamera
        OsdIcon.SUBTITLES -> PlezyIcons.Subtitles
        OsdIcon.AUDIO -> PlezyIcons.Audiotrack
        OsdIcon.ZOOM -> PlezyIcons.ZoomIn
    }

/**
 * A swipe's level ([LevelIndicator]: the brightness or the volume): a tall capsule on the black of
 * [OsdMessage], filled from the bottom to the level, its icon and percent over the middle, white above the fill and
 * dark where the fill covers them. The fill follows the level in 90 ms. TalkBack speaks its label ("Brightness
 * 40%"). Harness name: `player.level`.
 */
@Composable
internal fun LevelBar(level: LevelIndicator, hdr: Boolean, modifier: Modifier = Modifier) {
    val fill by animateFloatAsState(level.fraction.coerceIn(0f, 1f), tween(90), label = "level")
    val icon = when (level.kind) {
        LevelKind.BRIGHTNESS -> PlezyIcons.LightMode
        LevelKind.VOLUME -> PlezyIcons.VolumeUp
    }
    Box(
        modifier
            .layoutProbe("player.level")
            .size(54.dp, 184.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = ControlsScrim.alpha(0.6f, hdr)))
            .background(Color.White.copy(alpha = 0.14f))
            .clearAndSetSemantics {
                contentDescription = level.label
                liveRegion = LiveRegionMode.Polite
            },
    ) {
        Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().fillMaxHeight(fill).background(Color.White.copy(alpha = 0.74f)))
        LevelContent(icon, level.percent, PlezyColors.OnVideo, Modifier)
        LevelContent(
            icon,
            level.percent,
            Color.Black.copy(alpha = 0.86f),
            Modifier.drawWithContent { clipRect(top = size.height * (1 - fill)) { this@drawWithContent.drawContent() } },
        )
    }
}

/** [LevelBar]'s icon over its percent, centred on the whole bar, in [color]. */
@Composable
private fun LevelContent(icon: ImageVector, percent: String, color: Color, modifier: Modifier) {
    Column(modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
        Icon(icon, contentDescription = null, Modifier.size(24.dp), tint = color)
        Text(
            percent,
            Modifier.padding(top = 6.dp),
            color = color,
            style = TextStyle(fontSize = 14.sp, lineHeight = 14.sp, fontWeight = FontWeight.Bold, fontFeatureSettings = "tnum"),
        )
    }
}

/** The speed a finger held on the video plays at ("2×"), as [OsdMessage] looks, while it is held. Harness name: `player.heldSpeed`. */
@Composable
internal fun HeldSpeedMessage(speed: String, hdr: Boolean, modifier: Modifier = Modifier) {
    Surface(modifier.layoutProbe("player.heldSpeed"), shape = CircleShape, color = Color.Black.copy(alpha = ControlsScrim.alpha(0.6f, hdr)), contentColor = PlezyColors.OnVideo) {
        Row(
            Modifier.semantics(mergeDescendants = true) { liveRegion = LiveRegionMode.Polite }.padding(horizontal = 18.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(PlezyIcons.FastForward, contentDescription = null, Modifier.size(20.dp))
            Text(speed, style = MaterialTheme.typography.titleMedium)
        }
    }
}

/**
 * The locked screen's unlock button ([UnlockButton]): a pill with the lock and "Hold to unlock" on the black of
 * [OsdMessage]. While held ([UnlockButton.holding]) a white fill grows across it from its leading edge over
 * [UnlockButton.HOLD_MILLIS], the lock and the text dark where it covers them; let go, the fill is gone. It takes no
 * touches itself (the shield under it tells a finger on it from one beside it); TalkBack presses it through [onUnlock].
 * Harness name: `player.unlock`.
 */
@Composable
internal fun UnlockButtonPill(unlock: UnlockButton, hdr: Boolean, onUnlock: () -> Unit, modifier: Modifier = Modifier) {
    val fill by animateFloatAsState(
        if (unlock.holding) 1f else 0f,
        if (unlock.holding) tween(UnlockButton.HOLD_MILLIS.toInt(), easing = LinearEasing) else snap(),
        label = "unlock",
    )
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    Box(
        modifier
            .layoutProbe("player.unlock")
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = ControlsScrim.alpha(0.6f, hdr)))
            .drawBehind {
                val width = size.width * fill
                drawRect(Color.White, topLeft = Offset(if (rtl) size.width - width else 0f, 0f), size = Size(width, size.height))
            }
            .clearAndSetSemantics {
                role = Role.Button
                contentDescription = unlock.label
                liveRegion = LiveRegionMode.Polite
                onClick {
                    onUnlock()
                    true
                }
            },
    ) {
        UnlockPillContent(unlock.label, PlezyColors.OnVideo, Modifier)
        UnlockPillContent(
            unlock.label,
            Color.Black,
            Modifier.drawWithContent {
                val width = size.width * fill
                clipRect(left = if (rtl) size.width - width else 0f, right = if (rtl) size.width else width) { this@drawWithContent.drawContent() }
            },
        )
    }
}

/** [UnlockButtonPill]'s lock and label in [color]. */
@Composable
private fun UnlockPillContent(label: String, color: Color, modifier: Modifier) {
    Row(
        modifier.padding(horizontal = 20.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(PlezyIcons.Lock, contentDescription = null, Modifier.size(20.dp), tint = color)
        Text(label, color = color, style = MaterialTheme.typography.labelLarge)
    }
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun PlayerLoadingIndicator() {
    LoadingIndicator(Modifier.size(72.dp), color = PlezyColors.OnVideo)
}
