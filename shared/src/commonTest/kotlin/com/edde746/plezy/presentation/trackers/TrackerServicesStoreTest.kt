package com.edde746.plezy.presentation.trackers

import com.edde746.plezy.data.tracker.TrackerAccount
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.TrackerLibraryFilterMode
import com.edde746.plezy.strings.T
import com.edde746.plezy.trackers.DeviceCodeGrant
import com.edde746.plezy.trackers.DevicePoll
import com.edde746.plezy.trackers.FAR_FUTURE
import com.edde746.plezy.trackers.FakeDeviceCode
import com.edde746.plezy.trackers.FakeRelay
import com.edde746.plezy.trackers.FakeRelaySignIn
import com.edde746.plezy.trackers.RelayResult
import com.edde746.plezy.trackers.TrackerFixture
import com.edde746.plezy.trackers.TrackerService
import com.edde746.plezy.trackers.TrackerService.ANILIST
import com.edde746.plezy.trackers.TrackerService.MDBLIST
import com.edde746.plezy.trackers.TrackerService.MYANIMELIST
import com.edde746.plezy.trackers.TrackerService.SIMKL
import com.edde746.plezy.trackers.TrackerService.TRAKT
import com.edde746.plezy.trackers.TrackerSession
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/**
 * Settings > Services: the hub's rows, the connect dialog's life (it closes when the sign-in resolves, a failure leaves a
 * message, a cancel cancels once and says nothing, leaving cancels), each connected service's settings and the library
 * filter, which writes at once.
 */
class TrackerServicesStoreTest {
    private val fixtures = mutableListOf<TrackerFixture>()
    private val stores = mutableListOf<TrackerServicesStore>()

    @AfterTest
    fun close() {
        stores.forEach { it.release() }
        fixtures.forEach { it.close() }
    }

    private val libraries = MutableStateFlow<List<MediaLibrary>>(emptyList())

    private fun TestScope.setUp(relay: FakeRelay? = null, discordOffered: Boolean = false): Pair<TrackerFixture, TrackerServicesStore> {
        val f = TrackerFixture(this, relay = relay).also { fixtures += it }
        val store = TrackerServicesStore(f.profileId, f.hub.accounts, f.data.deviceSettings, libraries, backgroundScope, discordOffered)
            .also { stores += it }
        f.settle()
        return f to store
    }

    private val grant = DeviceCodeGrant("dc", "ABCD-1234", "https://trakt.tv/activate/", "https://trakt.tv/activate/ABCD-1234", 600, 5)

    /** [service]'s sign-in: approved at the first poll with [answers] unless given, its lookup held while [held]. */
    private fun TrackerFixture.deviceCode(service: TrackerService, answers: List<DevicePoll> = listOf(DevicePoll.Success(JsonObject(emptyMap()))), held: Boolean = false) =
        FakeDeviceCode(scope, answers, grant).also {
            if (held) it.lookupGate = CompletableDeferred()
            providers.getValue(service).deviceCode = it
        }

    @Test
    fun theHubListsTheServicesInOrderWithTheirAccounts() = runTest {
        val (f, store) = setUp()
        f.connect(TRAKT, TrackerSession("a", "r", FAR_FUTURE, "sean", 1))
        f.connect(SIMKL, TrackerSession("a", null, null, null, 1))
        f.settle()
        val rows = store.state.value.rows
        assertEquals(listOf(TRAKT, MYANIMELIST, ANILIST, SIMKL, MDBLIST), rows.map { it.service })
        assertEquals(listOf(T.trakt.title, T.services.names.mal, T.services.names.anilist, T.services.names.simkl, T.services.names.mdblist), rows.map { it.title })
        assertEquals(T.services.connectedAs("sean"), rows[0].subtitle)
        assertEquals(T.trakt.connected, rows[3].subtitle, "connected without a name: plain Connected")
        assertEquals(T.services.notConnected, rows[1].subtitle)
        assertEquals(listOf(true, false, false, true, false), rows.map { it.connected })
        assertEquals(T.services.hubSubtitle, store.state.value.subtitle)
    }

    @Test
    fun aServiceThisBuildCantConnectIsNotListed() = runTest {
        val f = TrackerFixture(this, services = listOf(SIMKL, TRAKT)).also { fixtures += it }
        val store = TrackerServicesStore(f.profileId, f.hub.accounts, f.data.deviceSettings, libraries, backgroundScope).also { stores += it }
        f.settle()
        assertEquals(listOf(TRAKT, SIMKL), store.state.value.rows.map { it.service })
    }

    @Test
    fun aSuccessfulSignInClosesTheDialogWithoutAMessage() = runTest {
        val (f, store) = setUp()
        val signIn = f.deviceCode(TRAKT, held = true)
        store.connect(TRAKT, pointer = false)
        f.advance(6.seconds)
        val dialog = assertIs<ConnectDialogUi.DeviceCode>(store.state.value.dialog)
        assertEquals("ABCD-1234", dialog.userCode)
        assertEquals("https://trakt.tv/activate/ABCD-1234", dialog.url, "the QR code and the open button take the prefilled link")
        assertEquals("trakt.tv/activate", dialog.readableUrl, "shown without its scheme and trailing slashes")
        assertEquals(T.services.deviceCode.title(T.trakt.title), dialog.title)
        assertNull(store.state.value.openUrl, "keyboard and D-pad: nothing opens by itself")
        assertTrue(store.state.value.rows.first { it.service == TRAKT }.busy)

        signIn.lookupGate!!.complete(Unit)
        f.settle()
        val state = store.state.value
        assertNull(state.dialog)
        assertNull(state.message)
        assertTrue(state.rows.first { it.service == TRAKT }.connected)
        assertNotNull(state.settings(TRAKT))
    }

    @Test
    fun aFailedSignInClosesTheDialogAndSaysSo() = runTest {
        val (f, store) = setUp()
        f.deviceCode(SIMKL, listOf(DevicePoll.Denied))
        store.connect(SIMKL, pointer = true)
        f.settle()
        assertEquals("https://trakt.tv/activate/ABCD-1234", store.state.value.openUrl, "pointer input opens the link")
        store.urlOpened()
        f.advance(10.seconds)
        assertNull(store.state.value.dialog)
        assertEquals(T.services.connectFailed(T.services.names.simkl), store.state.value.message)
        store.messageShown()
        assertNull(store.state.value.message)
    }

    @Test
    fun cancellingCancelsOnceAndSaysNothing() = runTest {
        val (f, store) = setUp()
        f.deviceCode(TRAKT, emptyList())
        store.connect(TRAKT, pointer = false)
        f.advance(6.seconds)
        assertNotNull(store.state.value.dialog)
        store.cancelConnect()
        // The system back after the Cancel button.
        store.cancelConnect()
        f.settle()
        val state = store.state.value
        assertNull(state.dialog)
        assertNull(state.message)
        assertNull(f.hub.accounts.connecting.value, "the poll stopped")
        assertEquals(emptyList(), f.hub.accounts.accounts(f.profileId))

        // The next sign-in isn't cancelled by the earlier one.
        f.deviceCode(TRAKT)
        store.connect(TRAKT, pointer = false)
        f.advance(10.seconds)
        assertTrue(store.state.value.rows.first { it.service == TRAKT }.connected)
    }

    @Test
    fun leavingTheScreensCancelsTheSignIn() = runTest {
        val (f, store) = setUp()
        f.deviceCode(TRAKT, held = true)
        store.connect(TRAKT, pointer = false)
        f.advance(6.seconds)
        store.release()
        f.settle()
        assertNull(f.hub.accounts.connecting.value)
        assertNull(f.stored(TRAKT))
    }

    @Test
    fun aConnectedOrBusyServiceIsNotSignedInAgain() = runTest {
        val (f, store) = setUp()
        f.connect(TRAKT)
        val trakt = f.deviceCode(TRAKT)
        store.connect(TRAKT, pointer = false)
        f.advance(10.seconds)
        assertEquals(emptyList(), trakt.polls)

        val simkl = f.deviceCode(SIMKL, emptyList())
        store.connect(SIMKL, pointer = false)
        f.advance(6.seconds)
        val mdblist = f.deviceCode(MDBLIST)
        store.connect(MDBLIST, pointer = false)
        f.advance(10.seconds)
        assertEquals(emptyList(), mdblist.polls, "one sign-in at a time")
        assertTrue(simkl.polls.isNotEmpty())
    }

    @Test
    fun aRelaySignInShowsItsLink() = runTest {
        val relay = FakeRelay()
        val (f, store) = setUp(relay)
        f.providers.getValue(ANILIST).relaySignIn = FakeRelaySignIn
        store.connect(ANILIST, pointer = true)
        f.settle()
        val dialog = assertIs<ConnectDialogUi.Link>(store.state.value.dialog)
        assertEquals("https://relay.example/auth/anilist?state=s1", dialog.url)
        assertEquals("relay.example/auth/anilist?state=s1", dialog.readableUrl)
        assertEquals(T.services.oauthProxy.title(T.services.names.anilist), dialog.title)
        assertEquals(dialog.url, store.state.value.openUrl)
        relay.result.complete(RelayResult("t", null, 3600))
        f.settle()
        assertNull(store.state.value.dialog)
        assertTrue(store.state.value.rows.first { it.service == ANILIST }.connected)
    }

    @Test
    fun traktsSettingsHaveItsOwnTitlesAndTheWatchedSyncToggle() = runTest {
        val (f, store) = setUp()
        f.connect(TRAKT, TrackerSession("a", "r", FAR_FUTURE, "sean", 1))
        f.settle()
        val trakt = assertNotNull(store.state.value.settings(TRAKT))
        assertEquals(T.trakt.connectedAs("sean"), trakt.accountTitle)
        assertEquals(T.trakt.connected, trakt.accountSubtitle)
        assertEquals(listOf(TrackerToggle.SCROBBLE, TrackerToggle.WATCHED_SYNC), trakt.toggles.map { it.toggle })
        assertTrue(trakt.toggles.all { it.on })
        assertEquals(T.trakt.disconnectConfirm, trakt.disconnectConfirm.title)
        assertEquals(T.common.disconnect, trakt.disconnectConfirm.confirm)

        store.setToggle(TRAKT, TrackerToggle.WATCHED_SYNC, false)
        f.settle()
        assertEquals(false, f.data.deviceSettings.value(AppSettings.enableTraktWatchedSync))
        assertEquals(listOf(true, false), store.state.value.settings(TRAKT)!!.toggles.map { it.on })
    }

    @Test
    fun anotherServicesSettingsAndItsDisconnect() = runTest {
        val (f, store) = setUp()
        f.connect(MDBLIST, TrackerSession("a", "r", FAR_FUTURE, null, 1))
        f.settle()
        val mdblist = assertNotNull(store.state.value.settings(MDBLIST))
        assertEquals(T.services.names.mdblist, mdblist.accountTitle, "no name: the service's")
        assertNull(mdblist.accountSubtitle)
        assertNull(mdblist.reconnect)
        assertEquals(listOf(TrackerToggle.SCROBBLE), mdblist.toggles.map { it.toggle })
        assertEquals(T.services.disconnectConfirm(T.services.names.mdblist), mdblist.disconnectConfirm.title)
        assertEquals(T.services.libraryFilter.subtitleAllSyncing, mdblist.libraryFilterValue)
        assertNull(mdblist.libraryFilterTrailingValue, "a sentence-long value sits under the title")
        assertEquals(T.services.libraryFilter.subtitleAllSyncing, mdblist.libraryFilterSubtitle)

        store.setToggle(MDBLIST, TrackerToggle.SCROBBLE, false)
        f.settle()
        assertEquals(false, f.data.deviceSettings.value(AppSettings.scrobble(MDBLIST)))

        store.disconnect(MDBLIST)
        f.settle()
        assertNull(store.state.value.settings(MDBLIST), "the screen closes")
        assertEquals(listOf("a"), f.providers.getValue(MDBLIST).revoked.map { it.accessToken })
    }

    @Test
    fun theLibraryFilterRowSaysWhatSyncs() {
        val blacklist = TrackerLibraryFilterMode.BLACKLIST
        val whitelist = TrackerLibraryFilterMode.WHITELIST
        assertEquals(T.services.libraryFilter.subtitleAllSyncing, TrackerServicesStore.filterValue(blacklist, emptyList()))
        assertEquals(T.services.libraryFilter.subtitleNoneSyncing, TrackerServicesStore.filterValue(whitelist, emptyList()))
        assertEquals(T.services.libraryFilter.subtitleBlocked("2"), TrackerServicesStore.filterValue(blacklist, listOf("a", "b", "a")))
        assertEquals(T.services.libraryFilter.subtitleAllowed("1"), TrackerServicesStore.filterValue(whitelist, listOf("a")))
    }

    private fun library(id: String, server: String?, serverName: String? = null) =
        MediaLibrary(id = id, backend = BackendKind.PLEX, title = "Library $id", serverId = server, serverName = serverName)

    @Test
    fun theLibraryFilterListsLibrariesByServerAndWritesAtOnce() = runTest {
        val (f, store) = setUp()
        libraries.value = listOf(library("1", "s1"), library("2", "s1"), library("3", null))
        f.settle()
        val one = assertNotNull(store.state.value.filter(SIMKL))
        assertEquals(listOf(T.services.libraryFilter.libraries), one.groups.map { it.title }, "one server: no server headers")
        assertEquals(listOf("s1:1", "s1:2"), one.groups.single().libraries.map { it.globalKey }, "a library without a server is left out")
        assertEquals(T.services.libraryFilter.modeHintBlacklist, one.hint)
        assertNull(one.empty)

        store.setLibraryFiltered(SIMKL, "s1:2", true)
        f.settle()
        assertEquals(listOf("s1:2"), f.data.deviceSettings.value(AppSettings.trackerFilterIds(SIMKL)))
        assertEquals(listOf(false, true), store.state.value.filter(SIMKL)!!.groups.single().libraries.map { it.on })

        store.setFilterMode(SIMKL, TrackerLibraryFilterMode.WHITELIST)
        f.settle()
        val whitelist = store.state.value.filter(SIMKL)!!
        assertEquals(listOf(false, true), whitelist.modes.map { it.selected })
        assertEquals(T.services.libraryFilter.modeHintWhitelist, whitelist.hint)
        assertEquals(listOf("s1:2"), f.data.deviceSettings.value(AppSettings.trackerFilterIds(SIMKL)), "the mode keeps the list")
        store.setLibraryFiltered(SIMKL, "s1:2", false)
        f.settle()
        assertEquals(emptyList(), f.data.deviceSettings.value(AppSettings.trackerFilterIds(SIMKL)))

        libraries.value = listOf(library("1", "s1", "Home"), library("2", "s2"))
        f.settle()
        assertEquals(listOf("Home", "s2"), store.state.value.filter(SIMKL)!!.groups.map { it.title }, "servers by name, else id")

        libraries.value = emptyList()
        f.settle()
        assertEquals(T.services.libraryFilter.noLibraries, store.state.value.filter(SIMKL)!!.empty)
    }

    @Test
    fun theSettingsRowNamesTheConnectedServicesInTheHubsOrder() {
        assertEquals(T.settings.servicesDescription, servicesRowSubtitle(emptyList()))
        val accounts = listOf(SIMKL, TRAKT, ANILIST).map { TrackerAccount(it, "alex", connectedAt = 1) }
        assertEquals("Trakt · AniList · Simkl", servicesRowSubtitle(accounts))
    }

    @Test
    fun theDiscordSwitchShowsOnlyWhereTheAppSpeaksToDiscord() = runTest {
        assertNull(setUp().second.state.value.discordPresence)
        val (f, store) = setUp(discordOffered = true)
        assertEquals(false, store.state.value.discordPresence)
        store.setDiscordPresence(true)
        f.settle()
        assertEquals(true, store.state.value.discordPresence)
        assertTrue(f.data.deviceSettings.value(AppSettings.enableDiscordRpc))
    }
}
