package com.edde746.plezy.livetv

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class LiveTvMatchingTest {
    @Test
    fun aProgramMatchesItsChannelByKeyOnItsServer() {
        val program = LiveTvProgram(title = "News", channelIdentifier = "101", serverId = "server-a")

        assertTrue(liveTvProgramMatchesChannel(program, LiveTvChannel(key = "101", serverId = "server-a")))
        assertFalse(liveTvProgramMatchesChannel(program, LiveTvChannel(key = "101", serverId = "server-b")))
    }

    @Test
    fun aProgramMatchesTheChannelIdentifierToo() {
        val program = LiveTvProgram(title = "News", channelIdentifier = "station-101", serverId = "server-a")

        assertTrue(liveTvProgramMatchesChannel(program, LiveTvChannel(key = "101", identifier = "station-101", serverId = "server-a")))
    }

    @Test
    fun theProviderTellsApartTheSameChannelOfTwoProvidersOnOneServer() {
        val program = LiveTvProgram(title = "News", channelIdentifier = "101", serverId = "server-a", providerIdentifier = "provider-a")
        val matching = LiveTvChannel(key = "101", serverId = "server-a", favoriteSource = "server://machine/provider-a")
        val otherProvider = LiveTvChannel(key = "101", serverId = "server-a", favoriteSource = "server://machine/provider-b")

        assertTrue(liveTvProgramMatchesChannel(program, matching))
        assertFalse(liveTvProgramMatchesChannel(program, otherProvider))
    }
}

class LiveTvGroupingTest {
    private fun channel(key: String, serverId: String, serverName: String, dvrKey: String, favoriteSource: String, sourceTitle: String?) =
        LiveTvChannel(
            key = key,
            serverId = serverId,
            serverName = serverName,
            liveDvrKey = dvrKey,
            favoriteSource = favoriteSource,
            liveTvSourceTitle = sourceTitle,
        )

    @Test
    fun channelsGroupBySourceInTheOrderSourcesFirstAppear() {
        val firstHome = channel("101", "home", "Home Plex", "dvr-a", "server://home/provider-a", "Seattle OTA")
        val cabin = channel("101", "cabin", "Cabin Plex", "dvr-a", "server://cabin/provider-b", "Portland OTA")
        val secondHome = channel("102", "home", "Home Plex", "dvr-a", "server://home/provider-a", "Seattle OTA")

        val groups = groupLiveTvChannelsBySource(listOf(firstHome, cabin, secondHome))

        assertEquals(listOf("Home Plex - Seattle OTA", "Cabin Plex - Portland OTA"), groups.map { it.label })
        assertEquals(listOf(firstHome, secondHome), groups.first().channels)
        assertEquals(listOf(cabin), groups.last().channels)
    }

    @Test
    fun twoDvrsOfOneServerAreSeparateGroupsNamedByTheirDvr() {
        val groups = groupLiveTvChannelsBySource(
            listOf(
                channel("101", "home", "Home Plex", "dvr-a", "server://home/provider-a", "Seattle OTA"),
                channel("101", "home", "Home Plex", "dvr-b", "server://home/provider-a", "Seattle OTA"),
            ),
        )

        assertEquals(listOf("Home Plex - Seattle OTA - dvr-a", "Home Plex - Seattle OTA - dvr-b"), groups.map { it.label })
    }
}
