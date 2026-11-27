package com.edde746.plezy.ui.player

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.input.TextFieldLineLimits
import androidx.compose.foundation.text.input.rememberTextFieldState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.onPlaced
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.layout.positionInParent
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.presentation.player.ChapterItem
import com.edde746.plezy.presentation.player.FileInfoState
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.QueueItem
import com.edde746.plezy.presentation.player.SleepTimerBanner
import com.edde746.plezy.presentation.player.SubtitleSearchState
import com.edde746.plezy.presentation.player.VersionsMenu
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.music.EqualizerIcon
import com.edde746.plezy.ui.menu.FileInfoContent
import com.edde746.plezy.ui.focus.OnTextChange
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.focus.rememberKeyboardOnSelect
import com.edde746.plezy.ui.focus.remoteLeavesField
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import androidx.compose.foundation.border
import kotlin.math.roundToInt

/** Disabled rows (a quality the server can't reach) draw their content at this alpha. */
private const val DisabledAlpha = 0.38f

/**
 * One row of a player page: [leading] (a thumbnail), [label] (bold where it is the [current] one) over [detail], then
 * [trailing] (a check where [selected], by default). A disabled row draws at 38 %.
 */
@Composable
internal fun SheetRow(
    label: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    detail: String? = null,
    selected: Boolean = false,
    enabled: Boolean = true,
    current: Boolean = false,
    contentLabel: Boolean = false,
    leading: (@Composable () -> Unit)? = null,
    trailing: (@Composable () -> Unit)? = if (selected) ({ Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(20.dp)) }) else null,
) {
    val content = MaterialTheme.colorScheme.onSurface
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight),
        shape = MaterialTheme.shapes.medium,
        color = Color.Transparent,
        contentColor = if (enabled) content else content.copy(alpha = DisabledAlpha),
        enabled = enabled,
        selected = selected,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        Row(
            Modifier.padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            leading?.invoke()
            Column(Modifier.weight(1f)) {
                val base = MaterialTheme.typography.bodyLarge.let { if (current) it.copy(fontWeight = FontWeight.SemiBold) else it }
                Text(label, style = if (contentLabel) base.contentDirection() else base, maxLines = 2, overflow = TextOverflow.Ellipsis)
                if (detail != null) {
                    Text(
                        detail,
                        style = MaterialTheme.typography.bodySmall,
                        color = PlezyColors.MutedContent,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
            trailing?.invoke()
        }
    }
}

/** A section's heading in a one-list page (the versions above the qualities): muted, small. */
@Composable
private fun SectionHeading(label: String) {
    Text(
        label,
        style = MaterialTheme.typography.titleSmall,
        color = PlezyColors.OnVideoMuted,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp),
    )
}

/** A page's single line of text: an empty list, a failure, the outcome of a download. */
@Composable
internal fun SheetMessage(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = MaterialTheme.typography.bodyMedium,
        color = PlezyColors.OnVideoMuted,
        modifier = modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 20.dp),
    )
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun SheetSpinner() {
    Box(Modifier.fillMaxWidth().padding(24.dp), contentAlignment = Alignment.Center) {
        LoadingIndicator(Modifier.size(28.dp))
    }
}

/**
 * The version and quality page, one list: the versions (with more than one) and then the qualities, each under its
 * heading where both show; the one playing checked, one the server can't play drawn at 38 % and not pickable. Focus
 * starts on the playing quality, else the playing version. Harness names: `player.versions.version.<i>`,
 * `player.versions.quality.<i>`.
 */
@Composable
internal fun VersionsPage(menu: VersionsMenu?, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    menu ?: return
    val focusVersion = menu.qualities.none { it.selected }
    val both = menu.showsVersions && menu.qualities.isNotEmpty()
    MenuList(modifier) {
        if (menu.showsVersions) {
            if (both) SectionHeading(T.videoControls.versionColumnHeader)
            ChoiceRows("version", menu.versions, focusVersion, initial, onCommand)
        }
        if (menu.qualities.isNotEmpty()) {
            if (both) SectionHeading(T.videoControls.qualityColumnHeader)
            ChoiceRows("quality", menu.qualities, !focusVersion, initial, onCommand)
        }
    }
}

@Composable
private fun ChoiceRows(section: String, choices: List<OptionChoice>, focus: Boolean, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit) {
    val focused = choices.indexOfFirst { it.selected }.coerceAtLeast(0)
    choices.forEachIndexed { index, choice ->
        SheetRow(
            choice.label,
            onClick = { onCommand(choice.command) },
            modifier = Modifier.layoutProbe("player.versions.$section.$index")
                .then(if (focus && index == focused) Modifier.focusRequester(initial) else Modifier),
            detail = choice.detail,
            selected = choice.selected,
            enabled = choice.enabled,
            contentLabel = section == "version",
        )
    }
}

/**
 * A list's thumbnail, rounded, the image cropped into it ([kind]'s placeholder where it has none); [blurred] for a
 * spoiler. The entry playing ([nowPlaying]) carries the now-playing mark, one look on every device: the artwork (or,
 * without one, the bare tile: no placeholder glyph showing through) darkened under a white equalizer, moving while
 * [playing], named for screen readers, its edge drawn in the muted text colour so even a dark tile stands off the sheet
 * (TV's focus fills a row with the primary colour, so a primary tile would read as focus). It marks the playing row in
 * the chapters and the queue in the artwork's place, as the music queue's leading column does, so the title beside it
 * never moves.
 */
@Composable
private fun Thumbnail(url: String?, kind: PlaceholderKind, nowPlaying: Boolean, playing: Boolean, blurred: Boolean = false) {
    Box(Modifier.size(96.dp, 54.dp).clip(MaterialTheme.shapes.extraSmall), contentAlignment = Alignment.Center) {
        RemoteImage(
            url,
            contentDescription = null,
            modifier = Modifier.fillMaxSize(),
            blank = PlezyColors.SurfaceHigh,
            blurred = blurred,
            error = if (nowPlaying) null else ({ ArtworkPlaceholder(kind) }),
        )
        if (nowPlaying) {
            val name = T.player.nowPlaying
            Box(
                Modifier.fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.6f))
                    .border(1.5.dp, PlezyColors.TextMuted, MaterialTheme.shapes.extraSmall)
                    .semantics { contentDescription = name },
                contentAlignment = Alignment.Center,
            ) {
                EqualizerIcon(playing, Color.White, Modifier.size(22.dp))
            }
        }
    }
}

/**
 * The entries of a long list, scrolling, then [footer] (a track list's More subtitles, search and delay) after them,
 * with the [current] one brought to about the middle of the list as it opens (or [current] changes), so what comes
 * before and after it shows around it, whether or not it takes focus (a touch screen focuses nothing). The list then
 * starts on a whole row, never on the second half of one (a detail line under the header without its title). Nothing
 * stays pinned while the entries scroll: the list ends where the sheet does, its last row cut by the edge while more
 * follow.
 */
@Composable
internal fun CentredList(
    count: Int,
    current: Int,
    modifier: Modifier,
    footer: @Composable () -> Unit = {},
    row: @Composable (index: Int, Modifier) -> Unit,
) {
    val scroll = rememberScrollState()
    val tops = remember(count) { IntArray(count) }
    val heights = remember(count) { IntArray(count) }
    var viewport by remember { mutableIntStateOf(0) }
    LaunchedEffect(current, count) {
        if (current !in 0 until count) return@LaunchedEffect
        // The rows are laid out by the next frame.
        withFrameNanos { }
        val centred = tops[current] - (viewport - heights[current]) / 2
        val start = (1..current).lastOrNull { tops[it] <= centred }?.let { tops[it] } ?: 0
        scroll.scrollTo(start.coerceIn(0, scroll.maxValue))
    }
    val reach = LocalPlezyDimens.current.focusReach
    Column(modifier.onSizeChanged { viewport = it.height }.verticalScroll(scroll).padding(vertical = reach)) {
        repeat(count) { index ->
            row(
                index,
                Modifier.onPlaced {
                    tops[index] = it.positionInParent().y.roundToInt()
                    heights[index] = it.size.height
                },
            )
        }
        footer()
    }
}

/**
 * The chapters: each with its thumbnail, title and start; the one playing marked as the queue's is ([Thumbnail]),
 * bold and selected, focused and in the middle as the page opens. A pick seeks there; where this device may not seek
 * the rows are disabled.
 */
@Composable
internal fun ChapterList(chapters: List<ChapterItem>, playing: Boolean, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    if (chapters.isEmpty()) return SheetMessage(T.videoControls.noChaptersAvailable, modifier)
    val current = chapters.indexOfFirst { it.current }.coerceAtLeast(0)
    CentredList(chapters.size, current, modifier) { index, rowModifier ->
        val chapter = chapters[index]
        val command = chapter.command
        SheetRow(
            chapter.title,
            onClick = { command?.let(onCommand) },
            modifier = rowModifier.menuItem(index, index == current, initial),
            detail = chapter.start,
            selected = chapter.current,
            enabled = command != null,
            current = chapter.current,
            contentLabel = true,
            leading = { Thumbnail(chapter.imageUrl, PlaceholderKind.MOVIE, nowPlaying = chapter.current, playing = playing) },
            trailing = null,
        )
    }
}

/**
 * The queue: each entry with its thumbnail, title and subtitle; the one playing marked as the chapters' is
 * ([Thumbnail]), bold and selected, focused and in the middle as the page opens. A pick plays it. A spoiler's thumbnail
 * is blurred.
 */
@Composable
internal fun QueueList(queue: List<QueueItem>, playing: Boolean, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    if (queue.isEmpty()) return SheetMessage(T.videoControls.noQueueItems, modifier)
    val current = queue.indexOfFirst { it.current }.coerceAtLeast(0)
    CentredList(queue.size, current, modifier) { index, rowModifier ->
        val item = queue[index]
        SheetRow(
            item.title,
            onClick = { onCommand(PlayerCommand.PlayQueueItem(item.key)) },
            modifier = rowModifier.menuItem(index, index == current, initial),
            detail = item.subtitle,
            selected = item.current,
            current = item.current,
            contentLabel = true,
            leading = { Thumbnail(item.imageUrl, PlaceholderKind.EPISODE, nowPlaying = item.current, playing = playing, blurred = item.spoiler) },
            trailing = null,
        )
    }
}

/**
 * The chapters-and-queue page's header ([com.edde746.plezy.input.PlayerMenu.CONTENT_STRIP], D-pad Down from the
 * controls, a swipe up on a phone's) where it has both: its Chapters and Queue tabs, the one picked ([queueTab]) filled,
 * in place of a title that would repeat it. Harness names: `player.menu.tab.chapters`, `player.menu.tab.queue`.
 */
@Composable
internal fun StripTabs(queueTab: MutableState<Boolean>) {
    Row(Modifier.focusGroup(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        PlezyChip(T.videoControls.chapters, selected = !queueTab.value, onClick = { queueTab.value = false }, Modifier.layoutProbe("player.menu.tab.chapters"), tab = true)
        PlezyChip(T.videoControls.queue, selected = queueTab.value, onClick = { queueTab.value = true }, Modifier.layoutProbe("player.menu.tab.queue"), tab = true)
    }
}

/**
 * The sleep timer page: the running timer's banner ("Timer Active", what it will do, +15 min while it counts down,
 * Cancel; the banner's first button takes focus), then one list of its choices: the end of the video and the durations,
 * the selected one checked. Without a running timer focus starts on the selected choice, else the first.
 */
@Composable
internal fun SleepTimerPage(option: PlayerOption?, banner: SleepTimerBanner?, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    val choices = option?.choices.orEmpty()
    val focused = choices.indexOfFirst { it.selected }.coerceAtLeast(0)
    MenuList(modifier) {
        banner?.let { SleepTimerActive(it, initial, onCommand) }
        choices.forEachIndexed { index, choice ->
            SheetRow(
                choice.label,
                onClick = { onCommand(choice.command) },
                modifier = Modifier.menuItem(index, banner == null && index == focused, initial),
                detail = choice.detail,
                selected = choice.selected,
            )
        }
    }
}

/** The running sleep timer on the panel's raised surface: "Timer Active", its text, +15 min (counting down) and Cancel. */
@Composable
private fun SleepTimerActive(banner: SleepTimerBanner, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit) {
    Surface(
        Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp).layoutProbe("player.sleep.active"),
        shape = MaterialTheme.shapes.large,
        color = PlezyColors.SurfaceHigh,
        contentColor = PlezyColors.OnVideo,
    ) {
        Column(Modifier.padding(16.dp).focusGroup(), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(T.videoControls.timerActive, style = MaterialTheme.typography.titleMedium)
            Text(banner.text, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.OnVideoMuted)
            Row(Modifier.padding(top = 12.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                val extend = banner.extend
                if (extend != null) {
                    PlezyButton(extend, onClick = { onCommand(PlayerCommand.ExtendSleepTimer) }, Modifier.focusRequester(initial), style = ButtonStyle.SECONDARY)
                }
                PlezyButton(
                    T.common.cancel,
                    onClick = { onCommand(PlayerCommand.CancelSleepTimer) },
                    if (extend == null) Modifier.focusRequester(initial) else Modifier,
                    style = ButtonStyle.TEXT,
                )
            }
        }
    }
}

/**
 * The file info page: a spinner while it loads, then the file info sheet's content ([FileInfoContent]: every
 * version, file and stream), or the failure ("File information not available").
 */
@Composable
internal fun FileInfoSheet(info: FileInfoState?, initial: FocusRequester, modifier: Modifier) {
    when {
        info == null || info.loading -> SheetSpinner()
        info.error != null -> SheetMessage(info.error.orEmpty(), modifier.layoutProbe("player.fileInfo.error"))
        else -> info.info?.let { FileInfoContent(it, info.title, "player.fileInfo", modifier.focusRequester(initial).focusGroup().padding(horizontal = 16.dp)) }
    }
}

/**
 * The subtitle search: the language (opening its list in place), the title searched (each edit goes to the store, which
 * searches once typing pauses; Search on the keyboard searches at once; on TV the keyboard waits for Select and the
 * arrows leave the field), then a spinner while it searches, the results (each downloads on a pick; while one downloads
 * its row spins and the others wait) and the outcome or failure.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
internal fun SubtitleSearchSheet(search: SubtitleSearchState?, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    search ?: return
    var picking by remember { mutableStateOf(false) }
    val query = rememberTextFieldState(search.title)
    val keyboard = rememberKeyboardOnSelect()
    fun searchTitle(now: Boolean) = onCommand(PlayerCommand.SearchSubtitles(search.languageCode, query.text.toString().ifBlank { null }, now = now))
    OnTextChange(query) { searchTitle(now = false) }
    MenuList(modifier) {
        PageEntry(
            PlezyIcons.Subtitles,
            T.videoControls.language,
            search.language,
            Modifier.layoutProbe("player.search.language").focusRequester(initial),
        ) { picking = !picking }
        if (picking) {
            search.languages.forEachIndexed { index, choice ->
                SheetRow(
                    choice.label,
                    onClick = {
                        picking = false
                        onCommand(choice.command)
                    },
                    modifier = Modifier.layoutProbe("player.search.language.$index"),
                    selected = choice.selected,
                )
            }
            return@MenuList
        }
        OutlinedTextField(
            state = query,
            lineLimits = TextFieldLineLimits.SingleLine,
            readOnly = keyboard.readOnly,
            leadingIcon = { Icon(PlezyIcons.Search, contentDescription = null) },
            placeholder = { Text(T.common.search) },
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
            onKeyboardAction = { searchTitle(now = true) },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp)
                .then(keyboard.modifier).remoteLeavesField(query).layoutProbe("player.search.title"),
        )
        when {
            search.searching -> SheetSpinner()
            else -> search.results.forEachIndexed { index, result ->
                val downloading = search.downloading == result.key
                SheetRow(
                    result.label,
                    onClick = { onCommand(result.command) },
                    modifier = Modifier.layoutProbe("player.search.result.$index"),
                    detail = result.detail,
                    enabled = search.downloading == null,
                    contentLabel = true,
                    trailing = if (downloading) {
                        { LoadingIndicator(Modifier.size(20.dp)) }
                    } else {
                        { Icon(PlezyIcons.Download, contentDescription = null, Modifier.size(20.dp)) }
                    },
                )
            }
        }
        search.message?.let { SheetMessage(it, Modifier.layoutProbe("player.search.message")) }
    }
}
