package com.edde746.plezy.ui.livetv

import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalViewConfiguration
import androidx.compose.ui.unit.dp
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.MediaHub
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.presentation.browse.PlaceholderKind
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.livetv.recordings.GrabRow
import com.edde746.plezy.presentation.livetv.recordings.RecordingsBody
import com.edde746.plezy.presentation.livetv.recordings.RecordingsStore
import com.edde746.plezy.presentation.livetv.recordings.RuleAction
import com.edde746.plezy.presentation.livetv.whatson.WhatsOnStore
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.HubRow
import com.edde746.plezy.ui.components.ItemMenu
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.rememberHeaderListState
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.settings.RowText
import com.edde746.plezy.ui.theme.LocalAppearance
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlin.time.TimeSource

/**
 * What's On: the servers' discover hubs as rows of posters (an episode as its series' poster). A tap tunes an airing on
 * now, opens a show's schedule or else the program's details; a long press, a held Select, a secondary click or the
 * menu key open its details. Harness names `hub.<id>` (the rows), `liveTv.whatsOn.<hub>.<i>`.
 *
 * @param artwork a server's image path drawn as the given kind.
 */
@Composable
internal fun WhatsOnTab(store: WhatsOnStore, artwork: (serverId: String?, path: String?, kind: ImageKind) -> Artwork?, contentFocus: FocusRequester) {
    val state by store.state.collectAsState()
    val appearance = LocalAppearance.current
    when {
        state.loading -> LoadingState()
        state.emptyText != null -> EmptyState(state.emptyText.orEmpty(), icon = PlezyIcons.LiveTv)
        else -> {
            val hubs = remember(state.hubs) { state.hubs.map { it.toHubUi(artwork) } }
            LazyColumn(Modifier.fillMaxSize().focusRequester(contentFocus), rememberHeaderListState(), contentPadding = PaddingValues(vertical = 8.dp)) {
                items(hubs, key = { it.id }) { hub ->
                    HubRow(hub, appearance, Modifier.padding(bottom = 8.dp), cardModifier = { card ->
                        val index = card.id.substringAfterLast('/').toInt()
                        Modifier
                            .cardActions({ store.tap(hub.id, index) }, { store.longPress(hub.id, index) })
                            .layoutProbe("liveTv.whatsOn.${hubs.indexOf(hub)}.$index")
                    })
                }
            }
        }
    }
    state.details?.let { ProgramDetailsSheet(it, store::closeDetails) }
}

/** [this] hub's items as poster cards: an episode shows its series' poster and title, the episode under it. */
private fun MediaHub.toHubUi(artwork: (serverId: String?, path: String?, kind: ImageKind) -> Artwork?): HubUi =
    HubUi(
        id = id,
        title = title,
        items = items.mapIndexed { index, item -> item.toCard("$id/$index", artwork) },
        shape = CardShape.POSTER,
    )

private fun MediaItem.toCard(id: String, artwork: (serverId: String?, path: String?, kind: ImageKind) -> Artwork?): MediaCardUi {
    val series = grandparentTitle
    return MediaCardUi(
        id = id,
        title = series ?: displayTitle,
        caption = if (series != null) displayTitle else null,
        shape = CardShape.POSTER,
        placeholder = if (series != null || isShow) PlaceholderKind.SHOW else PlaceholderKind.MOVIE,
        artwork = artwork(serverId, grandparentThumbPath ?: thumbPath, ImageKind.POSTER),
    )
}

/**
 * A card's taps for an element whose focus target comes after (a [com.edde746.plezy.ui.components.PosterCard]): a tap or
 * Select runs [onTap]; a long press, Select held for the long-press time, a secondary click or the menu key run
 * [onLongPress].
 */
@Composable
private fun Modifier.cardActions(onTap: () -> Unit, onLongPress: () -> Unit): Modifier {
    val tap by rememberUpdatedState(onTap)
    val long by rememberUpdatedState(onLongPress)
    val holdMillis = LocalViewConfiguration.current.longPressTimeoutMillis
    var pressedAt by remember { mutableStateOf<TimeSource.Monotonic.ValueTimeMark?>(null) }
    return this
        .menuGestures { long() }
        .pointerInput(Unit) { detectTapGestures(onTap = { tap() }, onLongPress = { long() }) }
        .onKeyEvent { event ->
            if (event.key != Key.Enter && event.key != Key.NumPadEnter && event.key != Key.DirectionCenter) return@onKeyEvent false
            when (event.type) {
                KeyEventType.KeyDown -> if (pressedAt == null) pressedAt = TimeSource.Monotonic.markNow()
                KeyEventType.KeyUp -> {
                    val held = pressedAt?.elapsedNow()?.inWholeMilliseconds ?: return@onKeyEvent true
                    pressedAt = null
                    if (held >= holdMillis) long() else tap()
                }
            }
            true
        }
}

/**
 * Scheduled: the "Upcoming" group (a running recording tinted with "Recording now", a failed one marked) and the
 * "Recording rules" group; a recording asks to be cancelled, a rule offers Edit and Delete. A spinner until the first
 * load, else a message under the record icon when there is nothing. Over it the questions, the Edit rule sheet and the
 * rule's menu. Harness names `liveTv.recordings.grab.<i>`, `liveTv.recordings.rule.<i>`, `liveTv.recordings.menu`.
 */
@Composable
internal fun RecordingsTab(store: RecordingsStore, contentFocus: FocusRequester) {
    val state by store.state.collectAsState()
    var tappedRule by remember { mutableStateOf<String?>(null) }
    val ruleFocus = remember { HashMap<String, FocusRequester>() }
    when (val body = state.body) {
        RecordingsBody.Loading -> LoadingState()
        is RecordingsBody.Empty -> EmptyState(body.text, icon = PlezyIcons.Record)
        is RecordingsBody.Lists -> LazyColumn(
            Modifier.fillMaxSize().focusRequester(contentFocus),
            rememberHeaderListState(),
            contentPadding = PaddingValues(start = LocalPlezyDimens.current.screenPadding, end = LocalPlezyDimens.current.screenPadding, bottom = 8.dp, top = LocalPlezyDimens.current.focusReach),
        ) {
            if (body.grabs.isNotEmpty()) {
                item(key = "grabsHeader") { GroupHeader(state.scheduledTitle) }
                item(key = "grabs") {
                    RowGroup {
                        body.grabs.forEachIndexed { index, grab ->
                            val onClick = {
                                tappedRule = null
                                store.tapGrab(grab.id)
                            }
                            GrabTile(grab, groupShape(index, body.grabs.size), onClick, Modifier.layoutProbe("liveTv.recordings.grab.$index"))
                        }
                    }
                }
            }
            if (body.rules.isNotEmpty()) {
                item(key = "rulesHeader") { GroupHeader(state.rulesTitle) }
                item(key = "rules") {
                    RowGroup {
                        body.rules.forEachIndexed { index, rule ->
                            Box {
                                GroupRow(
                                    rule.title,
                                    onClick = {
                                        tappedRule = rule.id
                                        store.tapRule(rule.id)
                                    },
                                    modifier = Modifier.focusRequester(remember(rule.id) { ruleFocus.getOrPut(rule.id) { FocusRequester() } }).layoutProbe("liveTv.recordings.rule.$index"),
                                    shape = groupShape(index, body.rules.size),
                                    subtitle = rule.subtitle,
                                )
                                if (tappedRule == rule.id) RuleMenu(store)
                            }
                        }
                    }
                }
            }
        }
    }
    state.confirmation?.let {
        ConfirmDialog(it.title, it.message, it.confirmText, store::confirm, store::dismissConfirmation, "liveTv.recordings.confirm")
    }
    // The Edit rule sheet or the delete question closed: focus goes back to the rule they were about, if it is still there
    // (the list reloads behind them).
    val overlayOpen = state.recordOptions != null || state.confirmation != null
    LaunchedEffect(overlayOpen) {
        if (overlayOpen) return@LaunchedEffect
        val id = tappedRule ?: return@LaunchedEffect
        withFrameNanos { }
        ruleFocus[id]?.requestFocus()
    }
    state.recordOptions?.let { RecordOptionsSheet(it) }
}

/** The tapped rule's Edit / Delete menu; closed without a pick, the store hears of it a frame later. */
@Composable
private fun RuleMenu(store: RecordingsStore) {
    val state by store.state.collectAsState()
    val menu = state.ruleMenu
    var closing by remember(menu) { mutableStateOf(false) }
    // The menu closes before it runs the picked entry: a pick, once it ran, has cleared the menu.
    LaunchedEffect(closing) {
        if (!closing) return@LaunchedEffect
        withFrameNanos { }
        if (store.state.value.ruleMenu != null) store.chooseRuleAction(null)
    }
    ItemMenu(
        expanded = menu != null && !closing,
        onDismiss = { closing = true },
        entries = menu?.actions.orEmpty().map { action ->
            ItemMenuEntry(
                action.label,
                probe = action.action.name.lowercase(),
                destructive = action.action == RuleAction.DELETE,
                icon = if (action.action == RuleAction.DELETE) PlezyIcons.Delete else PlezyIcons.Edit,
            ) { store.chooseRuleAction(action.action) }
        },
        probe = "liveTv.recordings.menu",
        title = menu?.title,
        contentTitle = true,
    )
}

@Composable
private fun GrabTile(grab: GrabRow, shape: Shape, onClick: () -> Unit, modifier: Modifier) {
    PlezySurface(onClick = onClick, modifier = modifier.fillMaxWidth(), shape = shape, color = if (grab.recording) PlezyColors.SurfaceHighest else PlezyColors.SurfaceHigh, grows = false) {
        Row(
            Modifier.heightIn(min = 56.dp).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            RowText(grab.title, grab.subtitle.takeIf { it.isNotEmpty() }, Modifier.weight(1f))
            grab.pill?.let { StatusPill(it, if (grab.failed) PlezyColors.Error else PlezyColors.Live) }
        }
    }
}
