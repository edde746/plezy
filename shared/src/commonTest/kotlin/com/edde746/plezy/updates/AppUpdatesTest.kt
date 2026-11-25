package com.edde746.plezy.updates

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.testData
import com.edde746.plezy.settings.AppSettings
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpRequestTimeoutException
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Clock
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Instant

class AppUpdatesTest {
    private val clock = object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(1_790_000_000_000)
    }
    private val data: LocalData = testData()
    private val scope = CoroutineScope(Dispatchers.Default + Job())
    private var requests = 0

    @AfterTest
    fun cancel() = scope.cancel()

    private fun updates(
        updater: Updater = Updater.GITHUB,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) = AppUpdates(
        updater,
        HttpClient(MockEngine { request -> requests++; handler(request) }) { install(HttpTimeout) },
        data.deviceSettings,
        currentVersion = "1.0.0",
        clock = clock,
        scope = scope,
    )

    private fun noRequests() = updates { error("no request expected") }

    private suspend fun lastCheck() = data.deviceSettings.value(AppSettings.updateLastCheckTime)

    private suspend fun setLastCheck(value: String) = data.deviceSettings.set(AppSettings.updateLastCheckTime, value)

    private fun MockRequestHandleScope.release(json: String) =
        respond(json, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))

    /** The failures a check meets: no answer in time, an answer other than 200, an answer that isn't JSON. */
    private val failures: Map<String, suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData> = mapOf(
        "timeout" to { request -> throw HttpRequestTimeoutException(request) },
        "non-200 response" to { respond("unavailable", HttpStatusCode.ServiceUnavailable) },
        "parse failure" to { respond("not-json", HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json")) },
    )

    @Test
    fun `malformed cooldown state fails open and removes the invalid value`() = runTest {
        setLastCheck("not-an-instant")

        assertTrue(noRequests().isDue())
        assertNull(lastCheck())
    }

    @Test
    fun `future cooldown state fails open and removes the invalid value`() = runTest {
        setLastCheck((clock.now() + 30.days).toString())

        assertTrue(noRequests().isDue())
        assertNull(lastCheck())
    }

    @Test
    fun `recent valid cooldown state suppresses a duplicate check and remains stored`() = runTest {
        val recent = (clock.now() - 5.minutes).toString()
        setLastCheck(recent)

        assertFalse(noRequests().isDue())
        assertEquals(recent, lastCheck())
    }

    @Test
    fun `old valid cooldown state permits a new check`() = runTest {
        val old = (clock.now() - 2.days).toString()
        setLastCheck(old)

        assertTrue(noRequests().isDue())
        assertEquals(old, lastCheck())
    }

    @Test
    fun `the local time of an earlier release without an offset is read`() = runTest {
        setLastCheck("2026-09-21T13:46:40.123456")
        val updates = updates { error("no request expected") }

        // 1_790_000_000_000 ms is 2026-09-21T14:13:20Z: the stored time reads as 27 minutes before, and stays.
        assertFalse(updates.isDue())
        assertEquals("2026-09-21T13:46:40.123456", lastCheck())
    }

    @Test
    fun `a manual check reports a failure rather than the latest version`() = runTest {
        for ((name, failure) in failures) {
            assertFailsWith<UpdateCheckException>(name) { updates(handler = failure).checkNow() }
        }
    }

    @Test
    fun `a manual check that finds no newer release returns null`() = runTest {
        val updates = updates { release("""{"tag_name":"v1.0.0","html_url":"https://example.com","published_at":"2026-01-01"}""") }

        assertNull(updates.checkNow())
    }

    @Test
    fun `startup failure records cooldown before request and manual check bypasses it`() = runTest {
        for ((name, failure) in failures) {
            data.deviceSettings.set(AppSettings.updateLastCheckTime, null)
            requests = 0
            val atRequest = mutableListOf<String?>()
            val updates = updates { request ->
                atRequest += lastCheck()
                failure(request)
            }

            assertNull(updates.check(respectCooldown = true, throwOnFailure = false), name)
            assertEquals(1, requests, name)
            val recorded = assertNotNull(atRequest.single(), name)
            assertEquals(recorded, lastCheck(), name)
            assertEquals(clock.now(), Instant.parse(recorded), name)

            assertNull(updates.check(respectCooldown = true, throwOnFailure = false), name)
            assertEquals(1, requests, "$name: a next launch honours the failed attempt's cooldown")

            assertNull(updates.check(respectCooldown = false, throwOnFailure = false), name)
            assertEquals(2, requests, "$name: a manual check bypasses a recent launch's cooldown")
            assertEquals(recorded, lastCheck(), "$name: a manual check leaves the launch's cooldown as it is")
        }
    }

    @Test
    fun `a newer release is offered with its page and name and notes and date`() = runTest {
        lateinit var seen: HttpRequestData
        val updates = updates { request ->
            seen = request
            release("""{"tag_name":"v1.2.0","html_url":"https://github.com/edde746/plezy/releases/tag/1.2.0","name":"Plezy 1.2","body":"- fixes","published_at":"2026-10-01T10:00:00Z"}""")
        }

        val update = updates.checkNow()

        assertEquals("https://api.github.com/repos/edde746/plezy/releases/latest", seen.url.toString())
        assertEquals("application/vnd.github+json", seen.headers[HttpHeaders.Accept])
        assertEquals(
            ReleaseUpdate(
                currentVersion = "1.0.0",
                latestVersion = "1.2.0",
                releaseUrl = "https://github.com/edde746/plezy/releases/tag/1.2.0",
                releaseName = "Plezy 1.2",
                releaseNotes = "- fixes",
                publishedAt = "2026-10-01T10:00:00Z",
            ),
            update,
        )
    }

    @Test
    fun `a release without a name or notes is offered as its version`() = runTest {
        val updates = updates { release("""{"tag_name":"2.0.0","html_url":"https://example.com/2.0.0","published_at":"2026-10-01"}""") }

        val update = assertNotNull(updates.checkNow())

        assertEquals("2.0.0", update.latestVersion)
        assertEquals("Version 2.0.0", update.releaseName)
        assertEquals("", update.releaseNotes)
    }

    @Test
    fun `a skipped release is not offered but a later one is`() = runTest {
        var tag = "v1.1.0"
        val updates = updates { release("""{"tag_name":"$tag","html_url":"https://example.com","published_at":"2026-10-01"}""") }
        updates.skip("1.1.0").join()

        assertNull(updates.checkNow())
        tag = "v1.1.1"
        assertEquals("1.1.1", updates.checkNow()?.latestVersion)
    }

    @Test
    fun `the launch check runs only for the GitHub updater with the setting on`() = runTest {
        val newer: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData =
            { release("""{"tag_name":"v1.1.0","html_url":"https://example.com","published_at":"2026-10-01"}""") }

        assertNull(updates(Updater.NATIVE, newer).releaseAtLaunch())
        assertNull(updates(Updater.NONE, newer).releaseAtLaunch())
        data.deviceSettings.set(AppSettings.autoCheckUpdatesOnStartup, false)
        assertNull(updates(Updater.GITHUB, newer).releaseAtLaunch())
        assertFalse(updates(Updater.NATIVE, newer).nativeCheckAtLaunch())
        assertEquals(0, requests)

        data.deviceSettings.set(AppSettings.autoCheckUpdatesOnStartup, true)
        assertTrue(updates(Updater.NATIVE, newer).nativeCheckAtLaunch())
        assertFalse(updates(Updater.GITHUB, newer).nativeCheckAtLaunch())
        assertEquals("1.1.0", updates(Updater.GITHUB, newer).releaseAtLaunch()?.latestVersion)
        assertEquals(clock.now().toString(), lastCheck())
    }

    @Test
    fun `the launch check hands the updater of the platform or the release on`() = runTest {
        val newer: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData =
            { release("""{"tag_name":"v1.1.0","html_url":"https://example.com","published_at":"2026-10-01"}""") }
        val events = mutableListOf<String>()
        val native = { events += "native" }
        val offer = { update: ReleaseUpdate -> events += "offer ${update.latestVersion}" }

        updates(Updater.NONE, newer).checkAtLaunch(native, offer).join()
        updates(Updater.NATIVE, newer).checkAtLaunch(native, offer).join()
        updates(Updater.GITHUB, newer).checkAtLaunch(native, offer).join()
        // Within the 6 hours the first check started.
        updates(Updater.GITHUB, newer).checkAtLaunch(native, offer).join()

        assertEquals(listOf("native", "offer 1.1.0"), events)
        assertEquals(1, requests)
    }

    @Test
    fun `versions compare by their numeric parts`() {
        assertTrue(isNewerVersion("1.0.1", "1.0.0"))
        assertTrue(isNewerVersion("1.10.0", "1.9.9"))
        assertTrue(isNewerVersion("2.0", "1.99.99"))
        assertTrue(isNewerVersion("1.0.0.1", "1.0.0"))
        assertFalse(isNewerVersion("1.0.0", "1.0.0"))
        assertFalse(isNewerVersion("1.0", "1.0.0"))
        assertFalse(isNewerVersion("1.0.0", "1.0.1"))
        // Suffixes after + or - are ignored; an unreadable part counts as 0.
        assertFalse(isNewerVersion("1.0.0+5", "1.0.0"))
        assertFalse(isNewerVersion("1.0.0-beta", "1.0.0"))
        assertTrue(isNewerVersion("1.1.0-beta", "1.0.0"))
        assertTrue(isNewerVersion("1.0.1", "1.0.x"))
    }
}
