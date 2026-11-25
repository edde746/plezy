package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope

/**
 * Settings → About: "Version {version}" and the description above the groups ([SettingsPageUiState.header]:
 * the version line, then the description), then Open Source Licenses.
 */
internal class AboutPage(
    settings: DeviceSettingsRepository,
    private val version: String,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.about.title }) {
    init {
        start(emptyList())
    }

    override fun header(): String = "${T.about.versionLabel(version)}\n${T.about.appDescription}"

    override fun build(rows: Rows): List<SettingsGroup> = listOf(
        SettingsGroup(
            "licenses",
            null,
            listOf(rows.page(LICENSES, T.about.openSourceLicenses, T.about.viewLicensesDescription, SettingIcon.ARTICLE, SettingsPageId.LICENSES)),
        ),
    )

    companion object {
        const val LICENSES = "licenses"
    }
}
