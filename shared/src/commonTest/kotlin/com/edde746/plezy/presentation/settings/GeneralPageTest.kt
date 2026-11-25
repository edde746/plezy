package com.edde746.plezy.presentation.settings

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.navigation.NavigationTabs
import com.edde746.plezy.presentation.settings.GeneralPage.Companion as General
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.StartupSection
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Settings → General. */
class GeneralPageTest {
    @AfterTest
    fun restoreLocale() {
        InterfaceLocale.setChosen(null)
        InterfaceLocale.setSystemLanguages(listOf("en"))
    }

    /** A language picked is stored, and the page it was picked on (its title too) is in it at once. */
    @Test
    fun choosingALanguageStoresItAndThePageShowsInIt() = runTest {
        val fixture = settingsFixture()
        val page = fixture.page(SettingsPageId.GENERAL)
        runCurrent()
        val german = page.rowOf<SettingChoiceRow>(General.LANGUAGE).options.first { it.id == "de" }
        val english = page.store.state.value.title

        page.store.choose(General.LANGUAGE, german.id)
        runCurrent()
        assertEquals("de", fixture.data.deviceSettings.value(AppSettings.appLocale))
        assertEquals(german.label, page.rowOf<SettingChoiceRow>(General.LANGUAGE).valueLabel)
        assertEquals(T.settings.general, page.store.state.value.title, "the page's title stayed \"$english\"")
        assertTrue(T.settings.general != english, "German titles the page \"$english\" too")
    }

    @Test
    fun everyLanguageIsListedInItsOwnNameWithNoSystemOptionAndTheOneInUseIsMarked() = runTest {
        val page = settingsFixture().page(SettingsPageId.GENERAL)
        runCurrent()
        val row = page.rowOf<SettingChoiceRow>(General.LANGUAGE)
        assertEquals(
            listOf(
                "English", "Azərbaycanca", "Български", "Dansk", "Deutsch", "Español", "Français", "Magyar", "Italiano", "日本語", "Қазақша",
                "한국어", "Norsk bokmål", "Nederlands", "Polski", "Português (Brasil)", "Português (Portugal)", "Русский", "Svenska", "Türkçe",
                "Oʻzbekcha", "简体中文", "繁體中文",
            ),
            row.options.map { it.label },
        )
        assertEquals("zhHant", row.options.last().id)
        assertEquals(listOf("English"), row.options.filter { it.selected }.map { it.label }, "the device's language, in use while none was chosen")
        assertEquals("English", row.valueLabel)
    }

    @Test
    fun aDeviceInARegionThatWritesEuropeanPortugueseShowsPortugalsPortuguese() = runTest {
        InterfaceLocale.setSystemLanguages(listOf("pt-AO"))
        val page = settingsFixture().page(SettingsPageId.GENERAL)
        runCurrent()
        val row = page.rowOf<SettingChoiceRow>(General.LANGUAGE)
        assertEquals("Português (Portugal)", row.valueLabel)
        assertEquals(listOf("Português (Portugal)"), row.options.filter { it.selected }.map { it.label })
    }

    @Test
    fun showsLanguageAndStartupAndHidesTheProfilePromptForOneProfile() = runTest {
        val session = FakeSettingsSession().apply { profiles.value = listOf(LocalProfile("p1", "Me", createdAt = 0)) }
        val page = settingsFixture(session = session).page(SettingsPageId.GENERAL)
        runCurrent()
        assertEquals(T.settings.language, page.row(General.LANGUAGE).title)
        assertEquals(T.settings.startupSection, page.row(General.STARTUP_SECTION).title)
        assertFalse(page.has(General.REQUIRE_PROFILE_SELECTION))
        // A desktop OS: the window group applies.
        assertTrue(page.has(General.START_IN_FULLSCREEN))
        assertTrue(page.has(General.FORCE_TV_MODE))

        session.profiles.value = session.profiles.value + LocalProfile("p2", "You", createdAt = 0)
        runCurrent()
        assertTrue(page.has(General.REQUIRE_PROFILE_SELECTION))
    }

    @Test
    fun phonesHaveNoWindowGroupAndAppleHasNoForceTv() = runTest {
        val android = settingsFixture(SettingsPlatform(os = "Android", formFactor = FormFactor.HANDHELD)).page(SettingsPageId.GENERAL)
        runCurrent()
        assertFalse(android.has(General.START_IN_FULLSCREEN))
        assertTrue(android.has(General.FORCE_TV_MODE))
        val iphone = settingsFixture(SettingsPlatform(os = "iOS", formFactor = FormFactor.HANDHELD, hasFileDialogs = false)).page(SettingsPageId.GENERAL)
        runCurrent()
        assertFalse(iphone.has(General.FORCE_TV_MODE))
    }

    @Test
    fun changesTheStoredStartupSection() = runTest {
        val fixture = settingsFixture()
        fixture.recordWrites(AppSettings.startupSection.key)
        val page = fixture.page(SettingsPageId.GENERAL)
        runCurrent()
        val libraries = NavigationTabs.startupOf(StartupSection.LIBRARIES).label
        assertTrue(libraries in page.rowOf<SettingChoiceRow>(General.STARTUP_SECTION).options.map { it.label })

        page.store.choose(General.STARTUP_SECTION, StartupSection.LIBRARIES.name)
        runCurrent()
        assertEquals(StartupSection.LIBRARIES, fixture.data.deviceSettings.value(AppSettings.startupSection))
        assertEquals(listOf("\"libraries\""), fixture.writes(AppSettings.startupSection.key))
        assertEquals(libraries, page.rowOf<SettingChoiceRow>(General.STARTUP_SECTION).valueLabel)
    }
}
