package com.edde746.plezy.ui.settings

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.presentation.libraries.LibrariesUiState
import com.edde746.plezy.presentation.libraries.LibraryAdminAction
import com.edde746.plezy.strings.T
import com.edde746.plezy.strings.isolate
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.EmptyState
import com.edde746.plezy.ui.components.GroupGap
import com.edde746.plezy.ui.components.ItemMenuEntry
import com.edde746.plezy.ui.components.OrderedRow
import com.edde746.plezy.ui.components.OrderedRowActions
import com.edde746.plezy.ui.components.PlezyToggleSurface
import com.edde746.plezy.ui.components.RowSwitch
import com.edde746.plezy.ui.components.ReorderState
import com.edde746.plezy.ui.components.rememberReorderState
import com.edde746.plezy.ui.components.reorderHandle
import com.edde746.plezy.ui.components.reorderItem
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe

/** Manage libraries ([com.edde746.plezy.presentation.settings.SettingsPageId.MANAGE_LIBRARIES]) over the Libraries destination's store. */
@Composable
internal fun ManageLibrariesPage(app: AppSession) {
    val store = remember { app.libraries() } ?: return
    val state by store.state.collectAsState()
    val toasts = remember { SettingsToasts() }
    val list = rememberLazyListState()
    SettingsPageFrame(T.libraries.manageLibraries, app, hub = false, toasts, scrolled = { list.canScrollBackward }) {
        ManageLibrariesPane(state, store::adminActions, store::runAdminAction, store::moveLibrary, store::setHidden, list)
    }
}

/**
 * Every library, in the Libraries destination's order (its server under its name where they come from several), each
 * an [OrderedRow] with its switch at its end, which shows or hides it. A library moves by its drag handle (mouse, touch;
 * a press on the handle only drags) or its menu (a click or Enter on the row, ⋮, a right click or the Menu key): Move up
 * and Move down; on TV by its ↑ and ↓ buttons instead. Where the user administers its server, its menu adds the admin
 * actions ([actionsFor]), each asking first and then running ([onAction]).
 *
 * Harness names: `settings.libraries.row.<i>` with `.handle`, `.switch`, `.more` (⋮), its menu `.menu.<up|down|scan|
 * analyze|refresh_metadata|empty_trash>` and TV's `.up` and `.down`; the question `libraries.adminConfirm` with
 * `.cancel` and `.confirm`.
 */
@Composable
internal fun ManageLibrariesPane(
    state: LibrariesUiState,
    actionsFor: (MediaLibrary) -> List<LibraryAdminAction>,
    onAction: (MediaLibrary, LibraryAdminAction) -> Unit,
    onMove: (globalKey: String, toIndex: Int) -> Unit,
    onHidden: (globalKey: String, hide: Boolean) -> Unit,
    list: LazyListState = rememberLazyListState(),
) {
    val libraries = state.libraries
    if (libraries.isEmpty()) return EmptyState(T.libraries.noLibrariesFound, icon = PlezyIcons.VideoLibrary)
    val tv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val reorder = rememberReorderState(GroupGap)
    val multiple = libraries.mapNotNullTo(HashSet()) { it.serverId }.size > 1
    val memory = rememberFocusMemory()
    var asking by remember { mutableStateOf<Pair<MediaLibrary, LibraryAdminAction>?>(null) }
    SettingsList(state = list) {
        // Keyed by library, so focus stays on a moved row and it can be moved again at once.
        settingsGroup(
            "libraries",
            null,
            libraries.mapIndexed { index, library ->
                SettingsItem(library.globalKey) { shape ->
                    LibraryRow(
                        library = library,
                        index = index,
                        count = libraries.size,
                        shown = library.globalKey !in state.hiddenKeys,
                        server = library.serverName.takeIf { multiple },
                        admin = actionsFor(library),
                        shape = shape,
                        reorder = reorder,
                        memory = memory,
                        draggable = !tv && libraries.size > 1,
                        onMove = onMove,
                        onHidden = onHidden,
                        onAsk = { action -> asking = library to action },
                    )
                }
            },
        )
    }
    asking?.let { (library, action) ->
        ConfirmDialog(
            action.confirmTitle,
            action.confirmMessage(library),
            action.label,
            onConfirm = {
                asking = null
                onAction(library, action)
            },
            onCancel = { asking = null },
            probe = "libraries.adminConfirm",
            modifier = Modifier.layoutProbe("libraries.adminConfirm", reportsFocus = false),
            destructive = action.destructive,
        )
    }
    RestoreFocus(memory, ready = true, fallback = libraries.first().globalKey)
}

@Composable
private fun LibraryRow(
    library: MediaLibrary,
    index: Int,
    count: Int,
    shown: Boolean,
    server: String?,
    admin: List<LibraryAdminAction>,
    shape: Shape,
    reorder: ReorderState,
    memory: FocusMemory,
    draggable: Boolean,
    onMove: (String, Int) -> Unit,
    onHidden: (String, Boolean) -> Unit,
    onAsk: (LibraryAdminAction) -> Unit,
) {
    val probe = "settings.libraries.row.$index"
    val key = library.globalKey
    val name = isolate(library.title)
    val actions = OrderedRowActions(
        moveUp = ItemMenuEntry(T.libraries.moveUp, "up", icon = PlezyIcons.ArrowUpward) { onMove(key, index - 1) },
        moveDown = ItemMenuEntry(T.libraries.moveDown, "down", icon = PlezyIcons.ArrowDownward) { onMove(key, index + 1) },
        moveUpName = T.libraries.moveUpNamed(name),
        moveDownName = T.libraries.moveDownNamed(name),
        canMoveUp = index > 0,
        canMoveDown = index < count - 1,
        more = admin.map { action ->
            ItemMenuEntry(action.label, action.name.lowercase(), destructive = action.destructive, icon = adminIcon(action)) { onAsk(action) }
        },
    )
    OrderedRow(
        actions = actions,
        title = library.title,
        moreLabel = T.libraries.moreActionsNamed(name),
        probe = probe,
        index = index,
        shape = shape,
        // Enter, like a click, opens the row's menu (Move up, Move down): only the switch shows or hides the library.
        onClick = null,
        modifier = Modifier.reorderItem(reorder, key, index),
        surfaceModifier = Modifier.rememberFocus(memory, key).layoutProbe(probe),
        contentTitle = true,
        trailing = {
            PlezyToggleSurface(
                shown,
                { show -> onHidden(key, !show) },
                Modifier.layoutProbe("$probe.switch").semantics { contentDescription = library.title },
                shape = CircleShape,
                color = Color.Transparent,
                contentColor = LocalContentColor.current,
            ) {
                Box(Modifier.padding(horizontal = 6.dp, vertical = 2.dp)) { RowSwitch(shown) }
            }
        },
    ) {
        if (draggable) {
            DragHandleIcon(T.libraries.dragToReorderNamed(name), Modifier.layoutProbe("$probe.handle").reorderHandle(reorder, key, index, count, onMove))
        }
        // Without a handle the text starts where a toggle row's does.
        RowText(library.title, server, Modifier.weight(1f).padding(start = if (draggable) 0.dp else 4.dp), contentTitle = true, contentSubtitle = true)
    }
}

private fun adminIcon(action: LibraryAdminAction) = when (action) {
    LibraryAdminAction.SCAN -> PlezyIcons.Refresh
    LibraryAdminAction.ANALYZE -> PlezyIcons.Info
    LibraryAdminAction.REFRESH_METADATA -> PlezyIcons.Sync
    LibraryAdminAction.EMPTY_TRASH -> PlezyIcons.Delete
}
