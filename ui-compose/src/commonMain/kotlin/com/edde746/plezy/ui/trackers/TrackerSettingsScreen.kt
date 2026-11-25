package com.edde746.plezy.ui.trackers

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.SettingToggleRow
import com.edde746.plezy.presentation.trackers.TrackerToggle
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.ui.components.ConfirmDialog
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.PlezyChip
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.icons.pathNodes
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.settings.SettingToggleItem
import com.edde746.plezy.ui.settings.SettingsIcons
import com.edde746.plezy.ui.settings.SettingsItem
import com.edde746.plezy.ui.settings.SettingsLinkRow
import com.edde746.plezy.ui.settings.SettingsList
import com.edde746.plezy.ui.settings.SettingsNote
import com.edde746.plezy.ui.settings.settingsGroup

/**
 * A connected service's settings: the account (and Simkl's Reconnect while its connection is legacy), the Behaviour
 * group (scrobbling, Trakt's watched sync, the library filter) and Disconnect, confirmed first. Once the service is
 * disconnected the screen closes itself.
 *
 * Harness names: `tracker.<account|reconnect|scrobble|watchedSync|filter|disconnect>`, `tracker.confirm.<cancel|confirm>`.
 */
@Composable
fun TrackerSettingsScreen(app: AppSession, route: Route.TrackerSettings) {
    val store = remember(app, route) { app.services(route) } ?: return
    val state by store.state.collectAsState()
    val settings = state.settings(route.service)
    LaunchedEffect(settings == null) {
        if (settings == null) app.navigator.pop(route)
    }
    if (settings == null) return
    val pointer = !isFocusVisible()
    var confirming by remember { mutableStateOf(false) }
    val memory = rememberFocusMemory()
    ServicesPage(app, route, store, settings.title) { list ->
        SettingsList(state = list) {
            settingsGroup(
                "account",
                null,
                listOf(
                    SettingsItem("account") { shape ->
                        GroupRow(settings.accountTitle, null, Modifier.layoutProbe("tracker.account"), shape, settings.accountSubtitle, icon = SettingsIcons.AccountCircle)
                    },
                    settings.reconnect?.let { row ->
                        SettingsItem("reconnect") { shape ->
                            GroupRow(
                                row.title,
                                { store.reconnect(route.service, pointer) },
                                Modifier.rememberFocus(memory, "reconnect").layoutProbe("tracker.reconnect"),
                                shape,
                                row.subtitle,
                                icon = PlezyIcons.Refresh,
                            )
                        }
                    },
                ),
            )
            settingsGroup(
                "behavior",
                settings.behaviorTitle,
                settings.toggles.map { toggle ->
                    SettingsItem(toggle.toggle.name) { shape ->
                        SettingToggleItem(
                            SettingToggleRow(toggle.toggle.name, toggle.title, toggle.subtitle, toggle.on),
                            { store.setToggle(route.service, toggle.toggle, it) },
                            shape,
                            Modifier.rememberFocus(memory, toggle.toggle.name)
                                .layoutProbe(if (toggle.toggle == TrackerToggle.SCROBBLE) "tracker.scrobble" else "tracker.watchedSync"),
                        )
                    }
                } + SettingsItem("filter") { shape ->
                    SettingsLinkRow(
                        settings.libraryFilterTitle,
                        settings.libraryFilterSubtitle,
                        settings.libraryFilterTrailingValue,
                        { app.navigator.navigate(Route.TrackerLibraryFilter(route.service)) },
                        shape,
                        Modifier.rememberFocus(memory, "filter").layoutProbe("tracker.filter"),
                        icon = TrackerIcons.FilterList,
                    )
                },
            )
            settingsGroup(
                "disconnect",
                null,
                listOf(
                    SettingsItem("disconnect") { shape ->
                        GroupRow(
                            settings.disconnect,
                            { confirming = true },
                            Modifier.rememberFocus(memory, "disconnect").layoutProbe("tracker.disconnect"),
                            shape,
                            icon = PlezyIcons.LinkOff,
                            destructive = true,
                        )
                    },
                ),
            )
        }
    }
    RestoreFocus(memory, ready = true, fallback = if (settings.reconnect != null) "reconnect" else settings.toggles.first().toggle.name)
    if (confirming) {
        val confirm = settings.disconnectConfirm
        ConfirmDialog(
            confirm.title,
            confirm.body,
            confirm.confirm,
            onConfirm = {
                confirming = false
                store.disconnect(route.service)
            },
            onCancel = { confirming = false },
            probe = "tracker.confirm",
            cancelLabel = confirm.cancel,
        )
    }
}

/**
 * A service's library filter: the mode's hint, the mode (Blacklist or Whitelist) and a switch per library, grouped by
 * server when there are several; each change is kept at once.
 *
 * Harness names: `filter.mode.<blacklist|whitelist>`, `filter.library.<i>`.
 */
@Composable
fun LibraryFilterScreen(app: AppSession, route: Route.TrackerLibraryFilter) {
    val store = remember(app, route) { app.services(route) } ?: return
    val state by store.state.collectAsState()
    val filter = state.filter(route.service) ?: return
    val service: TrackerService = route.service
    val memory = rememberFocusMemory()
    ServicesPage(app, route, store, filter.title) { list ->
        SettingsList(state = list) {
            item(key = "hint") { SettingsNote(filter.hint) }
            settingsGroup(
                "mode",
                null,
                listOf(
                    SettingsItem("mode") { shape ->
                        GroupRow(filter.modeTitle, null, shape = shape, icon = TrackerIcons.FilterList) {
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                                filter.modes.forEach { mode ->
                                    PlezyChip(
                                        mode.label,
                                        mode.selected,
                                        { store.setFilterMode(service, mode.mode) },
                                        Modifier.rememberFocus(memory, mode.mode.name).layoutProbe("filter.mode.${mode.mode.name.lowercase()}"),
                                        checkmark = true,
                                        tab = true,
                                    )
                                }
                            }
                        }
                    },
                ),
            )
            var index = 0
            filter.groups.forEach { group ->
                settingsGroup(
                    "group.${group.title}",
                    group.title,
                    group.libraries.map { library ->
                        val probe = "filter.library.${index++}"
                        SettingsItem(library.globalKey) { shape ->
                            SettingToggleItem(
                                SettingToggleRow(library.globalKey, library.title, null, library.on),
                                { store.setLibraryFiltered(service, library.globalKey, it) },
                                shape,
                                Modifier.rememberFocus(memory, library.globalKey).layoutProbe(probe),
                            )
                        }
                    },
                )
            }
            filter.empty?.let { empty -> item(key = "empty") { SettingsNote(empty) } }
        }
    }
    RestoreFocus(memory, ready = true, fallback = filter.modes.first().mode.name)
}

/** Material icons (baseline, 24 dp; Apache License 2.0) of the tracker screens. */
private object TrackerIcons {
    val FilterList by icon("M10,18h4v-2h-4v2zM3,6v2h18V6H3zM6,13h12v-2H6v2z")
}

private fun icon(pathData: String) = lazy(LazyThreadSafetyMode.NONE) {
    ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f)
        .addPath(pathNodes(pathData), fill = SolidColor(Color.Black))
        .build()
}
