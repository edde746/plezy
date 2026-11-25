package com.edde746.plezy.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.edde746.plezy.app.AppSession
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.presentation.settings.LicenseDetailUi
import com.edde746.plezy.presentation.settings.LicenseEntryUi
import com.edde746.plezy.presentation.settings.LicensesStore
import com.edde746.plezy.presentation.settings.SettingIcon
import com.edde746.plezy.presentation.settings.SettingsPageId
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.Chevron
import com.edde746.plezy.ui.components.GroupHeader
import com.edde746.plezy.ui.components.GroupRow
import com.edde746.plezy.ui.components.LoadingState
import com.edde746.plezy.ui.focus.RestoreFocus
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.rememberFocusMemory
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * Open source licenses: every component the app ships, by name with its licence, each opening its detail ([name]:
 * that component's) with its source link and its licence texts, reflowed to the width. Harness names:
 * `settings.licenses.<i>`, `settings.license.<url|text.i>`.
 */
@Composable
internal fun LicensesScreen(app: AppSession, route: Route, name: String?) {
    val store = retainedStore(app, route, "settings.licenses", { app.settings.licenses(name) }, LicensesStore::release) ?: return
    val state by store.state.collectAsState()
    val detail = state.detail
    if (name != null && detail != null) {
        LicenseDetail(app, detail)
        return
    }
    val memory = rememberFocusMemory()
    val list = rememberLazyListState()
    SettingsPageFrame(T.about.openSourceLicenses, app, hub = false, toasts = remember { SettingsToasts() }, scrolled = { list.canScrollBackward }) {
        SettingsList(state = list) {
            settingsGroup(
                "licenses",
                null,
                state.entries.mapIndexed { index, entry -> SettingsItem(entry.name) { shape -> LicenseRow(app, entry, index, shape, Modifier.rememberFocus(memory, entry.name)) } },
            )
        }
    }
    RestoreFocus(memory, ready = state.entries.isNotEmpty(), fallback = state.entries.firstOrNull()?.name)
}

@Composable
private fun LicenseRow(app: AppSession, entry: LicenseEntryUi, index: Int, shape: androidx.compose.ui.graphics.Shape, modifier: Modifier) {
    GroupRow(
        entry.name,
        onClick = { app.navigator.navigate(Route.SettingsPage(SettingsPageId.LICENSES, entry.name)) },
        modifier = modifier.layoutProbe("settings.licenses.$index"),
        shape = shape,
        subtitle = entry.license,
        trailing = { Chevron() },
    )
}

/** One component: its licence and source link, then each licence text under its title, paragraph by paragraph. */
@Composable
private fun LicenseDetail(app: AppSession, detail: LicenseDetailUi) {
    val memory = rememberFocusMemory()
    val list = rememberLazyListState()
    SettingsPageFrame(detail.name, app, hub = false, toasts = remember { SettingsToasts() }, scrolled = { list.canScrollBackward }) {
        SettingsList(state = list) {
            settingsGroup(
                "source",
                null,
                listOf(
                    SettingsItem("url") { shape ->
                        GroupRow(
                            detail.license,
                            onClick = { app.openUrl(detail.url) },
                            modifier = Modifier.rememberFocus(memory, "url").layoutProbe("settings.license.url"),
                            shape = shape,
                            subtitle = detail.url,
                            icon = SettingIcon.OPEN_IN_NEW.vector,
                        )
                    },
                ),
            )
            val texts = detail.texts
            if (texts == null) {
                item(key = "loading") { LoadingState() }
            } else {
                texts.forEachIndexed { index, text ->
                    item(key = "title.$index") { GroupHeader(text.title) }
                    text.paragraphs.forEachIndexed { line, paragraph ->
                        item(key = "text.$index.$line") { LicenseParagraph(paragraph, Modifier.layoutProbe("settings.license.text.$index.$line")) }
                    }
                }
            }
        }
    }
    RestoreFocus(memory, ready = true, fallback = "url")
}

/** A paragraph of a licence text; it takes focus, so a remote scrolls through a long text a paragraph at a time. */
@Composable
private fun LicenseParagraph(paragraph: String, modifier: Modifier) {
    val interactions = remember { MutableInteractionSource() }
    val focused by interactions.collectIsFocusedAsState()
    Text(
        paragraph,
        modifier
            .fillMaxWidth()
            .focusable(interactionSource = interactions)
            .background(if (focused) PlezyColors.SurfaceHighest else PlezyColors.Background, MaterialTheme.shapes.small)
            .padding(horizontal = 16.dp, vertical = 4.dp),
        style = MaterialTheme.typography.bodySmall,
    )
}
