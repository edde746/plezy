package com.edde746.plezy.trackers

import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.trackers.client.FakeCredentials
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/** Which services a build offers follows from the registrations it carries; none is half-offered. */
class TrackerProvidersTest {
    private val http = HttpClient(MockEngine { error("no request expected") })

    private fun services(config: TrackerConfig) = trackerProviders(http, config, "1.0").map { it.service }

    @Test
    fun aBuildWithoutRegistrationsOffersNoTracker() {
        assertEquals(emptyList(), services(TrackerConfig()))
        assertEquals(emptyList(), services(TrackerConfig(traktClientId = " ", simklClientId = "")))
    }

    @Test
    fun eachServiceNeedsAllItsRegistrationParts() {
        val full = TrackerConfig(
            traktClientId = "trakt-id",
            simklClientId = "simkl-id",
            mdblistClientId = "mdblist-id",
            malClientId = "mal-id",
            relayBaseUrl = "https://relay.example",
        )
        assertEquals(TrackerService.entries.toList(), services(full))

        assertEquals(listOf(TrackerService.SIMKL, TrackerService.MDBLIST, TrackerService.MYANIMELIST, TrackerService.ANILIST), services(full.copy(traktClientId = "")))
        // MyAnimeList signs in through the relay and refreshes with its own client id; AniList needs only the relay.
        assertEquals(listOf(TrackerService.TRAKT, TrackerService.SIMKL, TrackerService.MDBLIST), services(full.copy(relayBaseUrl = "")))
        assertEquals(listOf(TrackerService.TRAKT, TrackerService.SIMKL, TrackerService.MDBLIST, TrackerService.ANILIST), services(full.copy(malClientId = "")))
    }

    /**
     * The apps read a service's answer up to 32 MiB; a longer one fails as a network failure, never read whole. The
     * engine runs on the test's scheduler, so no request deadline passes while the body is read.
     */
    @Test
    fun anAnswerPastTheAppsCapFails() = runTest {
        val body = ByteArray(32 * 1024 * 1024 + 1) { ' '.code.toByte() } + "[]".encodeToByteArray()
        val http = HttpClient(MockEngine) {
            engine {
                dispatcher = StandardTestDispatcher(testScheduler)
                addHandler { respond(body, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json")) }
            }
        }
        val trakt = trackerProviders(http, TrackerConfig(traktClientId = "trakt-id"), "1.0").single().tracker(FakeCredentials(TrackerService.TRAKT)) as Rating
        assertFailsWith<TrackerException.Network> { trakt.rating(RatingTarget(RatingKind.MOVIE, ExternalIds(imdb = "tt0111161"))) }
    }
}
