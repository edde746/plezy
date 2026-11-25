package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.JsonPrimitive

class SeerrClientTest {
    private val quota = SeerrRequestPayload(mediaType = "movie", mediaId = 603)

    // ---- Silent re-auth ----

    @Test
    fun aSeerr403OnAuthMeTriggersOneReloginRetriesAndPersistsTheNewSession() = runTest {
        var meCalls = 0
        var loginCalls = 0
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/jellyfin") {
                loginCalls++
                assertEquals(JsonPrimitive("hunter2"), request.bodyJson()["password"])
                login()
            } else {
                assertEquals("/api/v1/auth/me", request.path)
                meCalls++
                if (request.cookie != cookieHeader("fresh-cookie")) sessionGone() else json(user())
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must not invalidate") }, onSessionUpdated = { updated = it })

        assertEquals(7, client.getMe().id)
        assertEquals(1, loginCalls)
        assertEquals(3, meCalls, "the rejected call, the sign-in read-back, and the retry")
        assertEquals("fresh-cookie", updated?.cookie)
        // The re-packed session keeps what it signs in again with.
        assertEquals("hunter2", updated?.secret)
        assertEquals(SeerrAuthMethod.JELLYFIN, updated?.method)
    }

    @Test
    fun plexReauthPullsTheLiveTokenFromTheSupplier() = runTest {
        var supplied = false
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/auth/plex" -> {
                    assertEquals(jsonObject("""{"authToken":"live-token"}"""), request.bodyJson())
                    login()
                }
                request.cookie != cookieHeader("fresh-cookie") -> sessionGone()
                else -> json(user())
            }
        }
        val client = seerrClient(
            server,
            session(SeerrAuthMethod.PLEX, secret = ""),
            plexToken = { supplied = true; "live-token" },
            onSessionInvalidated = { fail("must not invalidate") },
        )
        client.getMe()
        assertTrue(supplied)
    }

    @Test
    fun reauthWithoutStoredCredentialsInvalidatesTheSession() = runTest {
        var invalidated = false
        val client = seerrClient(MockServer(this) { sessionGone() }, session(secret = ""), onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.Auth> { client.getMe() }
        assertTrue(invalidated)
    }

    @Test
    fun aTransientlyUnresolvablePlexTokenErrorsWithoutUnlinkingTheSession() = runTest {
        var invalidated = false
        val server = MockServer(this) { sessionGone() }
        // A degraded launch: the profile's identity can't be resolved right now.
        val client = seerrClient(server, session(SeerrAuthMethod.PLEX, secret = ""), plexToken = { null }, onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.ReauthUnavailable> { client.getMe() }
        assertFalse(invalidated, "a retryable failure must not clear the stored session")
        assertTrue(server.requests.none { it.path == "/api/v1/auth/plex" })

        // Once the supplier recovers, the next expiry signs in again.
        val recovering = seerrClient(
            MockServer(this) { request ->
                when {
                    request.path == "/api/v1/auth/plex" -> login()
                    request.cookie != cookieHeader("fresh-cookie") -> sessionGone()
                    else -> json(user())
                }
            },
            session(SeerrAuthMethod.PLEX, secret = ""),
            plexToken = { "live-token" },
            onSessionInvalidated = { invalidated = true },
        )
        assertEquals(7, recovering.getMe().id)
        assertFalse(invalidated)
    }

    @Test
    fun a403ReauthsOnceAuthMeConfirmsTheInstanceDroppedTheSession() = runTest {
        // Seerr's middleware answers a missing session with 403 (never 401), as it answers a missing permission.
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/auth/jellyfin" -> login()
                request.cookie != cookieHeader("fresh-cookie") -> sessionGone()
                request.path == "/api/v1/auth/me" -> json(user())
                else -> json("""{"page":1,"totalPages":1,"results":[]}""")
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must not invalidate") }, onSessionUpdated = { updated = it })

        assertTrue(client.getTrending().items.isEmpty())
        assertEquals("fresh-cookie", updated?.cookie)
        assertEquals(
            listOf(
                "/api/v1/discover/trending",
                "/api/v1/auth/me", // confirms the session is gone
                "/api/v1/auth/jellyfin",
                "/api/v1/auth/me", // the sign-in's read-back
                "/api/v1/discover/trending",
            ),
            server.requests.map { it.path },
        )
    }

    @Test
    fun handlerAndMiddlewareDenialsRefreshLiveAuthorityWithoutReauthentication() = runTest {
        // POST /request's route denies permission, quota and blocklist alike with {message}; only the middleware and a
        // live /auth/me probe support a typed permission error. Both take the current authority.
        var invalidated = false
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/auth/me" -> json(user(0))
                "/api/v1/request" -> json("""{"message":"You do not have permission to make this request."}""", 403)
                "/api/v1/discover/trending" -> sessionGone()
                else -> fail("no login expected: ${request.path}")
            }
        }
        val client = seerrClient(
            server,
            session(SeerrAuthMethod.QUICK_CONNECT, secret = ""),
            onSessionInvalidated = { invalidated = true },
            onSessionUpdated = { updated = it },
        )

        val denied = assertFailsWith<SeerrException.Api> { client.createRequest(quota) }
        assertEquals(403, denied.statusCode)
        assertEquals("You do not have permission to make this request.", denied.message)
        assertEquals(listOf("/api/v1/request", "/api/v1/auth/me"), server.requests.map { it.path })
        assertEquals(0, updated?.permissions)

        server.clearRequests()
        val permission = assertFailsWith<SeerrException.Permission> { client.getTrending() }
        assertEquals(403, permission.statusCode)
        assertEquals(T.seerr.permissionDenied, permission.display)
        assertEquals(listOf("/api/v1/discover/trending", "/api/v1/auth/me"), server.requests.map { it.path })
        assertFalse(invalidated)
        assertEquals(0, client.session.permissions)
    }

    @Test
    fun aHandlerDenialPreservesItsMessageDespiteAnUnrelatedAuthorityChange() = runTest {
        for (denial in listOf("Request quota exceeded", "此媒体已被列入屏蔽名单")) {
            val server = MockServer(this) { request ->
                when (request.path) {
                    "/api/v1/request" -> json("""{"message":"$denial"}""", 403)
                    "/api/v1/auth/me" -> json(user(SeerrPermission.REQUEST))
                    else -> fail("no login or replay expected")
                }
            }
            val client = seerrClient(server, session(SeerrAuthMethod.QUICK_CONNECT, secret = ""), onSessionInvalidated = { fail("must remain linked") })
            assertEquals(denial, assertFailsWith<SeerrException.Api> { client.createRequest(quota) }.message)
            assertEquals(listOf("/api/v1/request", "/api/v1/auth/me"), server.requests.map { it.path })
            assertEquals(SeerrPermission.REQUEST, client.session.permissions)
            assertEquals("old-cookie", client.session.cookie)
        }
    }

    @Test
    fun anOptionalDenialProbeThatSaysNothingUsablePreservesTheOriginalErrorAndSession() = runTest {
        val probes = listOf("expired cookie", "wrong principal", "malformed user", "server failure", "proxy", "transport failure")
        for (name in probes) {
            val server = MockServer(this) { request ->
                when (request.path) {
                    "/api/v1/request" -> json("""{"message":"Quota exceeded"}""", 403)
                    "/api/v1/auth/me" -> when (name) {
                        "expired cookie" -> sessionGone()
                        "wrong principal" -> json(user(0, id = 99))
                        "malformed user" -> json("""{"id":7}""")
                        "server failure" -> json("""{"message":"unavailable"}""", 503)
                        "proxy" -> respond("<html>login</html>", HttpStatusCode.Forbidden)
                        else -> throw IOException("probe failed")
                    }
                    else -> fail("an optional authority read never signs in ($name)")
                }
            }
            val client = seerrClient(
                server,
                session(SeerrAuthMethod.QUICK_CONNECT, secret = ""),
                onSessionInvalidated = { fail("must remain linked ($name)") },
                onSessionUpdated = { fail("inconclusive authority must not be taken ($name)") },
            )
            assertEquals("Quota exceeded", assertFailsWith<SeerrException.Api>(name) { client.createRequest(quota) }.message)
            assertEquals(listOf("/api/v1/request", "/api/v1/auth/me"), server.requests.map { it.path }, name)
            assertEquals(SeerrPermission.ADMIN, client.session.permissions, name)
            assertEquals("old-cookie", client.session.cookie, name)
        }
    }

    @Test
    fun aHandlerDenialAfterSilentReauthRefreshesAuthorityWithoutReplayingAgain() = runTest {
        var posts = 0
        var logins = 0
        var freshReads = 0
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/request" -> {
                    posts++
                    if (posts == 1) sessionGone() else json("""{"message":"Quota exceeded"}""", 403)
                }
                "/api/v1/auth/jellyfin" -> {
                    logins++
                    login()
                }
                "/api/v1/auth/me" -> if (request.cookie != cookieHeader("fresh-cookie")) {
                    sessionGone()
                } else {
                    freshReads++
                    json(user(if (freshReads == 1) SeerrPermission.REQUEST else 0))
                }
                else -> fail("unexpected ${request.path}")
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must remain linked") })
        assertEquals("Quota exceeded", assertFailsWith<SeerrException.Api> { client.createRequest(quota) }.message)
        assertEquals(2, posts)
        assertEquals(1, logins)
        assertEquals(2, freshReads)
        assertEquals(0, client.session.permissions)
        assertEquals("fresh-cookie", client.session.cookie)
    }

    @Test
    fun silentReauthNeverAdoptsADifferentPrincipalOrRetriesWithTheirCookie() = runTest {
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/auth/jellyfin" -> login("other-user-cookie")
                request.cookie == cookieHeader("other-user-cookie") -> json(user(id = 99))
                else -> sessionGone()
            }
        }
        val client = seerrClient(
            server,
            onSessionInvalidated = { fail("a different principal is no credentials rejection") },
            onSessionUpdated = { fail("must not publish another user") },
        )
        assertFailsWith<SeerrException.ReauthUnavailable> { client.getMe() }
        assertEquals(listOf("/api/v1/auth/me", "/api/v1/auth/jellyfin", "/api/v1/auth/me"), server.requests.map { it.path })
        assertEquals("old-cookie", client.session.cookie)
        assertEquals(7, client.session.userId)
        assertEquals("hunter2", client.session.secret)
    }

    @Test
    fun lateAuthorityCannotRegrantPermissionsAfterANewerDenialProbeRevokedThem() = runTest {
        val oldRead = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        var reads = 0
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/request" -> json("""{"message":"Not allowed"}""", 403)
                ++reads == 1 -> {
                    started.complete(Unit)
                    oldRead.await()
                    json(user())
                }
                else -> json(user(0))
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must stay linked") })
        val refresh = async { client.refreshUser() }
        started.await()
        assertFailsWith<SeerrException.Api> { client.createRequest(quota) }
        oldRead.complete(Unit)
        refresh.await()
        assertEquals(0, client.session.permissions)
    }

    @Test
    fun authorityForTheOldCookieCannotReplaceAuthorityFromACompletedReauth() = runTest {
        val oldRead = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        var oldReads = 0
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/auth/jellyfin" -> login()
                request.cookie == cookieHeader("fresh-cookie") -> json(user(0))
                ++oldReads == 1 -> {
                    started.complete(Unit)
                    oldRead.await()
                    json(user())
                }
                else -> sessionGone()
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must stay linked") })
        val oldRefresh = async { client.refreshUser() }
        started.await()
        client.refreshUser()
        oldRead.complete(Unit)
        oldRefresh.await()
        assertEquals("fresh-cookie", client.session.cookie)
        assertEquals(0, client.session.permissions)
    }

    @Test
    fun disposingDuringLiveTokenResolutionPreventsLoginAndSessionInvalidation() = runTest {
        val token = CompletableDeferred<String?>()
        val started = CompletableDeferred<Unit>()
        val server = MockServer(this) { sessionGone() }
        val client = seerrClient(
            server,
            session(SeerrAuthMethod.PLEX),
            plexToken = {
                started.complete(Unit)
                token.await()
            },
            onSessionInvalidated = { fail("a disposed binding must not invalidate") },
            onSessionUpdated = { fail("a disposed binding must not publish") },
        )
        val result = async { runCatching { client.getMe() } }
        started.await()
        client.dispose()
        token.complete("new-profile-token")
        assertTrue(result.await().exceptionOrNull() is IllegalStateException)
        assertEquals(1, server.requests.size)
    }

    @Test
    fun sameUserClientsDoNotShareAnotherBindingsCookieOrStoredCredentials() = runTest {
        val release = CompletableDeferred<Unit>()
        val started = listOf(CompletableDeferred<Unit>(), CompletableDeferred<Unit>())
        fun TestScope.client(index: Int) = seerrClient(
            MockServer(this) { request ->
                when {
                    request.path == "/api/v1/auth/jellyfin" -> {
                        assertEquals(JsonPrimitive("password-$index-seerr"), request.bodyJson()["password"])
                        started[index].complete(Unit)
                        release.await()
                        login("cookie-$index-seerr")
                    }
                    request.cookie == cookieHeader("cookie-$index-seerr") -> json(user())
                    else -> sessionGone()
                }
            },
            session(secret = "password-$index-seerr"),
            onSessionInvalidated = { fail("must stay linked") },
        )
        val first = client(0)
        val second = client(1)
        val reads = listOf(async { first.getMe() }, async { second.getMe() })
        started[0].await()
        runCurrent()
        release.complete(Unit)
        reads.awaitAll()
        assertEquals("cookie-0-seerr", first.session.cookie)
        assertEquals("password-0-seerr", first.session.secret)
        assertEquals("cookie-1-seerr", second.session.cookie)
        assertEquals("password-1-seerr", second.session.secret)
    }

    @Test
    fun aDisposedBindingIgnoresALateReauthSuccess() = disposedBindingIgnoresLateReauth(loginSucceeds = true)

    @Test
    fun aDisposedBindingIgnoresALateReauthRejection() = disposedBindingIgnoresLateReauth(loginSucceeds = false)

    private fun disposedBindingIgnoresLateReauth(loginSucceeds: Boolean) = runTest {
        val started = CompletableDeferred<Unit>()
        val loginAnswer = CompletableDeferred<Unit>()
        var reads = 0
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/jellyfin") {
                started.complete(Unit)
                loginAnswer.await()
                if (loginSucceeds) login() else json("""{"message":"Access denied."}""", 403)
            } else {
                reads++
                if (request.cookie == cookieHeader("fresh-cookie")) json(user()) else sessionGone()
            }
        }
        val client = seerrClient(
            server,
            onSessionInvalidated = { fail("the old binding must not invalidate") },
            onSessionUpdated = { fail("the old binding must not publish") },
        )
        val result = async { runCatching { client.getMe() } }
        started.await()
        client.dispose()
        loginAnswer.complete(Unit)
        val error = result.await().exceptionOrNull()
        if (loginSucceeds) assertTrue(error is IllegalStateException, "$error") else assertTrue(error is SeerrException.Auth, "$error")
        assertEquals("old-cookie", client.session.cookie)
        assertEquals(if (loginSucceeds) 2 else 1, reads, "no replay of the original request after disposal")
    }

    @Test
    fun anyCallAfterDisposeFails() = runTest {
        val server = MockServer(this) { json(user()) }
        val client = seerrClient(server)
        client.dispose()
        assertFailsWith<IllegalStateException> { client.getTrending() }
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun aProxy401OnALiveSessionErrorsWithoutReauthOrUnlinking() = runTest {
        // The proxy's own cookie expired, not Seerr's: a re-auth would hit the same wall and wipe a good session.
        var invalidated = false
        val server = MockServer(this) {
            respond("Unauthorized", HttpStatusCode.Unauthorized, headersOf(HttpHeaders.WWWAuthenticate, "Basic realm=\"seerr\""))
        }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.Proxy> { client.getMe() }
        assertFalse(invalidated)
        assertEquals(listOf("/api/v1/auth/me"), server.requests.map { it.path }, "no login attempt through the wall")
    }

    @Test
    fun aProxyRedirectOnALiveSessionErrorsWithoutUnlinking() = runTest {
        var invalidated = false
        val server = MockServer(this) { respond("", HttpStatusCode.Found, headersOf(HttpHeaders.Location, "https://auth.example.com/")) }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.Proxy> { client.getTrending() }
        assertFalse(invalidated)
        assertEquals(1, server.requests.size)
    }

    @Test
    fun aJson403FromAGatewayOnALiveQuickConnectSessionErrorsWithoutReauthOrUnlinking() = runTest {
        // Cloudflare Access or a gateway answering JSON is still not Seerr: neither the middleware's {status,error} nor
        // a route's {message}, so it must not even reach the /auth/me probe (a Quick Connect session would unlink).
        var invalidated = false
        val server = MockServer(this) { json("""{"success":false,"errors":[{"code":1010,"message":"Access denied"}]}""", 403) }
        val client = seerrClient(server, session(SeerrAuthMethod.QUICK_CONNECT, secret = ""), onSessionInvalidated = { invalidated = true })
        assertEquals(403, assertFailsWith<SeerrException.Proxy> { client.getTrending() }.statusCode)
        assertFalse(invalidated)
        assertEquals(listOf("/api/v1/discover/trending"), server.requests.map { it.path })
    }

    @Test
    fun aJson401FromAGatewayOnALiveSessionErrorsWithoutReauthOrUnlinking() = runTest {
        // Seerr never answers 401 on a route the client calls; Kong's {"message":"Unauthorized"} is the wall's.
        var invalidated = false
        val server = MockServer(this) { json("""{"message":"Unauthorized"}""", 401) }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.Proxy> { client.getMe() }
        assertFalse(invalidated)
        assertEquals(listOf("/api/v1/auth/me"), server.requests.map { it.path }, "no login attempt through the wall")
    }

    @Test
    fun aGatewayAnsweringTheAuthMeProbeKeepsTheSession() = runTest {
        // The request's 403 looked like Seerr's, but the probe hit a wall: nothing proved the session gone.
        var invalidated = false
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/discover/trending" -> sessionGone()
                "/api/v1/auth/me" -> json("""{"error":"unauthorized"}""", 401)
                else -> fail("no login expected: ${request.path}")
            }
        }
        val client = seerrClient(server, session(SeerrAuthMethod.QUICK_CONNECT, secret = ""), onSessionInvalidated = { invalidated = true })
        assertEquals(401, assertFailsWith<SeerrException.Proxy> { client.getTrending() }.statusCode)
        assertFalse(invalidated)
        assertEquals(listOf("/api/v1/discover/trending", "/api/v1/auth/me"), server.requests.map { it.path })
    }

    @Test
    fun aGenuineSeerr403ReauthsAndUnlinksWhenSeerrRejectsTheStoredCredentials() = runTest {
        // The password changed on the server: the session is gone and the re-login was refused, so unlinking is honest.
        var invalidated = false
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/jellyfin") json("""{"message":"Access denied."}""", 403) else sessionGone()
        }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertEquals(T.seerr.signInRejected, assertFailsWith<SeerrException.Auth> { client.getTrending() }.display)
        assertTrue(invalidated)
        assertEquals(listOf("/api/v1/discover/trending", "/api/v1/auth/me", "/api/v1/auth/jellyfin"), server.requests.map { it.path })
    }

    @Test
    fun aSessionRejectedAgainAfterASuccessfulReauthUnlinks() = runTest {
        // The read-back right after the re-login knows the new cookie; Seerr refuses it from then on.
        var invalidated = false
        var freshReads = 0
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/auth/jellyfin" -> login()
                "/api/v1/auth/me" -> if (request.cookie == cookieHeader("fresh-cookie") && ++freshReads == 1) json(user()) else sessionGone()
                else -> sessionGone()
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertEquals(T.seerr.sessionRejectedAfterReauth, assertFailsWith<SeerrException.Auth> { client.getTrending() }.display)
        assertTrue(invalidated)
        assertEquals(2, server.requests.count { it.path == "/api/v1/discover/trending" }, "exactly one replay")
    }

    @Test
    fun aGatewayAnsweringTheReloginKeepsTheSession() = runTest {
        // Seerr dropped the session, but the re-auth POST met a JSON 403 that isn't Seerr's: the credentials were never
        // judged, so they stay.
        var invalidated = false
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/jellyfin") json("""{"message":"Forbidden","request_id":"abc"}""", 403) else sessionGone()
        }
        val client = seerrClient(server, onSessionInvalidated = { invalidated = true })
        assertFailsWith<SeerrException.Proxy> { client.getMe() }
        assertFalse(invalidated)
    }

    @Test
    fun concurrentExpiriesShareOneRelogin() = runTest {
        var logins = 0
        val server = MockServer(this) { request ->
            when {
                request.path == "/api/v1/auth/jellyfin" -> {
                    logins++
                    login()
                }
                request.cookie != cookieHeader("fresh-cookie") -> sessionGone()
                request.path == "/api/v1/auth/me" -> json(user())
                else -> json("""{"page":1,"totalPages":1,"results":[]}""")
            }
        }
        val client = seerrClient(server, onSessionInvalidated = { fail("must not invalidate") })
        listOf(async { client.getTrending() }, async { client.getPopularMovies() }).awaitAll()
        assertEquals(1, logins)
    }

    @Test
    fun aReauthCompletingFromAStaleSnapshotKeepsAConcurrentlyDetectedProduct() = runTest {
        val loginStarted = CompletableDeferred<Unit>()
        val loginGate = CompletableDeferred<Unit>()
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            when (request.path) {
                // Jellyseerr always sends a numeric mediaServerType.
                "/api/v1/settings/public" -> json("""{"initialized":true,"mediaServerType":2}""")
                "/api/v1/auth/jellyfin" -> {
                    loginStarted.complete(Unit)
                    loginGate.await()
                    login()
                }
                else -> {
                    assertEquals("/api/v1/auth/me", request.path)
                    if (request.cookie != cookieHeader("fresh-cookie")) sessionGone() else json(user())
                }
            }
        }
        // A session kept before the product was recorded.
        val client = seerrClient(server, onSessionInvalidated = { fail("must not invalidate") }, onSessionUpdated = { updated = it })

        // The expiry starts a re-auth whose snapshot still says unknown.
        val me = async { client.getMe() }
        loginStarted.await()

        // While the login is parked, the settings detect the product.
        assertEquals(SeerrProduct.JELLYSEERR, client.getPublicSettings().product)
        assertEquals(SeerrProduct.JELLYSEERR, client.session.product)

        // The re-auth completes from the older snapshot: the new cookie, without losing the product.
        loginGate.complete(Unit)
        assertEquals(7, me.await().id)
        assertEquals("fresh-cookie", client.session.cookie)
        assertEquals(SeerrProduct.JELLYSEERR, client.session.product)
        assertEquals("fresh-cookie", updated?.cookie)
        assertEquals(SeerrProduct.JELLYSEERR, updated?.product, "the kept session must keep the product")
    }

    // ---- Settings, authority and parsing ----

    @Test
    fun getPublicSettingsRefreshesAndPersistsTheProductDiscriminator() = runTest {
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            assertEquals("/api/v1/settings/public", request.path)
            json("""{"initialized":true,"mediaServerType":4}""")
        }
        val client = seerrClient(server, onSessionUpdated = { updated = it })

        // A session kept before the product existed converges on the first fetch and hands the change over.
        assertEquals(SeerrProduct.JELLYSEERR, client.getPublicSettings().product)
        assertEquals(SeerrProduct.JELLYSEERR, client.session.product)
        assertEquals(SeerrProduct.JELLYSEERR, updated?.product)

        // Kept for the client's lifetime: no refetch, nothing new to keep.
        updated = null
        client.getPublicSettings()
        assertEquals(1, server.requests.size)
        assertNull(updated)
    }

    @Test
    fun getPublicSettingsSharesOneInFlightRequestAndRetriesAfterAFailure() = runTest {
        var available = false
        val server = MockServer(this) { request ->
            assertEquals("/api/v1/settings/public", request.path)
            if (available) json("""{"initialized":true,"cacheImages":true}""") else json("""{"message":"unavailable"}""", 500)
        }
        val client = seerrClient(server)

        // Every Explore row asks at once: one request answers them all, and its failure reaches each.
        val failures = List(3) { async { runCatching { client.getPublicSettings() } } }.awaitAll()
        assertEquals(1, server.requests.size)
        assertTrue(failures.all { it.exceptionOrNull() is SeerrException.Api })

        // The failure isn't kept; the success is.
        available = true
        listOf(async { client.getPublicSettings() }, async { client.getPublicSettings() }).awaitAll()
        assertEquals(2, server.requests.size)
        assertEquals("$BASE_URL/imageproxy", client.tmdbImageProxyUrl())
        assertEquals(2, server.requests.size)
    }

    @Test
    fun theImageProxyRouteFollowsTheProductAndRelease() {
        assertNull(SeerrPublicSettings(cacheImages = false, mediaServerType = 2, youtubeUrl = "").tmdbImageProxyPath)
        assertEquals("/imageproxy/tmdb", SeerrPublicSettings(cacheImages = true, mediaServerType = 2, youtubeUrl = "").tmdbImageProxyPath)
        assertEquals("/imageproxy", SeerrPublicSettings(cacheImages = true, mediaServerType = 2).tmdbImageProxyPath)
        assertEquals("/imageproxy", SeerrPublicSettings(cacheImages = true, youtubeUrl = "").tmdbImageProxyPath)
    }

    @Test
    fun refreshUserAdoptsAndPersistsAChangedPermissionMask() = runTest {
        var permissions = SeerrPermission.REQUEST
        var updated: SeerrSession? = null
        val server = MockServer(this) { request ->
            assertEquals("/api/v1/auth/me", request.path)
            json(user(permissions))
        }
        val client = seerrClient(server, onSessionUpdated = { updated = it })

        // The stored snapshot says admin; the instance now says request-only.
        client.refreshUser()
        assertEquals(SeerrPermission.REQUEST, client.session.permissions)
        assertEquals(SeerrPermission.REQUEST, updated?.permissions)
        assertEquals("hunter2", updated?.secret, "the re-packed session keeps what it signs in again with")

        // Unchanged since: nothing to keep.
        updated = null
        client.refreshUser()
        assertNull(updated)

        permissions = SeerrPermission.REQUEST or SeerrPermission.REQUEST_4K
        client.refreshUser()
        assertEquals(permissions, updated?.permissions)
    }

    @Test
    fun getPublicSettingsWithoutMediaServerTypeMarksTheSessionOverseerr() = runTest {
        var updated: SeerrSession? = null
        val client = seerrClient(MockServer(this) { json("""{"initialized":true}""") }, onSessionUpdated = { updated = it })
        assertEquals(SeerrProduct.OVERSEERR, client.getPublicSettings().product)
        assertEquals(SeerrProduct.OVERSEERR, updated?.product)
    }

    @Test
    fun popularMoviesCoercesAMissingMediaTypeToMovie() = runTest {
        val client = seerrClient(
            MockServer(this) { request ->
                assertEquals("/api/v1/discover/movies", request.path)
                json("""{"page":1,"totalPages":1,"totalResults":37,"results":[{"id":4,"title":"Dune","releaseDate":"2021-09-15"}]}""")
            },
        )
        val page = client.getPopularMovies()
        assertTrue(page.items.single().isMovie)
        assertEquals(2021, page.items.single().year)
        assertFalse(page.hasMore)
        assertEquals(37, page.totalResults)
    }

    @Test
    fun mixedResultsLeaveOutPeople() = runTest {
        val client = seerrClient(
            MockServer(this) {
                json(
                    """{"page":1,"totalPages":3,"results":[{"id":1,"mediaType":"movie","title":"A"},
                    {"id":2,"mediaType":"person","name":"Someone"},{"id":3,"mediaType":"tv","name":"","originalName":"B"}]}""",
                )
            },
        )
        val page = client.search("a b")
        assertEquals(listOf(1, 3), page.items.map { it.id })
        assertEquals("B", page.items.last().displayTitle, "an untranslated title falls back to the original")
        assertTrue(page.hasMore)
    }

    @Test
    fun addsTheCurrentLocaleToTheCatalogGetsSeerrLocalizes() = runTest {
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/movie/4" || request.path == "/api/v1/tv/4") json("{}") else json("""{"page":1,"totalPages":1,"results":[]}""")
        }
        val client = seerrClient(server, language = { "zh-TW" })

        client.getUpcomingMovies()
        client.getUpcomingTv()
        client.getTrending()
        client.search("dune")
        client.getMovieRecommendations(4)
        client.getTvRecommendations(4)
        client.getMovie(4)
        client.getTv(4)

        assertEquals(
            listOf(
                "/api/v1/discover/movies/upcoming",
                "/api/v1/discover/tv/upcoming",
                "/api/v1/discover/trending",
                "/api/v1/search",
                "/api/v1/movie/4/recommendations",
                "/api/v1/tv/4/recommendations",
                "/api/v1/movie/4",
                "/api/v1/tv/4",
            ),
            server.requests.map { it.path },
        )
        for (request in server.requests) assertEquals("zh-TW", request.url.parameters["language"], request.path)
    }

    @Test
    fun popularRowsOmitLanguageSoSeerrCannotFilterThemByOriginalLanguage() = runTest {
        // Seerr binds these routes' `language` to TMDB's with_original_language: the app's language would keep only
        // titles originally made in it.
        val server = MockServer(this) { json("""{"page":1,"totalPages":1,"results":[]}""") }
        val client = seerrClient(server)
        client.getPopularMovies(page = 2)
        client.getPopularTv()
        assertEquals(listOf("/api/v1/discover/movies", "/api/v1/discover/tv"), server.requests.map { it.path })
        for (request in server.requests) assertNull(request.url.parameters["language"], request.path)
        assertEquals("2", server.requests.first().url.parameters["page"], "paging survives the locale opt-out")
    }

    @Test
    fun createRequestPostsTheMoviePayloadWithoutSeasons() = runTest {
        val server = MockServer(this) { request ->
            assertEquals("POST", request.method.value)
            assertEquals("/api/v1/request", request.path)
            json("""{"id":10,"status":1}""", 201)
        }
        val created = seerrClient(server).createRequest(SeerrRequestPayload(mediaType = "movie", mediaId = 603))
        assertEquals(jsonObject("""{"mediaType":"movie","mediaId":603,"is4k":false}"""), server.requests.single().bodyJson())
        assertEquals(SeerrRequestStatus.PENDING, created.status)
    }

    @Test
    fun createRequestPostsTvSeasonsDefaultingToAll() = runTest {
        val server = MockServer(this) { json("""{"id":11,"status":2}""") }
        val client = seerrClient(server)
        client.createRequest(SeerrRequestPayload(mediaType = "tv", mediaId = 1396, seasons = listOf(1, 2)))
        client.createRequest(SeerrRequestPayload(mediaType = "tv", mediaId = 1396, is4k = true, serverId = 1, profileId = 6))
        assertEquals(jsonObject("""{"mediaType":"tv","mediaId":1396,"seasons":[1,2],"is4k":false}"""), server.requests[0].bodyJson())
        assertEquals(
            jsonObject("""{"mediaType":"tv","mediaId":1396,"seasons":"all","is4k":true,"serverId":1,"profileId":6}"""),
            server.requests[1].bodyJson(),
        )
    }

    @Test
    fun createRequestPostsTagsOnlyWhenSetKeepingAnEmptyListAsARealOverride() = runTest {
        val server = MockServer(this) { json("""{"id":11,"status":2}""") }
        val client = seerrClient(server)
        client.createRequest(SeerrRequestPayload(mediaType = "tv", mediaId = 1396))
        client.createRequest(SeerrRequestPayload(mediaType = "tv", mediaId = 1396, tags = emptyList()))
        client.createRequest(SeerrRequestPayload(mediaType = "tv", mediaId = 1396, tags = listOf(5, 9), rootFolder = "/tv", languageProfileId = 2))
        assertFalse("tags" in server.requests[0].bodyJson())
        assertEquals(jsonObject("""{"tags":[]}""")["tags"], server.requests[1].bodyJson()["tags"])
        assertEquals(
            jsonObject("""{"mediaType":"tv","mediaId":1396,"seasons":"all","is4k":false,"rootFolder":"/tv","languageProfileId":2,"tags":[5,9]}"""),
            server.requests[2].bodyJson(),
        )
    }

    @Test
    fun serviceListsComeFromTheirArr() = runTest {
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/service/radarr" -> json("""[{"id":0,"name":"Radarr","is4k":false,"isDefault":true,"activeProfileId":4,"activeDirectory":"/movies"},"junk"]""")
                else -> json("""[{"id":1,"name":"Sonarr 4K","is4k":true}]""")
            }
        }
        val client = seerrClient(server)
        assertEquals(
            listOf(SeerrServiceInstance(id = 0, name = "Radarr", isDefault = true, activeDirectory = "/movies", activeProfileId = 4)),
            client.getRadarrServices(),
        )
        assertEquals(listOf(SeerrServiceInstance(id = 1, name = "Sonarr 4K", is4k = true)), client.getSonarrServices())
        assertEquals(listOf("/api/v1/service/radarr", "/api/v1/service/sonarr"), server.requests.map { it.path })
    }

    @Test
    fun getSonarrServiceParsesTheAnimeDefaultsAndTagOptions() = runTest {
        val server = MockServer(this) {
            json(
                """{"server":{"id":0,"name":"Sonarr","is4k":false,"isDefault":true,"activeProfileId":1,"activeDirectory":"/tv",
                "activeAnimeProfileId":2,"activeAnimeDirectory":"/anime","activeAnimeLanguageProfileId":3,"activeTags":[7],
                "activeAnimeTags":[5,6]},"profiles":[],"rootFolders":[],"languageProfiles":null,"tags":[{"id":5,"label":"anime"}]}""",
            )
        }
        val detail = seerrClient(server).getSonarrService(0)
        assertEquals("/api/v1/service/sonarr/0", server.requests.single().path)
        val instance = detail.server!!
        assertEquals(2, instance.activeAnimeProfileId)
        assertEquals("/anime", instance.activeAnimeDirectory)
        assertEquals(3, instance.activeAnimeLanguageProfileId)
        assertEquals(listOf(7), instance.activeTags)
        assertEquals(listOf(5, 6), instance.activeAnimeTags)
        assertEquals("anime", detail.tags?.single()?.label)
        assertNull(detail.languageProfiles)
        assertEquals(emptyList(), detail.profiles)
    }

    @Test
    fun apiErrorsCarryTheServerMessage() = runTest {
        val client = seerrClient(
            MockServer(this) { request ->
                if (request.path == "/api/v1/auth/me") json(user()) else json("""{"message":"Request quota exceeded"}""", 403)
            },
        )
        assertEquals("Request quota exceeded", assertFailsWith<SeerrException.Api> { client.createRequest(quota) }.message)
    }

    @Test
    fun theDetailRoutesParseTheTitleAndItsAnimeKeyword() = runTest {
        val server = MockServer(this) {
            json(
                """{"id":4,"name":"","originalName":"進撃の巨人","keywords":[{"id":210024,"name":"anime"}],
                "seasons":[{"seasonNumber":0,"episodeCount":3},{"seasonNumber":1,"name":"Season 1","episodeCount":25}],
                "mediaInfo":{"status":7,"seasons":[{"seasonNumber":1,"status":5}],"requests":[{"id":3,"status":4,"is4k":false,"seasons":[{"seasonNumber":1}]}]}}""",
            )
        }
        val detail = seerrClient(server, session(product = SeerrProduct.JELLYSEERR)).getTv(4)
        assertEquals("進撃の巨人", detail.displayTitle)
        assertTrue(detail.isAnime)
        assertEquals(listOf(0, 1), detail.seasons?.map { it.seasonNumber })
        val info = detail.mediaInfo!!
        assertEquals(SeerrMediaStatus.DELETED, info.status(SeerrProduct.JELLYSEERR))
        assertEquals(SeerrMediaStatus.AVAILABLE, info.seasons!!.single().status(SeerrProduct.JELLYSEERR))
        assertEquals(SeerrRequestStatus.FAILED, info.requests!!.single().status)
        assertEquals(listOf(1), info.requests!!.single().seasons?.map { it.seasonNumber })
    }

    @Test
    fun thePersonRoutesParseThePersonAndTheirMoviesAndShowsInTheAppLanguage() = runTest {
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/person/31" -> json(
                    """{"id":31,"name":"Tom Hanks","biography":"An actor.","birthday":"1956-07-09","deathday":null,
                    "placeOfBirth":"Concord, California, USA","knownForDepartment":"Acting","profilePath":"/hanks.jpg"}""",
                )
                "/api/v1/person/31/combined_credits" -> json(
                    """{"id":31,"cast":[
                    {"id":13,"mediaType":"movie","title":"Forrest Gump","releaseDate":"1994-07-06","posterPath":"/fg.jpg",
                     "character":"Forrest Gump","mediaInfo":{"status":5}},
                    {"id":4,"mediaType":"person","name":"Someone"},
                    {"mediaType":"tv","name":"No id"},
                    {"id":2,"mediaType":"tv","name":"Band of Brothers","firstAirDate":"2001-09-09","character":"Narrator"}],
                    "crew":[{"id":2,"mediaType":"tv","name":"Band of Brothers","job":"Executive Producer"}]}""",
                )
                else -> fail("unexpected request ${request.url}")
            }
        }
        val client = seerrClient(server, language = { "de" })

        assertEquals(
            SeerrPerson(
                id = 31,
                name = "Tom Hanks",
                biography = "An actor.",
                birthday = "1956-07-09",
                placeOfBirth = "Concord, California, USA",
                knownForDepartment = "Acting",
                profilePath = "/hanks.jpg",
            ),
            client.getPerson(31),
        )
        val credits = client.getPersonCombinedCredits(31)
        assertEquals(listOf(13 to "Forrest Gump", 2 to "Narrator"), credits.cast.map { it.media.id to it.role })
        assertEquals("Forrest Gump", credits.cast.first().media.displayTitle)
        assertEquals(1994, credits.cast.first().media.year)
        assertEquals(SeerrMediaStatus.AVAILABLE, credits.cast.first().media.mediaInfo?.status(SeerrProduct.JELLYSEERR))
        assertFalse(credits.cast.last().media.isMovie)
        assertEquals(listOf(2 to "Executive Producer"), credits.crew.map { it.media.id to it.role })
        for (request in server.requests) assertEquals("de", request.url.parameters["language"], request.path)
    }
}
