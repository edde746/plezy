package com.edde746.plezy.presentation.settings

import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.model.AccountPreferenceTarget
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.ThemeMode
import com.edde746.plezy.presentation.settings.HubPage.Companion as Hub
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.T
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.updates.AppUpdates
import com.edde746.plezy.updates.Updater
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import com.edde746.plezy.servers.LibrariesLoadState
import com.edde746.plezy.servers.LibrariesState

/** A GitHub latest-release answer for [tag]. */
private fun MockRequestHandleScope.release(tag: String, notes: String = "") = respond(
    """{"tag_name":"$tag","html_url":"https://example.com/$tag","published_at":"2026-10-01T00:00:00Z","body":"$notes"}""",
    HttpStatusCode.OK,
    headersOf(HttpHeaders.ContentType, "application/json"),
)

/** The Settings hub: its rows, the relay, reset, export and import, updates. */
class HubPageTest {
    /** The GitHub releases [updater]'s check reads: [answer] once [gate] (when set) opens. */
    private class Releases(private val scope: TestScope, private val updater: Updater = Updater.GITHUB) {
        var gate: CompletableDeferred<Unit>? = null
        var answer: MockRequestHandleScope.() -> HttpResponseData = { release("v1.0.0") }
        var requests = 0

        fun build(graph: AppGraph) = AppUpdates(
            updater,
            HttpClient(
                MockEngine.create {
                    dispatcher = StandardTestDispatcher(scope.testScheduler)
                    addHandler {
                        requests++
                        gate?.await()
                        answer()
                    }
                },
            ) { install(HttpTimeout) },
            graph.data.deviceSettings,
            currentVersion = "1.0.0",
            clock = graph.clock,
            scope = graph.scope,
        )
    }

    @Test
    fun desktopHubListsEveryGroupInOrderWithFocusKeys() = runTest {
        val session = FakeSettingsSession().apply { hasLibraries.value = true }
        val fixture = settingsFixture(session = session, updates = Releases(this)::build)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertEquals(
            listOf(
                Hub.SUPPORTER, Hub.GENERAL, Hub.APPEARANCE, Hub.PLAYBACK, Hub.MANAGE_LIBRARIES, Hub.SERVICES,
                Hub.ADD_CONNECTION, Hub.PROFILES,
                Hub.DOWNLOAD_LOCATION, Hub.DOWNLOAD_ON_WIFI_ONLY, Hub.AUTO_REMOVE_WATCHED,
                Hub.VIDEO_PLAYER_CONTROLS, Hub.VIDEO_PLAYER_NAVIGATION, Hub.CAST_ALLOW,
                Hub.WATCH_TOGETHER_RELAY, Hub.CRASH_REPORTING, Hub.DEBUG_LOGGING, Hub.SHOW_PLAYBACK_INFO, Hub.AUTO_HIDE_PLAYBACK_INFO,
                Hub.VIEW_LOGS,
                Hub.CLEAR_IMAGE_CACHE, Hub.RESET_SETTINGS,
                Hub.CHECK_FOR_UPDATES, Hub.AUTO_CHECK_UPDATES,
                Hub.EXPORT_SETTINGS, Hub.IMPORT_SETTINGS,
                Hub.ABOUT,
            ),
            hub.ids,
        )
        assertEquals(T.settings.servicesDescription, hub.rowOf<SettingLinkRow>(Hub.SERVICES).subtitle)
        hub.store.activate(Hub.SERVICES)
        assertEquals(SettingsEvent.OpenExternal(ExternalTarget.SERVICES), hub.events.last())
        hub.store.activate(Hub.MANAGE_LIBRARIES)
        assertEquals(SettingsEvent.Open(SettingsPageId.MANAGE_LIBRARIES), hub.events.last())
    }

    @Test
    fun appleTvHasNoDownloadsBackupOrUpdates() = runTest {
        val fixture = settingsFixture(SettingsPlatform(os = "tvOS", isTv = true, formFactor = FormFactor.TV, appleTv = true, hasFileDialogs = false))
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        val groups = hub.state.groups.map { it.id }
        assertFalse("downloads" in groups)
        assertFalse("backup" in groups)
        assertFalse("updates" in groups)
        assertFalse(hub.has(Hub.MANAGE_LIBRARIES))
        assertFalse(hub.has(Hub.VIDEO_PLAYER_CONTROLS))
    }

    @Test
    fun androidPhoneShowsBackgroundDownloadsAndNoKeyboardRows() = runTest {
        val fixture = settingsFixture(SettingsPlatform(os = "Android", formFactor = FormFactor.HANDHELD))
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertTrue(hub.has(Hub.BACKGROUND_DOWNLOADS))
        assertFalse(hub.has(Hub.VIDEO_PLAYER_CONTROLS))
    }

    @Test
    fun appearanceSubtitleFollowsThemeAndDensity() = runTest {
        val fixture = settingsFixture()
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        fixture.data.deviceSettings.set(AppSettings.libraryDensity, 5)
        runCurrent()
        fixture.checkFailures()
        assertTrue(hub.rowOf<SettingLinkRow>(Hub.APPEARANCE).subtitle!!.endsWith("${T.settings.libraryDensity} 5/5"))
    }

    @Test
    fun appearanceSubtitleNamesTheThemeOnScreenAndFollowsIt() = runTest {
        val fixture = settingsFixture()
        val settings = fixture.data.deviceSettings
        settings.set(AppSettings.themeMode, ThemeMode.LIGHT)
        settings.set(AppSettings.libraryDensity, 2)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertEquals("${themeLabel(ThemeMode.LIGHT)} · ${T.settings.libraryDensity} 2/5", hub.rowOf<SettingLinkRow>(Hub.APPEARANCE).subtitle)

        settings.set(AppSettings.themeMode, ThemeMode.DARK)
        runCurrent()
        assertEquals("${themeLabel(ThemeMode.DARK)} · ${T.settings.libraryDensity} 2/5", hub.rowOf<SettingLinkRow>(Hub.APPEARANCE).subtitle)
    }

    @Test
    fun connectionRowsNameTheActiveProfileAndTheAccountsWithPreferences() = runTest {
        val session = FakeSettingsSession()
        val hub = settingsFixture(session = session).page(SettingsPageId.HUB)
        runCurrent()
        assertEquals(T.connections.addConnectionSubtitleNoProfile, hub.rowOf<SettingLinkRow>(Hub.ADD_CONNECTION).subtitle)
        assertEquals(T.profiles.summarySingle, hub.rowOf<SettingLinkRow>(Hub.PROFILES).subtitle)
        assertFalse(hub.has(Hub.ACCOUNT_PREFERENCES))

        val me = LocalProfile("p1", "Me", createdAt = 0)
        session.profiles.value = listOf(me, LocalProfile("p2", "You", createdAt = 0))
        runCurrent()
        assertEquals(T.profiles.summaryMultiple("2"), hub.rowOf<SettingLinkRow>(Hub.PROFILES).subtitle)

        session.accounts = listOf(preferencesAccount("a", "Living Room"))
        session.activeProfile.value = me
        runCurrent()
        assertEquals(T.connections.addConnectionSubtitleScoped("Me"), hub.rowOf<SettingLinkRow>(Hub.ADD_CONNECTION).subtitle)
        assertEquals(T.profiles.summaryMultipleWithActive("2", "Me"), hub.rowOf<SettingLinkRow>(Hub.PROFILES).subtitle)
        assertEquals(T.accountPreferences.hubSubtitleSingle("Living Room"), hub.rowOf<SettingLinkRow>(Hub.ACCOUNT_PREFERENCES).subtitle)

        session.accounts = listOf(preferencesAccount("a", "Living Room"), preferencesAccount("b", "Den"))
        hub.store.resumed()
        runCurrent()
        assertEquals(T.accountPreferences.hubSubtitleMultiple("2"), hub.rowOf<SettingLinkRow>(Hub.ACCOUNT_PREFERENCES).subtitle)
        hub.store.activate(Hub.ACCOUNT_PREFERENCES)
        assertEquals(SettingsEvent.Open(SettingsPageId.ACCOUNT_PREFERENCES), hub.events.last())
        hub.store.activate(Hub.PROFILES)
        assertEquals(SettingsEvent.OpenExternal(ExternalTarget.PROFILES), hub.events.last())
    }

    @Test
    fun logOutHasItsOwnGroupAfterConnectionsOnceAProfileIsActive() = runTest {
        val session = FakeSettingsSession()
        val hub = settingsFixture(session = session).page(SettingsPageId.HUB)
        runCurrent()
        assertFalse(hub.has(Hub.LOGOUT))

        session.activeProfile.value = LocalProfile("p1", "Me", createdAt = 0)
        runCurrent()
        val groups = hub.state.groups
        val logOutGroup = groups[groups.indexOfFirst { it.id == "connections" } + 1]
        assertEquals(null, logOutGroup.header)
        assertEquals(listOf(Hub.LOGOUT), logOutGroup.rows.map { it.id })
        val logOut = hub.rowOf<SettingLinkRow>(Hub.LOGOUT)
        assertEquals(T.common.logout, logOut.title)
        assertTrue(logOut.destructive)
        hub.store.activate(Hub.LOGOUT)
        assertEquals(SettingsEvent.OpenExternal(ExternalTarget.LOGOUT), hub.events.last())
    }

    @Test
    fun hubShowsItsRowsOnlyOnceTheyAreAllKnownSoNoneMoves() = runTest {
        val me = LocalProfile("p1", "Me", createdAt = 0)
        val gate = CompletableDeferred<Unit>()
        val session = FakeSettingsSession().apply {
            hasLibraries.value = true
            profiles.value = listOf(me)
            activeProfile.value = me
            accounts = emptyList()
            accountsGate = gate
            profileBinding.value = true
        }
        val fixture = settingsFixture(session = session)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertTrue(hub.state.loading)

        // Listed while the profile binds: its connection isn't stored yet, so the page waits.
        gate.complete(Unit)
        runCurrent()
        assertTrue(hub.state.loading)
        session.accounts = listOf(preferencesAccount("a", "Living Room"))
        session.profileBinding.value = false
        runCurrent()
        assertFalse(hub.state.loading)
        val first = hub.ids
        assertTrue(listOf(Hub.MANAGE_LIBRARIES, Hub.PROFILES, Hub.ACCOUNT_PREFERENCES, Hub.LOGOUT).all { it in first })
        // Shown again later: the accounts are read again, the rows stay as they were meanwhile.
        val again = CompletableDeferred<Unit>()
        session.accountsGate = again
        hub.store.resumed()
        runCurrent()
        assertFalse(hub.state.loading)
        assertEquals(first, hub.ids)
        again.complete(Unit)
    }

    @Test
    fun manageLibrariesKeepsItsPlaceWhileTheProfilesLibrariesLoad() {
        val loading = LibrariesState(loadState = LibrariesLoadState.LOADING)
        val cleared = LibrariesState()
        val loadedEmpty = LibrariesState(loadState = LibrariesLoadState.LOADED)
        // A profile switch: the list is cleared and the new profile's servers bind, then load.
        assertTrue(manageLibrariesShown(cleared, profileActive = true, binding = true, serverCount = 0))
        assertTrue(manageLibrariesShown(loading, profileActive = true, binding = false, serverCount = 1))
        // Loaded without any library, or nothing to load: no row.
        assertFalse(manageLibrariesShown(loadedEmpty, profileActive = true, binding = false, serverCount = 1))
        assertFalse(manageLibrariesShown(cleared, profileActive = true, binding = false, serverCount = 0))
        assertFalse(manageLibrariesShown(cleared, profileActive = false, binding = true, serverCount = 0))
    }

    @Test
    fun backupIsOfferedWhereFileDialogsWorkEvenInForceTvMode() = runTest {
        val androidTv = settingsFixture(SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV, hasFileDialogs = false)).page(SettingsPageId.HUB)
        runCurrent()
        assertFalse("backup" in androidTv.state.groups.map { it.id })

        val fixture = settingsFixture()
        fixture.data.deviceSettings.set(AppSettings.forceTvMode, true)
        val desktop = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertEquals(listOf(Hub.EXPORT_SETTINGS, Hub.IMPORT_SETTINGS), desktop.state.groups.single { it.id == "backup" }.rows.map { it.id })
        assertEquals(SettingIcon.UPLOAD, desktop.rowOf<SettingLinkRow>(Hub.EXPORT_SETTINGS).icon)
        assertEquals(SettingIcon.DOWNLOAD, desktop.rowOf<SettingLinkRow>(Hub.IMPORT_SETTINGS).icon)
        assertTrue(desktop.rowOf<SettingToggleRow>(Hub.VIDEO_PLAYER_NAVIGATION).checked, "the TV layout navigates the player by arrows")
    }

    @Test
    fun theDevicesFeaturesAreDetectedOnceWhenASettingsPageFirstOpens() = runTest {
        val fixture = settingsFixture()
        assertEquals(0, fixture.platform.featureReads, "building the settings stores probes nothing")
        fixture.page(SettingsPageId.HUB)
        fixture.page(SettingsPageId.VIDEO_PLAYBACK)
        fixture.data.deviceSettings.set(AppSettings.forceTvMode, true)
        runCurrent()
        assertEquals(1, fixture.platform.featureReads)
    }

    private fun preferencesAccount(id: String, label: String) =
        AccountPreferenceAccount(AccountPreferenceTarget(AccountRef.mediaBrowser(BackendKind.JELLYFIN, id), label), null)

    @Test
    fun relayRefusesInvalidStoresCanonicalBlankRemovesAndTheRowShowsTheRelayInUse() = runTest {
        val fixture = settingsFixture()
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        hub.store.activate(Hub.WATCH_TOGETHER_RELAY)
        assertIs<SettingsEvent.EditText>(hub.events.last())

        assertNull(hub.store.checkText(Hub.WATCH_TOGETHER_RELAY, "not a relay"), "the relay is checked on Save only")
        assertEquals(T.settings.watchTogetherRelayInvalid, hub.store.submitText(Hub.WATCH_TOGETHER_RELAY, "not a relay"))
        runCurrent()
        assertNull(fixture.data.deviceSettings.value(AppSettings.watchPartyRelayUrl))
        assertEquals(T.settings.watchTogetherRelayPublic, hub.rowOf<SettingLinkRow>(Hub.WATCH_TOGETHER_RELAY).valueLabel)

        val typed = "https://relay.example.com/"
        assertNull(hub.store.submitText(Hub.WATCH_TOGETHER_RELAY, "  $typed "))
        runCurrent()
        val stored = AppSettings.watchPartyRelayUrl.normalize(typed)
        assertEquals(stored, fixture.data.deviceSettings.value(AppSettings.watchPartyRelayUrl))
        // The address is too long to sit beside the title: it is the row's second line.
        val relay = hub.rowOf<SettingLinkRow>(Hub.WATCH_TOGETHER_RELAY)
        assertNull(relay.trailingValue)
        assertEquals(stored, relay.subtitle)

        assertNull(hub.store.submitText(Hub.WATCH_TOGETHER_RELAY, "  "))
        runCurrent()
        assertNull(fixture.data.deviceSettings.value(AppSettings.watchPartyRelayUrl))

        hub.store.submitText(Hub.WATCH_TOGETHER_RELAY, typed)
        runCurrent()
        assertNull(hub.store.resetText(Hub.WATCH_TOGETHER_RELAY), "Reset stores at once and closes the dialog")
        runCurrent()
        assertNull(fixture.data.deviceSettings.value(AppSettings.watchPartyRelayUrl))
    }

    @Test
    fun `a remembered sender is listed and removing it after the confirmation forgets it`() = runTest {
        val fixture = settingsFixture()
        fixture.session.castSenders.value = listOf(CastPeerInfo("phone-1", "Phone", "iOS", CastDeviceKind.HANDHELD))
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        assertEquals("Phone", hub.rowOf<SettingLinkRow>(Hub.CAST_SENDER + "phone-1").title)

        hub.store.activate(Hub.CAST_SENDER + "phone-1")
        val confirm = assertIs<SettingsEvent.Confirm>(hub.events.last())
        assertTrue(confirm.destructive)
        assertEquals(1, fixture.session.castSenders.value.size)
        hub.store.confirm(confirm.id)
        runCurrent()
        assertEquals(emptyList(), fixture.session.castSenders.value)
        assertFalse(hub.has(Hub.CAST_SENDER + "phone-1"))
    }

    @Test
    fun resetAsksThenRestoresDefaultsAndTheDownloadLocation() = runTest {
        val fixture = settingsFixture()
        val settings = fixture.data.deviceSettings
        settings.set(AppSettings.seekTimeSmall, 30)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()

        hub.store.activate(Hub.RESET_SETTINGS)
        val confirm = assertIs<SettingsEvent.Confirm>(hub.events.last())
        assertTrue(confirm.destructive)
        assertEquals(30, settings.value(AppSettings.seekTimeSmall))

        hub.store.confirm(confirm.id)
        runCurrent()
        assertEquals(AppSettings.seekTimeSmall.default, settings.value(AppSettings.seekTimeSmall))
        assertEquals(1, fixture.session.locationResets)
        assertEquals(T.settings.resetSettingsSuccess, hub.messages.last().text)
    }

    @Test
    fun resetMovesTheDownloadLocationFirstAndAFailureThereKeepsTheSettings() = runTest {
        val fixture = settingsFixture()
        val settings = fixture.data.deviceSettings
        settings.set(AppSettings.seekTimeSmall, 30)
        val seenAtLocationReset = mutableListOf<Int>()
        fixture.session.onLocationReset = { seenAtLocationReset += settings.value(AppSettings.seekTimeSmall) }
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()

        hub.store.activate(Hub.RESET_SETTINGS)
        hub.store.confirm(assertIs<SettingsEvent.Confirm>(hub.events.last()).id)
        runCurrent()
        assertEquals(listOf(30), seenAtLocationReset, "the location went back before any setting did")
        assertEquals(AppSettings.seekTimeSmall.default, settings.value(AppSettings.seekTimeSmall))

        settings.set(AppSettings.seekTimeSmall, 45)
        fixture.session.onLocationReset = { throw IllegalStateException("the folder is busy") }
        hub.store.activate(Hub.RESET_SETTINGS)
        hub.store.confirm(assertIs<SettingsEvent.Confirm>(hub.events.last()).id)
        runCurrent()
        assertEquals(45, settings.value(AppSettings.seekTimeSmall), "a failed location reset resets nothing")
        assertNotEquals(T.settings.resetSettingsSuccess, hub.messages.last().text)
    }

    @Test
    fun clearImageCacheConfirmsThenAsksTheUiAndSaysSo() = runTest {
        val hub = settingsFixture().page(SettingsPageId.HUB)
        runCurrent()
        hub.store.activate(Hub.CLEAR_IMAGE_CACHE)
        hub.store.confirm(assertIs<SettingsEvent.Confirm>(hub.events.last()).id)
        runCurrent()
        assertTrue(SettingsEvent.ClearImageCache in hub.events)
        assertEquals(T.settings.clearImageCacheSuccess, hub.messages.last().text)
    }

    @Test
    fun exportOffersTheDatedFileAndReportsTheSave() = runTest {
        val fixture = settingsFixture()
        fixture.data.deviceSettings.set(AppSettings.seekTimeSmall, 25)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()

        hub.store.activate(Hub.EXPORT_SETTINGS)
        runCurrent()
        val file = assertIs<SettingsEvent.SaveFile>(hub.events.last())
        assertTrue(Regex("""plezy-settings-\d{8}\.json""").matches(file.fileName), file.fileName)
        assertTrue("\"seek_time_small\"" in file.bytes.decodeToString())

        hub.store.exported(saved = false)
        assertTrue(hub.messages.isEmpty())
        hub.store.exported(saved = false, error = "disk full")
        runCurrent()
        assertEquals(SettingsEvent.Message(T.settings.saveFailed, error = true), hub.messages.last())
        hub.store.exported(saved = true)
        runCurrent()
        assertEquals(T.settings.exportSettingsSuccess, hub.messages.last().text)
    }

    @Test
    fun importNeedsAProfileAValidFileAndReloadsTheLibraries() = runTest {
        val session = FakeSettingsSession()
        val fixture = settingsFixture(session = session)
        val settings = fixture.data.deviceSettings
        settings.set(AppSettings.seekTimeSmall, 25)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        hub.store.activate(Hub.EXPORT_SETTINGS)
        runCurrent()
        val exported = assertIs<SettingsEvent.SaveFile>(hub.events.last()).bytes
        settings.set(AppSettings.seekTimeSmall, 5)

        hub.store.activate(Hub.IMPORT_SETTINGS)
        hub.store.confirm(assertIs<SettingsEvent.Confirm>(hub.events.last()).id)
        assertEquals(SettingsEvent.OpenFile, hub.events.last())

        hub.store.imported(null)
        runCurrent()
        assertTrue(hub.messages.isEmpty())

        hub.store.imported(exported)
        runCurrent()
        assertEquals(SettingsEvent.Message(T.settings.importSettingsNoUser, error = true), hub.messages.last())

        session.activeProfile.value = LocalProfile("p1", "Me", createdAt = 0)
        runCurrent()
        hub.store.imported("{}".encodeToByteArray())
        runCurrent()
        assertEquals(SettingsEvent.Message(T.settings.importSettingsInvalidFile, error = true), hub.messages.last())

        hub.store.imported(exported)
        runCurrent()
        assertEquals(T.settings.importSettingsSuccess, hub.messages.last().text)
        assertEquals(25, settings.value(AppSettings.seekTimeSmall))
        assertEquals(1, session.reloads)
        assertEquals("p1", profileUserScope("p1"))
    }

    @Test
    fun updatesGroupShowsOnlyWhereTheInstallUpdatesItself() = runTest {
        assertFalse("updates" in settingsFixture().page(SettingsPageId.HUB).state.groups.map { it.id })
        val none = settingsFixture(updates = Releases(this, Updater.NONE)::build).page(SettingsPageId.HUB)
        assertFalse("updates" in none.state.groups.map { it.id })
        val github = settingsFixture(updates = Releases(this)::build).page(SettingsPageId.HUB)
        assertEquals(listOf(Hub.CHECK_FOR_UPDATES, Hub.AUTO_CHECK_UPDATES), github.state.groups.single { it.id == "updates" }.rows.map { it.id })
        assertEquals(SettingIcon.CHECK_CIRCLE, github.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES).icon)
        val native = settingsFixture(updates = Releases(this, Updater.NATIVE)::build).page(SettingsPageId.HUB)
        assertEquals(SettingIcon.SYSTEM_UPDATE, native.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES).icon)
    }

    @Test
    fun updateCheckSpinsThenSaysLatestReportsFailureOrOffersTheRelease() = runTest {
        val releases = Releases(this)
        val hub = settingsFixture(updates = releases::build).page(SettingsPageId.HUB)
        runCurrent()

        releases.gate = CompletableDeferred()
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        runCurrent()
        assertTrue(hub.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES).busy)
        // A second tap while checking doesn't check again.
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        releases.gate!!.complete(Unit)
        runCurrent()
        assertEquals(1, releases.requests)
        assertFalse(hub.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES).busy)
        assertEquals(SettingsEvent.Message(T.update.latestVersion), hub.messages.last())
        releases.gate = null

        releases.answer = { respond("unavailable", HttpStatusCode.ServiceUnavailable) }
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        runCurrent()
        assertEquals(SettingsEvent.Message(T.update.checkFailed, error = true), hub.messages.last())
        assertFalse(hub.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES).busy)

        releases.answer = { release("v2.0.0", notes = "notes") }
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        runCurrent()
        val offered = SettingsEvent.UpdateAvailable("2.0.0", "notes", "https://example.com/v2.0.0")
        assertEquals(offered, hub.events.last())
        val row = hub.rowOf<SettingLinkRow>(Hub.CHECK_FOR_UPDATES)
        assertEquals(T.settings.updateAvailable, row.title)
        assertEquals(T.update.versionAvailable("2.0.0"), row.subtitle)
        assertTrue(row.accent)

        // Tapping the found update opens its dialog again, without another check.
        hub.events.clear()
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        runCurrent()
        assertEquals(listOf<SettingsEvent>(offered), hub.events)
        assertEquals(3, releases.requests)
    }

    @Test
    fun nativeUpdaterChecksItself() = runTest {
        val releases = Releases(this, Updater.NATIVE)
        val hub = settingsFixture(updates = releases::build).page(SettingsPageId.HUB)
        runCurrent()
        hub.store.activate(Hub.CHECK_FOR_UPDATES)
        runCurrent()
        assertEquals(SettingsEvent.NativeUpdateCheck, hub.events.last())
        assertEquals(0, releases.requests)
        assertTrue(hub.messages.isEmpty())
    }

    @Test
    fun autoCheckOnStartupToggleIsStored() = runTest {
        val fixture = settingsFixture(updates = Releases(this)::build)
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        val initial = fixture.data.deviceSettings.value(AppSettings.autoCheckUpdatesOnStartup)
        assertEquals(initial, hub.rowOf<SettingToggleRow>(Hub.AUTO_CHECK_UPDATES).checked)
        hub.store.toggle(Hub.AUTO_CHECK_UPDATES, !initial)
        runCurrent()
        assertEquals(!initial, fixture.data.deviceSettings.value(AppSettings.autoCheckUpdatesOnStartup))
        assertEquals(!initial, hub.rowOf<SettingToggleRow>(Hub.AUTO_CHECK_UPDATES).checked)
    }

    @Test
    fun debugLoggingToggleIsStored() = runTest {
        val fixture = settingsFixture()
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        hub.store.toggle(Hub.DEBUG_LOGGING, true)
        runCurrent()
        assertTrue(fixture.data.deviceSettings.value(AppSettings.enableDebugLogging))
        assertTrue(hub.rowOf<SettingToggleRow>(Hub.DEBUG_LOGGING).checked)
    }

    @Test
    fun crashReportingToggleIsStored() = runTest {
        val fixture = settingsFixture()
        val hub = fixture.page(SettingsPageId.HUB)
        runCurrent()
        hub.store.toggle(Hub.CRASH_REPORTING, false)
        runCurrent()
        assertFalse(fixture.data.deviceSettings.value(AppSettings.crashReporting))
        assertFalse(hub.rowOf<SettingToggleRow>(Hub.CRASH_REPORTING).checked)
    }
}
