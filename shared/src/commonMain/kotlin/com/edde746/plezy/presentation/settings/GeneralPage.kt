package com.edde746.plezy.presentation.settings

import com.edde746.plezy.data.settings.DeviceSettingsRepository
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.StartupSection
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.Locales
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.StateFlow

/**
 * Settings → General: the interface language, the startup section, the profile prompt (with more than
 * one profile), Force TV mode (Android and desktop systems) and fullscreen at launch (desktop systems).
 */
internal class GeneralPage(
    settings: DeviceSettingsRepository,
    private val session: SettingsSession,
    private val facts: StateFlow<SettingsFacts>,
    parentScope: CoroutineScope,
) : RowPageStore(settings, parentScope, { T.settings.general }) {
    private var profileCount = 0

    init {
        follow(session.profiles) { profileCount = it.size }
        follow(InterfaceLocale.tag) {}
        start(
            listOf(AppSettings.appLocale, AppSettings.startupSection, AppSettings.requireProfileSelectionOnOpen, AppSettings.forceTvMode, AppSettings.startInFullscreen),
        )
    }

    override fun build(rows: Rows): List<SettingsGroup> {
        val facts = facts.value
        return listOfNotNull(
            SettingsGroup("language", T.settings.languageAndRegion, listOf(languageRow(rows))),
            SettingsGroup(
                "startup",
                T.settings.startup,
                listOfNotNull(
                    rows.choice(
                        STARTUP_SECTION,
                        AppSettings.startupSection,
                        T.settings.startupSection,
                        choices(StartupSection.entries, { NavigationTabs.startupOf(it).label }),
                        SettingIcon.HOME,
                    ),
                    if (profileCount > 1) {
                        rows.toggle(
                            REQUIRE_PROFILE_SELECTION,
                            AppSettings.requireProfileSelectionOnOpen,
                            T.settings.requireProfileSelectionOnOpen,
                            T.settings.requireProfileSelectionOnOpenDescription,
                            SettingIcon.PERSON,
                        )
                    } else {
                        null
                    },
                    if (facts.android || facts.desktopOs) {
                        rows.toggle(FORCE_TV_MODE, AppSettings.forceTvMode, T.settings.forceTvMode, T.settings.forceTvModeDescription, SettingIcon.TV)
                    } else {
                        null
                    },
                ),
            ),
            if (facts.desktopOs) {
                SettingsGroup(
                    "window",
                    T.settings.window,
                    listOf(rows.toggle(START_IN_FULLSCREEN, AppSettings.startInFullscreen, T.settings.startInFullscreen, T.settings.startInFullscreenDescription, SettingIcon.FULLSCREEN)),
                )
            } else {
                null
            },
        )
    }

    /**
     * The interface language: every language named in itself, the one in use shown and marked in the menu (the
     * device's while none was chosen); a pick switches the interface at once. No "system" option: only Reset returns to
     * the device's languages.
     */
    private fun languageRow(rows: Rows): SettingChoiceRow {
        val stored = AppLocale.fromStored(value(AppSettings.appLocale))
        val shown = Locales.resolve(T.locale).let { tag -> LANGUAGE_CHOICES.firstOrNull { (locale, _) -> locale.tag == tag } }
        return rows.choice(
            LANGUAGE,
            T.settings.language,
            LANGUAGE_CHOICES.map { (locale, name) -> Choice<AppLocale?>(locale, locale.storedName, name) },
            stored ?: shown?.first,
            SettingIcon.LANGUAGE,
            unselectedLabel = shown?.second.orEmpty(),
        ) { picked ->
            val locale = checkNotNull(picked)
            InterfaceLocale.setChosen(locale.tag)
            write(AppSettings.appLocale, locale.storedName)
        }
    }

    companion object {
        const val LANGUAGE = "language"
        const val STARTUP_SECTION = "startup_section"
        const val REQUIRE_PROFILE_SELECTION = "require_profile_selection_on_open"
        const val FORCE_TV_MODE = "force_tv_mode"
        const val START_IN_FULLSCREEN = "start_in_fullscreen"
    }
}
