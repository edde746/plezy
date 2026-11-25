package com.edde746.plezy.plex

import com.edde746.plezy.backend.PlaybackReportMetadata
import com.edde746.plezy.backend.PlaybackReportOrigin
import io.ktor.client.request.HttpRequestData
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/** The timeline carries the playback's session identifier, so the server ties it to the stream it serves. */
class PlexTimelineSessionTest {
    private val requests = mutableListOf<HttpRequestData>()
    private val client = testPlexClient({ request ->
        requests += request
        jsonResponse("")
    })

    private fun timeline() = requests.first { it.url.encodedPath == "/:/timeline" }

    @Test
    fun `reportPlaybackStarted sends the session identifier`() = runTest {
        client.reportPlaybackStarted("42", 12.seconds, 90.minutes, playSessionId = "session-abc", playMethod = "Transcode")

        assertEquals("POST", timeline().method.value)
        assertEquals("playing", timeline().url.parameters["state"])
        assertEquals("session-abc", timeline().headers["X-Plex-Session-Identifier"])
    }

    @Test
    fun `reportPlaybackProgress sends the session identifier`() = runTest {
        client.reportPlaybackProgress("42", 5.minutes, 90.minutes, playSessionId = "session-abc", playMethod = "Transcode")

        assertEquals("playing", timeline().url.parameters["state"])
        assertEquals("session-abc", timeline().headers["X-Plex-Session-Identifier"])
    }

    @Test
    fun `reportPlaybackStopped sends the session identifier`() = runTest {
        client.reportPlaybackStopped("42", 5.minutes, 90.minutes, playSessionId = "session-abc")

        assertEquals("stopped", timeline().url.parameters["state"])
        assertEquals("session-abc", timeline().headers["X-Plex-Session-Identifier"])
    }

    @Test
    fun `the timeline omits the session identifier without a play session`() = runTest {
        client.reportPlaybackProgress("42", 5.minutes, 90.minutes)

        assertNull(timeline().headers["X-Plex-Session-Identifier"])
        assertNull(timeline().url.parameters["offline"])
        assertNull(timeline().url.parameters["continuing"])
    }

    @Test
    fun `an offline replay carries its recorded time and continuation`() = runTest {
        val report = PlaybackReportMetadata(PlaybackReportOrigin.OFFLINE_REPLAY, Instant.fromEpochSeconds(1_700_000_000), willContinue = false)

        client.reportPlaybackStopped("42", 5.minutes, report = report)

        val params = timeline().url.parameters
        assertEquals("1", params["offline"])
        assertEquals("1700000000", params["updated"])
        assertEquals("0", params["continuing"])
        assertNull(params["duration"])
    }
}
