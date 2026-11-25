package com.edde746.plezy.ui.player

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.gestures.LocalBringIntoViewSpec
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalViewConfiguration
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.height
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.LayoutDirection
import kotlin.math.roundToLong
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.paneTitle
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.presentation.player.DelayState
import com.edde746.plezy.presentation.player.MovableBarButton
import com.edde746.plezy.presentation.player.OptionChoice
import com.edde746.plezy.presentation.player.PictureInPictureRules
import com.edde746.plezy.presentation.player.PictureInPictureVideo
import com.edde746.plezy.presentation.player.PlayerOption
import com.edde746.plezy.presentation.player.PlayerOptionId
import com.edde746.plezy.presentation.player.PlayerUiState
import com.edde746.plezy.presentation.player.SpeedControl
import com.edde746.plezy.presentation.player.SubtitleLanguage
import com.edde746.plezy.presentation.player.TrackItem
import com.edde746.plezy.presentation.probeName
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.components.Badge
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.SheetOption
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.SCROLL_EDGE_FADE
import com.edde746.plezy.ui.components.hidesRowsAbove
import com.edde746.plezy.ui.components.hidesRowsBelow
import com.edde746.plezy.ui.components.scrollEdgeFades
import com.edde746.plezy.ui.focus.StayInViewSpec
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.contentDirection
import com.edde746.plezy.ui.watch.WatchSessionSheet
import kotlin.math.min

/** Panels over bright or HDR video stay opaque: a translucent one loses its text. */
internal val PanelShape = RoundedCornerShape(20.dp)

/**
 * [menu] in a [PlezySheet]: a bottom sheet on upright phones and tablets, docked along the right edge at full height on
 * one held on its side, on TV and (the chapters, the queue, the shaders, the file info and the subtitle search) on the
 * desktop, headed by one line: the page's back button and title, the Chapters and Queue tabs where the page has both
 * (no title repeating the tab picked), else the menu's title. The selected entry takes focus as it opens, so a remote
 * continues from there; a tap outside or a drag down close it, and so does Back, except on a page, which Back leaves
 * for the menu it opened from (an option's page for the options, a subtitle language for More subtitles, More
 * subtitles and the subtitle search for the subtitles: the store's Back; a back button beside the page's title does
 * the same). A menu that follows in the same sheet (a delay control opened from a track menu, a page, the menu it came
 * from) takes focus on its first button, its selected entry (else its first), or the entry it came back from, as it
 * replaces the one before ([FocusOnChange]).
 * Once the store has closed the menu ([visible] false) the sheet slides away showing it as it was left (the pick
 * checked). Keys nothing in the sheet took go to [onKey] (the player's: Backspace outside the search's text field).
 */
@Composable
internal fun PlayerMenuSheet(
    menu: PlayerMenu,
    visible: Boolean,
    state: PlayerUiState,
    onCommand: (PlayerCommand) -> Unit,
    onKey: (KeyEvent) -> Boolean,
) {
    val initial = remember(menu) { FocusRequester() }
    val pages = remember { PageMemory() }
    if (visible) pages.show(menu, state) else pages.forget()
    val title = pages.title
    val queueTab = remember(menu) { mutableStateOf(state.chapters.isEmpty()) }
    val tabs = menu == PlayerMenu.CONTENT_STRIP && state.chapters.isNotEmpty() && state.queue.isNotEmpty()
    // A page shows a back button beside its title on every device, as the library sheets' pages do; Back does the same.
    val pageHeader = menu.back != null
    val headerStyle = if (LocalWindowLayout.current.formFactor == FormFactor.TV) MaterialTheme.typography.headlineSmall else MaterialTheme.typography.titleLarge
    // A page's header line is as tall as a menu's title, so its title and list start where the menu's did.
    val titleLine = with(LocalDensity.current) { headerStyle.lineHeight.toDp() }
    // The app's overlay host composes the sheet's content at its root, outside the player: the player's own locals
    // (the top bar's moved buttons, picture in picture) go along with it.
    val moved = LocalMovedBarButtons.current
    val pip = LocalPictureInPictureHost.current
    val pipFailed = LocalPictureInPictureFailed.current
    PlezySheet(
        onDismiss = { onCommand(PlayerCommand.CloseMenu) },
        modifier = Modifier.onKeyEvent(onKey),
        // The room's session sheet heads its pages itself.
        title = if (pageHeader || tabs || menu == PlayerMenu.WATCH_TOGETHER) null else title,
        visible = visible,
        initialFocus = initial,
        probe = "player.menu",
        onBack = { onCommand(if (menu.back != null) PlayerCommand.Back else PlayerCommand.CloseMenu) },
        label = if (tabs) state.menuTitle(if (queueTab.value) PlayerMenu.QUEUE else PlayerMenu.CHAPTERS) else title,
        header = when {
            tabs -> ({ StripTabs(queueTab) })
            pageHeader -> ({ PageHeader(title, headerStyle, onCommand, Modifier.height(titleLine)) })
            else -> null
        },
        dockInLandscape = menu.docksInLandscape,
    ) {
        CompositionLocalProvider(LocalMovedBarButtons provides moved, LocalPictureInPictureHost provides pip, LocalPictureInPictureFailed provides pipFailed) {
            // The sheet focuses the menu it opens with; one that follows in it takes focus here, in the sheet's composition.
            FocusOnChange(menu, initial, onOpen = false)
            PlayerMenuContent(menu, state, initial, pages, queueTab.value, onCommand, Modifier.weight(1f, fill = false))
        }
    }
}

/**
 * Focus to [initial] in the change that shows [menu] in place of another, and as the first shows with [onOpen]: the
 * entry that had focus went with the menu before, and until focus is placed nothing has it, so a key pressed or
 * released meanwhile reaches nothing. An effect or the next frame would place it after the input already waiting (the
 * release of the Escape that went back to the options, so the player took Escape for still held). An empty page has
 * nothing to focus.
 */
@Composable
private fun FocusOnChange(menu: PlayerMenu, initial: FocusRequester, onOpen: Boolean) {
    val shown = remember { arrayOfNulls<PlayerMenu>(1) }
    SideEffect {
        if (shown[0] != menu && (onOpen || shown[0] != null)) initial.requestFocus()
        shown[0] = menu
    }
}

/**
 * The open menu as a panel of its own (desktop, anchored above its button by the player; the chapters, the queue and the
 * pages that need the room dock in a [PlayerMenuSheet] instead): its title (a page with a back button to the menu it
 * opened from) and entries. The selected entry takes focus as it opens, so the arrow keys continue from there; back
 * from a page, the entry that opened it ([pages], the player's, which knows the docked pages too). A screen reader
 * announces it as a pane titled by the menu (the player hides its controls from it meanwhile). Its width is
 * [panelWidth].
 */
@Composable
internal fun PlayerMenuPanel(
    menu: PlayerMenu,
    state: PlayerUiState,
    pages: PageMemory,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier = Modifier,
) {
    val initial = remember(menu) { FocusRequester() }
    val title = pages.title
    Surface(
        modifier
            .width(panelWidth(state))
            .semantics {
                paneTitle = title
                isTraversalGroup = true
            },
        shape = PanelShape,
        color = PlezyColors.Surface,
        contentColor = PlezyColors.OnVideo,
    ) {
        Column(Modifier.padding(horizontal = 8.dp, vertical = 8.dp)) {
            when {
                // The room's session sheet heads its pages itself.
                menu == PlayerMenu.WATCH_TOGETHER -> Unit
                menu.back != null -> PageHeader(title, MaterialTheme.typography.titleSmall, onCommand)
                else -> Text(
                    title,
                    style = MaterialTheme.typography.titleSmall,
                    color = PlezyColors.OnVideoMuted,
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                )
            }
            PlayerMenuContent(menu, state, initial, pages, queueTab = state.chapters.isEmpty(), onCommand, Modifier.weight(1f, fill = false))
        }
    }
    FocusOnChange(menu, initial, onOpen = true)
}

/**
 * The desktop panel's width, one for every menu: 340 dp, wider (up to 440 dp) where an option of the settings or the
 * audio menu needs it to show on one line whole: its title, then its value and chevron or its switch. A value counts
 * at its widest form ([PlayerOption.valueForms]), so the sleep timer's countdown never moves the width. Past 440 dp a
 * value ends in "…" and a switch's title wraps.
 */
@Composable
private fun panelWidth(state: PlayerUiState): Dp {
    val measurer = rememberTextMeasurer()
    val titleStyle = MaterialTheme.typography.bodyLarge
    val valueStyle = MaterialTheme.typography.bodyMedium
    val density = LocalDensity.current
    // Each row's title, its values (none for a switch) and whether it ends in a chevron.
    val rows = (state.options + state.audioOptions).map { option ->
        Triple(option.label, if (option.toggle != null) emptyList() else option.valueForms.ifEmpty { listOf(option.value) }, option.page != null)
    }
    val widest = remember(rows, titleStyle, valueStyle, density) {
        fun width(text: String, style: TextStyle) = with(density) { measurer.measure(text, style, maxLines = 1).size.width.toDp() }
        rows.maxOfOrNull { (title, values, chevron) ->
            // After the title: the gap, the adjusted mark and its gap, then the switch, or the value and the chevron.
            val end = if (values.isEmpty()) 52.dp else values.maxOf { width(it, valueStyle) } + if (chevron) 32.dp else 0.dp
            width(title, titleStyle) + 30.dp + end
        } ?: 0.dp
    }
    // Before the title: the panel's and the row's padding, the icon and its gap.
    return (widest + 80.dp).coerceIn(340.dp, 440.dp)
}

/**
 * What the menu showed before, while it stays open: back on the menu a page opened from, focus returns to the entry
 * that opened it (an option, More subtitles, a language). It keeps the title and the subtitle language of the menu that
 * showed last, which a sheet sliding away goes on showing.
 */
internal class PageMemory {
    private var shown: PlayerMenu? = null

    /** The menu shown before the one showing. */
    var from: PlayerMenu? = null
        private set

    /** The title of the menu as it showed last ([PlayerUiState.menuTitle]). */
    var title: String = ""
        private set

    /** The language of [PlayerMenu.SUBTITLE_LANGUAGE]'s page as it showed last. */
    var language: SubtitleLanguage? = null
        private set

    fun show(menu: PlayerMenu, state: PlayerUiState) {
        if (menu != shown) {
            from = shown
            shown = menu
        }
        title = state.menuTitle(menu)
        if (menu == PlayerMenu.SUBTITLE_LANGUAGE) language = state.subtitleLanguage
    }

    /** The menu closed: the next one opens from none. */
    fun forget() {
        shown = null
        from = null
    }
}

/**
 * A page's title with a back button to the menu it opened from (the store's Back). The button stands out of a [modifier]
 * line lower than itself, centred on it, and keeps clear of the title as focus grows it on TV.
 */
@Composable
private fun PageHeader(title: String, style: TextStyle, onCommand: (PlayerCommand) -> Unit, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        PlayerButton(
            PlezyIcons.ArrowBack,
            T.nav.back,
            onClick = { onCommand(PlayerCommand.Back) },
            modifier = Modifier.wrapContentHeight(unbounded = true),
            probe = "player.menu.back",
        )
        Text(title, style = style, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/**
 * A track list (the audio's with its delay and the audio settings as its last entries; the subtitles' with More
 * subtitles, the subtitle search and the delay), the speeds, a delay control, the languages of More subtitles, one
 * language's subtitles, the settings, an option's page, the version and quality page, the chapters, the queue, both
 * together ([queueTab]: the queue's tab is the one picked), the subtitle search, the file info or the room's session
 * sheet.
 */
@Composable
private fun PlayerMenuContent(
    menu: PlayerMenu,
    state: PlayerUiState,
    initial: FocusRequester,
    pages: PageMemory,
    queueTab: Boolean,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier,
) {
    when (menu) {
        PlayerMenu.AUDIO -> {
            // While the server transcodes, its tracks (the source's) in place of the stream's.
            val source = state.sourceAudioTracks.isNotEmpty()
            // Back from an audio setting's page, focus returns to its row.
            val from = pages.from
            val backFromPage = state.audioOptions.any { it.page != null && it.page == from }
            TrackList(
                if (source) state.sourceAudioTracks else state.audioTracks,
                select = { track ->
                    if (source) PlayerCommand.SelectSourceTrack(TrackKind.AUDIO, track.id?.toInt()) else PlayerCommand.SelectTrack(TrackKind.AUDIO, track.id)
                },
                second = false,
                initial,
                focusSelected = !backFromPage,
                onCommand,
                modifier,
            ) {
                DelayEntry(state.audioDelay, onCommand)
                state.audioOptions.forEach { option ->
                    OptionEntry(option, onCommand, if (backFromPage && option.page == from) Modifier.focusRequester(initial) else Modifier)
                }
            }
        }
        PlayerMenu.SUBTITLES -> {
            // Back from More subtitles or the search, focus returns to its entry.
            val from = pages.from
            val backFromPage = from == PlayerMenu.MORE_SUBTITLES || from == PlayerMenu.SUBTITLE_SEARCH
            TrackList(
                state.subtitleTracks,
                select = { PlayerCommand.SelectTrack(TrackKind.SUBTITLE, it.id) },
                second = true,
                initial,
                focusSelected = !backFromPage,
                onCommand,
                modifier,
            ) {
                if (state.moreSubtitles.isNotEmpty()) {
                    PageEntry(
                        PlezyIcons.Subtitles,
                        T.player.menu.moreSubtitles,
                        state.moreSubtitlesCount,
                        Modifier.layoutProbe("player.menu.more").then(if (from == PlayerMenu.MORE_SUBTITLES) Modifier.focusRequester(initial) else Modifier),
                    ) { onCommand(PlayerCommand.OpenMenu(PlayerMenu.MORE_SUBTITLES)) }
                }
                if (state.subtitleSearch != null) {
                    PageEntry(
                        PlezyIcons.Search,
                        T.videoControls.searchSubtitles,
                        value = "",
                        Modifier.layoutProbe("player.menu.search").then(if (from == PlayerMenu.SUBTITLE_SEARCH) Modifier.focusRequester(initial) else Modifier),
                    ) { onCommand(PlayerCommand.OpenMenu(PlayerMenu.SUBTITLE_SEARCH)) }
                }
                DelayEntry(state.subtitleDelay, onCommand)
            }
        }
        PlayerMenu.SPEED -> {
            val choices = state.openOption?.choices.orEmpty()
            // Back from the custom speed, focus returns to Custom, its last entry.
            val focused = if (pages.from == PlayerMenu.CUSTOM_SPEED) choices.lastIndex else state.selectedEntry
            ChoiceList(choices, focused, initial, onCommand, modifier, contentLabels = false)
        }
        PlayerMenu.CUSTOM_SPEED -> CustomSpeedControl(state.customSpeed, initial, onCommand)
        PlayerMenu.SUBTITLE_DELAY -> DelayControl(state.subtitleDelay, initial, onCommand)
        PlayerMenu.AUDIO_DELAY -> DelayControl(state.audioDelay, initial, onCommand)
        PlayerMenu.MORE_SUBTITLES -> {
            val backFrom = if (pages.from == PlayerMenu.SUBTITLE_LANGUAGE) pages.language?.key else null
            LanguageList(state.moreSubtitles, backFrom, initial, onCommand, modifier)
        }
        PlayerMenu.SUBTITLE_LANGUAGE -> ChoiceList(pages.language?.subtitles.orEmpty(), state.selectedEntry, initial, onCommand, modifier, contentLabels = true)
        PlayerMenu.OPTIONS -> OptionList(state, LocalMovedBarButtons.current.buttons, pages.from, initial, onCommand, modifier)
        PlayerMenu.AUDIO_OUTPUT -> {
            val outputs = state.openOption?.choices.orEmpty()
            if (outputs.isEmpty()) {
                SheetMessage(T.videoControls.noAudioDevicesAvailable, modifier)
            } else {
                // The outputs are the devices' own names (one someone gave a headset), "System output" aside.
                ChoiceList(outputs, state.selectedEntry, initial, onCommand, modifier, contentLabels = true)
            }
        }
        PlayerMenu.VIDEO_FIT, PlayerMenu.ZOOM, PlayerMenu.AUDIO_CHANNELS, PlayerMenu.DOLBY_VISION_CONVERSION, PlayerMenu.HTTP_STATUS -> ChoiceList(
            state.openOption?.choices.orEmpty(),
            state.selectedEntry,
            initial,
            onCommand,
            modifier,
            contentLabels = false,
        )
        PlayerMenu.SLEEP_TIMER -> SleepTimerPage(state.openOption, state.sleepTimer, initial, onCommand, modifier)
        PlayerMenu.SHADERS -> ShaderList(state.openOption, state.selectedEntry, initial, onCommand, modifier)
        PlayerMenu.WATCH_TOGETHER -> state.watch?.let { WatchSessionSheet(it, initial, onCommand, modifier) }
        PlayerMenu.SUBTITLE_SEARCH -> SubtitleSearchSheet(state.subtitleSearch, initial, onCommand, modifier)
        PlayerMenu.VERSIONS -> VersionsPage(state.versions, initial, onCommand, modifier)
        PlayerMenu.FILE_INFO -> FileInfoSheet(state.fileInfo, initial, modifier)
        PlayerMenu.CHAPTERS -> ChapterList(state.chapters, playing = !state.paused, initial, onCommand, modifier)
        PlayerMenu.QUEUE -> QueueList(state.queue, playing = !state.paused, initial, onCommand, modifier)
        PlayerMenu.CONTENT_STRIP -> {
            // Only the tab showing takes the entry focus starts on.
            val elsewhere = remember { FocusRequester() }
            StripPages(
                queueTab,
                modifier,
                chapters = { ChapterList(state.chapters, playing = !state.paused, if (queueTab) elsewhere else initial, onCommand, Modifier) },
                queue = { QueueList(state.queue, playing = !state.paused, if (queueTab) initial else elsewhere, onCommand, Modifier) },
            )
        }
        // The player opens Audio and Subtitles, each its own list, in place of the two-column tracks sheet.
        PlayerMenu.TRACKS -> Unit
    }
}

/**
 * The chapters and the queue of the page with both tabs: both lists measured and only [queueTab]'s placed, so the page
 * is as tall as the taller list whichever tab shows and a tab never resizes the sheet. The other list, never placed,
 * draws nothing and takes no touch or focus.
 */
@Composable
private fun StripPages(queueTab: Boolean, modifier: Modifier, chapters: @Composable () -> Unit, queue: @Composable () -> Unit) {
    Layout(listOf(chapters, queue), modifier) { (chapterList, queueList), constraints ->
        val (shown, other) = if (queueTab) queueList to chapterList else chapterList to queueList
        val otherHeight = other.maxOfOrNull { it.measure(constraints.copy(minHeight = 0)).height } ?: 0
        val tallest = otherHeight.coerceIn(constraints.minHeight, constraints.maxHeight)
        val placeables = shown.map { it.measure(constraints.copy(minHeight = tallest)) }
        val width = placeables.maxOfOrNull { it.width } ?: constraints.minWidth
        val height = placeables.maxOfOrNull { it.height } ?: tallest
        layout(width, height) { placeables.forEach { it.place(0, 0) } }
    }
}

/**
 * The settings, one row each: first the top bar's buttons it has no room for ([moved], in the bar's order: rotation
 * lock, fit, picture in picture, screen lock), and Lock screen where the bar has no lock button (a tablet), the bar
 * repeated nowhere else; then the options in the store's order ([OptionEntry]). Focus starts on the option whose page
 * [lastPage] was (back from it), else on the first.
 */
@Composable
private fun OptionList(
    state: PlayerUiState,
    moved: Set<MovableBarButton>,
    lastPage: PlayerMenu?,
    initial: FocusRequester,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier,
) {
    val options = state.options
    val focused = options.indexOfFirst { it.page != null && it.page == lastPage }.coerceAtLeast(0)
    val handheld = LocalWindowLayout.current.formFactor == FormFactor.HANDHELD
    val pip = LocalPictureInPictureHost.current
    val pipFailed = LocalPictureInPictureFailed.current
    val scope = rememberCoroutineScope()
    MenuList(modifier) {
        val locked = state.rotationLocked
        if (MovableBarButton.ROTATION_LOCK in moved && locked != null) {
            OptionAction(
                if (locked) PlezyIcons.ScreenLockRotation else PlezyIcons.ScreenRotation,
                if (locked) T.videoControls.unlockRotation else T.videoControls.lockRotation,
                onClick = { onCommand(PlayerCommand.ToggleRotationLock) },
                Modifier.layoutProbe("player.option.rotation"),
            )
        }
        val fit = state.videoFit ?: options.firstOrNull { it.id == PlayerOptionId.VIDEO_FIT }
        val fitPage = fit?.page
        if (MovableBarButton.VIDEO_FIT in moved && fit != null && fitPage != null) {
            OptionRow(fit, onClick = { onCommand(PlayerCommand.OpenMenu(fitPage)) }, Modifier.layoutProbe("player.option.${fit.id.probeName}"))
        }
        if (MovableBarButton.PICTURE_IN_PICTURE in moved && pip != null) {
            OptionAction(
                PlezyIcons.PictureInPicture,
                T.videoControls.pipButton,
                onClick = {
                    scope.launch { PictureInPictureRules.toggle(pip, video = { PictureInPictureVideo() }, prepare = {}, restore = {}, report = pipFailed) }
                },
                Modifier.layoutProbe("player.option.pip"),
            )
        }
        state.lockLabel?.takeIf { !handheld || MovableBarButton.SCREEN_LOCK in moved }?.let { label ->
            // Locking closes the menu with the controls.
            OptionAction(PlezyIcons.Lock, label, onClick = { onCommand(PlayerCommand.LockScreen) }, Modifier.layoutProbe("player.option.lock"))
        }
        options.forEachIndexed { index, option ->
            OptionEntry(option, onCommand, if (index == focused) Modifier.focusRequester(initial) else Modifier)
        }
    }
}

/**
 * An option's row (`player.option.<id>`): an option with a page shows its value and opens the page; a switch flips in
 * place; a row to read (how the system renders the audio) does nothing. A value away from its default is marked
 * ([PlayerOption.adjusted]).
 */
@Composable
private fun OptionEntry(option: PlayerOption, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    val rowModifier = Modifier.layoutProbe("player.option.${option.id.probeName}").then(modifier)
    val page = option.page
    val toggle = option.toggle
    when {
        page != null -> OptionRow(option, onClick = { onCommand(PlayerCommand.OpenMenu(page)) }, rowModifier)
        toggle != null -> OptionSwitch(
            option.id.icon,
            option.label,
            option.on == true,
            adjustedProbe = if (option.adjusted) "player.option.${option.id.probeName}.adjusted" else null,
            onToggle = { onCommand(toggle) },
            rowModifier,
            detail = option.detail,
            enabled = option.enabled,
        )
        // A row to read (how the system renders the audio): focusable, so the remote can reach it, and inert.
        else -> OptionRow(option, onClick = {}, rowModifier, chevron = false)
    }
}

private val PlayerOptionId.icon
    get() = when (this) {
        PlayerOptionId.WATCH_TOGETHER -> PlezyIcons.Groups
        PlayerOptionId.VIDEO_FIT -> PlezyIcons.AspectRatio
        PlayerOptionId.ZOOM -> PlezyIcons.ZoomIn
        PlayerOptionId.SHADERS -> PlezyIcons.AutoFixHigh
        PlayerOptionId.SLEEP_TIMER -> PlezyIcons.Bedtime
        PlayerOptionId.AUTO_PLAY_NEXT -> PlezyIcons.PlaylistPlay
        PlayerOptionId.AUDIO_OUTPUT -> PlezyIcons.Speaker
        PlayerOptionId.AUDIO_NORMALIZATION -> PlezyIcons.GraphicEq
        PlayerOptionId.AUDIO_CHANNELS -> PlezyIcons.SurroundSound
        PlayerOptionId.SPEED -> PlezyIcons.Speed
        PlayerOptionId.VERSIONS -> PlezyIcons.VideoLibrary
        PlayerOptionId.HDR, PlayerOptionId.HDR_TONE_MAPPING -> PlezyIcons.LightMode
        PlayerOptionId.AUDIO_RENDERING -> PlezyIcons.Speaker
        PlayerOptionId.AMBIENT_LIGHTING -> PlezyIcons.BlurOn
        PlayerOptionId.PLAYBACK_INFO -> PlezyIcons.ShowChart
        PlayerOptionId.FILE_INFO -> PlezyIcons.Info
        PlayerOptionId.DOLBY_VISION_CONVERSION -> PlezyIcons.LightMode
        PlayerOptionId.HTTP_STATUS -> PlezyIcons.Info
    }

/**
 * An option with a page: its icon and label, its value (marked when adjusted) and, with [chevron], a chevron ([ValueLine]).
 * The audio output's value is a device's own name, which takes its direction from its first letter; the other values
 * are ours.
 */
@Composable
private fun OptionRow(option: PlayerOption, onClick: () -> Unit, modifier: Modifier, chevron: Boolean = true) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight),
        shape = MaterialTheme.shapes.medium,
        color = Color.Transparent,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        ValueLine(option.id.icon, option.label, chevron) {
            if (option.adjusted) AdjustedMark("player.option.${option.id.probeName}.adjusted")
            val content = LocalContentColor.current
            val style = MaterialTheme.typography.bodyMedium
            Text(
                option.value,
                style = if (option.id == PlayerOptionId.AUDIO_OUTPUT) style.contentDirection() else style,
                color = if (option.adjusted) content else content.copy(alpha = 0.6f),
                maxLines = 1,
                modifier = Modifier.weight(1f, fill = false),
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

/**
 * A row with a value: its icon, its [label] and its [value], then a chevron where [chevron]. The label keeps one line
 * at its full width; the value takes what's left at the row's end and ends in "…" where it doesn't fit. Only a label
 * too long for the row by itself wraps ([LabelFirst]).
 */
@Composable
private fun ValueLine(icon: ImageVector?, label: String, chevron: Boolean, value: @Composable RowScope.() -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (icon != null) Icon(icon, contentDescription = null, Modifier.size(20.dp))
        LabelFirst(
            label = { Text(label, style = MaterialTheme.typography.bodyLarge, maxLines = 2, overflow = TextOverflow.Ellipsis) },
            value = { Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp), content = value) },
            Modifier.weight(1f),
        )
        if (chevron) Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.size(20.dp))
    }
}

/**
 * [label] at the start, measured first, and [value] at the end in what's left after a 12 dp gap; both centred on the
 * line. The label takes its whole width on one line, short of the room the value needs to show something (its own
 * width, up to 32 dp: "Off", "No…"); only a label longer than that wraps, at that width (a long language on a narrow
 * phone).
 */
@Composable
private fun LabelFirst(label: @Composable () -> Unit, value: @Composable () -> Unit, modifier: Modifier) {
    Layout(listOf(label, value), modifier) { (labels, values), constraints ->
        val gap = 12.dp.roundToPx()
        val loose = constraints.copy(minWidth = 0, minHeight = 0)
        val glimpse = minOf(values.single().maxIntrinsicWidth(Constraints.Infinity), 32.dp.roundToPx())
        val start = labels.single().measure(loose.copy(maxWidth = (constraints.maxWidth - gap - glimpse).coerceAtLeast(0)))
        val end = values.single().measure(loose.copy(maxWidth = (constraints.maxWidth - start.width - gap).coerceAtLeast(0)))
        val width = constraints.maxWidth
        val height = maxOf(start.height, end.height).coerceIn(constraints.minHeight, constraints.maxHeight)
        layout(width, height) {
            start.placeRelative(0, (height - start.height) / 2)
            end.placeRelative(width - end.width, (height - end.height) / 2)
        }
    }
}

/** The mark of an option away from its default, under the harness name [probe]. */
@Composable
private fun AdjustedMark(probe: String) {
    Box(Modifier.size(6.dp).background(LocalContentColor.current, CircleShape).layoutProbe(probe))
}

/** An action: its icon and label; the whole row does it. */
@Composable
private fun OptionAction(icon: ImageVector, label: String, onClick: () -> Unit, modifier: Modifier) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight),
        shape = MaterialTheme.shapes.medium,
        color = Color.Transparent,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        OptionLine(icon, label, adjustedProbe = null) {}
    }
}

/** A switch: its icon and label, and the switch (marked when [adjustedProbe] is set); the whole row flips it. */
@Composable
private fun OptionSwitch(
    icon: ImageVector,
    label: String,
    on: Boolean,
    adjustedProbe: String?,
    onToggle: () -> Unit,
    modifier: Modifier,
    detail: String? = null,
    enabled: Boolean = true,
) {
    PlezyToggleSurface(
        checked = on,
        onCheckedChange = { onToggle() },
        modifier = modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight),
        color = Color.Transparent,
        enabled = enabled,
    ) {
        OptionLine(icon, label, adjustedProbe, detail) { RowSwitch(on) }
    }
}

/**
 * A row's icon, label (with [detail] as a second line under it) and, with [adjustedProbe] (an option away from its
 * default), the adjusted mark; then [trailing].
 */
@Composable
private fun OptionLine(icon: ImageVector, label: String, adjustedProbe: String?, detail: String? = null, trailing: @Composable () -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(icon, contentDescription = null, Modifier.size(20.dp))
        Column(Modifier.weight(1f)) {
            Text(label, style = MaterialTheme.typography.bodyLarge, maxLines = 2, overflow = TextOverflow.Ellipsis)
            if (detail != null) {
                Text(
                    detail,
                    style = MaterialTheme.typography.bodySmall,
                    color = PlezyColors.MutedContent,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (adjustedProbe != null) AdjustedMark(adjustedProbe)
        trailing()
    }
}

/**
 * The languages of More subtitles, each with how many subtitles it has, opening its page. Focus starts on the language
 * whose page [backFrom] (its key) was (back from it), else on the first.
 */
@Composable
private fun LanguageList(
    languages: List<SubtitleLanguage>,
    backFrom: String?,
    initial: FocusRequester,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier,
) {
    val focused = languages.indexOfFirst { it.key == backFrom }.coerceAtLeast(0)
    MenuList(modifier) {
        languages.forEachIndexed { index, language ->
            PageEntry(icon = null, language.label, language.count, Modifier.menuItem(index, index == focused, initial)) {
                onCommand(PlayerCommand.OpenSubtitleLanguage(language.key))
            }
        }
    }
}

/**
 * An option's page or a subtitle language's: its choices, the selected one checked, each with its detail line; a choice
 * that opens a page (the speeds' Custom) with a chevron. The selected one takes focus as it opens, else the first.
 * [contentLabels]: whether the choices' labels are content text (an external subtitle's title, a device's name), which
 * takes its direction from its first letter ([contentDirection]).
 */
@Composable
private fun ChoiceList(
    choices: List<OptionChoice>,
    focused: Int,
    initial: FocusRequester,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier,
    contentLabels: Boolean,
) {
    MenuList(modifier) {
        choices.forEachIndexed { index, choice ->
            SheetOption(
                choice.label,
                onClick = { onCommand(choice.command) },
                modifier = Modifier.menuItem(index, index == focused, initial),
                selected = choice.selected,
                detail = choice.detail,
                contentLabel = contentLabels,
                badge = if (choice.command is PlayerCommand.OpenMenu) ({ Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.size(20.dp)) }) else null,
            )
        }
    }
}

/**
 * The Shaders page: its presets as an option page's choices ([ChoiceList]), each imported one with a delete button
 * beside it that asks first, then where the device has file dialogs ([PlayerOption.importLabel]) a last entry that
 * imports a shader through the system's open dialog. The imported shaders' names are their files', content text.
 * Harness names: `player.menu.item.<i>.delete`, `player.menu.import`, `player.menu.delete.<confirm|cancel>`.
 */
@Composable
private fun ShaderList(option: PlayerOption?, focused: Int, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    val platform = LocalPlezyPlatform.current
    var deleting by remember { mutableStateOf<OptionChoice?>(null) }
    MenuList(modifier) {
        option?.choices.orEmpty().forEachIndexed { index, choice ->
            val delete = choice.delete
            val row = @Composable { rowModifier: Modifier ->
                SheetOption(
                    choice.label,
                    onClick = { onCommand(choice.command) },
                    modifier = rowModifier.menuItem(index, index == focused, initial),
                    selected = choice.selected,
                    detail = choice.detail,
                    contentLabel = delete != null,
                )
            }
            if (delete == null) {
                row(Modifier)
            } else {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    row(Modifier.weight(1f))
                    PlayerButton(
                        PlezyIcons.Delete,
                        T.player.options.shader.deleteLabel(choice.label),
                        onClick = { deleting = choice },
                        probe = "player.menu.item.$index.delete",
                    )
                }
            }
        }
        option?.importLabel?.let { label ->
            OptionAction(
                PlezyIcons.Add,
                label,
                onClick = {
                    platform.openFile(
                        opened = { name, text -> onCommand(PlayerCommand.ImportShader(name, text)) },
                        failed = { onCommand(PlayerCommand.ShaderImportFailed) },
                    )
                },
                Modifier.layoutProbe("player.menu.import"),
            )
        }
    }
    deleting?.let { choice ->
        val strings = T.player.options.shader
        ConfirmDialog(
            strings.deleteTitle(choice.label),
            null,
            strings.delete,
            onConfirm = {
                deleting = null
                choice.delete?.let(onCommand)
            },
            onCancel = { deleting = null },
            probe = "player.menu.delete",
            cancelLabel = strings.cancel,
        )
    }
}

/**
 * The tracks, then a divider and [footer] (More subtitles, the search, the delay) after them, all in one list that
 * scrolls when it doesn't fit: nothing pinned under the tracks takes the list's room, and a list cut by the sheet's edge
 * shows its cut row. A pick is [select]'s command. The selected track takes focus and comes to the list's middle as the
 * menu opens (a forced track the player picked by itself too, however far down), unless [focusSelected] is false (an
 * entry of [footer] takes it). A forced track is badged Forced. With [second] (the subtitles) a row's second action (a
 * long press, a held Select, a right-click or the menu key) shows its track as the second subtitle or takes it away
 * ([PlayerCommand.ToggleSecondSubtitle]); the second's row has a "2" badge.
 */
@Composable
private fun TrackList(
    tracks: List<TrackItem>,
    select: (TrackItem) -> PlayerCommand,
    second: Boolean,
    initial: FocusRequester,
    focusSelected: Boolean,
    onCommand: (PlayerCommand) -> Unit,
    modifier: Modifier,
    footer: @Composable () -> Unit,
) {
    val selected = if (focusSelected) tracks.indexOfFirst { it.selected } else -1
    CentredList(
        tracks.size,
        selected,
        modifier,
        footer = {
            HorizontalDivider(Modifier.padding(vertical = 6.dp), color = PlezyColors.Hairline)
            footer()
        },
    ) { index, rowModifier ->
        val track = tracks[index]
        // Every subtitle row has the second action, so a held Select never falls through to a pick; the store
        // decides.
        val toggleSecond = { onCommand(PlayerCommand.ToggleSecondSubtitle(track.id)) }
        SheetOption(
            track.label,
            onClick = { onCommand(select(track)) },
            modifier = rowModifier.menuItem(index, index == selected, initial)
                .then(if (second) Modifier.menuGestures(toggleSecond) else Modifier),
            selected = track.selected,
            detail = track.detail,
            // A file's track title or our language name ("Track 2" without either, which opens on a letter of
            // the interface's own script in every language we ship).
            contentLabel = true,
            onLongClick = if (second) toggleSecond else null,
            onLongClickLabel = when {
                !second -> null
                track.second || track.id == null -> T.player.track.removeSecond
                track.selected -> null
                else -> T.player.track.showAsSecond
            },
            badge = if (track.second || track.forced) {
                {
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        if (track.forced) Badge(T.player.track.forced)
                        if (track.second) SecondBadge(Modifier.layoutProbe("player.menu.item.$index.second"))
                    }
                }
            } else {
                null
            },
        )
    }
}

/** The second subtitle's mark: "2" in the primary fill, named for screen readers. */
@Composable
internal fun SecondBadge(modifier: Modifier) {
    val name = T.player.track.second
    Badge("2", modifier.clearAndSetSemantics { contentDescription = name }, emphasised = true)
}

/**
 * The entries, scrolling when they don't fit, with room around them for a focused entry's growth. While entries lie past
 * an edge the sheet's surface fades over that edge, so the cut entry reads as more to come rather than as clipped, and a
 * focused entry keeps clear of the fade.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun MenuList(modifier: Modifier, content: @Composable () -> Unit) {
    val reach = LocalPlezyDimens.current.focusReach
    val scroll = rememberScrollState()
    val density = LocalDensity.current
    val reachPx = with(density) { reach.roundToPx() }
    val fade = with(density) { SCROLL_EDGE_FADE.toPx() }
    val platformScroll = LocalBringIntoViewSpec.current
    val stayInView = remember(platformScroll, fade) { StayInViewSpec(platformScroll, before = fade, after = fade) }
    CompositionLocalProvider(LocalBringIntoViewSpec provides stayInView) {
        Column(
            modifier
                .scrollEdgeFades({ scroll.hidesRowsAbove(reachPx) }, { scroll.hidesRowsBelow(reachPx) })
                .verticalScroll(scroll)
                .padding(PaddingValues(vertical = reach)),
        ) { content() }
    }
}

/** Entry [index] of a menu, for the harness; a [focused] one takes focus as the menu opens. */
internal fun Modifier.menuItem(index: Int, focused: Boolean, initial: FocusRequester): Modifier =
    layoutProbe("player.menu.item.$index").then(if (focused) Modifier.focusRequester(initial) else Modifier)

/**
 * An entry that opens a page, its value beside it ([ValueLine]): a track menu's delay and More subtitles, a language of
 * More subtitles (no [icon]).
 */
@Composable
internal fun PageEntry(icon: ImageVector?, label: String, value: String, modifier: Modifier, onClick: () -> Unit) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth().heightIn(min = LocalPlezyDimens.current.controlHeight),
        shape = MaterialTheme.shapes.medium,
        color = Color.Transparent,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        ValueLine(icon, label, chevron = true) {
            Text(
                value,
                style = MaterialTheme.typography.bodyMedium,
                color = PlezyColors.MutedContent,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f, fill = false),
            )
        }
    }
}

/** A track menu's last entry: its delay, with the delay's value, opening the delay's page. */
@Composable
private fun DelayEntry(delay: DelayState, onCommand: (PlayerCommand) -> Unit) {
    PageEntry(PlezyIcons.Timer, delay.title, delay.label, Modifier.layoutProbe("player.menu.delay")) {
        onCommand(PlayerCommand.OpenMenu(delay.menu))
    }
}

/**
 * − value +, a slider of ±[DelayState.limitSeconds] and Reset ([DelayState]): − and + step the delay
 * ([DelayState.stepSeconds]: 10 ms audio, 50 ms subtitles), and held step it by a second every [RepeatMillis] until let
 * go. The slider moves on the same grid and sets the delay where it is let go; with focus, D-pad or arrow left and
 * right step it. Reset (enabled away from zero) puts it back at zero. The buttons disable at the ends of the range;
 * screen readers name − and + by the way they move the delay ("Subtitle delay: earlier"), the slider by the delay's
 * title. Focus starts on the slider. Harness names: `player.delay.decrease`, `player.delay.value`,
 * `player.delay.increase`, `player.delay.slider`, `player.delay.reset`.
 */
@Composable
private fun DelayControl(delay: DelayState, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit) {
    val subtitles = delay.menu == PlayerMenu.SUBTITLE_DELAY
    fun adjust(seconds: Double): PlayerCommand =
        if (subtitles) PlayerCommand.AdjustSubtitleDelay(seconds) else PlayerCommand.AdjustAudioDelay(seconds)
    val reach = LocalPlezyDimens.current.focusReach
    Column(Modifier.fillMaxWidth().padding(vertical = reach + 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            RepeatButton(
                PlezyIcons.Remove,
                delay.decreaseLabel,
                enabled = delay.canDecrease,
                probe = "player.delay.decrease",
                onStep = { onCommand(delay.decrease) },
                onRepeat = { onCommand(adjust(-RepeatSeconds)) },
            )
            Text(
                delay.label,
                style = MaterialTheme.typography.headlineSmall.copy(fontFeatureSettings = "tnum"),
                textAlign = TextAlign.Center,
                modifier = Modifier.width(112.dp).layoutProbe("player.delay.value", reportsFocus = false),
            )
            RepeatButton(
                PlezyIcons.Add,
                delay.increaseLabel,
                enabled = delay.canIncrease,
                probe = "player.delay.increase",
                onStep = { onCommand(delay.increase) },
                onRepeat = { onCommand(adjust(RepeatSeconds)) },
            )
        }
        DelaySlider(delay, initial, onCommand, Modifier.padding(horizontal = 16.dp, vertical = 8.dp))
        PlezyButton(
            T.player.menu.reset,
            onClick = { onCommand(delay.reset) },
            modifier = Modifier.padding(top = 4.dp).layoutProbe("player.delay.reset"),
            style = ButtonStyle.TEXT,
            enabled = delay.canReset,
        )
    }
}

/** The delay's slider ([DelayControl]) on the delay's step grid: while dragged it shows where it is, let go it sets the delay there. */
@Composable
private fun DelaySlider(delay: DelayState, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit, modifier: Modifier) {
    val subtitles = delay.menu == PlayerMenu.SUBTITLE_DELAY
    var dragging by remember { mutableStateOf<Float?>(null) }
    val limit = delay.limitSeconds.toFloat()
    StepSlider(
        value = dragging ?: delay.seconds.toFloat(),
        range = -limit..limit,
        onValueChange = { dragging = ((it / delay.stepSeconds).roundToLong() * delay.stepSeconds).toFloat() },
        onValueChangeFinished = {
            dragging?.let { onCommand(if (subtitles) PlayerCommand.SetSubtitleDelay(it.toDouble()) else PlayerCommand.SetAudioDelay(it.toDouble())) }
            dragging = null
        },
        onStep = { up -> onCommand(if (up) delay.increase else delay.decrease) },
        label = delay.title,
        valueLabel = delay.label,
        probe = "player.delay.slider",
        modifier = modifier.focusRequester(initial),
    )
}

/**
 * The custom speed ([SpeedControl]): − speed +, a slider of the player's whole range and Normal. − and + step the speed
 * ([SpeedControl.step]), and held step it by the speed shortcuts' quarter every [RepeatMillis] until let go. The slider
 * moves on the same grid and sets the speed as it moves; with focus, D-pad or arrow left and right step it. Normal
 * (enabled away from 1×) puts it back. Each change applies at once, as a preset's pick does. Focus starts on the slider.
 * Harness names: `player.speed.decrease`, `player.speed.value`, `player.speed.increase`, `player.speed.slider`,
 * `player.speed.reset`.
 */
@Composable
private fun CustomSpeedControl(speed: SpeedControl, initial: FocusRequester, onCommand: (PlayerCommand) -> Unit) {
    val reach = LocalPlezyDimens.current.focusReach
    Column(Modifier.fillMaxWidth().padding(vertical = reach + 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            RepeatButton(
                PlezyIcons.Remove,
                speed.decreaseLabel,
                enabled = speed.canDecrease,
                probe = "player.speed.decrease",
                onStep = { onCommand(speed.decrease) },
                onRepeat = { onCommand(PlayerCommand.SpeedDown) },
            )
            Text(
                speed.label,
                style = MaterialTheme.typography.headlineSmall.copy(fontFeatureSettings = "tnum"),
                textAlign = TextAlign.Center,
                modifier = Modifier.width(112.dp).layoutProbe("player.speed.value", reportsFocus = false),
            )
            RepeatButton(
                PlezyIcons.Add,
                speed.increaseLabel,
                enabled = speed.canIncrease,
                probe = "player.speed.increase",
                onStep = { onCommand(speed.increase) },
                onRepeat = { onCommand(PlayerCommand.SpeedUp) },
            )
        }
        StepSlider(
            value = speed.speed.toFloat(),
            range = speed.min.toFloat()..speed.max.toFloat(),
            onValueChange = { value ->
                val picked = speed.snapped(value.toDouble())
                if (picked != speed.speed) onCommand(PlayerCommand.SetSpeed(picked))
            },
            onValueChangeFinished = {},
            onStep = { up -> onCommand(if (up) speed.increase else speed.decrease) },
            label = T.player.speed.customTitle,
            valueLabel = speed.label,
            probe = "player.speed.slider",
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp).focusRequester(initial),
        )
        PlezyButton(
            T.player.speed.normal,
            onClick = { onCommand(speed.reset) },
            modifier = Modifier.padding(top = 4.dp).layoutProbe("player.speed.reset"),
            style = ButtonStyle.TEXT,
            enabled = speed.canReset,
        )
    }
}

/**
 * A page's slider (a delay's, the custom speed's): a 3 dp line under a round knob (12 dp, 18 dp with focus). With
 * focus, D-pad or arrow left and right step it ([onStep], up to the right in a left-to-right layout). Screen readers
 * name it by [label] and read [valueLabel].
 */
@Composable
private fun StepSlider(
    value: Float,
    range: ClosedFloatingPointRange<Float>,
    onValueChange: (Float) -> Unit,
    onValueChangeFinished: () -> Unit,
    onStep: (up: Boolean) -> Unit,
    label: String,
    valueLabel: String,
    probe: String,
    modifier: Modifier,
) {
    val rtl = LocalLayoutDirection.current == LayoutDirection.Rtl
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    val colors = SliderDefaults.colors(thumbColor = PlezyColors.Text, activeTrackColor = PlezyColors.Text, inactiveTrackColor = PlezyColors.Hairline)
    Slider(
        value = value,
        onValueChange = onValueChange,
        onValueChangeFinished = onValueChangeFinished,
        valueRange = range,
        interactionSource = interactions,
        thumb = { SliderDefaults.Thumb(interactions, colors = colors, thumbSize = if (focused) DpSize(18.dp, 18.dp) else DpSize(12.dp, 12.dp)) },
        track = { state -> SliderDefaults.Track(state, Modifier.height(3.dp), colors = colors, drawStopIndicator = null, thumbTrackGapSize = 0.dp) },
        modifier = modifier
            .fillMaxWidth()
            .layoutProbe(probe)
            .semantics {
                contentDescription = label
                stateDescription = valueLabel
            }
            .onPreviewKeyEvent { event ->
                val up = when (event.key) {
                    Key.DirectionLeft -> rtl
                    Key.DirectionRight -> !rtl
                    else -> return@onPreviewKeyEvent false
                }
                if (event.type == KeyEventType.KeyDown) onStep(up)
                true
            },
    )
}

/** A held − or + steps the delay by this much, every [RepeatMillis]. */
internal const val RepeatSeconds = 1.0
internal const val RepeatMillis = 200L

/**
 * − or +: a click (or Select) steps once ([onStep]); a press held past the long-press timeout steps by [onRepeat] at once
 * and then every [RepeatMillis] until let go, without the click at its end.
 */
@Composable
private fun RepeatButton(
    icon: ImageVector,
    label: String,
    enabled: Boolean,
    probe: String,
    onStep: () -> Unit,
    onRepeat: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val longPress = LocalViewConfiguration.current.longPressTimeoutMillis
    val repeat by rememberUpdatedState(onRepeat)
    var repeated by remember { mutableStateOf(false) }
    PlayerButton(
        icon,
        label = label,
        onClick = {
            // The release of a held press repeated already.
            if (repeated) repeated = false else onStep()
        },
        modifier = Modifier.pointerInput(enabled) {
            if (!enabled) return@pointerInput
            awaitEachGesture {
                awaitFirstDown(requireUnconsumed = false, pass = PointerEventPass.Initial)
                repeated = false
                val job = scope.launch {
                    delay(longPress)
                    repeated = true
                    while (true) {
                        repeat()
                        delay(RepeatMillis)
                    }
                }
                waitForUpOrCancellation(PointerEventPass.Initial)
                job.cancel()
            }
        },
        probe = probe,
        filled = true,
        enabled = enabled,
    )
}
