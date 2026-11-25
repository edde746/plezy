package com.edde746.plezy.livetv

import com.edde746.plezy.data.livetv.FavoriteChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertSame
import kotlin.test.assertTrue

class LiveTvChannelTest {
    @Test
    fun favoriteChannelKeyIncludesSourceAndId() {
        assertNotEquals(favoriteChannelKey("server://a/provider", "101"), favoriteChannelKey("server://b/provider", "101"))
        assertEquals(favoriteChannelKey("server://a/provider", "101"), FavoriteChannel(source = "server://a/provider", id = "101").stableKey)
    }

    @Test
    fun scopeKeyIncludesServerDvrAndChannelKey() {
        val a = LiveTvChannel(key = "101", serverId = "server-1", liveDvrKey = "dvr-a")
        val b = LiveTvChannel(key = "101", serverId = "server-1", liveDvrKey = "dvr-b")

        assertNotEquals(a.scopeKey, b.scopeKey)
    }

    @Test
    fun favoriteFilteringDistinguishesDisabledLoadingAndLoadedEmptyStates() {
        val channels = listOf(LiveTvChannel(key = "101"), LiveTvChannel(key = "102"))
        fun filter(favoritesOnly: Boolean, favoritesLoaded: Boolean) = filterLiveTvChannelsForFavorites(
            channels = channels,
            favoritesOnly = favoritesOnly,
            favoritesLoaded = favoritesLoaded,
            favorites = emptyList(),
            sourceForChannel = { "server://server-1/provider-a" },
        )

        assertSame(channels, filter(favoritesOnly = false, favoritesLoaded = true))
        assertSame(channels, filter(favoritesOnly = true, favoritesLoaded = false))
        assertTrue(filter(favoritesOnly = true, favoritesLoaded = true).isEmpty())
    }

    @Test
    fun favoriteFilteringPreservesFavoriteOrderAndSourceScope() {
        val channels = listOf(LiveTvChannel(key = "101"), LiveTvChannel(key = "102"), LiveTvChannel(key = "101"))
        val sourceA = "server://server-1/provider-a"
        val sourceB = "server://server-2/provider-a"

        val filtered = filterLiveTvChannelsForFavorites(
            channels = channels,
            favoritesOnly = true,
            favoritesLoaded = true,
            favorites = listOf(FavoriteChannel(source = sourceB, id = "101"), FavoriteChannel(source = sourceA, id = "102")),
            sourceForChannel = { channel -> if (channel === channels[2]) sourceB else sourceA },
        )

        assertEquals(2, filtered.size)
        assertSame(channels[2], filtered[0])
        assertSame(channels[1], filtered[1])
    }
}
