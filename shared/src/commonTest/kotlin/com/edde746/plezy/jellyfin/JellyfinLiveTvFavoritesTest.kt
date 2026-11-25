package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.data.livetv.FavoriteChannel
import com.edde746.plezy.data.testData
import com.edde746.plezy.model.MediaBrowserDialect
import io.ktor.client.network.sockets.ConnectTimeoutException
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertSame
import kotlin.test.assertTrue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

/** The server's favourite flags are mirrored, the local list keeps only what the server confirmed. */
class JellyfinLiveTvFavoritesTest {
    private val data = testData()

    @AfterTest
    fun closeData() = data.close()

    private fun favorite(id: String, title: String = id) = FavoriteChannel(source = "server://machine-1/jellyfin", id = id, title = title)

    /** The local store: [current] is what's persisted; reads and writes fail with the given errors. */
    private class MemoryFavorites(initial: List<FavoriteChannel>, val readError: Exception? = null, val writeError: Exception? = null) {
        var current = initial
        var writeAttempts = 0
        var writeCount = 0
        val keys = mutableListOf<String>()

        suspend fun read(connectionId: String): List<FavoriteChannel> {
            keys += connectionId
            readError?.let { throw it }
            return current
        }

        suspend fun write(connectionId: String, channels: List<FavoriteChannel>) {
            keys += connectionId
            writeAttempts++
            writeError?.let { throw it }
            current = channels
            writeCount++
        }
    }

    private fun TestScope.liveTv(server: JellyfinTestServer, store: MemoryFavorites) = server.liveTv(this, readFavorites = store::read, writeFavorites = store::write)

    private fun RecordedRequest.mutation() = "$method:${path.substringAfterLast('/')}"

    @Test fun mixedOutcomesPersistTheConfirmedProjectionAndRetryOnlyWhatIsUnconfirmed() = runTest {
        val store = MemoryFavorites(listOf(favorite("keep", "Old keep"), favorite("remove-ok"), favorite("remove-fail")))
        var failing = setOf("add-fail", "remove-fail")
        val server = JellyfinTestServer { FakeResponse(status = if (it.path.substringAfterLast('/') in failing) 400 else 204, body = "") }
        val desired = listOf(favorite("keep", "Updated keep"), favorite("add-ok", "Added"), favorite("add-fail"))

        val error = assertFailsWith<MediaServerHttpException> { liveTv(server, store).setFavoriteChannels(desired) }
        assertEquals(400, error.statusCode)
        assertEquals(listOf("POST:add-ok", "POST:add-fail", "DELETE:remove-ok", "DELETE:remove-fail"), server.requests.map { it.mutation() })
        assertEquals(MediaBrowserPaths(MediaBrowserDialect.JELLYFIN, "user-1").favoriteItem("add-ok"), server.requests[0].path)
        assertEquals(1, store.writeCount)
        assertEquals(listOf("keep", "add-ok", "remove-fail"), store.current.map { it.id })
        assertEquals("Updated keep", store.current.first().title)
        assertTrue(store.keys.all { it == "machine-1/user-1" })

        server.requests.clear()
        failing = emptySet()
        liveTv(server, store).setFavoriteChannels(desired)
        assertEquals(listOf("POST:add-fail", "DELETE:remove-fail"), server.requests.map { it.mutation() })
        assertEquals(2, store.writeCount)
        assertEquals(listOf("keep", "add-ok", "add-fail"), store.current.map { it.id })
    }

    @Test fun aRejectedAdditionKeepsTheEmptyBaselineAndThrows() = runTest {
        val store = MemoryFavorites(emptyList())
        val server = JellyfinTestServer { FakeResponse(status = 409, body = "") }
        assertFailsWith<MediaServerHttpException> { liveTv(server, store).setFavoriteChannels(listOf(favorite("add"))) }
        assertEquals(1, server.requests.size)
        assertEquals(emptyList(), store.current)
    }

    @Test fun aRejectedRemovalKeepsThePriorFavouriteAndThrows() = runTest {
        val store = MemoryFavorites(listOf(favorite("remove")))
        val server = JellyfinTestServer { FakeResponse(status = 409, body = "") }
        assertFailsWith<MediaServerHttpException> { liveTv(server, store).setFavoriteChannels(emptyList()) }
        assertEquals(1, server.requests.size)
        assertEquals(listOf("remove"), store.current.map { it.id })
    }

    @Test fun successfulWritesKeepTheRequestedOrderAndFieldsWithoutReorderRequests() = runTest {
        val store = MemoryFavorites(listOf(favorite("first"), favorite("second")))
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        liveTv(server, store).setFavoriteChannels(listOf(favorite("second", "Second updated"), favorite("third", "Third added"), favorite("first", "First updated")))
        assertEquals(listOf("POST:third"), server.requests.map { it.mutation() })
        assertEquals(mapOf("userId" to "user-1"), server.requests.single().query)
        assertEquals(listOf("second", "third", "first"), store.current.map { it.id })
        assertEquals(listOf("Second updated", "Third added", "First updated"), store.current.map { it.title })

        server.requests.clear()
        liveTv(server, store).setFavoriteChannels(listOf(favorite("first", "First newest"), favorite("second", "Second newest"), favorite("third", "Third newest")))
        assertEquals(emptyList(), server.requests)
        assertEquals(listOf("First newest", "Second newest", "Third newest"), store.current.map { it.title })
    }

    @Test fun aFailedBaselineReadStopsBeforeAnyRequestOrWrite() = runTest {
        val failure = IllegalStateException("baseline unavailable")
        val store = MemoryFavorites(emptyList(), readError = failure)
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        assertSame(failure, assertFailsWith<IllegalStateException> { liveTv(server, store).setFavoriteChannels(listOf(favorite("add"))) })
        assertEquals(emptyList(), server.requests)
        assertEquals(0, store.writeAttempts)
    }

    @Test fun aFailedLocalWriteWinsOverCompletedServerChanges() = runTest {
        val failure = IllegalStateException("durable write unavailable")
        val store = MemoryFavorites(emptyList(), writeError = failure)
        val server = JellyfinTestServer { FakeResponse(status = 204, body = "") }
        assertSame(failure, assertFailsWith<IllegalStateException> { liveTv(server, store).setFavoriteChannels(listOf(favorite("add"))) })
        assertEquals(1, server.requests.size)
        assertEquals(1, store.writeAttempts)
        assertEquals(emptyList(), store.current)
    }

    @Test fun anAmbiguousTimeoutKeepsThePriorStateStaysTypedAndRetriesTheIntent() = runTest {
        val store = MemoryFavorites(emptyList())
        var timeOut = true
        val server = JellyfinTestServer {
            if (timeOut) throw ConnectTimeoutException("request timed out")
            FakeResponse(status = 204, body = "")
        }
        val desired = listOf(favorite("add"))
        val error = assertFailsWith<MediaServerHttpException> { liveTv(server, store).setFavoriteChannels(desired) }
        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertEquals(emptyList(), store.current)

        timeOut = false
        liveTv(server, store).setFavoriteChannels(desired)
        assertEquals(2, server.requests.size)
        assertEquals(listOf("add"), store.current.map { it.id })
    }

    // The local store isolates users of one server; a read failure reaches the caller.
    @Test fun usersOfOneServerKeepTheirOwnFavourites() = runTest {
        val server = JellyfinTestServer { error("favourite reads are local") }
        fun client(userId: String) = JellyfinClient(
            connection = server.connection().copy(id = "machine-1/$userId", userId = userId),
            http = server.http,
            identity = JellyfinDeviceIdentity("Plezy Linux", "Test Box", "1.2.3", "dev-1"),
            cache = JellyfinApiCache(server.store, JellyfinCacheResolver(server.store, { emptyList() }, { emptyList() })),
            scope = CoroutineScope(coroutineContext),
            favorites = data.liveTvFavorites,
        )
        data.liveTvFavorites.replace("machine-1/user-a", listOf(favorite("chan-a1"), favorite("chan-a2")))
        assertEquals(listOf("chan-a1", "chan-a2"), client("user-a").liveTv.fetchFavoriteChannels().map { it.id })
        assertEquals(emptyList(), client("user-b").liveTv.fetchFavoriteChannels())

        val failure = IllegalStateException("favorite store unavailable")
        val failing = server.liveTv(this, readFavorites = { throw failure })
        assertSame(failure, assertFailsWith<IllegalStateException> { failing.fetchFavoriteChannels() })
    }
}
