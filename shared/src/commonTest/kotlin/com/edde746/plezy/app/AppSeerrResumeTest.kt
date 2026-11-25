package com.edde746.plezy.app

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.seerr.SeerrAuthMethod
import com.edde746.plezy.seerr.SeerrSession
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

class AppSeerrResumeTest {
    /**
     * The Seerr account is read again only on a real resume of the shown main screen: a return to the front before the
     * startup bind settled reads nothing, and one after it reads the account once.
     */
    @Test
    fun `a return to the front before the main screen shows reads no Seerr account`() = runTest {
        val server = MockServer(this) { request ->
            if (request.url.encodedPath == AUTH_ME) {
                respond(
                    """{"id":7,"displayName":"Alice","permissions":2,"avatar":"/a.png"}""",
                    HttpStatusCode.OK,
                    headersOf(HttpHeaders.ContentType, "application/json"),
                )
            } else {
                respond("", HttpStatusCode.NotFound)
            }
        }
        val session = SeerrSession(
            baseUrl = "https://seerr.example.com",
            method = SeerrAuthMethod.LOCAL,
            identifier = "a@b.c",
            secret = "pw",
            cookie = "stored-cookie",
            userId = 7,
            permissions = 2,
            displayName = "Alice",
            instanceLabel = "Seerr",
            createdAt = 0,
        )
        val secrets = MemorySecretStore().apply { entries["seerr_session.$PROFILE"] = session.encode().encodeToByteArray() }
        val data = testData()
        data.profiles.upsert(LocalProfile(id = PROFILE, displayName = "Me", createdAt = 0))
        ProfileIdentity(data).setActiveProfileId(PROFILE)
        val graph = testGraph(data, http = server.http, secrets = secrets)
        val app = AppSession(graph, FakeAppPlatform())
        fun accountReads() = server.requests.count { it.url.encodedPath == AUTH_ME }

        // The bind's own read, joined (concurrent refreshes share one read) and settled.
        app.seerr.session.filterNotNull().first()
        app.seerr.refreshUser()
        runCurrent()
        val bound = accountReads()

        // The app runs in the background scope, off advanceUntilIdle, and reads the account on its own dispatcher, off the
        // test scheduler: a resume is run with runCurrent and its request waited for in real time.
        suspend fun readsAfterResume(): Int {
            graph.setForeground(false)
            runCurrent()
            graph.setForeground(true)
            runCurrent()
            withContext(Dispatchers.Default) { withTimeoutOrNull(SETTLE) { while (accountReads() == bound) delay(10) } }
            runCurrent()
            return accountReads()
        }

        app.primed = false
        assertEquals(bound, readsAfterResume())

        app.primed = true
        assertEquals(bound + 1, readsAfterResume())
        app.close()
    }

    private companion object {
        const val PROFILE = "profile-1"
        const val AUTH_ME = "/api/v1/auth/me"

        /** How long a read launched by a return to the front is waited for, in real time. */
        val SETTLE = 2.seconds
    }
}
