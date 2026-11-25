package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.livetv.ChannelMapping
import com.edde746.plezy.livetv.FavoriteChannelPersistenceMode
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvDvr
import com.edde746.plezy.livetv.scopeKey
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LiveTvStoreTest {
    private class Screen(val store: LiveTvStore, val tabs: FakeTabs, val servers: FakeLiveTvServers) {
        val state get() = store.state.value
        val guideKeys get() = tabs.guide.displayed.map { it.key }
    }

    private fun entryFor(liveTv: ScreenLiveTv): LiveTvServerEntry {
        val suffix = liveTv.serverId.removePrefix("server-")
        return LiveTvServerEntry(ServerId(liveTv.serverId), "dvr-$suffix", lineup = "provider-$suffix")
    }

    private fun TestScope.screen(
        vararg liveTvs: ScreenLiveTv = arrayOf(ScreenLiveTv()),
        entries: List<LiveTvServerEntry> = liveTvs.map(::entryFor),
        favoritesOnly: Boolean = true,
    ): Screen {
        val servers = FakeLiveTvServers(entries, liveTvs.map { it.client })
        val tabs = FakeTabs(backgroundScope)
        val store = LiveTvStore(servers, tabs.guide, tabs.whatsOn, tabs.recordings, favoritesOnly, backgroundScope, use24HourClock = true)
        runCurrent()
        return Screen(store, tabs, servers)
    }

    private fun favoriteA() = FavoriteChannel(source = "server://server-a/provider-a", id = "channel-a")

    @Test
    fun loadedEmptyFavoritesShowTheEmptyStateAndShowAllRestoresTheChannels() = runTest {
        val liveTv = ScreenLiveTv()
        val screen = screen(liveTv)

        assertTrue(screen.state.actions.single { it.action == LiveTvAction.FAVORITES_FILTER }.active)
        assertEquals(listOf("channel-a"), screen.guideKeys)

        liveTv.favorites.complete(emptyList())
        runCurrent()

        val empty = screen.state.favoritesEmpty
        assertEquals(T.liveTv.noFavoriteChannels, empty?.title)
        assertEquals(T.liveTv.showAllChannels, empty?.actionLabel)
        assertEquals(emptyList(), screen.guideKeys)

        screen.store.showAllChannels(hadFocus = true)

        assertNull(screen.state.favoritesEmpty)
        assertFalse(screen.state.actions.single { it.action == LiveTvAction.FAVORITES_FILTER }.active)
        assertEquals(listOf("channel-a"), screen.guideKeys)
        assertEquals(LiveTvFocusTarget.CONTENT, screen.state.focus)
    }

    @Test
    fun favoritesMatchingNoLoadedChannelShowTheEmptyState() = runTest {
        val liveTv = ScreenLiveTv()
        val screen = screen(liveTv)

        liveTv.favorites.complete(listOf(FavoriteChannel(source = "server://server-a/provider-a", id = "channel-gone")))
        runCurrent()

        assertEquals(T.liveTv.noFavoriteChannels, screen.state.favoritesEmpty?.title)
    }

    @Test
    fun aRefreshKeepsTheFavoritesFilterNarrowWhileFavoritesReload() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        val screen = screen(liveTv)
        liveTv.favorites.complete(listOf(favoriteA()))
        runCurrent()
        assertEquals(listOf("channel-a"), screen.guideKeys)

        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(2, liveTv.favoriteReads.size)
        assertEquals(listOf("channel-a"), screen.guideKeys)

        liveTv.favorites.complete(listOf(favoriteA()))
        runCurrent()

        assertEquals(listOf("channel-a"), screen.guideKeys)
    }

    @Test
    fun guideSearchCoversAllChannelsAndSelectingANonFavoriteDropsTheFilter() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        liveTv.liveTv.schedule = { _, _ -> emptyList() }
        val screen = screen(liveTv)
        liveTv.favorites.complete(listOf(favoriteA()))
        runCurrent()
        assertEquals(listOf("channel-a"), screen.guideKeys)

        screen.store.perform(LiveTvAction.SEARCH)
        runCurrent()

        val search = screen.state.search!!
        assertEquals(listOf("Unique Channel A", "Unique Channel channel-b"), search.channels.map { it.title })

        screen.store.selectSearchChannel(search.channels[1].channel)

        assertNull(screen.state.search)
        assertEquals(listOf("channel-a", "channel-b"), screen.guideKeys)
        assertEquals(LiveTvTab.GUIDE, screen.state.selectedTab)
        assertEquals(listOf("channel channel-b"), screen.tabs.guide.jumps)
    }

    @Test
    fun selectingAFavoriteFromSearchKeepsTheFilter() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        liveTv.liveTv.schedule = { _, _ -> emptyList() }
        val screen = screen(liveTv)
        liveTv.favorites.complete(listOf(favoriteA()))
        runCurrent()

        screen.store.openSearch()
        runCurrent()
        screen.store.selectSearchChannel(screen.state.search!!.channels[0].channel)

        assertTrue(screen.state.favoritesOnly)
        assertEquals(listOf("channel-a"), screen.guideKeys)
        assertEquals(listOf("channel channel-a"), screen.tabs.guide.jumps)
    }

    @Test
    fun aFavoriteReadFailurePreservesTheRawGuideChannels() = runTest {
        val liveTv = ScreenLiveTv()
        val screen = screen(liveTv)

        liveTv.favorites.completeExceptionally(IllegalStateException("favorite read failed"))
        runCurrent()

        assertTrue(screen.state.favoritesOnly)
        assertEquals(listOf("channel-a"), screen.guideKeys)
        assertNull(screen.state.favoritesEmpty)
    }

    @Test
    fun aFavoriteFailureKeepsFavoritesLoadedFromHealthyStores() = runTest {
        val failed = ScreenLiveTv(serverId = "server-a", storeKey = "store-a")
        val healthy = ScreenLiveTv(serverId = "server-b", storeKey = "store-b")
        val screen = screen(failed, healthy)

        failed.favorites.completeExceptionally(IllegalStateException("favorite read failed"))
        runCurrent()
        healthy.favorites.complete(listOf(FavoriteChannel(source = "server://server-b/provider-b", id = "channel-server-b")))
        runCurrent()

        val shown = screen.tabs.guide.displayed
        assertEquals(listOf("server-b"), shown.map { it.serverId })
        assertEquals(setOf(shown.single().scopeKey), screen.tabs.guide.favoriteKeys)
    }

    @Test
    fun `a failed favourite write puts the star back`() = runTest {
        val liveTv = ScreenLiveTv()
        val screen = screen(liveTv, favoritesOnly = false)
        liveTv.writeFailures += IllegalStateException("favorite write failed")
        liveTv.favorites.complete(emptyList())
        runCurrent()

        val channel = screen.tabs.guide.displayed.single()
        screen.store.toggleFavorite(channel)
        runCurrent()

        assertEquals(emptySet(), screen.tabs.guide.favoriteKeys)
        assertEquals(emptySet(), screen.state.favoriteChannelKeys)
        assertEquals(LiveTvMessage(T.liveTv.favoritesUpdateFailed, isError = true), screen.state.message)
        assertEquals(listOf(listOf("channel-a")), liveTv.writes.map { write -> write.map { it.id } })

        // The queue stays usable: the next toggle saves.
        screen.store.messageShown()
        screen.store.toggleFavorite(channel)
        runCurrent()

        assertEquals(setOf(channel.scopeKey), screen.tabs.guide.favoriteKeys)
        assertNull(screen.state.message)
        assertEquals(listOf(listOf("channel-a"), listOf("channel-a")), liveTv.writes.map { write -> write.map { it.id } })
    }

    @Test
    fun aToggleWaitsForTheFavoritesLoadAndIsRefusedWhenAStoreFailed() = runTest {
        val liveTv = ScreenLiveTv()
        val screen = screen(liveTv, favoritesOnly = false)

        screen.store.toggleFavorite(screen.tabs.guide.displayed.single())
        runCurrent()
        assertEquals(emptyList(), liveTv.writes)

        liveTv.favorites.completeExceptionally(IllegalStateException("favorite read failed"))
        runCurrent()

        assertEquals(LiveTvMessage(T.liveTv.favoritesLoadFailed, isError = true), screen.state.message)
        assertEquals(emptyList(), liveTv.writes)
        assertEquals(emptySet(), screen.state.favoriteChannelKeys)
    }

    @Test
    fun aSharedStoreGetsTheWholeListAndAPerServerStoreItsOwnSlice() = runTest {
        val plexA = ScreenLiveTv(serverId = "server-a", storeKey = "plex:account").apply {
            liveTv.favoritePersistenceMode = FavoriteChannelPersistenceMode.SHARED_FULL_LIST
        }
        val plexB = ScreenLiveTv(serverId = "server-b", storeKey = "plex:account").apply {
            liveTv.favoritePersistenceMode = FavoriteChannelPersistenceMode.SHARED_FULL_LIST
        }
        val jellyfin = ScreenLiveTv(serverId = "server-c", storeKey = "jellyfin:c")
        val screen = screen(plexA, plexB, jellyfin, favoritesOnly = false)
        val favoriteB = FavoriteChannel(source = "server://server-b/provider-b", id = "channel-server-b")
        plexA.favorites.complete(listOf(favoriteB))
        runCurrent()
        jellyfin.favorites.complete(emptyList())
        runCurrent()

        // The account store was read once, through its first server.
        assertEquals(0, plexB.favoriteReads.size)

        screen.store.toggleFavorite(screen.tabs.guide.displayed.single { it.key == "channel-a" })
        screen.store.toggleFavorite(screen.tabs.guide.displayed.single { it.key == "channel-server-c" })
        runCurrent()

        val wholeList = listOf("channel-server-b", "channel-a")
        assertEquals(listOf(wholeList, wholeList), plexA.writes.map { w -> w.map { it.id } })
        assertEquals(emptyList(), plexB.writes)
        assertEquals(listOf(emptyList(), listOf("channel-server-c")), jellyfin.writes.map { w -> w.map { it.id } })
    }

    @Test
    fun whatsOnShowsOnlyWhenAServerHasHubsAndScheduledOnlyWithADvr() = runTest {
        val plain = screen(ScreenLiveTv())
        assertEquals(listOf(LiveTvTab.GUIDE), plain.state.tabs.map { it.tab })

        val plex = ScreenLiveTv(serverId = "server-b", hasDvr = true).apply { liveTv.hasWhatsOn = true }
        val full = screen(ScreenLiveTv(), plex)
        assertEquals(listOf(LiveTvTab.GUIDE, LiveTvTab.WHATS_ON, LiveTvTab.RECORDINGS), full.state.tabs.map { it.tab })
        // The DVR tab holds what is scheduled to record and the rules, not the recorded items (those are the server's
        // recordings library), so it is named Scheduled.
        assertEquals(listOf("Guide", "What's On", "Scheduled"), full.state.tabs.map { it.label })
    }

    @Test
    fun onlyTheSelectedTabOfAShownScreenRefreshes() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true).apply { liveTv.hasWhatsOn = true }
        val screen = screen(liveTv)
        val tabs = screen.tabs
        assertTrue(tabs.guide.refresh.isOpen)
        assertFalse(tabs.recordings.refresh.isOpen)

        screen.store.selectTab(LiveTvTab.RECORDINGS)
        assertEquals(LiveTvTab.RECORDINGS, screen.state.selectedTab)
        assertFalse(tabs.guide.refresh.isOpen)
        assertFalse(tabs.whatsOn.refresh.isOpen)
        assertTrue(tabs.recordings.refresh.isOpen)

        screen.store.setShown(false)
        assertFalse(tabs.recordings.refresh.isOpen)
        screen.store.setShown(true)
        assertTrue(tabs.recordings.refresh.isOpen)
    }

    @Test
    fun refreshOnRecordingsReloadsThemAloneAndAChannelReloadKeepsTheTab() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        val screen = screen(liveTv)
        screen.store.selectTab(LiveTvTab.RECORDINGS)

        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(1, screen.tabs.recordings.reloads)
        assertEquals(1, liveTv.liveTv.calls.count { it.startsWith("fetchChannels") })

        screen.store.retry()
        runCurrent()

        assertEquals(2, liveTv.liveTv.calls.count { it.startsWith("fetchChannels") })
        assertEquals(LiveTvTab.RECORDINGS, screen.state.selectedTab)
    }

    @Test
    fun aTabThatGoesAwayFallsBackToTheGuide() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        liveTv.liveTv.reload = {}
        val screen = screen(liveTv)
        screen.store.selectTab(LiveTvTab.RECORDINGS)
        screen.store.selectTab(LiveTvTab.GUIDE)

        liveTv.liveTv.hasDvr = false
        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(listOf(LiveTvTab.GUIDE), screen.state.tabs.map { it.tab })
        assertEquals(LiveTvTab.GUIDE, screen.state.selectedTab)
        assertTrue(screen.tabs.guide.refresh.isOpen)
    }

    @Test
    fun selectingTheSelectedTabSendsFocusIntoItsContent() = runTest {
        val screen = screen(ScreenLiveTv())
        screen.store.focusHandled()

        screen.store.selectTab(LiveTvTab.GUIDE)

        assertEquals(LiveTvFocusTarget.CONTENT, screen.state.focus)
        screen.store.focusHandled()
        assertNull(screen.state.focus)
    }

    @Test
    fun theActionBarFollowsTheTabTheFilterAndTheFavorites() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"), hasDvr = true)
        liveTv.liveTv.supportsRuleProcessing = true
        val screen = screen(liveTv)
        fun actions() = screen.state.actions.map { it.action }

        assertEquals(listOf(LiveTvAction.SEARCH, LiveTvAction.FAVORITES_FILTER, LiveTvAction.REFRESH), actions())
        assertEquals(T.liveTv.reloadGuide, screen.state.actions.last().label)

        liveTv.favorites.complete(listOf(favoriteA(), FavoriteChannel(source = "server://server-a/provider-a", id = "channel-b")))
        runCurrent()
        assertEquals(
            listOf(LiveTvAction.SEARCH, LiveTvAction.FAVORITES_FILTER, LiveTvAction.REORDER_FAVORITES, LiveTvAction.REFRESH),
            actions(),
        )

        screen.store.perform(LiveTvAction.FAVORITES_FILTER)
        assertEquals(listOf(LiveTvAction.SEARCH, LiveTvAction.FAVORITES_FILTER, LiveTvAction.REFRESH), actions())

        screen.store.selectTab(LiveTvTab.RECORDINGS)
        assertEquals(listOf(LiveTvAction.SEARCH, LiveTvAction.PROCESS_RULES, LiveTvAction.REFRESH), actions())
        assertEquals(T.common.refresh, screen.state.actions.last().label)
    }

    @Test
    fun aRefreshThatFailsOnEveryServerKeepsTheLoadedChannels() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        val screen = screen(liveTv)
        liveTv.favorites.complete(emptyList())
        runCurrent()
        screen.store.showAllChannels(hadFocus = false)
        assertEquals(listOf("channel-a", "channel-b"), screen.guideKeys)

        liveTv.channelsFailure = IllegalStateException("offline")
        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(listOf("channel-a", "channel-b"), screen.guideKeys)
        assertEquals(LiveTvBody.Tabs, screen.state.body)
        assertEquals(LiveTvMessage(T.errors.unableToLoad(T.liveTv.title), isError = true), screen.state.message)
    }

    @Test
    fun aFirstLoadThatFailsOnEveryServerShowsTheErrorAndRetryLoadsAgain() = runTest {
        val liveTv = ScreenLiveTv().apply { channelsFailure = IllegalStateException("offline") }
        val screen = screen(liveTv)

        assertEquals(LiveTvBody.Failed(T.errors.unableToLoad(T.liveTv.title), T.common.retry), screen.state.body)

        liveTv.channelsFailure = null
        screen.store.retry()
        runCurrent()

        assertEquals(LiveTvBody.Tabs, screen.state.body)
        assertEquals(listOf("channel-a"), screen.state.channels.map { it.key })
    }

    @Test
    fun aServerThatFailsAloneIsDropped() = runTest {
        val broken = ScreenLiveTv(serverId = "server-a").apply { channelsFailure = IllegalStateException("offline") }
        val healthy = ScreenLiveTv(serverId = "server-b")
        val screen = screen(broken, healthy, favoritesOnly = false)

        assertEquals(LiveTvBody.Tabs, screen.state.body)
        assertNull(screen.state.message)
        assertEquals(listOf("channel-server-b"), screen.state.channels.map { it.key })
    }

    @Test
    fun withoutLiveTvServersTheScreenSaysThereIsNoDvr() = runTest {
        val screen = screen(entries = emptyList())

        assertEquals(LiveTvBody.Failed(T.liveTv.noDvr, T.common.retry), screen.state.body)
    }

    @Test
    fun aReloadAfterTheLastSourceWentSaysThereIsNoDvrNotNoChannels() = runTest {
        val screen = screen()
        assertEquals(LiveTvBody.Tabs, screen.state.body)

        screen.servers.entries = emptyList()
        screen.store.retry()
        runCurrent()
        assertEquals(LiveTvBody.Failed(T.liveTv.noDvr, T.common.retry), screen.state.body)
    }

    @Test
    fun noChannelsShowTheEmptyTextUnlessThereIsARecordingsTab() = runTest {
        val screen = screen(ScreenLiveTv(channelKeys = emptyList()))
        assertEquals(LiveTvBody.Empty(T.liveTv.noChannels), screen.state.body)

        val withDvr = screen(ScreenLiveTv(channelKeys = emptyList(), hasDvr = true))
        assertEquals(LiveTvBody.Tabs, withDvr.state.body)
        assertEquals(listOf(LiveTvTab.GUIDE, LiveTvTab.RECORDINGS), withDvr.state.tabs.map { it.tab })
        assertEquals(T.liveTv.noChannels, withDvr.state.guideEmpty)
    }

    @Test
    fun aLoadShowsTheSpinnerAndConcurrentRefreshesShareIt() = runTest {
        val liveTv = ScreenLiveTv()
        val gate = CompletableDeferred<Unit>()
        val channels = liveTv.liveTv.channels
        liveTv.liveTv.channels = { lineup -> gate.await(); channels(lineup) }
        val screen = screen(liveTv, favoritesOnly = false)

        assertEquals(LiveTvBody.Loading, screen.state.body)
        screen.store.perform(LiveTvAction.REFRESH)
        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()
        gate.complete(Unit)
        runCurrent()

        assertEquals(1, liveTv.liveTv.calls.count { it.startsWith("fetchChannels") })
        assertEquals(LiveTvBody.Tabs, screen.state.body)
    }

    @Test
    fun channelsLoadThroughEveryDvrFilteredByItsMappingAndSortedByNumber() = runTest {
        val liveTv = ScreenLiveTv(serverId = "plex")
        liveTv.liveTv.favoriteSource = { lineup -> "server://plex/$lineup" }
        liveTv.liveTv.channels = { lineup ->
            listOf(
                LiveTvChannel(key = "1", number = "12", serverId = "plex"),
                LiveTvChannel(key = "2", number = "2.1", serverId = "plex"),
                LiveTvChannel(key = "3", serverId = "plex"),
                LiveTvChannel(key = "4", number = "x", serverId = "plex"),
                LiveTvChannel(key = "5", number = "2", serverId = "plex"),
            ).filter { lineup == "ota" || it.key != "2" }
        }
        val dvrs = listOf(
            LiveTvDvr(key = "dvr-1", lineup = "ota", lineupTitle = "Seattle OTA", channelMappings = listOf(
                ChannelMapping("1", enabled = true), ChannelMapping("2", enabled = true), ChannelMapping("3", enabled = true),
                ChannelMapping("4", enabled = true), ChannelMapping("5", enabled = false),
            )),
            LiveTvDvr(key = "dvr-2", lineup = "cable"),
        )
        val screen = screen(
            liveTv,
            entries = listOf(
                LiveTvServerEntry(ServerId("plex"), "dvr-1", "ota", dvrs),
                LiveTvServerEntry(ServerId("plex"), "dvr-1", "ota", dvrs),
                LiveTvServerEntry(ServerId("plex"), "dvr-2", "cable", dvrs),
            ),
            favoritesOnly = false,
        )

        val loaded = screen.state.channels
        // dvr-2 has no mapping of its own (dvr-1's applies to dvr-1 only); the repeated entry dedupes; unnumbered last.
        assertEquals(
            listOf("5" to "dvr-2", "2" to "dvr-1", "1" to "dvr-1", "1" to "dvr-2", "3" to "dvr-1", "4" to "dvr-1", "3" to "dvr-2", "4" to "dvr-2"),
            loaded.map { it.key to it.liveDvrKey },
        )
        val ota = loaded.first { it.liveDvrKey == "dvr-1" }
        assertEquals("Seattle OTA", ota.liveTvSourceTitle)
        assertEquals("server://plex/ota", ota.favoriteSource)
        assertEquals("test-store", ota.favoriteStoreKey)
        assertEquals("cable", loaded.first().liveTvSourceTitle)
        assertEquals(screen.state.channels, screen.tabs.whatsOn.received)
        assertEquals(listOf("plex - cable", "plex - Seattle OTA"), screen.tabs.guide.groups.map { it.label })
    }

    @Test
    fun guideReloadReportsADvrFailureInsteadOfSuccess() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        val reloaded = mutableListOf<String>()
        liveTv.liveTv.reload = { reloaded += it; throw IllegalStateException("reload failed") }
        val screen = screen(liveTv)
        liveTv.favorites.complete(emptyList())
        runCurrent()

        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(listOf("dvr-a"), reloaded)
        assertEquals(LiveTvMessage(T.liveTv.guideReloadFailed, isError = true), screen.state.message)
        assertEquals(2, liveTv.liveTv.calls.count { it.startsWith("fetchChannels") })
    }

    @Test
    fun guideReloadNamesTheAdminRequirementWhenTheDvrRefusesWith403() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        liveTv.liveTv.reload = { throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, statusCode = 403) }
        val screen = screen(liveTv)

        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(LiveTvMessage(T.liveTv.dvrAdminRequired, isError = true), screen.state.message)
    }

    @Test
    fun guideReloadThatEveryDvrTookSaysSo() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        liveTv.liveTv.reload = {}
        val screen = screen(liveTv)

        screen.store.perform(LiveTvAction.REFRESH)
        runCurrent()

        assertEquals(LiveTvMessage(T.liveTv.guideReloadRequested), screen.state.message)
    }

    @Test
    fun processingRulesReportsAndReloadsTheRecordings() = runTest {
        val liveTv = ScreenLiveTv(hasDvr = true)
        liveTv.liveTv.supportsRuleProcessing = true
        liveTv.liveTv.process = {}
        val screen = screen(liveTv)
        screen.store.selectTab(LiveTvTab.RECORDINGS)

        screen.store.perform(LiveTvAction.PROCESS_RULES)
        runCurrent()

        assertEquals(LiveTvMessage(T.liveTv.rulesProcessRequested), screen.state.message)
        assertEquals(1, screen.tabs.recordings.reloads)

        liveTv.liveTv.process = { throw IllegalStateException("refused") }
        screen.store.perform(LiveTvAction.PROCESS_RULES)
        runCurrent()

        assertEquals(LiveTvMessage(T.liveTv.rulesProcessFailed, isError = true), screen.state.message)
        assertEquals(2, screen.tabs.recordings.reloads)
    }

    @Test
    fun reorderingSavesEachMoveAndRemovingTheLastClosesTheSheet() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        val screen = screen(liveTv)
        val favoriteB = FavoriteChannel(source = "server://server-a/provider-a", id = "channel-b", title = "B title", vcn = "7")
        val gone = FavoriteChannel(source = "server://server-a/provider-a", id = "channel-gone", title = "Gone", vcn = "9")
        liveTv.favorites.complete(listOf(favoriteA(), favoriteB, gone))
        runCurrent()

        screen.store.perform(LiveTvAction.REORDER_FAVORITES)
        val rows = screen.state.reorder!!.rows
        assertEquals(listOf("Unique Channel A", "Unique Channel channel-b", "Gone"), rows.map { it.title })
        assertEquals(listOf(null, "7", "9"), rows.map { it.number })

        screen.store.moveFavorite(0, 1)
        runCurrent()
        assertEquals(listOf("channel-b", "channel-a", "channel-gone"), liveTv.writes.last().map { it.id })
        assertEquals(listOf("channel-b", "channel-a"), screen.guideKeys)

        screen.store.removeFavorite(2)
        screen.store.removeFavorite(0)
        runCurrent()
        assertEquals(listOf("channel-a"), liveTv.writes.last().map { it.id })
        assertEquals(1, screen.state.reorder!!.rows.size)

        screen.store.removeFavorite(0)
        runCurrent()
        assertNull(screen.state.reorder)
        assertEquals(emptyList(), liveTv.writes.last())
    }

    @Test
    fun theGuideGetsTheGroupsAndTheFavoriteFlags() = runTest {
        val liveTv = ScreenLiveTv(channelKeys = listOf("channel-a", "channel-b"))
        val screen = screen(liveTv, favoritesOnly = false)
        liveTv.favorites.complete(listOf(favoriteA()))
        runCurrent()

        val guide = screen.tabs.guide
        assertEquals(listOf("channel-a", "channel-b"), guide.displayed.map { it.key })
        assertEquals(1, guide.groups.size)
        assertEquals(setOf(guide.displayed.first().scopeKey), guide.favoriteKeys)
    }
}
