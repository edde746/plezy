package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.seerr.FixedClock
import com.edde746.plezy.seerr.SeerrAccounts
import com.edde746.plezy.seerr.SeerrAuthMethod
import com.edde746.plezy.seerr.SeerrMediaServerType
import com.edde746.plezy.seerr.bodyJson
import com.edde746.plezy.seerr.cookie
import com.edde746.plezy.seerr.cookieHeader
import com.edde746.plezy.seerr.json
import com.edde746.plezy.seerr.login
import com.edde746.plezy.seerr.path
import com.edde746.plezy.seerr.session
import com.edde746.plezy.seerr.user
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import kotlinx.io.IOException
import kotlinx.serialization.json.JsonPrimitive

class SeerrConnectStoreTest {
    /**
     * The connect screen over an account bound to a profile without a session, with [plexToken] as the profile's Plex
     * token; its traffic reaches [handler].
     */
    private class Connect(
        scope: TestScope,
        plexToken: String? = null,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) {
        val server = MockServer(scope, handler)
        val accounts = SeerrAccounts(
            http = server.http,
            secrets = MemorySecretStore(),
            scope = scope.backgroundScope,
            plexToken = { plexToken },
            language = { "en" },
            clock = FixedClock,
            dispatcher = StandardTestDispatcher(scope.testScheduler),
        )
        val store = SeerrConnectStore(accounts, scope.backgroundScope)

        /** The HTTP client finishes answers off the test scheduler: wait on the state, not on virtual time. */
        suspend fun until(predicate: (SeerrConnectUiState) -> Boolean): SeerrConnectUiState = store.state.first(predicate)

        suspend fun submitUrl(input: String): SeerrConnectUiState {
            accounts.onActiveProfileChanged("profile-1")
            store.setUrl(input)
            store.probe()
            return until { !it.busy }
        }
    }

    private val SeerrConnectUiState.signIn: SeerrConnectStep.SignIn get() = step as SeerrConnectStep.SignIn

    private fun settings(mediaServerType: Int = SeerrMediaServerType.JELLYFIN, localLogin: Boolean = false) =
        """{"initialized":true,"applicationTitle":"Requests","localLogin":$localLogin,"mediaServerLogin":true,"mediaServerType":$mediaServerType}"""

    /** A Seerr answering only on plain HTTP at its default port, the LAN setup a https-only form missed. */
    private fun TestScope.plainHttpLanInstance(mediaServerType: Int = SeerrMediaServerType.JELLYFIN, localLogin: Boolean = false) =
        Connect(this) { request ->
            if (request.url.protocol.name != "http" || request.url.port != 5055) throw IOException("connection refused")
            when (request.path) {
                "/api/v1/settings/public" -> json(settings(mediaServerType, localLogin))
                "/api/v1/auth/jellyfin" -> login()
                "/api/v1/auth/me" -> json(user())
                else -> throw IOException("unexpected ${request.path}")
            }
        }

    /** An instance with the Quick Connect routes: [approved] answers the poll, [initiateStatus] 404 lacks the routes. */
    private fun TestScope.quickConnectInstance(approved: Boolean = true, initiateStatus: Int = 200) = Connect(this) { request ->
        when (request.path) {
            "/api/v1/settings/public" -> json(settings())
            "/api/v1/auth/jellyfin/quickconnect/initiate" ->
                // A secret no other test uses: initiation registers it with the process-wide log redactor.
                if (initiateStatus != 200) json("""{"message":"Not Found"}""", initiateStatus) else json("""{"code":"ABC123","secret":"zq7-connect-store"}""")
            "/api/v1/auth/jellyfin/quickconnect/check" -> json("""{"authenticated":$approved}""")
            "/api/v1/auth/jellyfin/quickconnect/authenticate" -> login(cookie = "fresh")
            "/api/v1/auth/me" -> {
                // Sign-in reads the user back with the fresh cookie.
                assertEquals(cookieHeader("fresh"), request.cookie)
                json(user())
            }
            else -> throw IOException("unexpected ${request.path}")
        }
    }

    @Test
    fun aSchemelessAddressReachesAPlainHttpInstanceOnTheDefaultPort() = runTest {
        val connect = plainHttpLanInstance()
        val step = connect.submitUrl("seerr.lan").signIn
        // The address that answered is the one sign-in and the session use.
        assertEquals("http://seerr.lan:5055", step.baseUrl)
        assertEquals("Requests", step.instanceLabel)
        connect.store.release()
    }

    @Test
    fun anEmptyAddressIsRequiredAndSendsNoProbe() = runTest {
        val connect = plainHttpLanInstance()
        connect.store.setUrl("   ")
        connect.store.probe()
        assertEquals(T.addServer.required, connect.store.state.value.error)
        assertTrue(connect.server.requests.isEmpty())
        connect.store.release()
    }

    @Test
    fun anUnreachableAddressKeepsTheUrlStepAndSaysNoSeerrAnswered() = runTest {
        val connect = Connect(this) { throw IOException("connection refused") }
        val state = connect.submitUrl("seerr.lan")
        assertTrue(state.step is SeerrConnectStep.Url)
        assertEquals(T.addServer.noReachableServer(product = "Seerr"), state.error)
        connect.store.release()
    }

    @Test
    fun anOverseerrInstanceOffersPlexSignInWithTheProfilesToken() = runTest {
        // Overseerr's public settings have no mediaServerType, nor a media server login switch: it is always Plex-backed.
        val connect = Connect(this, plexToken = "plex-token") { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json("""{"initialized":true,"applicationTitle":"Overseerr","localLogin":false}""")
                "/api/v1/auth/plex" -> login()
                "/api/v1/auth/me" -> json(user())
                else -> throw IOException("unexpected ${request.path}")
            }
        }
        val step = connect.submitUrl("https://overseerr.example.com").signIn
        assertEquals(T.auth.signInWithPlex, step.plexLabel)
        assertNull(step.noMethodsMessage)

        connect.store.signInWithPlex()
        assertTrue(connect.until { it.done || (!it.busy && it.error != null) }.done)
        assertEquals(JsonPrimitive("plex-token"), connect.server.requests.single { it.path == "/api/v1/auth/plex" }.bodyJson()["authToken"])
        assertEquals(SeerrAuthMethod.PLEX, connect.accounts.session.value?.method)
        connect.store.release()
    }

    @Test
    fun aJellyfinOnlyInstanceOpensItsFormDirectlyWithQuickConnect() = runTest {
        val connect = plainHttpLanInstance()
        val step = connect.submitUrl("seerr.lan").signIn
        assertNull(step.plexLabel)
        assertEquals(SeerrCredentialKind.JELLYFIN, step.form?.kind)
        assertEquals(T.addServer.username, step.form?.identifierLabel)
        assertEquals(T.auth.useQuickConnect, step.form?.quickConnectLabel)
        assertTrue(step.methods.isEmpty())
        connect.store.release()
    }

    @Test
    fun quickConnectIsWithheldFromAnEmbyBackedInstance() = runTest {
        // Seerr refuses its Quick Connect routes for Emby; Emby's own sign-in stays.
        val connect = plainHttpLanInstance(mediaServerType = SeerrMediaServerType.EMBY)
        val form = connect.submitUrl("seerr.lan").signIn.form
        assertEquals(SeerrCredentialKind.EMBY, form?.kind)
        assertNull(form?.quickConnectLabel)
        assertEquals(T.addServer.signIn, form?.signInLabel)
        connect.store.release()
    }

    @Test
    fun severalMethodsShowAListAndSwitchingFormsClearsTheCredentials() = runTest {
        val connect = plainHttpLanInstance(localLogin = true)
        val step = connect.submitUrl("seerr.lan").signIn
        assertNull(step.form)
        assertEquals(
            listOf(SeerrSignInMethod(SeerrCredentialKind.JELLYFIN, T.seerr.signInWithJellyfin), SeerrSignInMethod(SeerrCredentialKind.LOCAL, T.seerr.signInWithLocal)),
            step.methods,
        )

        connect.store.chooseForm(SeerrCredentialKind.LOCAL)
        connect.store.setIdentifier("a@b.c")
        connect.store.chooseForm(SeerrCredentialKind.JELLYFIN)
        val switched = connect.store.state.value.signIn
        assertEquals("", switched.form?.identifier)
        assertEquals(listOf(SeerrCredentialKind.LOCAL), switched.methods.map { it.kind })
        connect.store.release()
    }

    @Test
    fun anInstanceWithNoSupportedMethodSaysSo() = runTest {
        val connect = Connect(this) { json("""{"initialized":true,"localLogin":false,"mediaServerLogin":true,"mediaServerType":1}""") }
        val step = connect.submitUrl("https://seerr.example.com").signIn
        assertEquals(T.seerr.noSignInMethods, step.noMethodsMessage)
        assertNull(step.form)
        connect.store.release()
    }

    @Test
    fun credentialsAreRequiredThenSentTrimmedAndTheSessionIsAdopted() = runTest {
        val connect = plainHttpLanInstance()
        connect.submitUrl("seerr.lan")

        connect.store.signIn()
        val invalid = connect.store.state.value.signIn.form!!
        assertEquals(T.addServer.required, invalid.identifierError)
        assertEquals(T.addServer.required, invalid.passwordError)

        connect.store.setIdentifier("  alice ")
        connect.store.setPassword(" pw ")
        connect.store.signIn()
        assertTrue(connect.until { it.done || (!it.busy && it.error != null) }.done)
        val login = connect.server.requests.single { it.path == "/api/v1/auth/jellyfin" }.bodyJson()
        assertEquals(JsonPrimitive("alice"), login["username"])
        assertEquals(JsonPrimitive(" pw "), login["password"])
        val adopted = connect.accounts.session.value!!
        assertEquals("Requests", adopted.instanceLabel)
        assertEquals(SeerrAuthMethod.JELLYFIN, adopted.method)
        assertEquals("http://seerr.lan:5055", adopted.baseUrl)
        connect.store.release()
    }

    @Test
    fun changeReturnsToTheUrlStep() = runTest {
        val connect = plainHttpLanInstance()
        connect.submitUrl("seerr.lan")
        connect.store.changeServer()
        assertEquals("seerr.lan", (connect.store.state.value.step as SeerrConnectStep.Url).url)
        connect.store.release()
    }

    @Test
    fun quickConnectShowsTheCodeAndCancelRestoresTheForm() = runTest {
        val connect = quickConnectInstance(approved = false)
        connect.submitUrl("https://seerr.example.com")

        connect.store.startQuickConnect()
        val waiting = connect.until { it.step is SeerrConnectStep.QuickConnect }
        assertEquals(SeerrConnectStep.QuickConnect("ABC123", T.common.cancel), waiting.step)
        assertEquals(false, waiting.busy)

        connect.store.cancelQuickConnect()
        val restored = connect.store.state.value
        assertEquals(SeerrCredentialKind.JELLYFIN, restored.signIn.form?.kind)
        assertNull(restored.error)
        assertNull(connect.accounts.session.value)
        connect.store.release()
    }

    @Test
    fun approvingTheCodeAdoptsAQuickConnectSessionAndFinishes() = runTest {
        val connect = quickConnectInstance()
        connect.submitUrl("https://seerr.example.com")

        connect.store.startQuickConnect()
        assertTrue(connect.until { it.done || (!it.busy && it.error != null) }.done)
        val adopted = connect.accounts.session.value!!
        assertEquals(SeerrAuthMethod.QUICK_CONNECT, adopted.method)
        assertEquals("fresh", adopted.cookie)
        assertEquals("", adopted.secret, "no secret to keep means no silent re-auth to attempt")
        assertEquals("Requests", adopted.instanceLabel)
        connect.store.release()
    }

    @Test
    fun anInstanceWithoutTheQuickConnectRoutesSaysSoAndRestoresTheForm() = runTest {
        val connect = quickConnectInstance(initiateStatus = 404)
        connect.submitUrl("https://seerr.example.com")

        connect.store.startQuickConnect()
        val failed = connect.until { !it.busy && it.error != null }
        assertEquals(T.seerr.quickConnectUnsupported, failed.error)
        assertEquals(T.auth.useQuickConnect, failed.signIn.form?.quickConnectLabel)
        connect.store.release()
    }
}

class SeerrSettingsStoreTest {
    @Test
    fun showsTheAccountAndClosesOnceADisconnectIsConfirmed() = runTest {
        val server = MockServer(this) { request -> if (request.path == "/api/v1/auth/logout") json("{}") else throw IOException("offline") }
        val secrets = MemorySecretStore()
        val accounts = SeerrAccounts(server.http, secrets, backgroundScope, { null }, { "en" }, FixedClock, StandardTestDispatcher(testScheduler))
        accounts.onActiveProfileChanged("profile-1")
        accounts.adoptSession(session().copy(instanceLabel = ""))
        val store = SeerrSettingsStore(accounts, backgroundScope)

        val shown = store.state.value
        assertEquals(T.services.connectedAs("Alice"), shown.connectedAs)
        assertEquals("Jellyfin", shown.method)
        assertEquals(T.seerr.instance, shown.instanceLabel)
        assertEquals("https://seerr.example.com", shown.baseUrl)
        assertEquals(SeerrServiceRow(T.seerr.title, "Alice · seerr.example.com", connected = true), SeerrServiceRow.of(accounts.session.value))

        store.requestDisconnect()
        assertEquals(T.seerr.disconnectConfirm, store.state.value.confirm?.title)
        store.cancelDisconnect()
        assertNull(store.state.value.confirm)

        store.requestDisconnect()
        store.confirmDisconnect()
        assertTrue(store.state.first { it.closed }.closed)
        assertNull(accounts.session.value)
        assertEquals(SeerrServiceRow(T.seerr.title, T.services.notConnected, connected = false), SeerrServiceRow.of(accounts.session.value))
        assertTrue(secrets.entries.isEmpty())
        store.release()
    }

    @Test
    fun theServicesRowNamesTheUserAndTheInstance() {
        assertEquals("Alice · Family Seerr", SeerrServiceRow.of(session().copy(instanceLabel = "Family Seerr")).subtitle)
        assertEquals(T.services.notConnected, SeerrServiceRow.of(null).subtitle)
    }
}
