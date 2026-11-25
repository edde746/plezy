package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.LiveTvChannel
import com.edde746.plezy.livetv.LiveTvProgram
import com.edde746.plezy.model.BackendKind
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
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.hours
import kotlin.time.Instant

class GuideSearchTest {
    private val now = Instant.fromEpochSeconds(1_800_000_000)
    private val nowSeconds = now.epochSeconds

    private val channels = listOf(
        LiveTvChannel(key = "channel-alpha", identifier = "station-alpha", title = "Alpha News", callSign = "KALP", number = "100", serverId = "server-a"),
        LiveTvChannel(key = "channel-beta", identifier = "station-beta", title = "Beta Sports", callSign = "KBET", number = "200", serverId = "server-a"),
    )

    // One airing per case: a title match on Beta, a series match on Alpha, one already over.
    private val programs = listOf(
        LiveTvProgram(ratingKey = "program-game", title = "Championship Game", beginsAt = nowSeconds + 2 * 3600, endsAt = nowSeconds + 3 * 3600,
            channelIdentifier = "station-beta", serverId = "server-a"),
        LiveTvProgram(ratingKey = "program-series", title = "Episode 12", grandparentTitle = "Cooking Series", beginsAt = nowSeconds + 4 * 3600,
            endsAt = nowSeconds + 5 * 3600, channelIdentifier = "station-alpha", serverId = "server-a"),
        LiveTvProgram(ratingKey = "program-ended", title = "Ended Show", beginsAt = nowSeconds - 3600, endsAt = nowSeconds - 1800,
            channelIdentifier = "station-alpha", serverId = "server-a"),
    )

    private class Harness(
        val store: LiveTvStore,
        val tabs: FakeTabs,
        val schedule: CompletableDeferred<List<LiveTvProgram>>,
        val requests: List<Pair<Instant?, Instant?>>,
    ) {
        val search get() = store.state.value.search!!
    }

    private fun TestScope.open(): Harness {
        val liveTv = FakeLiveTv(hasDvr = false)
        val schedule = CompletableDeferred<List<LiveTvProgram>>()
        val requests = mutableListOf<Pair<Instant?, Instant?>>()
        liveTv.favoriteSource = { "server://server-a/default" }
        liveTv.channels = { lineup -> if (lineup == "a") channels else emptyList() }
        liveTv.favorites = { emptyList() }
        liveTv.schedule = { from, to -> requests += from to to; schedule.await() }
        val client = FakeMediaBackend("server-a", backend = BackendKind.JELLYFIN).also { it.liveTv = liveTv }
        val servers = FakeLiveTvServers(
            listOf(LiveTvServerEntry(ServerId("server-a"), "dvr-a", "a"), LiveTvServerEntry(ServerId("server-a"), "dvr-b", "b")),
            listOf(client),
        )
        val tabs = FakeTabs(backgroundScope)
        val store = LiveTvStore(servers, tabs.guide, tabs.whatsOn, tabs.recordings, false, backgroundScope, use24HourClock = true, now = { now })
        runCurrent()
        store.perform(LiveTvAction.SEARCH)
        runCurrent()
        return Harness(store, tabs, schedule, requests)
    }

    @Test
    fun theSearchLoadsTheNextDayOnceFromEachServer() = runTest {
        val harness = open()

        assertEquals(listOf<Pair<Instant?, Instant?>>(now - 1.hours to now + 24.hours), harness.requests)
    }

    @Test
    fun anEmptyQueryListsEveryChannelAndTypingFiltersByTitleCallSignAndNumber() = runTest {
        val harness = open()
        harness.schedule.complete(emptyList())
        runCurrent()
        fun shown() = harness.search.channels.map { it.title }

        assertEquals(listOf("KALP", "KBET"), shown())
        assertFalse(harness.search.showsPrograms)
        assertEquals(T.liveTv.channelNumber("100"), harness.search.channels.first().subtitle)

        harness.store.setSearchQuery("news")
        assertEquals(listOf("KALP"), shown())
        harness.store.setSearchQuery("kbet")
        assertEquals(listOf("KBET"), shown())
        harness.store.setSearchQuery("100")
        assertEquals(listOf("KALP"), shown())
    }

    @Test
    fun selectingAChannelJumpsToItAndClosesTheSearch() = runTest {
        val harness = open()
        harness.schedule.complete(emptyList())
        runCurrent()

        harness.store.selectSearchChannel(harness.search.channels.first().channel)

        assertEquals(listOf("channel channel-alpha"), harness.tabs.guide.jumps)
        assertNull(harness.store.state.value.search)
    }

    @Test
    fun aProgramQueryNeedsTwoCharactersMatchesSeriesNamesAndDropsEndedAirings() = runTest {
        val harness = open()
        harness.schedule.complete(programs)
        runCurrent()

        // One character never searches programs; with no channel match either, nothing matches.
        harness.store.setSearchQuery("c")
        assertFalse(harness.search.showsPrograms)
        assertEquals(T.liveTv.searchNoResults("c"), harness.search.noResults)

        harness.store.setSearchQuery("champ")
        assertTrue(harness.search.showsPrograms)
        assertEquals(listOf("Championship Game"), harness.search.programs.map { it.title })
        assertTrue(harness.search.programs.single().subtitle.startsWith("KBET · "))

        harness.store.setSearchQuery("cooking")
        assertEquals(listOf("program-series"), harness.search.programs.map { it.program.ratingKey })

        harness.store.setSearchQuery("ended")
        assertEquals(emptyList(), harness.search.programs)
        assertEquals(T.liveTv.searchNoResults("ended"), harness.search.noResults)
    }

    @Test
    fun programsLoadingShowTheSectionInsteadOfNoResults() = runTest {
        val harness = open()

        harness.store.setSearchQuery("champ")

        assertTrue(harness.search.showsPrograms)
        assertTrue(harness.search.programsLoading)
        assertNull(harness.search.noResults)
    }

    @Test
    fun selectingAProgramJumpsToTheAiringOnItsChannel() = runTest {
        val harness = open()
        harness.schedule.complete(programs)
        runCurrent()
        harness.store.setSearchQuery("champ")

        val row = harness.search.programs.single()
        harness.store.selectSearchProgram(row.channel, row.program)

        assertEquals(listOf("program channel-beta program-game"), harness.tabs.guide.jumps)
        assertNull(harness.store.state.value.search)
        assertEquals(LiveTvTab.GUIDE, harness.store.state.value.selectedTab)
    }

    @Test
    fun aRemoteQueryFiltersAndSubmittingFocusesTheFirstResult() = runTest {
        val harness = open()
        harness.schedule.complete(emptyList())
        runCurrent()

        harness.store.setSearchQuery("beta")
        harness.store.submitSearch()

        assertEquals("beta", harness.search.query)
        assertEquals(listOf("KBET"), harness.search.channels.map { it.title })
        assertEquals(LiveTvFocusTarget.SEARCH_RESULT, harness.store.state.value.focus)

        harness.store.focusHandled()
        harness.store.setSearchQuery("nothing matches")
        harness.store.submitSearch()
        assertNull(harness.store.state.value.focus)
    }
}
