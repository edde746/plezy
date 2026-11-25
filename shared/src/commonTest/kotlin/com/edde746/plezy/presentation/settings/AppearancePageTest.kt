package com.edde746.plezy.presentation.settings

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.settings.AppearancePage.Companion as Appearance
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Settings → Appearance. */
class AppearancePageTest {
    @Test
    fun rendersEveryGroupAndNothingThatMovedAway() = runTest {
        val page = settingsFixture().page(SettingsPageId.APPEARANCE)
        runCurrent()
        assertEquals(
            listOf(
                "display" to T.settings.display,
                "library" to T.settings.libraryAndCards,
                "home" to T.settings.homeScreen,
                "navigation" to T.settings.navigation,
                "live_tv" to T.settings.liveTv,
            ),
            page.state.groups.map { it.id to it.header },
        )
        assertTrue(page.has(Appearance.LIVE_TV_DEFAULT_FAVORITES))
        // Moved to General and Advanced.
        assertFalse(page.has(GeneralPage.REQUIRE_PROFILE_SELECTION))
        assertFalse(page.has(HubPage.AUTO_HIDE_PLAYBACK_INFO))
    }

    @Test
    fun theThemeEntryOpensThePickerAndNamesTheThemeInUse() = runTest {
        val fixture = settingsFixture()
        val page = fixture.page(SettingsPageId.APPEARANCE)
        runCurrent()
        page.store.activate(Appearance.THEME)
        assertEquals(SettingsEvent.Open(SettingsPageId.THEME), page.events.last())

        fixture.data.deviceSettings.set(AppSettings.themeMode, ThemeMode.PLUM)
        runCurrent()
        val theme = page.rowOf<SettingLinkRow>(Appearance.THEME)
        assertEquals(T.settings.plumTheme, theme.trailingValue)
        assertNull(theme.subtitle)
    }

    @Test
    fun rowsFollowTheLayout() = runTest {
        val tv = settingsFixture(SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV)).page(SettingsPageId.APPEARANCE)
        runCurrent()
        for (id in listOf(Appearance.TV_FULL_CARDS, Appearance.GRID_SPACING, Appearance.APP_ICON, Appearance.VISUAL_EFFECTS)) assertTrue(tv.has(id), id)
        // No TV UI draws the corner spotlight backdrop: the stored setting has no row.
        for (id in listOf(Appearance.SHOW_SEASON_POSTERS, Appearance.SHOW_NAV_BAR_LABELS, AppSettings.focusGlow.key, AppSettings.tvCornerSpotlightBackdrop.key)) assertFalse(tv.has(id), id)

        val desktop = settingsFixture().page(SettingsPageId.APPEARANCE)
        runCurrent()
        for (id in listOf(Appearance.APP_ICON, Appearance.VISUAL_EFFECTS, Appearance.TV_FULL_CARDS, Appearance.SHOW_EXPLORE_TAB)) assertFalse(desktop.has(id), id)
        assertTrue(desktop.has(Appearance.GROUP_LIBRARIES_BY_SERVER))
    }

    @Test
    fun navigationRowsShowOnlyWhereTheUiHonoursThem() = runTest {
        fun TestScope.rows(platform: SettingsPlatform): Set<String> {
            val page = settingsFixture(platform).page(SettingsPageId.APPEARANCE)
            runCurrent()
            return listOf(Appearance.SHOW_NAV_BAR_LABELS, Appearance.ALWAYS_KEEP_SIDEBAR_OPEN).filter { page.has(it) }.toSet()
        }
        assertEquals(setOf(Appearance.SHOW_NAV_BAR_LABELS), rows(SettingsPlatform(os = "Android", formFactor = FormFactor.HANDHELD)))
        assertEquals(emptySet(), rows(SettingsPlatform(os = "iOS", deviceModel = "iPhone", formFactor = FormFactor.HANDHELD)))
        assertEquals(setOf(Appearance.ALWAYS_KEEP_SIDEBAR_OPEN), rows(SettingsPlatform(os = "iOS", deviceModel = "iPad", formFactor = FormFactor.HANDHELD)))
        assertEquals(emptySet(), rows(SettingsPlatform(os = "tvOS", isTv = true, formFactor = FormFactor.TV, appleTv = true)))
        assertEquals(emptySet(), rows(SettingsPlatform(os = "Windows")))
        assertEquals(emptySet(), rows(SettingsPlatform(os = "Linux")))
        assertEquals(setOf(Appearance.ALWAYS_KEEP_SIDEBAR_OPEN), rows(SettingsPlatform(os = "macOS")))
    }

    @Test
    fun gridSpacingHidesOffTvOnPosterCardPlatformsAndFocusGlowNowhere() = runTest {
        val phone = settingsFixture(SettingsPlatform(os = "Android", formFactor = FormFactor.HANDHELD)).page(SettingsPageId.APPEARANCE)
        runCurrent()
        assertFalse(phone.has(Appearance.GRID_SPACING))

        val appleTv = settingsFixture(SettingsPlatform(os = "tvOS", isTv = true, formFactor = FormFactor.TV, appleTv = true)).page(SettingsPageId.APPEARANCE)
        runCurrent()
        assertFalse(appleTv.has(AppSettings.focusGlow.key))
        assertTrue(appleTv.has(Appearance.GRID_SPACING))
    }
}
