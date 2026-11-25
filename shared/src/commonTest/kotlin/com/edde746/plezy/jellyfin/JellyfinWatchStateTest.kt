package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.test.runTest

class JellyfinWatchStateTest {
    private val item = MediaItem("item-1", BackendKind.JELLYFIN, MediaKind.MOVIE)
    private fun JellyfinTestServer.log() = requests.map { "${it.method} ${it.path}?${it.url.encodedQuery}" }

    private fun withPosition(ticks: Long) = JellyfinTestServer { req ->
        if (req.path.endsWith("/UserData")) FakeResponse(204, "") else FakeResponse(body = """{"ItemId":"item-1","Played":true,"PlaybackPositionTicks":$ticks}""")
    }

    @Test
    fun jellyfinMarkWatchedClearsSurvivingPositionThroughUnprefixedRoute() = runTest {
        val server = withPosition(12_000_000_000)
        JellyfinWatchState(server.core()).markWatched(item)
        assertEquals(listOf("POST /UserPlayedItems/item-1?userId=user-1", "POST /UserItems/item-1/UserData?userId=user-1"), server.log())
        assertEquals("""{"PlaybackPositionTicks":0}""", server.requests.last().body)
    }

    @Test
    fun embyMarkWatchedClearsSurvivingPositionThroughUserScopedRoute() = runTest {
        val server = withPosition(12_000_000_000)
        JellyfinWatchState(server.core(MediaBrowserDialect.EMBY)).markWatched(item)
        assertEquals(
            listOf("POST /Users/user-1/PlayedItems/item-1?userId=user-1", "POST /Users/user-1/Items/item-1/UserData?userId=user-1"),
            server.log(),
        )
        assertEquals("""{"PlaybackPositionTicks":0}""", server.requests.last().body)
    }

    @Test
    fun markThatZeroedThePositionIssuesNoFollowUp() = runTest {
        val server = withPosition(0)
        JellyfinWatchState(server.core()).markWatched(item)
        assertEquals(listOf("POST /UserPlayedItems/item-1?userId=user-1"), server.log())
    }

    @Test
    fun bodyWithoutUserDataIsLeftAlone() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        JellyfinWatchState(server.core()).markWatched(item)
        assertEquals(listOf("POST /UserPlayedItems/item-1?userId=user-1"), server.log())
    }

    @Test
    fun failedClearThrows() = runTest {
        val server = JellyfinTestServer { req ->
            if (req.path.endsWith("/UserData")) FakeResponse(500, "nope") else FakeResponse(body = """{"PlaybackPositionTicks":12000000000}""")
        }
        assertFailsWith<MediaServerHttpException> { JellyfinWatchState(server.core()).markWatched(item) }
    }

    @Test
    fun markWatchedStatusFailuresKeepTheirStatus() = runTest {
        for (status in listOf(400, 500)) {
            val server = JellyfinTestServer { FakeResponse(status, "{}") }
            val error = assertFailsWith<MediaServerHttpException> { JellyfinWatchState(server.core()).markWatched(item) }
            assertEquals(status, error.statusCode)
        }
    }

    @Test
    fun embyHidesFromContinueWatching() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        JellyfinWatchState(server.core(MediaBrowserDialect.EMBY)).removeFromContinueWatching(item)
        assertEquals(listOf("POST /Users/user-1/Items/item-1/HideFromResume?Hide=true"), server.log())
    }

    @Test
    fun jellyfinRefusesContinueWatchingRemovalWithoutRequest() = runTest {
        val server = JellyfinTestServer { FakeResponse(204, "") }
        assertFailsWith<UnsupportedOperationException> { JellyfinWatchState(server.core()).removeFromContinueWatching(item) }
        assertEquals(emptyList(), server.requests)
    }

    @Test
    fun watchStateRoutesPathEncodeReservedIds() = runTest {
        val server = JellyfinTestServer()
        val state = JellyfinWatchState(server.core())
        val reserved = item.copy(id = "folder/item #1?x")
        state.markUnwatched(reserved)
        state.rate(reserved, 7.0)
        state.rate(reserved, -1.0)
        state.rate(reserved, 5.9)
        assertEquals(
            listOf(
                "DELETE /UserPlayedItems/folder%2Fitem%20%231%3Fx?userId=user-1",
                "POST /UserItems/folder%2Fitem%20%231%3Fx/Rating?userId=user-1&Likes=true",
                "DELETE /UserItems/folder%2Fitem%20%231%3Fx/Rating?userId=user-1",
                "POST /UserItems/folder%2Fitem%20%231%3Fx/Rating?userId=user-1&Likes=false",
            ),
            server.log(),
        )
    }

    @Test
    fun favoriteTogglesPostAndDelete() = runTest {
        val server = JellyfinTestServer()
        JellyfinWatchState(server.core()).setFavorite(item, true)
        JellyfinWatchState(server.core(MediaBrowserDialect.EMBY)).setFavorite(item, false)
        assertEquals(
            listOf("POST /UserFavoriteItems/item-1?userId=user-1", "DELETE /Users/user-1/FavoriteItems/item-1?userId=user-1"),
            server.log(),
        )
    }
}
