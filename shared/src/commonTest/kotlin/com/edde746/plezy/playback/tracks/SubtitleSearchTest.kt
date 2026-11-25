package com.edde746.plezy.playback.tracks

import com.edde746.plezy.model.MediaSubtitleTrack
import com.edde746.plezy.playback.session.SubtitleDownloadOutcome
import com.edde746.plezy.plex.PlexSubtitleSearchResult
import com.edde746.plezy.plex.jsonResponse
import com.edde746.plezy.plex.testPlexClient
import io.ktor.client.request.HttpRequestData
import io.ktor.http.HttpMethod
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class SubtitleSearchTest {
    @Test
    fun `the new external row ignores embedded and known rows`() {
        val embedded = MediaSubtitleTrack(id = 1, selected = false, forced = false)
        val existing = MediaSubtitleTrack(id = 2, external = true, selected = false, forced = false)
        val downloaded = MediaSubtitleTrack(id = 3, external = true, selected = false, forced = false)
        assertEquals(downloaded, findNewExternalSubtitleTrack(listOf(embedded, existing, downloaded), setOf(1, 2)))
    }

    @Test
    fun `a download onto the already selected source counts as applied`() {
        assertEquals(SubtitleDownloadOutcome.APPLIED, subtitleDownloadOutcomeFor(SourceSwitchOutcome.UNCHANGED))
        assertEquals(SubtitleDownloadOutcome.APPLIED, subtitleDownloadOutcomeFor(SourceSwitchOutcome.APPLIED))
        assertEquals(SubtitleDownloadOutcome.NOT_APPLIED, subtitleDownloadOutcomeFor(SourceSwitchOutcome.BUSY))
    }

    private val result = PlexSubtitleSearchResult(id = 1, key = "/sub/7", providerTitle = "OpenSubtitles", hearingImpaired = true)

    private fun metadata(withDownload: Boolean): String {
        val downloaded = if (withDownload) """,{"streamType":3,"id":403,"codec":"srt","languageCode":"fra","key":"/library/streams/403","external":true}""" else ""
        return """{"MediaContainer":{"Metadata":[{"ratingKey":"42","Media":[{"id":7,"container":"mkv","Part":[{"id":99,"key":"/library/parts/99/file.mkv","Stream":[
            {"streamType":1,"id":300,"codec":"h264"},
            {"streamType":3,"id":401,"index":1,"codec":"ass","languageCode":"eng"}$downloaded]}]}]}]}}"""
    }

    @Test
    fun `a download polls every 2 s until the new row appears then switches to it`() = runTest {
        val requests = mutableListOf<HttpRequestData>()
        var polls = 0
        val client = testPlexClient({ request ->
            requests += request
            if (request.method == HttpMethod.Put) {
                jsonResponse("", 200)
            } else {
                polls++
                jsonResponse(metadata(withDownload = polls >= 3))
            }
        })
        val switched = mutableListOf<Int>()
        val outcome = PlexSubtitleDownloader(client, testScheduler.timeSource).downloadAndApply(
            ratingKey = "42",
            result = result,
            searchLanguage = "fr",
            existingSourceIds = setOf(401),
            position = { null },
            isCurrent = { true },
            switchToSource = { switched += it; SourceSwitchOutcome.APPLIED },
        )
        assertEquals(SubtitleDownloadOutcome.APPLIED, outcome)
        assertEquals(listOf(403), switched)
        assertEquals(3, polls)
        assertEquals(6_000L, testScheduler.currentTime)
        val put = requests.first()
        assertEquals("/library/metadata/42/subtitles", put.url.encodedPath)
        assertEquals("srt", put.url.parameters["codec"])
        assertEquals("fr", put.url.parameters["language"])
        assertEquals("1", put.url.parameters["hearingImpaired"])
        assertEquals("OpenSubtitles", put.url.parameters["providerTitle"])
    }

    @Test
    fun `a row that never appears times out after 15 s`() = runTest {
        var polls = 0
        val client = testPlexClient({ request ->
            if (request.method == HttpMethod.Put) jsonResponse("", 200) else jsonResponse(metadata(withDownload = false)).also { polls++ }
        })
        val outcome = PlexSubtitleDownloader(client, testScheduler.timeSource).downloadAndApply(
            "42", result, "fr", setOf(401), { null }, { true }, { error("nothing to switch to") },
        )
        assertEquals(SubtitleDownloadOutcome.TIMED_OUT, outcome)
        assertEquals(8, polls)
    }

    @Test
    fun `playback moving on ends the wait unapplied`() = runTest {
        val client = testPlexClient({ request ->
            if (request.method == HttpMethod.Put) jsonResponse("", 200) else jsonResponse(metadata(withDownload = true))
        })
        val outcome = PlexSubtitleDownloader(client, testScheduler.timeSource).downloadAndApply(
            "42", result, "fr", setOf(401), { null }, { false }, { error("superseded") },
        )
        assertEquals(SubtitleDownloadOutcome.NOT_APPLIED, outcome)
    }

    @Test
    fun `a refused download throws`() = runTest {
        val client = testPlexClient({ jsonResponse("", 201) })
        assertFailsWith<SubtitleDownloadException> {
            PlexSubtitleDownloader(client, testScheduler.timeSource).downloadAndApply("42", result, "fr", emptySet(), { null }, { true }, { SourceSwitchOutcome.APPLIED })
        }
    }
}
