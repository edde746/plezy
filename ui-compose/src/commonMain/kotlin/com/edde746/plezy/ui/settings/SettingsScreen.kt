package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.CompositionLocalProvider
import com.edde746.plezy.ui.components.LocalPaneRoot
import com.edde746.plezy.ui.onboarding.ProfileAvatar
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.runtime.snapshotFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withTimeoutOrNull
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.NavigationStacks
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.navigation.TopLevelDestination
import com.edde746.plezy.presentation.settings.LinkTrailing
import com.edde746.plezy.presentation.settings.SettingChecklistRow
import com.edde746.plezy.presentation.settings.SettingChoiceRow
import com.edde746.plezy.presentation.settings.SettingColorRow
import com.edde746.plezy.presentation.settings.SettingLinkRow
import com.edde746.plezy.presentation.settings.SettingNumberRow
import com.edde746.plezy.presentation.settings.SettingRow
import com.edde746.plezy.presentation.settings.SettingSliderRow
import com.edde746.plezy.presentation.settings.SettingSlot
import com.edde746.plezy.presentation.settings.SettingSlotRow
import com.edde746.plezy.presentation.settings.SettingTextRow
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.presentation.settings.SettingsEvent
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.presentation.settings.SettingsPageStore
import com.edde746.plezy.presentation.settings.SettingsEmptyState
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.adaptive.NavigationKind
import com.edde746.plezy.ui.app.UserMenuNotices
import com.edde746.plezy.ui.app.LocalPlezyPlatform
import com.edde746.plezy.ui.app.SaveResult
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.components.ScreenHeader
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.navigation.statusBarOverlap
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import androidx.compose.ui.text.font.FontFamily
import coil3.SingletonImageLoader
import coil3.compose.LocalPlatformContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext
import kotlinx.coroutines.launch
import kotlinx.coroutines.CancellationException
import com.edde746.plezy.log.Log
import com.edde746.plezy.ui.updates.PlatformUpdates
import com.edde746.plezy.ui.downloads.DownloadLocationOverlay

/**
 * Settings: the hub ([Route.Settings], the tab's root) or a page pushed over it ([Route.SettingsPage]) of [app]. Row
 * pages draw through one renderer ([RowsPage]); Theme, Custom theme, mpv.conf, External player, Keyboard shortcuts,
 * Logs, Manage libraries and Licenses have screens of their own. On wide windows the hub stays beside the page
 * ([SettingsSplit]).
 */
@Composable
fun SettingsScreen(app: AppSession, route: Route, modifier: Modifier = Modifier) {
    val page = when (route) {
        Route.Settings -> SettingsPageId.HUB
        is Route.SettingsPage -> route.page
        else -> return
    }
    val arg = (route as? Route.SettingsPage)?.arg
    Box(modifier.fillMaxSize()) {
        SettingsSplit(app, route) {
            when (page) {
                SettingsPageId.HUB, SettingsPageId.GENERAL, SettingsPageId.APPEARANCE, SettingsPageId.VIDEO_PLAYBACK,
                SettingsPageId.SUBTITLE_STYLING, SettingsPageId.ABOUT, SettingsPageId.ACCOUNT_PREFERENCES,
                -> RowsPage(app, route, page, arg)
                SettingsPageId.THEME -> ThemePickerScreen(app, route)
                SettingsPageId.CUSTOM_THEME -> CustomThemeEditorScreen(app, route)
                SettingsPageId.MPV_CONFIG -> MpvConfigScreen(app, route)
                SettingsPageId.EXTERNAL_PLAYER -> ExternalPlayerScreen(app, route)
                SettingsPageId.KEYBOARD_SHORTCUTS -> KeyboardShortcutsScreen(app, route)
                SettingsPageId.LOGS -> LogsScreen(app, route)
                SettingsPageId.MANAGE_LIBRARIES -> ManageLibrariesPage(app)
                SettingsPageId.LICENSES -> LicensesScreen(app, route, arg)
            }
        }
        SupporterSheetHost(app)
        // The hub's Log out asks first through the profile menu's confirmation, which a phone (no profile button) shows here.
        if (page == SettingsPageId.HUB && LocalWindowLayout.current.navigation == NavigationKind.BAR) UserMenuNotices(app)
    }
}

/**
 * A settings screen of [route] ([content]): alone on phones, medium windows and TV; on windows at least 840 dp wide (a
 * desktop, a tablet in landscape), with the hub's list kept at the start beside it while the Settings stack shows,
 * as a list and its detail, the hub's row of the open section marked. The hub alone shows General beside its list.
 * A row of the list beside a section replaces that section rather than piling up on it, at once ([swapsSettingsPane]),
 * and the section opened from the list has no back button ([LocalPaneRoot]); a page it opens in turn has. A screen
 * leaving (popped, given way to, its destination left) is drawn as it showed until it is gone ([drawnStack]). Wherever
 * the hub's list shows, so does the download location's dialog its row opens, and its outcome. Harness name
 * `settings.pane`.
 */
@Composable
internal fun SettingsSplit(app: AppSession, route: Route, content: @Composable () -> Unit) {
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val stack = drawnStack(app, route)
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val beside = listBeside(maxWidth, tv) && stack.firstOrNull() == Route.Settings
        if (beside) {
            // About a third of the width, so a row's subtitle takes two lines at most where there is room.
            val listWidth = (maxWidth * 0.32f).coerceIn(340.dp, 400.dp)
            Row(Modifier.fillMaxSize()) {
                // Focus comes to the list on the hub alone, to the section once one is open.
                Box(Modifier.width(listWidth).fillMaxHeight()) { RowsPage(app, Route.Settings, SettingsPageId.HUB, null, beside = true, restore = route == Route.Settings) }
                Box(Modifier.weight(1f).fillMaxHeight().layoutProbe("settings.pane", reportsFocus = false)) {
                    CompositionLocalProvider(LocalPaneRoot provides (route == Route.Settings || stack.getOrNull(1) == route)) {
                        if (route == Route.Settings) DefaultPane(app) else content()
                    }
                }
            }
        } else {
            content()
        }
        if (beside || route == Route.Settings) {
            app.downloadLocation?.let { DownloadLocationOverlay(it, Modifier.align(Alignment.BottomCenter).padding(24.dp)) }
        }
    }
}

/** The narrowest window that keeps the hub's list beside a section. */
private val SplitWidth = 840.dp

/** Screens [width] wide keep the hub's list beside the Settings stack's pages ([SettingsSplit]); never on TV. */
internal fun listBeside(width: Dp, tv: Boolean): Boolean = !tv && width >= SplitWidth

/**
 * Beside the hub's list ([listBeside]), the screens [to] take the place of [from] at once, as a list's detail changes
 * with no transition: both are the hub alone or one screen opened from its list (a section, Services, the profiles,
 * a connection), drawn in the pane ([SettingsSplit]). A page pushed over a section, and anything leaving Settings,
 * moves as any screen does.
 */
internal fun swapsSettingsPane(from: List<Route>, to: List<Route>): Boolean = from.paneRoot() && to.paneRoot()

private fun List<Route>.paneRoot(): Boolean =
    size <= 2 && first() == Route.Settings && last().let { TopLevelDestination.owner(it) == TopLevelDestination.SETTINGS || it is Route.ProfilePicker }

/**
 * The stack [route]'s screen is drawn on: the one holding it ([NavigationStacks.stackOf]), shown or not; once it is on
 * none (popped, given way to: it animates out), the last that held it, so the screen leaves as it showed rather than as
 * a page pushed over another.
 */
@Composable
private fun drawnStack(app: AppSession, route: Route): List<Route> {
    val stacks by app.navigator.stacks.collectAsState()
    val held = remember(route) { HeldStack() }
    return (stacks.stackOf(route) ?: held.routes ?: stacks.current).also { held.routes = it }
}

/** The stack a screen was last drawn on ([drawnStack]). */
private class HeldStack {
    var routes: List<Route>? = null
}

/**
 * The hub's row that opened the section beside it ([SettingsSplit]) and where the hub's list there is scrolled, kept
 * with the hub: each screen of the Settings stack draws the list anew.
 */
private class HubSelection {
    var id by mutableStateOf<String?>(HubGeneral)
    var firstItem = 0
    var firstItemOffset = 0
}

/**
 * The stores of the row pages ([RowPages]) the hub's list beside them opened, each made and loaded before its page takes
 * the pane ([prepare]), so the page shows its rows from its first frame rather than its loading state; the page takes
 * its store as it shows ([take]). Kept with the hub, which releases those never taken.
 */
private class PreparedPages {
    private val stores = HashMap<Route, SettingsPageStore>()

    /** Makes [route]'s store and waits, at most [PREPARE_MILLIS], until it has loaded; nothing for a page shown already. */
    suspend fun prepare(app: AppSession, route: Route.SettingsPage) {
        if (route.page !in RowPages || route in app.navigator.backStack.value) return
        val store = app.settings.page(route.page, route.arg)
        stores.put(route, store)?.release()
        withTimeoutOrNull(PREPARE_MILLIS) { store.state.first { !it.loading } }
    }

    fun take(route: Route): SettingsPageStore? = stores.remove(route)

    fun release() {
        stores.values.forEach { it.release() }
        stores.clear()
    }
}

@Composable
private fun preparedPages(app: AppSession): PreparedPages =
    checkNotNull(retainedStore(app, Route.Settings, "settings.prepared", ::PreparedPages, PreparedPages::release))

/** The pages drawn from rows, besides the hub ([RowsPage]). */
private val RowPages = setOf(
    SettingsPageId.GENERAL, SettingsPageId.APPEARANCE, SettingsPageId.VIDEO_PLAYBACK, SettingsPageId.SUBTITLE_STYLING,
    SettingsPageId.ABOUT, SettingsPageId.ACCOUNT_PREFERENCES,
)

/** The longest a section waits to load before it shows anyway (its loading state: a real wait, an account's preferences). */
private const val PREPARE_MILLIS = 300L

/** The hub's General row: the section shown beside the hub before any is opened. */
private const val HubGeneral = "general"

/** General beside the hub before a section is opened: its own store, released when the pane goes. */
@Composable
private fun DefaultPane(app: AppSession) {
    val store = remember(app) { app.settings.page(SettingsPageId.GENERAL, null) }
    DisposableEffect(store) { onDispose { store.release() } }
    RowsPageContent(app, Route.Settings, SettingsPageId.GENERAL, store, beside = false, restore = false)
}

/**
 * The running profile at the top of the hub: its avatar and name over Switch Profile, the whole card the button that
 * opens the profile picker through [place] (the hub's Manage profiles row opens it too, to manage them). Nothing before
 * a profile is active. Harness name `settings.profile.switch`.
 */
@Composable
private fun ProfileCard(app: AppSession, place: (show: () -> Unit) -> Unit, modifier: Modifier = Modifier) {
    val active = app.userMenu.state.collectAsState().value.active ?: return
    GroupRow(
        active.name,
        onClick = { place { app.navigator.navigate(Route.ProfilePicker(required = false)) } },
        modifier = modifier.layoutProbe("settings.profile.switch"),
        subtitle = T.screens.switchProfile,
        leading = { ProfileAvatar(active.name, active.avatarUrl, 48.dp, locked = active.locked) },
        trailing = { Chevron() },
    )
}

/**
 * The store [create] makes for [route], kept while the route is on a stack ([com.edde746.plezy.presentation.navigation.PlezyNavigator.retain])
 * and released by [release] once it leaves; null while the route is on none (it animates out).
 */
@Composable
internal fun <S : Any> retainedStore(app: AppSession, route: Route, key: String, create: () -> S, release: (S) -> Unit): S? =
    remember(route) { app.navigator.retain(route, key, create, release) }

/** Calls [onResumed] each time [route] shows again after something covered it: back from a page, the tab shown again. */
@Composable
internal fun ResumeOnReturn(app: AppSession, route: Route, onResumed: () -> Unit) {
    val current by rememberUpdatedState(onResumed)
    LaunchedEffect(route) {
        app.navigator.covered(route).drop(1).filter { !it }.collect { current() }
    }
}

/** The one-off messages a settings page shows at its foot ([SettingsEvent.Message]), one at a time. */
@Stable
internal class SettingsToasts {
    var current by mutableStateOf<SettingsEvent.Message?>(null)

    fun show(message: SettingsEvent.Message) {
        current = message
    }
}

/** A settings page of [app] ([SettingsPageFrame]); Back pops it unless [onBack] says otherwise (null: no back button). */
@Composable
internal fun SettingsPageFrame(
    title: String,
    app: AppSession,
    hub: Boolean,
    toasts: SettingsToasts,
    onBack: (() -> Unit)? = { app.navigator.back() },
    modifier: Modifier = Modifier,
    actions: (@Composable androidx.compose.foundation.layout.RowScope.() -> Unit)? = null,
    scrolled: () -> Boolean = { false },
    content: @Composable ColumnScope.() -> Unit,
) = SettingsPageFrame(title, hub, toasts, onBack, modifier, actions, scrolled, content)

/**
 * A settings page: a pushed page's pinned title with a back button beside it running [onBack]; the hub, a top-level
 * screen, has no title (the selected navigation item names it), only its [actions] at the end of a row below the status
 * bar. Then [content] and the page's [toasts] at its foot; [modifier] on the whole page. Harness names:
 * `settings.title`, `settings.toast`.
 */
@Composable
internal fun SettingsPageFrame(
    title: String,
    hub: Boolean,
    toasts: SettingsToasts,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
    actions: (@Composable androidx.compose.foundation.layout.RowScope.() -> Unit)? = null,
    scrolled: () -> Boolean = { false },
    content: @Composable ColumnScope.() -> Unit,
) {
    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize()) {
            if (hub) {
                Row(
                    Modifier.fillMaxWidth().padding(start = LocalPlezyDimens.current.screenPadding, end = LocalPlezyDimens.current.screenPadding, top = statusBarOverlap + 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.End),
                    verticalAlignment = Alignment.CenterVertically,
                ) { actions?.invoke(this) }
            } else {
                ScreenHeader(title, Modifier.layoutProbe("settings.title", reportsFocus = false), onBack = onBack, actions = actions, scrolled = scrolled)
            }
            content()
        }
        toasts.current?.let { message ->
            TimedToast(
                message.text,
                "settings.toast",
                onShown = { if (toasts.current === message) toasts.current = null },
                modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = LocalPlezyDimens.current.sectionSpacing),
            )
        }
    }
}

/**
 * A page drawn from rows ([SettingsPageId.rows]) of [route], its store kept with the route ([RowsPageContent]), the one
 * made for it ahead if any ([PreparedPages]); [beside]: the hub's list beside a section ([SettingsSplit]).
 */
@Composable
private fun RowsPage(app: AppSession, route: Route, id: SettingsPageId, arg: String?, beside: Boolean = false, restore: Boolean = true) {
    val prepared = preparedPages(app)
    val store = retainedStore(app, route, "settings.page", { prepared.take(route) ?: app.settings.page(id, arg) }, SettingsPageStore::release) ?: return
    RowsPageContent(app, route, id, store, beside, restore = restore)
}

/**
 * A page drawn from rows of [store]: its groups as grouped lists, each row bound to its store by id; the hub starts
 * with the profile ([ProfileCard]). The store's events act here (pages pushed, questions asked, files saved and opened,
 * messages, links); the hub's list [beside] a section opens a page in that section's place, made ready first
 * ([PreparedPages]), marks the row that opened it (none for the profile's buttons) and stays scrolled where it was
 * through the sections it opens. Focus comes back to the row that had it last when the page shows again (the tab
 * re-entered, back from a page), else to the first row; the title takes none.
 */
@Composable
private fun RowsPageContent(app: AppSession, route: Route, id: SettingsPageId, store: SettingsPageStore, beside: Boolean, restore: Boolean) {
    val state by store.state.collectAsState()
    val toasts = remember { SettingsToasts() }
    val dialogs = remember { SettingsDialogs() }
    val memory = rememberFocusMemory()
    val selection = if (beside) retainedStore(app, Route.Settings, "settings.selection", ::HubSelection) {} else null
    val stack = drawnStack(app, route)
    val place: (show: () -> Unit) -> Unit = if (beside) {
        { show ->
            // The section beside the list gives way to the next one.
            app.navigator.backStack.value.getOrNull(1)?.let { app.navigator.pop(it) }
            show()
        }
    } else {
        { show -> show() }
    }
    val prepared = preparedPages(app)
    SettingsEvents(app, store.events, toasts, dialogs, store, place, prepare = if (beside) { page -> prepared.prepare(app, page) } else null)
    ResumeOnReturn(app, route, store::resumed)
    val shown = state.groups.map { group -> group to group.rows.filter { it !is SettingSlotRow || slotShown(it.slot, app) } }
    val list = if (selection != null) remember { LazyListState(selection.firstItem, selection.firstItemOffset) } else rememberLazyListState()
    if (selection != null) {
        LaunchedEffect(list) {
            snapshotFlow { list.firstVisibleItemIndex to list.firstVisibleItemScrollOffset }.collect { (item, offset) ->
                selection.firstItem = item
                selection.firstItemOffset = offset
            }
        }
    }
    SettingsPageFrame(state.title, app, hub = id == SettingsPageId.HUB, toasts, scrolled = { list.canScrollBackward }) {
        val empty = state.empty
        when {
            state.loading -> LoadingState()
            empty != null -> EmptyState(empty.body ?: "", title = empty.title, icon = empty.icon.vector) {
                empty.retryLabel?.let { PlezyButton(it, { store.activate(SettingsEmptyState.RETRY_ID) }, Modifier.layoutProbe("settings.retry"), style = ButtonStyle.PRIMARY) }
            }
            else -> SettingsList(state = list) {
                if (id == SettingsPageId.HUB) {
                    item(key = "profile") {
                        val card: (show: () -> Unit) -> Unit = { show ->
                            place {
                                selection?.id = null
                                show()
                            }
                        }
                        ProfileCard(app, card, Modifier.padding(bottom = 4.dp))
                    }
                }
                state.header?.let { header -> item(key = "header") { if (id == SettingsPageId.ABOUT) AboutHeader(header) else SettingsNote(header) } }
                for ((group, rows) in shown) {
                    settingsGroup(
                        group.id,
                        group.header,
                        rows.map { row ->
                            SettingsItem(row.id) { shape ->
                                SettingRowItem(
                                    row, store, shape, memory, onOpen = { dialogs.row = it },
                                    selected = selection != null && row.id == (if (stack.size > 1) selection.id else HubGeneral),
                                    onActivated = { selection?.id = row.id },
                                ) { slot, slotShape, slotModifier -> SettingSlotContent(slot.slot, app, slotShape, toasts, slotModifier) }
                            }
                        },
                        group.footer,
                    )
                }
            }
        }
    }
    if (restore) RestoreFocus(memory, ready = !state.loading, fallback = firstFocusRow(shown.map { (_, rows) -> rows }))
    SettingsDialogsContent(dialogs, app, store)
}

/**
 * The row a settings page focuses when no row had focus before: its first, past the Support Plezy offer that heads the
 * hub (a press there opens a purchase or a donation page, not a setting).
 */
internal fun firstFocusRow(groups: List<List<SettingRow>>): String? =
    groups.firstNotNullOfOrNull { rows -> rows.firstOrNull { !(it is SettingSlotRow && it.slot == SettingSlot.SUPPORTER) }?.id }

/**
 * The dialogs a settings page's events open ([SettingsEvents]): a question, a text field, a found update, an uploaded
 * log; and the overlay of the row ([row]: a number, text, checklist or colour row) the user opened. That one is kept
 * with the page, not in the row, so it stays open while its row leaves the list: the keyboard it raises shrinks the
 * window, and a row low on the page scrolls out of the shorter list.
 */
@Stable
internal class SettingsDialogs {
    var confirm by mutableStateOf<SettingsEvent.Confirm?>(null)
    var editText by mutableStateOf<SettingTextRow?>(null)
    var update by mutableStateOf<SettingsEvent.UpdateAvailable?>(null)
    var uploaded by mutableStateOf<String?>(null)
    var row by mutableStateOf<SettingRow?>(null)
}

/**
 * Acts on a settings store's [events]: opens pages and other features' screens, each shown through [place] (beside the
 * hub's list: in the place of the section open there) once [prepare] has made a page ready, opens [dialogs], saves and
 * opens files through the platform's dialogs for [store] (where the platform has none, nothing opens), clears the image
 * caches, shows messages in [toasts] and opens links.
 */
@Composable
internal fun SettingsEvents(
    app: AppSession,
    events: Flow<SettingsEvent>,
    toasts: SettingsToasts,
    dialogs: SettingsDialogs,
    store: SettingsPageStore?,
    place: (show: () -> Unit) -> Unit = { show -> show() },
    prepare: (suspend (Route.SettingsPage) -> Unit)? = null,
) {
    val platform = LocalPlezyPlatform.current
    val images = LocalPlatformContext.current
    val placer by rememberUpdatedState(place)
    val preparer by rememberUpdatedState(prepare)
    LaunchedEffect(events) {
        events.collect { event ->
            when (event) {
                is SettingsEvent.Open -> {
                    val route = Route.SettingsPage(event.page, event.arg)
                    preparer?.invoke(route)
                    placer { app.navigator.navigate(route) }
                }
                is SettingsEvent.OpenExternal -> openExternal(event.target, app, placer)
                is SettingsEvent.Confirm -> dialogs.confirm = event
                is SettingsEvent.EditText -> dialogs.editText = event.row
                is SettingsEvent.SaveFile -> if (platform.hasFileDialogs) {
                    platform.saveFile(event.fileName, event.bytes.decodeToString()) { result ->
                        store?.exported(result == SaveResult.SAVED, if (result == SaveResult.FAILED) T.settings.saveFailed else null)
                    }
                } else {
                    store?.exported(false)
                }
                SettingsEvent.OpenFile -> if (platform.hasFileDialogs) {
                    platform.openFile(
                        opened = { _, text -> store?.imported(text.encodeToByteArray()) },
                        failed = { toasts.show(SettingsEvent.Message(T.settings.importSettingsInvalidFile, error = true)) },
                    )
                } else {
                    store?.imported(null)
                }
                SettingsEvent.ClearImageCache -> {
                    val loader = SingletonImageLoader.get(images)
                    loader.memoryCache?.clear()
                    withContext(Dispatchers.Default) { loader.diskCache?.clear() }
                }
                is SettingsEvent.Message -> toasts.show(event)
                is SettingsEvent.OpenUrl -> app.openUrl(event.url)
                is SettingsEvent.UpdateAvailable -> dialogs.update = event
                SettingsEvent.NativeUpdateCheck -> platform.updates?.let { updates -> launch { checkInstaller(updates, toasts) } }
                is SettingsEvent.LogsUploaded -> dialogs.uploaded = event.id
            }
        }
    }
}

/** The installer updater's check the user asked for: its dialog when the feed has an update, else a message. */
private suspend fun checkInstaller(updates: PlatformUpdates, toasts: SettingsToasts) {
    val found = try {
        updates.checkInstallerNow()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w("settings", e) { "the installer updater's check failed" }
        toasts.show(SettingsEvent.Message(T.update.checkFailed, error = true))
        return
    }
    if (!found) toasts.show(SettingsEvent.Message(T.update.latestVersion))
}

/** The dialogs [dialogs] has open, acting on [store] (a question confirmed, a text stored, a row's value set). */
@Composable
internal fun SettingsDialogsContent(dialogs: SettingsDialogs, app: AppSession, store: SettingsPageStore?) {
    dialogs.confirm?.let { question ->
        ConfirmDialog(
            question.title,
            question.message,
            question.confirmLabel,
            onConfirm = {
                dialogs.confirm = null
                store?.confirm(question.id)
            },
            onCancel = { dialogs.confirm = null },
            probe = "settings.confirm",
            destructive = question.destructive,
            confirmProbe = "settings.confirm.ok",
        )
    }
    dialogs.editText?.let { row ->
        TextOverlay(row, onSave = { store?.submitText(row.id, it) }, onReset = { store?.resetText(row.id) }, onDismiss = { dialogs.editText = null })
    }
    dialogs.update?.let { found -> UpdateDialog(found, app, onDismiss = { dialogs.update = null }) }
    dialogs.uploaded?.let { id -> UploadedDialog(id, onDismiss = { dialogs.uploaded = null }) }
    val row = dialogs.row
    if (row != null && store != null) RowOverlay(row, store, close = { dialogs.row = null })
}

/** The overlay a number, checklist, text or colour row opens, storing through [store]; [close] ends it. */
@Composable
private fun RowOverlay(row: SettingRow, store: SettingsPageStore, close: () -> Unit) {
    when (row) {
        is SettingNumberRow -> NumberOverlay(row, onSave = { store.setNumber(row.id, it) }, validate = { store.checkNumber(row.id, it) }, onDismiss = close)
        is SettingChecklistRow -> ChecklistSheet(row, onSave = { store.setChecked(row.id, it) }, onDismiss = close)
        is SettingTextRow -> TextOverlay(
            row,
            onSave = { store.submitText(row.id, it) },
            onReset = { store.resetText(row.id) },
            onDismiss = close,
            validate = { store.checkText(row.id, it) },
        )
        is SettingColorRow -> ColorSheet(row, onSave = { store.setColor(row.id, it) }, onDismiss = close)
        else -> Unit
    }
}

/** A found update: its version and notes, Close, and View Release (its page) where it has one. */
@Composable
private fun UpdateDialog(found: SettingsEvent.UpdateAvailable, app: AppSession, onDismiss: () -> Unit) {
    ModalOverlay(T.settings.updateAvailable, onDismiss) {
        Text(T.update.versionAvailable(found.version), style = MaterialTheme.typography.bodyLarge)
        found.notes?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted) }
        OverlayActions {
            PlezyButton(T.common.close, onDismiss, style = ButtonStyle.TEXT)
            found.url?.let { url ->
                PlezyButton(
                    T.update.viewRelease,
                    {
                        onDismiss()
                        app.openUrl(url)
                    },
                    style = ButtonStyle.PRIMARY,
                )
            }
        }
    }
}

/** The About page's head: the app's name over the store's [header] (its version, then what it is), centred. */
@Composable
private fun AboutHeader(header: String) {
    Column(
        Modifier.fillMaxWidth().padding(vertical = 16.dp).layoutProbe("settings.about.header", reportsFocus = false),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(PlezyLogo, contentDescription = null, Modifier.size(72.dp, 80.dp), tint = Color.Unspecified)
        Text("Plezy", style = MaterialTheme.typography.headlineMedium.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.Bold))
        for (line in header.lines()) {
            Text(line, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, textAlign = androidx.compose.ui.text.style.TextAlign.Center)
        }
    }
}

/** The log was uploaded: its id, to quote in a report, with Copy. Harness names: `settings.uploaded.<id|copy>`. */
@Composable
private fun UploadedDialog(id: String, onDismiss: () -> Unit) {
    val platform = LocalPlezyPlatform.current
    ModalOverlay(T.messages.logsUploaded, onDismiss) {
        Text(T.messages.logId, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
        Text(id, Modifier.layoutProbe("settings.uploaded.id"), style = MaterialTheme.typography.titleMedium.copy(fontFamily = FontFamily.Monospace))
        OverlayActions {
            PlezyButton(T.common.close, onDismiss, style = ButtonStyle.TEXT)
            PlezyButton(T.deepLinks.copy, { platform.setClipboardText(id) }, Modifier.layoutProbe("settings.uploaded.copy"), style = ButtonStyle.PRIMARY, icon = SettingSymbols.ContentCopy)
        }
    }
}

/**
 * One row of a row page, bound to [store] by its id, in [shape] (its place in its group), its focus kept in [memory]
 * under its id; a slot row is drawn by [slot]. A number, checklist, text or colour row hands itself to [onOpen], which
 * shows its overlay outside the list ([SettingsDialogs.row]). A link row that is [selected] is marked (the hub's row of
 * the section shown beside it) and tells [onActivated] as it acts. Harness name: `settings.row.<id>`.
 */
@Composable
internal fun SettingRowItem(
    row: SettingRow,
    store: SettingsPageStore,
    shape: Shape,
    memory: FocusMemory,
    onOpen: (SettingRow) -> Unit,
    selected: Boolean = false,
    onActivated: () -> Unit = {},
    slot: @Composable (SettingSlotRow, Shape, Modifier) -> Unit,
) {
    val probe = "settings.row.${row.id}"
    val focus = Modifier.rememberFocus(memory, row.id)
    when (row) {
        is SettingToggleRow -> SettingToggleItem(row, { store.toggle(row.id, it) }, shape, focus.layoutProbe(probe))
        is SettingChoiceRow -> SettingChoiceItem(row, { store.choose(row.id, it) }, probe, shape, focus)
        is SettingNumberRow -> OverlayRow(row, shape, focus.layoutProbe(probe), subtitle = row.subtitle, onOpen = onOpen, value = row.trailingValue)
        is SettingSliderRow -> SliderItem(row, { store.setSlider(row.id, it) }, shape, focus, probe)
        is SettingLinkRow -> LinkItem(row, {
            if (row.trailing == LinkTrailing.CHEVRON) onActivated()
            store.activate(row.id)
        }, shape, focus.layoutProbe(probe), selected)
        is SettingChecklistRow -> OverlayRow(row, shape, focus.layoutProbe(probe), subtitle = row.subtitle, onOpen = onOpen, value = row.trailingValue)
        is SettingTextRow -> OverlayRow(row, shape, focus.layoutProbe(probe), subtitle = row.subtitle, onOpen = onOpen, value = row.trailingValue, monospace = row.monospace)
        is SettingColorRow -> OverlayRow(row, shape, focus.layoutProbe(probe), subtitle = row.hex, onOpen = onOpen, trailing = { ColorDot(parseHex(row.hex), 28) })
        is SettingSlotRow -> slot(row, shape, focus.layoutProbe(probe))
    }
}

/**
 * A row that opens its overlay ([onOpen]): its title, [subtitle] ([monospace]: a pattern's), [value] and a chevron, or
 * [trailing].
 */
@Composable
private fun OverlayRow(
    row: SettingRow,
    shape: Shape,
    modifier: Modifier,
    subtitle: String?,
    onOpen: (SettingRow) -> Unit,
    value: String? = null,
    monospace: Boolean = false,
    trailing: (@Composable () -> Unit)? = null,
) {
    GroupRow(
        row.title, onClick = { onOpen(row) }, modifier = modifier, shape = shape, subtitle = subtitle, value = value, icon = row.icon?.vector,
        subtitleMonospace = monospace,
        trailing = { if (trailing != null) trailing() else Chevron() },
    )
}

/**
 * A row that acts when activated: its icon (the warning colour when [SettingLinkRow.accent]), title, the setting's
 * value beside it while short ([SettingLinkRow.trailingValue]), subtitle (at most [SettingLinkRow.subtitleLines] lines)
 * and a chevron, an external-link mark or nothing at its end; while [SettingLinkRow.busy] a spinner there, and a click
 * does nothing.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun LinkItem(row: SettingLinkRow, onActivate: () -> Unit, shape: Shape, modifier: Modifier, selected: Boolean) {
    val trailing: (@Composable androidx.compose.foundation.layout.RowScope.() -> Unit)? = when {
        row.busy -> { { LoadingIndicator(Modifier.size(20.dp), color = LocalContentColor.current) } }
        row.trailing == LinkTrailing.CHEVRON -> { { Chevron() } }
        row.trailing == LinkTrailing.EXTERNAL -> { { Icon(PlezyIcons.OpenInNew, contentDescription = null, tint = PlezyColors.MutedContent) } }
        else -> null
    }
    GroupRow(
        row.title,
        onClick = { if (!row.busy) onActivate() },
        modifier = modifier,
        shape = shape,
        subtitle = row.subtitle,
        value = row.trailingValue,
        icon = row.icon?.vector,
        enabled = row.enabled,
        selected = selected,
        destructive = row.destructive,
        iconTint = if (row.accent) Warning else null,
        subtitleLines = row.subtitleLines,
        trailing = trailing,
    )
}

/** The warning colour: an update waiting. */
private val Warning = Color(0xFFFFB300)

/**
 * A continuous setting: the row's title and value over a slider (the D-pad's left and right move it), its end labels
 * under it. Every move writes. Harness name: `[probe]` on the slider.
 */
@Composable
private fun SliderItem(row: SettingSliderRow, onChange: (Double) -> Unit, shape: Shape, focus: Modifier, probe: String) {
    // The slider follows the finger at once; the store's value, once written, replaces it.
    var value by remember(row.value) { mutableFloatStateOf(row.value.toFloat()) }
    RowSurface(shape) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            RowHeading(row.title, null, row.icon?.vector, Modifier.weight(1f))
            row.valueLabel?.let { Text(it, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.MutedContent) }
        }
        PlezySlider(
            value,
            {
                value = it
                onChange(it.toDouble())
            },
            row.min.toFloat()..row.max.toFloat(),
            steps = (row.steps - 1).coerceAtLeast(0),
            label = row.title,
            modifier = focus.layoutProbe(probe),
        )
        if (row.startLabel != null || row.endLabel != null) {
            Row {
                Text(row.startLabel.orEmpty(), style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent, modifier = Modifier.weight(1f))
                Text(row.endLabel.orEmpty(), style = MaterialTheme.typography.bodySmall, color = PlezyColors.MutedContent)
            }
        }
    }
}

/** A row that isn't one control: the grouped row's fill in [shape], [content] inside its padding. */
@Composable
private fun RowSurface(shape: Shape, modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier.fillMaxWidth().background(PlezyColors.SurfaceHigh, shape).padding(horizontal = 16.dp, vertical = 12.dp), content = content)
}

/** A row's icon, title and subtitle, as [GroupRow] lays them out. */
@Composable
private fun RowHeading(title: String, subtitle: String?, icon: androidx.compose.ui.graphics.vector.ImageVector?, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
        icon?.let { Icon(it, contentDescription = null, Modifier.size(22.dp), tint = PlezyColors.MutedContent) }
        RowText(title, subtitle)
    }
}
