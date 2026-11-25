package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.SpecialsOrdering
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.currentTime
import kotlinx.coroutines.test.runTest

class JellyfinDeletePermissionTest {
    private val server = JellyfinTestServer()
    private val browse = JellyfinBrowse(server.core()) { SpecialsOrdering.RESPECT_SERVER }
    private val item = MediaItem(id = "movie-1", backend = BackendKind.JELLYFIN, kind = MediaKind.MOVIE, serverId = "machine-1")

    @Test
    fun asksTheListEndpointForCanDeleteOnlyScopedToTheItemAndUser() = runTest {
        server.handler = { FakeResponse(200, """{"Items":[{"Id":"movie-1","CanDelete":true}]}""") }

        browse.fetchDeletePermission(item)

        // `/Items?ids=`, not `/Users/{id}/Items/{id}`: the single-item route ignores `Fields` and ships the whole DTO.
        val req = server.requests.single()
        assertEquals("/Items", req.path)
        assertEquals(
            mapOf(
                "ids" to "movie-1",
                "userId" to "user-1",
                "Fields" to "CanDelete",
                "EnableImages" to "false",
                "EnableUserData" to "false",
                "EnableTotalRecordCount" to "false",
            ),
            req.query,
        )
    }

    @Test
    fun reportsTheServerAnswer() = runTest {
        server.handler = { FakeResponse(200, """{"Items":[{"Id":"movie-1","CanDelete":true}]}""") }
        assertTrue(browse.fetchDeletePermission(item)!!)
        server.handler = { FakeResponse(200, """{"Items":[{"Id":"movie-1","CanDelete":false}]}""") }
        assertFalse(browse.fetchDeletePermission(item)!!)
    }

    @Test
    fun anItemTheUserCannotSeeIsNotDeletable() = runTest {
        server.handler = { FakeResponse(200, """{"Items":[]}""") }
        assertEquals(false, browse.fetchDeletePermission(item))
    }

    @Test
    fun anOmittedCanDeleteIsUnknown() = runTest {
        server.handler = { FakeResponse(200, """{"Items":[{"Id":"movie-1"}]}""") }
        assertNull(browse.fetchDeletePermission(item))
    }

    @Test
    fun anErrorResponseThrowsInsteadOfReportingAPermission() = runTest {
        server.handler = { FakeResponse(401, "nope") }
        assertEquals(401, assertFailsWith<MediaServerHttpException> { browse.fetchDeletePermission(item) }.statusCode)
    }

    @Test
    fun aServerThatNeverAnswersTimesOutAtTheProbeDeadline() = runTest {
        server.handler = { awaitCancellation() }

        val error = assertFailsWith<MediaServerHttpException> { browse.fetchDeletePermission(item) }

        assertEquals(MediaServerHttpErrorType.CONNECTION_TIMEOUT, error.type)
        assertTrue(currentTime <= MediaServerTimeouts.DELETE_PERMISSION_PROBE.inWholeMilliseconds)
    }

    @Test
    fun deleteMediaItemSendsDelete() = runTest {
        server.handler = { FakeResponse(204, "") }
        assertTrue(browse.deleteMediaItem(item))
        assertEquals("DELETE", server.requests.single().method)
        assertEquals("/Items/movie-1", server.requests.single().path)
    }
}
