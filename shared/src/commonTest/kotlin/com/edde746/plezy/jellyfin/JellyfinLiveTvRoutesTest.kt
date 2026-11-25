package com.edde746.plezy.jellyfin

import kotlin.test.Test
import kotlin.test.assertEquals

class JellyfinLiveTvRoutesTest {
    private fun JellyfinRoute.url() = path + JellyfinCore.queryString(query)

    @Test
    fun availabilityAsksForOneChannel() {
        assertEquals("/LiveTv/Channels?limit=1&userId=user-1", JellyfinLiveTvRoutes.availability("user-1").url())
    }

    @Test
    fun channelsSortByName() {
        assertEquals(
            "/LiveTv/Channels?userId=user-1&enableImages=true&enableUserData=true&sortBy=SortName&sortOrder=Ascending",
            JellyfinLiveTvRoutes.channels("user-1").url(),
        )
    }

    @Test
    fun programsCarryOptionalChannelAndWindowFilters() {
        val base = "/LiveTv/Programs?userId=user-1&enableImages=true&fields=Overview&sortBy=StartDate&sortOrder=Ascending"
        assertEquals(base, JellyfinLiveTvRoutes.programs("user-1").url())
        assertEquals(
            "$base&channelIds=c1%2Cc2&minEndDate=2026-01-01T00%3A00%3A00.000Z&maxStartDate=2026-01-02T00%3A00%3A00.000Z",
            JellyfinLiveTvRoutes.programs("user-1", listOf("c1", "c2"), "2026-01-01T00:00:00.000Z", "2026-01-02T00:00:00.000Z").url(),
        )
    }

    @Test
    fun directStreamIsStaticWithSourceStreamAndDevice() {
        assertEquals(
            "/Videos/ch%201/stream.ts?Static=true&MediaSourceId=ms-1&LiveStreamId=ls-1&DeviceId=dev-1",
            JellyfinLiveTvRoutes.directStream("ch 1", "ts", "ms-1", "ls-1", "dev-1").url(),
        )
        assertEquals("/Videos/ch/stream.ts?Static=true&DeviceId=dev-1", JellyfinLiveTvRoutes.directStream("ch", "ts", null, null, "dev-1").url())
    }
}
