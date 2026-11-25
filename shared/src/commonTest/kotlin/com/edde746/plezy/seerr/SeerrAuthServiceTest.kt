package com.edde746.plezy.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.log.Redactor
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException

class SeerrAuthServiceTest {
    // ---- Probe ----

    @Test
    fun probeRejectsAnUninitializedInstance() = runTest {
        val auth = authService(MockServer(this) { json("""{"initialized":false}""") })
        assertFailsWith<SeerrException.Url> { auth.probe(BASE_URL) }
    }

    @Test
    fun probeDerivesTheProductFromMediaServerTypePresenceNotItsValue() = runTest {
        // Jellyseerr and Seerr always send a numeric mediaServerType: 4 is NOT_CONFIGURED, and still tells them apart.
        val jellyseerr = authService(MockServer(this) { json("""{"initialized":true,"mediaServerType":4}""") })
        assertEquals(SeerrProduct.JELLYSEERR, jellyseerr.probe(BASE_URL).product)

        // Overseerr's public settings have no mediaServerType at all.
        val overseerr = authService(MockServer(this) { json("""{"initialized":true}""") })
        assertEquals(SeerrProduct.OVERSEERR, overseerr.probe(BASE_URL).product)
    }

    @Test
    fun probeReadsThePublicSettingsWithTheirDefaults() = runTest {
        val settings = authService(MockServer(this) { json("""{"initialized":true,"applicationTitle":""}""") }).probe(BASE_URL)
        assertEquals(
            SeerrPublicSettings(initialized = true, applicationTitle = ""),
            settings,
        )
        assertEquals("Seerr", settings.instanceLabel)
        assertTrue(settings.localLogin && settings.mediaServerLogin && settings.partialRequestsEnabled)
        val titled = authService(MockServer(this) { json("""{"initialized":true,"applicationTitle":"Requests"}""") }).probe(BASE_URL)
        assertEquals("Requests", titled.instanceLabel)
    }

    @Test
    fun aForwardAuthRedirectOnProbeIsDiagnosedAsAnAuthProxyNotAMissingInstance() = runTest {
        // Authelia, Authentik and Cloudflare Access bounce unauthenticated requests to their login page; following the
        // redirect would answer an HTML 200 and the misleading "No Seerr instance at … (HTTP 200)".
        val server = MockServer(this) { request ->
            if (request.url.host == "auth.example.com") json("<html>login</html>")
            else respond("", HttpStatusCode.Found, headersOf(HttpHeaders.Location, "https://auth.example.com/?rd=$BASE_URL"))
        }
        val error = assertFailsWith<SeerrException.Url> { authService(server).probe(BASE_URL) }
        assertEquals(T.seerr.behindAuthProxy, error.display)
        assertEquals(302, error.statusCode)
        assertEquals(1, server.requests.size, "a followed redirect hides the proxy behind an HTML 200")
    }

    @Test
    fun anHttpBasicChallengeOnProbeIsDiagnosedAsAnAuthProxy() = runTest {
        val server = MockServer(this) {
            respond("Unauthorized", HttpStatusCode.Unauthorized, headersOf(HttpHeaders.WWWAuthenticate, "Basic realm=\"seerr\""))
        }
        assertEquals(T.seerr.behindAuthProxy, assertFailsWith<SeerrException.Url> { authService(server).probe(BASE_URL) }.display)
    }

    @Test
    fun aJson401OnProbeIsAnAuthWallBecauseSeerrNeverGuardsPublicSettings() = runTest {
        val error = assertFailsWith<SeerrException.Url> {
            authService(MockServer(this) { json("""{"message":"Unauthorized"}""", 401) }).probe(BASE_URL)
        }
        assertEquals(T.seerr.behindAuthProxy, error.display)
        assertEquals(401, error.statusCode)
    }

    @Test
    fun probeNamesAServerThatIsNoSeerrAndOneThatCannotBeReached() = runTest {
        val notSeerr = assertFailsWith<SeerrException.Url> { authService(MockServer(this) { json("<html></html>") }).probe(BASE_URL) }
        assertEquals(T.seerr.noInstanceAtUrl(url = BASE_URL, status = "200"), notSeerr.display)
        assertEquals(200, notSeerr.statusCode)

        val unreachable = assertFailsWith<SeerrException.Url> {
            authService(MockServer(this) { throw IOException("connection refused") }).probe(BASE_URL)
        }
        assertTrue(unreachable.message.startsWith("Could not reach $BASE_URL: ") && "connection refused" in unreachable.message)
        assertEquals(T.addServer.noReachableServer(product = "Seerr"), unreachable.display)
        assertNull(unreachable.statusCode)
    }

    // ---- Candidates and the probe race ----

    @Test
    fun triesTlsFirstThenPlainHttpAndTheDefaultInstallPort() {
        assertEquals(
            listOf("https://seerr.example.com", "http://seerr.example.com", "http://seerr.example.com:5055"),
            SeerrAuthService.expandUrlCandidates("seerr.example.com"),
        )
    }

    @Test
    fun anExplicitHttpAddressIsProbedAsTypedWithoutTryingHttps() = runTest {
        val server = MockServer(this) { json("""{"initialized":true,"mediaServerType":2}""") }
        assertEquals("http://seerr.lan:5055", authService(server).probeFirstReachable("http://seerr.lan:5055").baseUrl)
        assertEquals(listOf("http://seerr.lan:5055/api/v1/settings/public"), server.requests.map { it.url.toString() })
    }

    @Test
    fun anHttpsServerThatIsNoSeerrIsReportedInsteadOfFallingBackToPlainHttp() = runTest {
        // HTTPS connected: plain HTTP is used only when the user types it.
        val auth = authService(
            MockServer(this) { request ->
                if (request.url.protocol.name == "https") json("<html></html>") else json("""{"initialized":true,"mediaServerType":2}""")
            },
        )
        val error = assertFailsWith<SeerrException.Url> { auth.probeFirstReachable("seerr.example.com") }
        assertEquals(T.seerr.noInstanceAtUrl(url = BASE_URL, status = "200"), error.display)
    }

    @Test
    fun keepsAnExplicitSchemeAndATypedPortAsTheOnlyCandidate() {
        assertEquals(listOf("http://192.168.1.5:5055"), SeerrAuthService.expandUrlCandidates("http://192.168.1.5:5055"))
        assertEquals(listOf("https://192.168.1.5:5055", "http://192.168.1.5:5055"), SeerrAuthService.expandUrlCandidates("192.168.1.5:5055"))
    }

    @Test
    fun fallsBackToPlainHttpOnTheDefaultPortWhenNothingElseAnswers() = runTest {
        val auth = authService(
            MockServer(this) { request ->
                if (request.url.port != 5055) throw IOException("connection refused")
                json("""{"initialized":true,"mediaServerType":2}""")
            },
        )
        val result = auth.probeFirstReachable("seerr.example.com")
        assertEquals("http://seerr.example.com:5055", result.baseUrl)
        assertEquals(SeerrProduct.JELLYSEERR, result.settings.product)
    }

    @Test
    fun prefersASlowTlsInstanceOverAFastPlaintextOne() = runTest {
        // The sign-in that follows posts a password to the winner: plaintext never wins while TLS still can.
        val auth = authService(
            MockServer(this) { request ->
                if (request.url.protocol.name == "https") delay(120.milliseconds)
                json("""{"initialized":true,"mediaServerType":2}""")
            },
        )
        assertEquals(BASE_URL, auth.probeFirstReachable("seerr.example.com").baseUrl)
    }

    @Test
    fun reportsTheInstanceItReachedInsteadOfTheTlsTransportFailure() = runTest {
        // An uninitialized instance on plain http is the actionable answer, not "could not reach https://…".
        val auth = authService(
            MockServer(this) { request ->
                if (request.url.protocol.name == "https") throw IOException("connection refused")
                json("""{"initialized":false,"mediaServerType":4}""")
            },
        )
        val error = assertFailsWith<SeerrException.Url> { auth.probeFirstReachable("seerr.example.com") }
        assertTrue("first-run setup" in error.message)
        assertEquals(200, error.statusCode)
    }

    @Test
    fun namesThePrimaryCandidateWhenNothingAnsweredAtAll() = runTest {
        val auth = authService(MockServer(this) { throw IOException("connection refused") })
        val error = assertFailsWith<SeerrException.Url> { auth.probeFirstReachable("seerr.example.com") }
        assertTrue(BASE_URL in error.message)
        assertNull(error.statusCode)
    }

    @Test
    fun rejectsInputWithNoHostInsteadOfProbingAHostlessUrl() = runTest {
        val server = MockServer(this) { json("""{"initialized":true}""") }
        val error = assertFailsWith<SeerrException.Url> { authService(server).probeFirstReachable("/seerr") }
        assertEquals(T.seerr.invalidUrl, error.display)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun theConnectFlowKeepsTheSessionNamedAndTypedByTheInstanceThatAnswered() = runTest {
        val auth = authService(MockServer(this) { json("""{"initialized":true,"applicationTitle":"Requests","mediaServerType":2}""") })
        val instance = auth.probeFirstReachable("https://seerr.example.com/")
        val kept = instance.complete(session())
        assertEquals("Requests", kept.instanceLabel)
        assertEquals(SeerrProduct.JELLYSEERR, kept.product)
        assertEquals(session().copy(instanceLabel = "Requests", product = SeerrProduct.JELLYSEERR), kept)
    }

    // ---- Sign-in ----

    @Test
    fun jellyfinSignInPostsServerTypeAndPacksTheSession() = runTest {
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/jellyfin") {
                login()
            } else {
                assertEquals("/api/v1/auth/me", request.path)
                assertEquals(cookieHeader("fresh-cookie"), request.cookie)
                json(user())
            }
        }
        val session = authService(server).signInWithJellyfin("$BASE_URL/", "alice", "hunter2")
        assertEquals(jsonObject("""{"username":"alice","password":"hunter2","serverType":2}"""), server.requests.first().bodyJson())
        assertEquals(SeerrAuthMethod.JELLYFIN, session.method)
        assertEquals(BASE_URL, session.baseUrl)
        assertEquals("fresh-cookie", session.cookie)
        assertEquals(7, session.userId)
        assertEquals("hunter2", session.secret)
        assertEquals("Alice", session.displayName)
        assertEquals(FixedClock.now().epochSeconds, session.createdAt)
        assertNull(server.requests.first().cookie, "a login sends no cookie")

        val emby = authService(MockServer(this) { if (it.path == "/api/v1/auth/jellyfin") login() else json(user()) })
        assertEquals(SeerrAuthMethod.EMBY, emby.signInWithJellyfin(BASE_URL, "alice", "hunter2", emby = true).method)
    }

    @Test
    fun plexSignInPostsTheTokenAndStoresNoSecret() = runTest {
        val server = MockServer(this) { if (it.path == "/api/v1/auth/plex") login() else json(user()) }
        val session = authService(server).signInWithPlex(BASE_URL, "plex-token")
        assertEquals(jsonObject("""{"authToken":"plex-token"}"""), server.requests.first().bodyJson())
        assertEquals(SeerrAuthMethod.PLEX, session.method)
        assertEquals("", session.secret)
        assertEquals("", session.identifier)
    }

    @Test
    fun signInTakesTheUserFromAuthMeNotFromTheLoginBody() = runTest {
        // POST /auth/local returns the user it loaded to check the password: permissions 0 and the email as name.
        val server = MockServer(this) { request ->
            if (request.path == "/api/v1/auth/local") {
                login(body = """{"id":7,"displayName":"a@b.c","permissions":0,"warnings":[]}""")
            } else {
                assertEquals(cookieHeader("fresh-cookie"), request.cookie)
                json(user(SeerrPermission.REQUEST))
            }
        }
        val session = authService(server).signInWithLocal(BASE_URL, "a@b.c", "hunter2")
        assertEquals(listOf("/api/v1/auth/local", "/api/v1/auth/me"), server.requests.map { it.path })
        assertEquals(jsonObject("""{"email":"a@b.c","password":"hunter2"}"""), server.requests.first().bodyJson())
        assertEquals(SeerrAuthMethod.LOCAL, session.method)
        assertEquals(SeerrPermission.REQUEST, session.permissions)
        assertEquals("Alice", session.displayName)
    }

    @Test
    fun theDisplayNameFallsBackToTheIdentifier() = runTest {
        val server = MockServer(this) { if (it.path == "/api/v1/auth/local") login() else json("""{"id":7,"permissions":32}""") }
        assertEquals("a@b.c", authService(server).signInWithLocal(BASE_URL, "a@b.c", "hunter2").displayName)
    }

    @Test
    fun anAuthMeBodyWithoutAPermissionMaskIsASignInFailureNotACrash() = runTest {
        val server = MockServer(this) { if (it.path == "/api/v1/auth/local") login(body = "{}") else json("""{"id":7,"displayName":"Alice"}""") }
        val error = assertFailsWith<SeerrException.Auth> { authService(server).signInWithLocal(BASE_URL, "a@b.c", "x") }
        assertEquals(T.seerr.noUserInformation, error.display)
    }

    @Test
    fun aLoginWithoutASessionCookieOrWhoseCookieIsRefusedFails() = runTest {
        val noCookie = authService(MockServer(this) { json(user()) })
        assertEquals(T.seerr.noSessionCookie, assertFailsWith<SeerrException.Auth> { noCookie.signInWithLocal(BASE_URL, "a@b.c", "x") }.display)

        val refused = authService(MockServer(this) { if (it.path == "/api/v1/auth/local") login() else sessionGone() })
        val error = assertFailsWith<SeerrException.Auth> { refused.signInWithLocal(BASE_URL, "a@b.c", "x") }
        assertEquals(T.seerr.freshCookieRejected, error.display)
        assertEquals(403, error.statusCode)
    }

    @Test
    fun rejectedCredentialsSurfaceAsAuthExceptions() = runTest {
        // Login routes reject through Seerr's error handler: 403 {message}. Only Jellyfin logins forward Jellyfin's
        // 401, with INVALID_CREDENTIALS as the message.
        val local = authService(MockServer(this) { json("""{"message":"Access denied."}""", 403) })
        val localError = assertFailsWith<SeerrException.Auth> { local.signInWithLocal(BASE_URL, "a@b.c", "x") }
        assertEquals("Access denied.", localError.message)
        assertEquals(T.seerr.signInRejected, localError.display)

        val jellyfin = authService(MockServer(this) { json("""{"message":"INVALID_CREDENTIALS"}""", 401) })
        assertEquals(401, assertFailsWith<SeerrException.Auth> { jellyfin.signInWithJellyfin(BASE_URL, "alice", "x") }.statusCode)
    }

    @Test
    fun aJson401FromAGatewayOnSignInIsAProxyFailureNotACredentialsRejection() = runTest {
        // Seerr never answers a local login with 401; a JSON body doesn't make the gateway's answer Seerr's.
        val auth = authService(MockServer(this) { json("""{"message":"Unauthorized"}""", 401) })
        assertEquals(401, assertFailsWith<SeerrException.Proxy> { auth.signInWithLocal(BASE_URL, "a@b.c", "x") }.statusCode)
    }

    @Test
    fun aProxyWallOnSignInIsAProxyFailureNotACredentialsRejection() = runTest {
        val auth = authService(MockServer(this) { respond("<html>login</html>", HttpStatusCode.Forbidden) })
        assertEquals(403, assertFailsWith<SeerrException.Proxy> { auth.signInWithLocal(BASE_URL, "a@b.c", "x") }.statusCode)
    }

    @Test
    fun signOutPostsLogoutWithTheCookieAndSwallowsItsFailure() = runTest {
        val server = MockServer(this) { throw IOException("offline") }
        authService(server).signOut(session())
        assertEquals("/api/v1/auth/logout", server.requests.single().path)
        assertEquals(cookieHeader("old-cookie"), server.requests.single().cookie)
    }

    // ---- Re-auth ----

    @Test
    fun aQuickConnectSessionHasNoSilentReauth() = runTest {
        val server = MockServer(this) { json("{}") }
        val error = assertFailsWith<SeerrException.Auth> { authService(server).reauth(session(SeerrAuthMethod.QUICK_CONNECT, secret = "")) }
        assertEquals(T.seerr.noStoredCredentials, error.display)
        assertTrue(server.requests.isEmpty())
    }

    @Test
    fun aPlexReauthWithoutATokenIsUnavailableNotARejection() = runTest {
        val server = MockServer(this) { json("{}") }
        val error = assertFailsWith<SeerrException.ReauthUnavailable> { authService(server).reauth(session(SeerrAuthMethod.PLEX, secret = ""), plexToken = "") }
        assertEquals(T.seerr.noPlexTokenForReauth, error.display)
        assertTrue(server.requests.isEmpty())
    }

    // ---- Quick Connect ----

    @Test
    fun initiatePostsUnauthenticatedAndSurfacesTheCodeAndSecret() = runTest {
        val server = MockServer(this) { json("""{"code":"ABC123","secret":"qc-secret-one"}""") }
        val initiation = authService(server).initiateQuickConnect(BASE_URL)
        assertEquals("ABC123", initiation.code)
        assertEquals("qc-secret-one", initiation.secret)
        val request = server.requests.single()
        assertEquals("POST", request.method.value)
        assertEquals("/api/v1/auth/jellyfin/quickconnect/initiate", request.path)
        assertNull(request.cookie)
        assertEquals("check …", Redactor.redact("check qc-secret-one"))
    }

    @Test
    fun initiateNamesTheMissingFeatureWhenTheInstancePredatesTheRoutes() = runTest {
        val auth = authService(MockServer(this) { json("""{"message":"Not Found"}""", 404) })
        val error = assertFailsWith<SeerrException.Auth> { auth.initiateQuickConnect(BASE_URL) }
        assertEquals(404, error.statusCode)
        assertEquals(T.seerr.quickConnectUnsupported, error.display)
    }

    @Test
    fun initiateReportsTheInstancesRefusalAndAnAnswerWithoutCodeOrSecret() = runTest {
        val refused = authService(MockServer(this) { json("""{"message":"Quick Connect is disabled"}""", 400) })
        assertEquals(
            T.addServer.quickConnectFailed(error = "Quick Connect is disabled"),
            assertFailsWith<SeerrException.Auth> { refused.initiateQuickConnect(BASE_URL) }.display,
        )
        val incomplete = authService(MockServer(this) { json("""{"code":"ABC123","secret":""}""") })
        assertEquals(
            T.addServer.quickConnectMissingFields,
            assertFailsWith<SeerrException.Auth> { incomplete.initiateQuickConnect(BASE_URL) }.display,
        )
    }

    @Test
    fun signInPollsTheSecretUntilApprovedThenExchangesItForASession() = runTest {
        var checks = 0
        val server = MockServer(this) { request ->
            when (request.path) {
                "/api/v1/auth/jellyfin/quickconnect/check" -> {
                    assertEquals("qc-secret-one", request.url.parameters["secret"])
                    checks++
                    when (checks) {
                        1 -> throw IOException("blip")
                        2 -> json("""{"authenticated":false}""")
                        else -> json("""{"authenticated":true}""")
                    }
                }
                "/api/v1/auth/jellyfin/quickconnect/authenticate" -> {
                    assertEquals(jsonObject("""{"secret":"qc-secret-one"}"""), request.bodyJson())
                    login()
                }
                else -> {
                    assertEquals("/api/v1/auth/me", request.path)
                    json(user())
                }
            }
        }
        val started = testScheduler.currentTime
        val session = authService(server).signInWithQuickConnect("$BASE_URL/", "qc-secret-one")!!
        assertEquals(SeerrAuthMethod.QUICK_CONNECT, session.method)
        assertEquals("fresh-cookie", session.cookie)
        assertEquals("", session.identifier)
        assertEquals("", session.secret)
        assertEquals("Alice", session.displayName)
        assertEquals(
            List(3) { "/api/v1/auth/jellyfin/quickconnect/check" } +
                listOf("/api/v1/auth/jellyfin/quickconnect/authenticate", "/api/v1/auth/me"),
            server.requests.map { it.path },
        )
        // A blip keeps polling, every 2 s.
        assertEquals(4_000L, testScheduler.currentTime - started)
    }

    @Test
    fun signInStopsWithoutASessionWhenTheSecretExpiresMidPoll() = runTest {
        val server = MockServer(this) { json("""{"message":"Invalid Quick Connect secret."}""", 404) }
        assertNull(authService(server).signInWithQuickConnect(BASE_URL, "qc-secret-one"))
        assertEquals(listOf("/api/v1/auth/jellyfin/quickconnect/check"), server.requests.map { it.path })
    }

    @Test
    fun signInStopsWithoutASessionWhenTheWindowPasses() = runTest {
        val server = MockServer(this) { json("""{"authenticated":false}""") }
        val started = testScheduler.currentTime
        assertNull(authService(server).signInWithQuickConnect(BASE_URL, "qc-secret-one"))
        assertEquals(5 * 60_000L, testScheduler.currentTime - started)
        assertTrue(server.requests.none { it.path.endsWith("/authenticate") })
    }

    @Test
    fun aRejectedPollIsASignInFailure() = runTest {
        val server = MockServer(this) { json("""{"message":"Quick Connect is disabled"}""", 403) }
        val error = assertFailsWith<SeerrException.Auth> { authService(server).signInWithQuickConnect(BASE_URL, "qc-secret-one") }
        assertEquals(T.addServer.quickConnectPollRejected, error.display)
    }

    @Test
    fun signInStopsWithoutExchangingOnceCancelled() = runTest {
        val server = MockServer(this) { json("""{"authenticated":false}""") }
        val signIn = async(start = CoroutineStart.UNDISPATCHED) { authService(server).signInWithQuickConnect(BASE_URL, "qc-secret-one") }
        runCurrent()
        assertEquals(1, server.requests.size)
        signIn.cancel()
        testScheduler.advanceUntilIdle()
        assertTrue(signIn.isCancelled)
        assertEquals(listOf("/api/v1/auth/jellyfin/quickconnect/check"), server.requests.map { it.path })
    }
}
