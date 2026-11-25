package com.edde746.plezy.ui.livetv

import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.style.TextOverflow
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.image.Artwork
import com.edde746.plezy.image.ImageKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.presentation.livetv.LiveTvAction
import com.edde746.plezy.presentation.livetv.LiveTvActionUi
import com.edde746.plezy.presentation.livetv.LiveTvBody
import com.edde746.plezy.presentation.livetv.LiveTvFocusTarget
import com.edde746.plezy.presentation.livetv.LiveTvMessage
import com.edde746.plezy.presentation.livetv.LiveTvScreenFocus
import com.edde746.plezy.presentation.livetv.LiveTvStore
import com.edde746.plezy.presentation.livetv.LiveTvTab
import com.edde746.plezy.presentation.livetv.LiveTvUiState
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.ErrorState
import com.edde746.plezy.ui.components.FILTER_GAP
import com.edde746.plezy.ui.components.FilterChip
import com.edde746.plezy.ui.components.FittingRow
import com.edde746.plezy.ui.components.HeaderAction
import com.edde746.plezy.ui.components.HeaderScaffold
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.MenuChip
import com.edde746.plezy.ui.components.MenuChoice
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.components.TabNavigationEffect
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.use24HourClock
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.navigation.LocalSideNavigation
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens

/**
 * Live TV: its header row ([HeaderScaffold]): the tab chips (Guide, What's On, Scheduled), or where they don't fit
 * (phones) one dropdown chip of them, and the selected tab's actions (search, the favourites filter, reorder favourites,
 * re-evaluate rules, refresh) at its end; under it the selected tab. A spinner while the channels load, the error with
 * Retry, "No channels" without channels or recordings, and in the Guide the favourites' empty state. Over it the guide
 * search, reorder favourites, a program's details and the snackbar. Focus goes where the store says (the chips, the
 * actions, the tab's content, the side navigation); without a side navigation, focus coming in from outside (a phone's
 * first key after a touch) goes into the tab. Harness names `liveTv.tab.<guide|whatsOn|recordings>`,
 * `liveTv.view`, `liveTv.action.<search|favorites|reorder|rules|refresh>`, `liveTv.showAll`, `liveTv.message`.
 */
@Composable
fun LiveTvScreen(app: AppSession, modifier: Modifier = Modifier) {
    val clock24 = use24HourClock()
    val stores = remember(app) { app.liveTv(Route.LiveTv, clock24) } ?: return
    LaunchedEffect(clock24) { stores.setUse24HourClock(clock24) }
    DisposableEffect(stores) {
        stores.screen.setShown(true)
        onDispose { stores.screen.setShown(false) }
    }
    val store = stores.screen
    val ui by store.state.collectAsState()
    val details by stores.details.collectAsState()
    val whatsOn by stores.whatsOn.state.collectAsState()
    val recordings by stores.recordings.state.collectAsState()
    val artwork = remember(app) { { serverId: String?, path: String?, kind: ImageKind -> app.liveTvArtwork(serverId, path, kind) } }

    val tabFocus = remember { FocusRequester() }
    val actionsFocus = remember { FocusRequester() }
    val contentFocus = remember { FocusRequester() }
    val guideFocus = remember { FocusRequester() }
    val showAllFocus = remember { FocusRequester() }
    val searchResult = remember { FocusRequester() }
    // L1 and R1: the previous or next tab, focus on its chip.
    TabNavigationEffect(ui.tabs.map { it.tab }, ui.selectedTab, enabled = ui.body == LiveTvBody.Tabs) { tab ->
        store.selectTab(tab)
        store.focusTabBar()
    }

    // Focus coming into the screen without a side navigation to come from (a phone's first key after a touch, Up from
    // its bottom bar) goes into the shown tab, as the store's Down from the header row does: not to the row's Back.
    val side = LocalSideNavigation.current != null
    val enterTab = Modifier.focusProperties {
        onEnter = {
            if (!side && ui.body == LiveTvBody.Tabs) {
                when {
                    ui.selectedTab != LiveTvTab.GUIDE -> contentFocus.requestFocus()
                    ui.guideEmpty != null -> Unit
                    ui.favoritesEmpty != null -> showAllFocus.requestFocus()
                    else -> guideFocus.requestFocus()
                }
            }
        }
    }.focusGroup()
    Box(modifier.fillMaxSize().then(enterTab)) {
        // While the channels load the row already has its loaded form (the Guide's chip, the others joining it): the tab
        // chips (or, where they don't fit, the tab's dropdown chip) and the tab's actions at the row's end; the title in
        // the chips' place when there are no tabs to show (a failure, no channels).
        val tabs = ui.body == LiveTvBody.Tabs || ui.body == LiveTvBody.Loading
        HeaderScaffold(
            filters = { padding, measuring ->
                if (tabs) {
                    TabChips(ui, store, tabFocus, Modifier.padding(padding), measuring)
                } else {
                    Text(ui.title, Modifier.padding(padding), style = MaterialTheme.typography.titleLarge, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            },
            fitted = if (tabs) ({ padding -> TabMenu(ui, store, tabFocus, Modifier.padding(padding)) }) else null,
            actions = { Actions(ui.actions, store, actionsFocus) },
            // Live TV is pushed over Home.
            onBack = { app.navigator.back() },
        ) {
            when (val body = ui.body) {
                LiveTvBody.Loading -> LoadingState()
                is LiveTvBody.Failed -> ErrorState(body.message, onRetry = store::retry, retryLabel = body.retryLabel)
                is LiveTvBody.Empty -> EmptyState(body.message, icon = PlezyIcons.LiveTv)
                LiveTvBody.Tabs -> when (ui.selectedTab) {
                    LiveTvTab.GUIDE -> {
                        val noChannels = ui.guideEmpty
                        val empty = ui.favoritesEmpty
                        if (noChannels != null) {
                            EmptyState(noChannels, icon = PlezyIcons.LiveTv)
                        } else if (empty != null) {
                            var focused by remember { mutableStateOf(false) }
                            EmptyState(empty.hint, title = empty.title, icon = PlezyIcons.StarBorder) {
                                PlezyButton(
                                    empty.actionLabel,
                                    { store.showAllChannels(focused) },
                                    Modifier.focusRequester(showAllFocus).onFocusChanged { focused = it.isFocused }.layoutProbe("liveTv.showAll"),
                                    style = ButtonStyle.PRIMARY,
                                    icon = PlezyIcons.ListAll,
                                )
                            }
                        } else {
                            GuideTab(
                                stores.guide,
                                logo = { artwork(it.serverId, it.thumb, ImageKind.THUMB) },
                                thumb = { artwork(it.serverId, it.thumb, ImageKind.THUMB) },
                                focusRequester = guideFocus,
                            )
                        }
                    }
                    LiveTvTab.WHATS_ON -> WhatsOnTab(stores.whatsOn, artwork, contentFocus)
                    LiveTvTab.RECORDINGS -> RecordingsTab(stores.recordings, contentFocus)
                }
            }
        }
        Messages(
            listOf(
                ui.message to store::messageShown,
                whatsOn.message to stores.whatsOn::messageShown,
                recordings.message to stores.recordings::messageShown,
            ),
            Modifier.align(Alignment.BottomCenter),
        )
    }

    ui.search?.let { GuideSearchSheet(it, store, searchResult) { serverId, thumb -> artwork(serverId, thumb, ImageKind.THUMB) } }
    ui.reorder?.let { ReorderFavoritesSheet(it, store) { serverId, thumb -> artwork(serverId, thumb, ImageKind.THUMB) } }
    details?.let { ProgramDetailsSheet(it, stores::closeDetails) }

    // Focus the store moves: into the tab (down from the chips or the actions), the chips (up from the content), the
    // actions (right from the last chip), the search's first result.
    LaunchedEffect(ui.focus) {
        val target = ui.focus ?: return@LaunchedEffect
        // A tab just selected composes its content first.
        withFrameNanos { }
        val current = store.state.value
        when (target) {
            LiveTvFocusTarget.CONTENT -> when {
                current.selectedTab != LiveTvTab.GUIDE -> contentFocus.requestFocus()
                current.favoritesEmpty != null -> showAllFocus.requestFocus()
                else -> stores.guide.focusContent()
            }
            LiveTvFocusTarget.TAB_BAR -> tabFocus.requestFocus()
            LiveTvFocusTarget.ACTIONS -> actionsFocus.requestFocus()
            LiveTvFocusTarget.SEARCH_RESULT -> searchResult.requestFocus()
        }
        store.focusHandled()
    }
    // Left or Back out of the guide: the side navigation; without one, focus leaves the screen's content.
    val screenFocus by stores.focus.collectAsState()
    val focusManager = LocalFocusManager.current
    val hasRail = LocalSideNavigation.current != null
    LaunchedEffect(screenFocus) {
        if (screenFocus != LiveTvScreenFocus.SIDEBAR) return@LaunchedEffect
        if (!hasRail || !focusManager.moveFocus(FocusDirection.Left)) focusManager.clearFocus()
        stores.focusHandled()
    }
}

/** A server's image [path] drawn as [kind]; null without a path or a connected server. */
internal fun AppSession.liveTvArtwork(serverId: String?, path: String?, kind: ImageKind): Artwork? =
    Artwork.of(ServerId.tryParse(serverId)?.let(servers.store::client), path, kind)

/**
 * The tab chips, the selected one filled. With a remote or the keyboard Left and Right select the chip they move to (as
 * the tabs' strip does on TV; focus arriving any other way selects nothing), Down goes into the tab, Up (from any chip)
 * and Right from the last chip to the actions. [measuring]: composed to be measured only ([HeaderScaffold]).
 */
@Composable
private fun TabChips(ui: LiveTvUiState, store: LiveTvStore, selectedFocus: FocusRequester, modifier: Modifier, measuring: Boolean) {
    Row(
        if (measuring) modifier else modifier.onKeyEvent { event -> tabBarKey(event, store) },
        horizontalArrangement = Arrangement.spacedBy(FILTER_GAP),
    ) {
        ui.tabs.forEachIndexed { index, tab ->
            val selected = tab.tab == ui.selectedTab
            val last = index == ui.tabs.lastIndex
            PlezyChip(
                tab.label,
                selected,
                { store.selectTab(tab.tab) },
                if (measuring) {
                    Modifier
                } else {
                    Modifier
                        .then(if (selected) Modifier.focusRequester(selectedFocus) else Modifier)
                        .onKeyEvent { event ->
                            if (event.type != KeyEventType.KeyDown) return@onKeyEvent false
                            if (event.key == Key.DirectionRight && last) {
                                store.focusActions()
                                return@onKeyEvent true
                            }
                            if (event.key == Key.DirectionRight) store.selectTab(ui.tabs[index + 1].tab)
                            if (event.key == Key.DirectionLeft && index > 0) store.selectTab(ui.tabs[index - 1].tab)
                            // Focus moves on to that chip as the key's default does.
                            false
                        }
                        .layoutProbe("liveTv.tab.${tab.tab.probe}")
                },
                tab = true,
            )
        }
    }
}

/**
 * The tabs as one dropdown chip naming the selected one, where the chips don't fit (phones); Down goes into the tab, Up
 * to the actions. Harness name `liveTv.view`.
 */
@Composable
private fun TabMenu(ui: LiveTvUiState, store: LiveTvStore, selectedFocus: FocusRequester, modifier: Modifier) {
    val selected = ui.tabs.firstOrNull { it.tab == ui.selectedTab } ?: return
    FittingRow(modifier.onKeyEvent { event -> tabBarKey(event, store) }) {
        MenuChip(
            FilterChip(ui.title, selected.label),
            choices = ui.tabs.map { MenuChoice(it.label, it.tab == ui.selectedTab) },
            onPick = { store.selectTab(ui.tabs[it].tab) },
            probe = "liveTv.view",
            modifier = Modifier.focusRequester(selectedFocus),
        )
    }
}

/** Down from the tab bar into the tab, Up to the actions. */
private fun tabBarKey(event: KeyEvent, store: LiveTvStore): Boolean {
    if (event.type != KeyEventType.KeyDown) return false
    when (event.key) {
        Key.DirectionDown -> store.focusContent()
        Key.DirectionUp -> store.focusActions()
        else -> return false
    }
    return true
}

private val LiveTvTab.probe: String
    get() = when (this) {
        LiveTvTab.GUIDE -> "guide"
        LiveTvTab.WHATS_ON -> "whatsOn"
        LiveTvTab.RECORDINGS -> "recordings"
    }

/** The selected tab's actions, at the header row's end; Down from them goes into the tab. */
@Composable
private fun Actions(actions: List<LiveTvActionUi>, store: LiveTvStore, firstFocus: FocusRequester) {
    Row(
        Modifier.onKeyEvent { event ->
            if (event.type != KeyEventType.KeyDown || event.key != Key.DirectionDown || store.state.value.body != LiveTvBody.Tabs) return@onKeyEvent false
            store.focusContent()
            true
        },
        horizontalArrangement = Arrangement.spacedBy(FILTER_GAP),
    ) {
        actions.forEachIndexed { index, action ->
            val (icon, probe) = when (action.action) {
                LiveTvAction.SEARCH -> PlezyIcons.Search to "search"
                LiveTvAction.FAVORITES_FILTER -> (if (action.active) PlezyIcons.Star else PlezyIcons.StarBorder) to "favorites"
                LiveTvAction.REORDER_FAVORITES -> PlezyIcons.SwapVert to "reorder"
                LiveTvAction.PROCESS_RULES -> PlezyIcons.FlashOn to "rules"
                LiveTvAction.REFRESH -> PlezyIcons.Refresh to "refresh"
            }
            HeaderAction(
                icon,
                action.label,
                { store.perform(action.action) },
                "liveTv.action.$probe",
                if (index == 0) Modifier.focusRequester(firstFocus) else Modifier,
                selected = if (action.action == LiveTvAction.FAVORITES_FILTER) action.active else null,
            )
        }
    }
}

/** The stores' snackbars, the first pending one at a time. */
@Composable
private fun Messages(messages: List<Pair<LiveTvMessage?, () -> Unit>>, modifier: Modifier) {
    val (message, shown) = messages.firstOrNull { it.first != null } ?: return
    TimedToast(message!!.text, "liveTv.message", shown, modifier.padding(bottom = LocalPlezyDimens.current.sectionSpacing), isError = message.isError)
}
