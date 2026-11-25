package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.seerr.json
import com.edde746.plezy.seerr.path
import com.edde746.plezy.seerr.seerrClient
import com.edde746.plezy.seerr.session
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.fail
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest

/** Whether a title page offers Request, or the state that stands in for it, judged as the request sheet judges. */
class SeerrRequestBlockTest {
    private val settings = """{"initialized":true,"localLogin":true,"mediaServerLogin":true,"partialRequestsEnabled":true}"""

    private suspend fun TestScope.block(kind: MediaKind, body: String): SeerrBlock? {
        val path = if (kind == MediaKind.MOVIE) "/api/v1/movie/7" else "/api/v1/tv/7"
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings)
                path -> json(body)
                else -> fail("unexpected request ${request.path}")
            }
        }
        return seerrRequestBlock(seerrClient(server, session()), kind, 7)
    }

    private fun tv(seasons: String, info: String) =
        """{"id":7,"name":"Show","seasons":[{"seasonNumber":0,"episodeCount":3,"name":"Specials"},$seasons],"mediaInfo":$info}"""

    private val twoSeasons = """{"seasonNumber":1,"episodeCount":8,"name":"Season 1"},{"seasonNumber":2,"episodeCount":8,"name":"Season 2"}"""

    @Test
    fun aMovieSeerrHasNeverSeenCanBeRequested() = runTest {
        assertNull(block(MediaKind.MOVIE, """{"id":7,"title":"Movie"}"""))
    }

    @Test
    fun anAvailableMovieIsAvailable() = runTest {
        assertEquals(SeerrBlock.AVAILABLE, block(MediaKind.MOVIE, """{"id":7,"title":"Movie","mediaInfo":{"status":5,"status4k":1,"requests":[]}}"""))
    }

    @Test
    fun aPendingRequestMakesAMovieRequested() = runTest {
        val info = """{"status":2,"status4k":1,"requests":[{"id":1,"status":1,"is4k":false}]}"""
        assertEquals(SeerrBlock.REQUESTED, block(MediaKind.MOVIE, """{"id":7,"title":"Movie","mediaInfo":$info}"""))
    }

    @Test
    fun aMovieOnlyAFailedRequestClaimsCanBeRequestedAgain() = runTest {
        val info = """{"status":2,"status4k":1,"requests":[{"id":1,"status":4,"is4k":false}]}"""
        assertNull(block(MediaKind.MOVIE, """{"id":7,"title":"Movie","mediaInfo":$info}"""))
    }

    @Test
    fun aShowWithEverySeasonAvailableIsAvailableSpecialsAside() = runTest {
        val info = """{"status":5,"status4k":1,"seasons":[{"seasonNumber":1,"status":5},{"seasonNumber":2,"status":5}],"requests":[]}"""
        assertEquals(SeerrBlock.AVAILABLE, block(MediaKind.SHOW, tv(twoSeasons, info)))
    }

    @Test
    fun aShowWithSomeSeasonsAvailableAndTheRestRequestedIsRequested() = runTest {
        val info = """{"status":4,"status4k":1,"seasons":[{"seasonNumber":1,"status":5}],
            "requests":[{"id":1,"status":2,"is4k":false,"seasons":[{"seasonNumber":2}]}]}"""
        assertEquals(SeerrBlock.REQUESTED, block(MediaKind.SHOW, tv(twoSeasons, info)))
    }

    @Test
    fun aShowWithASeasonLeftToRequestCanBeRequested() = runTest {
        val info = """{"status":4,"status4k":1,"seasons":[{"seasonNumber":1,"status":5}],"requests":[]}"""
        assertNull(block(MediaKind.SHOW, tv(twoSeasons, info)))
    }
}
