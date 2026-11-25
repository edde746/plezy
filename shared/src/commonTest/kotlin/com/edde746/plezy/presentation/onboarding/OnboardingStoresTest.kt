package com.edde746.plezy.presentation.onboarding

import com.edde746.plezy.app.BrowserMode
import com.edde746.plezy.jellyfin.DiscoveredJellyfinServer
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.playback.resolve.FakeHttp
import com.edde746.plezy.plex.tv.authWith
import com.edde746.plezy.plex.tv.jsonResponse
import com.edde746.plezy.presentation.navigation.PlezyNavigator
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.MediaBrowserAddResult
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileHarness
import com.edde746.plezy.profiles.computePinHash
import com.edde746.plezy.profiles.jellyfin
import com.edde746.plezy.profiles.plexAccount
import com.edde746.plezy.profiles.profileTest
import com.edde746.plezy.profiles.resources
import com.edde746.plezy.profiles.serverJson
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

/** [opens]: the modes a link opens in here; [urls] each asked, [closes] the in-app view closes asked. */
private class FakeHost(override val tv: Boolean = false, private val opens: Set<BrowserMode> = BrowserMode.entries.toSet()) : AccountsHost {
    val opened = mutableListOf<Route>()
    val added = mutableListOf<Pair<Route, Boolean>>()
    val urls = mutableListOf<Pair<BrowserMode, String>>()
    var closes = 0
    var pickAnswer = true
    var picks = 0
    var borrowAnswer = true
    val borrows = mutableListOf<String>()
    var backs = 0
    override fun open(route: Route) {
        opened += route
    }
    override fun back() {
        backs++
    }
    override fun connectionAdded(from: Route, pickProfile: Boolean) {
        added += from to pickProfile
    }
    override fun profileChosen(from: Route) = Unit
    override fun leavePicker(from: Route) = Unit
    override fun signedOut() = Unit
    override fun pickRequired() = Unit
    override suspend fun pickProfile(): Boolean = pickAnswer.also { picks++ }
    override suspend fun borrowInto(profileId: String): Boolean = borrowAnswer.also { borrows += profileId }
    override fun openUrl(url: String, mode: BrowserMode): Boolean {
        urls += mode to url
        return mode in opens
    }
    override fun closeBrowser() {
        closes++
    }
    override fun exit() = Unit
}

class PlexPinFlowTest {
    private val pin = """{"id":7,"code":"abcd"}"""

    @Test
    fun `the QR page shows a short PIN code with the plex tv link QR code and a claimed PIN hands over its token`() = runTest {
        var claimed = false
        val strong = mutableListOf<String?>()
        val (auth, _) = authWith { req ->
            when {
                req.url.encodedPath.endsWith("/pins") -> jsonResponse("""{"id":8,"code":"AB12"}""", 201).also { strong += req.url.parameters["strong"] }
                req.url.encodedPath.endsWith("/pins/8") && claimed -> jsonResponse("""{"authToken":"tok"}""")
                else -> jsonResponse("{}")
            }
        }
        val tokens = mutableListOf<String>()
        val flow = PlexPinFlow({ auth }, FakeHost(), { tokens += it }, backgroundScope)
        runCurrent()
        assertTrue(flow.state.value.ready)

        flow.startQr()
        runCurrent()
        assertEquals(PlexPinPhase.QR, flow.state.value.phase)
        assertEquals(listOf<String?>("false"), strong)
        assertEquals("https://www.plex.tv/link/?pin=AB12", flow.state.value.qrUrl)
        assertEquals("AB12", flow.state.value.code)
        assertFalse(flow.state.value.expired)

        claimed = true
        advanceTimeBy(1_500)
        assertEquals(listOf("tok"), tokens)
        assertEquals(PlexPinPhase.REGISTERING, flow.state.value.phase)
    }

    @Test
    fun `the browser handoff opens the auth link in the in app browser and cancel goes back to the buttons`() = runTest {
        val (auth, _) = authWith { req -> if (req.url.encodedPath.endsWith("/pins")) jsonResponse(pin, 201) else jsonResponse("{}") }
        val host = FakeHost()
        val tokens = mutableListOf<String>()
        val flow = PlexPinFlow({ auth }, host, { tokens += it }, backgroundScope)
        runCurrent()
        flow.startBrowser()
        runCurrent()
        assertEquals(PlexPinPhase.BROWSER, flow.state.value.phase)
        assertEquals(listOf(BrowserMode.IN_APP_BROWSER), host.urls.map { it.first })

        flow.cancel()
        advanceTimeBy(10_000)
        assertEquals(PlexPinUiState(ready = true), flow.state.value)
        assertTrue(tokens.isEmpty())
    }

    @Test
    fun `a sign in link nothing opens shows a code instead of waiting on a browser`() = runTest {
        var claimed = false
        val (auth, _) = authWith { req ->
            if (req.url.encodedPath.endsWith("/pins")) jsonResponse(pin, 201) else jsonResponse(if (claimed) """{"authToken":"tok"}""" else "{}")
        }
        val host = FakeHost(opens = emptySet())
        val tokens = mutableListOf<String>()
        val flow = PlexPinFlow({ auth }, host, { tokens += it }, backgroundScope)
        runCurrent()
        flow.startBrowser()
        runCurrent()
        assertEquals(listOf(BrowserMode.IN_APP_BROWSER, BrowserMode.EXTERNAL), host.urls.map { it.first })
        assertEquals(PlexPinPhase.QR, flow.state.value.phase)
        assertEquals("https://www.plex.tv/link/?pin=abcd", flow.state.value.qrUrl)
        assertEquals("abcd", flow.state.value.code)

        claimed = true
        advanceTimeBy(1_500)
        assertEquals(listOf("tok"), tokens)
        assertEquals(0, host.closes)
    }

    @Test
    fun `an in app browser that does not open falls back to the browser outside the app`() = runTest {
        var claimed = false
        val (auth, _) = authWith { req ->
            if (req.url.encodedPath.endsWith("/pins")) jsonResponse(pin, 201) else jsonResponse(if (claimed) """{"authToken":"tok"}""" else "{}")
        }
        val host = FakeHost(opens = setOf(BrowserMode.EXTERNAL))
        val tokens = mutableListOf<String>()
        val flow = PlexPinFlow({ auth }, host, { tokens += it }, backgroundScope)
        runCurrent()
        flow.startBrowser()
        runCurrent()
        assertEquals(listOf(BrowserMode.IN_APP_BROWSER, BrowserMode.EXTERNAL), host.urls.map { it.first })
        assertEquals(PlexPinPhase.BROWSER, flow.state.value.phase)
        assertNull(flow.state.value.qrUrl)

        claimed = true
        advanceTimeBy(1_500)
        assertEquals(listOf("tok"), tokens)
        assertEquals(0, host.closes)
    }

    @Test
    fun `on TV the auth link opens in a web view which closes once the PIN is claimed`() = runTest {
        var claimed = false
        val (auth, _) = authWith { req ->
            if (req.url.encodedPath.endsWith("/pins")) jsonResponse(pin, 201) else jsonResponse(if (claimed) """{"authToken":"tok"}""" else "{}")
        }
        val host = FakeHost(tv = true)
        val closesAtToken = mutableListOf<Int>()
        val flow = PlexPinFlow({ auth }, host, { closesAtToken += host.closes }, backgroundScope)
        runCurrent()
        flow.startBrowser()
        runCurrent()
        assertEquals(listOf(BrowserMode.IN_APP_WEB_VIEW), host.urls.map { it.first })
        assertEquals(0, host.closes)

        claimed = true
        advanceTimeBy(1_500)
        assertEquals(listOf(1), closesAtToken)
        assertEquals(1, host.closes)
    }

    @Test
    fun `an expired QR code stays on the QR page with its expiry and a browser wait times out to the buttons`() = runTest {
        var expired = false
        val (auth, _) = authWith { req ->
            when {
                req.url.encodedPath.endsWith("/pins") -> jsonResponse(pin, 201)
                expired -> jsonResponse("{}", 410)
                else -> jsonResponse("{}")
            }
        }
        val flow = PlexPinFlow({ auth }, FakeHost(), {}, backgroundScope)
        runCurrent()
        val expiredPage = PlexPinUiState(phase = PlexPinPhase.QR, expired = true, error = T.auth.codeExpired, ready = true)
        flow.startQr()
        advanceTimeBy(121_000)
        assertEquals(expiredPage, flow.state.value)

        expired = true
        flow.retry()
        advanceTimeBy(2_000)
        assertEquals(expiredPage, flow.state.value)

        expired = false
        flow.startBrowser()
        advanceTimeBy(121_000)
        assertEquals(PlexPinUiState(error = T.auth.authenticationTimeout, ready = true), flow.state.value)
    }

    @Test
    fun `retry starts a new PIN in the same mode`() = runTest {
        var created = 0
        val (auth, _) = authWith { req ->
            if (req.url.encodedPath.endsWith("/pins")) jsonResponse("""{"id":${++created},"code":"c$created"}""", 201) else jsonResponse("{}")
        }
        val flow = PlexPinFlow({ auth }, FakeHost(), {}, backgroundScope)
        runCurrent()
        flow.startQr()
        runCurrent()
        flow.retry()
        advanceTimeBy(150)
        assertEquals(2, created)
        assertEquals(PlexPinPhase.QR, flow.state.value.phase)
        assertEquals("c2", flow.state.value.code)
        assertTrue(flow.state.value.qrUrl!!.endsWith("pin=c2"))
    }
}

class SignInStoreTest {
    @Test
    fun `an account without servers names it and the recovery notice goes once a sign in starts`() = profileTest { h ->
        h.plexTv = { req ->
            val path = req.url.encodedPath
            when {
                path.endsWith("/pins") -> jsonResponse("""{"id":1,"code":"abc"}""", 201)
                path.endsWith("/pins/1") -> jsonResponse("""{"authToken":"tok"}""")
                path.endsWith("/user") -> jsonResponse("""{"uuid":"u1","username":"ann","email":"ann@example.com"}""")
                path.endsWith("/resources") -> jsonResponse("[]")
                path.endsWith("/home/users") -> jsonResponse("""{"users":[]}""")
                else -> jsonResponse("{}")
            }
        }
        val host = FakeHost()
        val store = SignInStore(h.services, host, recoveryRequired = true, backgroundScope)
        runCurrent()
        assertEquals(T.auth.localDataRecoveryRequired, store.notice.value)

        store.plex.startBrowser()
        advanceTimeBy(5_000)
        assertNull(store.notice.value)
        assertEquals(T.serverSelection.noServersFoundForAccount("ann", "ann@example.com"), store.plex.state.value.error)
        assertTrue(host.added.isEmpty())
    }

    @Test
    fun `Jellyfin and Emby open the server form for the device`() = profileTest { h ->
        val host = FakeHost()
        SignInStore(h.services, host, recoveryRequired = false, backgroundScope).connect(MediaBrowserDialect.EMBY)
        assertEquals(listOf<Route>(Route.AddMediaBrowser(MediaBrowserDialect.EMBY, null)), host.opened)
    }
}

class AddMediaBrowserStoreTest {
    private fun ProfileHarness.server(quickConnect: Boolean, product: String = "Jellyfin Server") {
        jellyfinServer = { req ->
            when (req.url.encodedPath) {
                "/System/Info/Public" -> jsonResponse("""{"Id":"jf-machine","ServerName":"Home","Version":"10.10.7","ProductName":"$product"}""")
                "/QuickConnect/Enabled" -> jsonResponse(if (quickConnect) "true" else "false")
                "/QuickConnect/Initiate" -> jsonResponse("""{"Code":"123456","Secret":"s3cret"}""")
                "/QuickConnect/Connect" -> jsonResponse("""{"Authenticated":false}""")
                "/Users/AuthenticateByName" -> jsonResponse("""{"AccessToken":"tok","User":{"Id":"user-a","Name":"maestro"}}""")
                else -> respond("", HttpStatusCode.NotFound)
            }
        }
    }

    private fun ProfileHarness.store(host: AccountsHost, dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN, lan: List<DiscoveredJellyfinServer> = emptyList()) =
        AddMediaBrowserStore(Route.AddMediaBrowser(dialect, null), services, connections, host, test.backgroundScope) { lan }

    @Test
    fun `stored servers come first marked added and a LAN answer of the same machine is dropped`() = profileTest { h ->
        h.store(jellyfin())
        val lan = listOf(
            DiscoveredJellyfinServer("http://10.0.0.2:8096", "jf-machine", "Home again", MediaBrowserDialect.JELLYFIN),
            DiscoveredJellyfinServer("http://10.0.0.3:8096", "other", "Other", MediaBrowserDialect.JELLYFIN),
        )
        val store = h.store(FakeHost(), lan = lan)
        advanceTimeBy(5_000)
        val state = store.state.value
        assertFalse(state.discovering)
        assertEquals(listOf("jf-machine", "other"), state.localServers.map { it.id }.sorted())
        assertEquals(2, state.localServers.size)
        assertEquals(setOf("jf-machine"), state.addedServerIds)
    }

    @Test
    fun `no URL asks for one and a probe finds the server then focuses the username`() = profileTest { h ->
        h.server(quickConnect = true)
        val store = h.store(FakeHost())
        store.findServer()
        assertTrue(store.state.value.urlRequired)

        store.setUrls("http://192.168.0.15:28096")
        store.findServer()
        advanceTimeBy(5_000)
        val state = store.state.value
        assertEquals(FoundServer("Home", "Jellyfin 10.10.7"), state.server)
        assertTrue(state.quickConnectAvailable)
        assertEquals(1, state.focusUsername)
        assertFalse(state.busy)
        assertNull(state.quickConnectCode)
    }

    @Test
    fun `signing in again probes the expired server at once and focuses the password`() = profileTest { h ->
        h.server(quickConnect = false)
        val route = Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null, url = "http://192.168.0.15:28096", username = "maestro")
        val store = AddMediaBrowserStore(route, h.services, h.connections, FakeHost(), h.test.backgroundScope) { error("no LAN search") }
        advanceTimeBy(5_000)
        val state = store.state.value
        assertEquals(T.connections.signInAgain, state.title)
        assertEquals(FoundServer("Home", "Jellyfin 10.10.7"), state.server)
        assertEquals("maestro", state.username)
        assertEquals(1, state.focusPassword)
        assertEquals(0, state.focusUsername)
        assertFalse(state.discovering)
        assertTrue(state.localServers.isEmpty())
    }

    @Test
    fun `on TV a server with Quick Connect starts it after the probe and cancel shows the form`() = profileTest { h ->
        h.server(quickConnect = true)
        val store = h.store(FakeHost(tv = true))
        store.setUrls("http://192.168.0.15:28096")
        store.findServer()
        advanceTimeBy(500)
        assertEquals("123456", store.state.value.quickConnectCode)
        assertEquals(1, store.state.value.focusCancel)
        assertFalse(store.state.value.busy)

        store.cancelQuickConnect()
        assertNull(store.state.value.quickConnectCode)
        assertEquals(FoundServer("Home", "Jellyfin 10.10.7"), store.state.value.server)
    }

    @Test
    fun `Emby never offers Quick Connect`() = profileTest { h ->
        h.server(quickConnect = true, product = "Emby Server")
        val store = h.store(FakeHost(tv = true), MediaBrowserDialect.EMBY)
        store.setUrls("http://192.168.0.15:28097")
        store.findServer()
        advanceTimeBy(5_000)
        assertFalse(store.state.value.quickConnectAvailable)
        assertNull(store.state.value.quickConnectCode)
    }

    @Test
    fun `a first sign in makes a profile named after the user and closes the flow`() = profileTest { h ->
        h.server(quickConnect = false)
        h.services.start()
        val host = FakeHost()
        val store = h.store(host)
        store.setUrls("http://192.168.0.15:28096")
        store.findServer()
        advanceTimeBy(5_000)
        store.signIn()
        assertTrue(store.state.value.usernameRequired)
        store.setUsername("maestro")
        store.setPassword("maestro")
        store.signIn()
        advanceTimeBy(5_000)

        assertEquals(listOf<Pair<Route, Boolean>>(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null) to false), host.added)
        assertEquals("maestro", h.services.active.value?.displayName)
        assertIs<LocalProfile>(h.services.active.value)
    }

    @Test
    fun `wrong credentials show the refusal of the server`() = profileTest { h ->
        h.server(quickConnect = false)
        val base = h.jellyfinServer
        h.jellyfinServer = { req -> if (req.url.encodedPath == "/Users/AuthenticateByName") respond("", HttpStatusCode.Unauthorized) else base(req) }
        val host = FakeHost()
        val store = h.store(host)
        store.setUrls("http://192.168.0.15:28096")
        store.findServer()
        advanceTimeBy(5_000)
        store.setUsername("maestro")
        store.signIn()
        advanceTimeBy(5_000)
        assertEquals(T.addServer.invalidCredentials, store.state.value.error)
        assertTrue(host.added.isEmpty())
        assertFalse(store.state.value.busy)
    }

    @Test
    fun `a server that times out during setup shows timed out not the exception text`() = profileTest { h ->
        h.server(quickConnect = false)
        val base = h.jellyfinServer
        h.jellyfinServer = { req -> if (req.url.encodedPath == "/Users/AuthenticateByName") awaitCancellation() else base(req) }
        val store = h.store(FakeHost())
        store.setUrls("http://192.168.0.15:28096")
        store.findServer()
        advanceTimeBy(5_000)
        store.setUsername("maestro")
        store.signIn()
        advanceTimeBy(600_000)
        assertEquals(T.addServer.signInFailed(T.errors.reasonTimedOut), store.state.value.error)
        assertFalse(store.state.value.busy)
    }
}

class PinPrompterTest {
    @Test
    fun `a new PIN is asked twice and two different ones are refused`() = runTest {
        val pins = PinPrompter()
        var mismatched = false
        val asked = async { pins.askNew { mismatched = true } }
        runCurrent()
        assertEquals(T.profiles.setPinTitle, pins.request.value?.title)
        pins.submit("1234")
        runCurrent()
        assertEquals(T.profiles.confirmPinTitle, pins.request.value?.title)
        pins.submit("4321")
        assertNull(asked.await())
        assertTrue(mismatched)
        assertNull(pins.request.value)
    }

    @Test
    fun `a wrong PIN is asked again with the error`() = runTest {
        val pins = PinPrompter()
        val profile = LocalProfile(id = "local-1", displayName = "Kids", createdAt = 0)
        val asked = async { pins.ask(profile, incorrectPin = true) }
        runCurrent()
        assertEquals("Kids", pins.request.value?.title)
        assertEquals(T.profiles.incorrectPinTryAgain, pins.request.value?.error)
        pins.cancel()
        assertNull(asked.await())
    }
}

class OnboardingNavigationTest {
    private fun onboarding(navigator: PlezyNavigator, exits: MutableList<Unit> = mutableListOf()) =
        Onboarding(navigator, { _, _ -> true }, {}, { exits += Unit }, { false })

    @Test
    fun `the sign in takes the stack alone and an added account enters the app`() {
        val navigator = PlezyNavigator(Route.Home)
        val onboarding = onboarding(navigator)
        onboarding.enter(BootRoute.SIGN_IN, recoveryRequired = true)
        assertEquals(listOf<Route>(Route.SignIn), navigator.backStack.value)
        assertTrue(onboarding.gated)

        onboarding.open(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null))
        onboarding.connectionAdded(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null), pickProfile = false)
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
        assertFalse(onboarding.recoveryRequired)
        assertFalse(onboarding.gated)
    }

    @Test
    fun `asked to pick on open the app enters at the required picker alone`() {
        val navigator = PlezyNavigator(Route.Home)
        onboarding(navigator).enter(BootRoute.PICK_PROFILE, recoveryRequired = false)
        assertEquals(listOf<Route>(Route.ProfilePicker(required = true)), navigator.backStack.value)
    }

    @Test
    fun `a sign in that needs a pick goes to the required picker whose back leaves the app`() {
        val navigator = PlezyNavigator(Route.Home)
        val exits = mutableListOf<Unit>()
        val onboarding = onboarding(navigator, exits)
        onboarding.enter(BootRoute.SIGN_IN, recoveryRequired = false)
        onboarding.connectionAdded(Route.SignIn, pickProfile = true)
        assertEquals(listOf<Route>(Route.ProfilePicker(required = true)), navigator.backStack.value)

        onboarding.leavePicker(Route.ProfilePicker(required = true))
        assertEquals(1, exits.size)
        onboarding.profileChosen(Route.ProfilePicker(required = true))
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
    }

    @Test
    fun `a pick awaited from a required picker at the stacks root answers and enters the app`() = runTest {
        val navigator = PlezyNavigator(Route.Home)
        val onboarding = onboarding(navigator)
        val pick = async { onboarding.pickProfile() }
        runCurrent()
        // The picker the waiting sign-in opened ends up alone at the bottom of the stack shown (a stack switch while
        // the bind went offline and back).
        onboarding.pickRequired()
        assertEquals(listOf<Route>(Route.ProfilePicker(required = true)), navigator.backStack.value)

        onboarding.profileChosen(Route.ProfilePicker(required = true))

        assertTrue(pick.await())
        assertEquals(listOf<Route>(Route.Home), navigator.backStack.value)
        assertFalse(onboarding.gated)
    }

    @Test
    fun `inside the app an added connection closes its whole flow`() {
        val navigator = PlezyNavigator(Route.Settings)
        val onboarding = onboarding(navigator)
        navigator.navigate(Route.ProfileDetail("p"))
        navigator.navigate(Route.AddConnection("p"))
        navigator.navigate(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, "p"))
        onboarding.connectionAdded(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, "p"), pickProfile = false)
        assertEquals(listOf(Route.Settings, Route.ProfileDetail("p")), navigator.backStack.value)
    }

    @Test
    fun `Settings adds a connection for the profile active now`() {
        val navigator = PlezyNavigator(Route.Settings)
        var active: String? = "local-kids"
        val onboarding = Onboarding(navigator, { _, _ -> true }, {}, {}, { false }) { active }
        onboarding.addConnection()
        assertEquals(Route.AddConnection("local-kids"), navigator.current)
        navigator.back()
        active = null
        onboarding.addConnection()
        assertEquals(Route.AddConnection(null), navigator.current)
    }

    @Test
    fun `a borrow waited for answers true without closing and leaving it answers false`() = runTest {
        val navigator = PlezyNavigator(Route.Settings)
        val onboarding = onboarding(navigator)
        navigator.navigate(Route.AddConnection("p"))
        navigator.navigate(Route.AddPlexAccount("p"))
        val borrowed = async { onboarding.borrowInto("p") }
        runCurrent()
        assertEquals(Route.BorrowConnection("p"), navigator.current)
        onboarding.connectionAdded(Route.BorrowConnection("p"), pickProfile = false)
        assertTrue(borrowed.await())
        assertEquals(Route.BorrowConnection("p"), navigator.current)

        navigator.back()
        val declined = async { onboarding.borrowInto("p") }
        runCurrent()
        navigator.back()
        assertFalse(declined.await())
        assertEquals(Route.AddPlexAccount("p"), navigator.current)
    }

    @Test
    fun `nothing left after a removal goes back to the sign in`() {
        val navigator = PlezyNavigator(Route.Settings)
        val onboarding = onboarding(navigator)
        navigator.navigate(Route.ProfilePicker(required = false))
        onboarding.signedOut()
        assertEquals(listOf<Route>(Route.SignIn), navigator.backStack.value)
    }

    @Test
    fun `a pick asked from a flow returns there`() = runTest {
        val navigator = PlezyNavigator(Route.Home)
        val onboarding = onboarding(navigator)
        onboarding.enter(BootRoute.SIGN_IN, recoveryRequired = false)
        navigator.navigate(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null))
        val picked = async { onboarding.pickProfile() }
        runCurrent()
        assertEquals(Route.ProfilePicker(required = true), navigator.current)
        onboarding.profileChosen(Route.ProfilePicker(required = true))
        assertTrue(picked.await())
        assertEquals(Route.AddMediaBrowser(MediaBrowserDialect.JELLYFIN, null), navigator.current)
    }

    @Test
    fun `the stacks own back off the picker a pick waits for declines the pick`() = runTest {
        val navigator = PlezyNavigator(Route.Settings)
        val onboarding = onboarding(navigator)
        navigator.navigate(Route.AddConnection("p"))
        val picked = async { onboarding.pickProfile() }
        runCurrent()
        assertEquals(Route.ProfilePicker(required = true), navigator.current)

        navigator.pop(Route.ProfilePicker(required = true))
        runCurrent()

        assertTrue(picked.isCompleted)
        assertFalse(picked.await())
        assertEquals(Route.AddConnection("p"), navigator.current)
    }
}

class ReconnectRuleTest {
    @Test
    fun `the active profile is bound again only when it reaches no server though one could`() {
        assertTrue(shouldRebindAfterReconnect(true, false, hasManagerOnlineServers = true, hasKnownOfflineServers = false))
        assertTrue(shouldRebindAfterReconnect(true, false, hasManagerOnlineServers = false, hasKnownOfflineServers = false))
        assertFalse(shouldRebindAfterReconnect(true, true, hasManagerOnlineServers = true, hasKnownOfflineServers = false))
        assertFalse(shouldRebindAfterReconnect(false, false, hasManagerOnlineServers = true, hasKnownOfflineServers = false))
        assertFalse(shouldRebindAfterReconnect(true, false, hasManagerOnlineServers = false, hasKnownOfflineServers = true))
    }
}

class ProfilePickerStoreTest {
    @Test
    fun `a profile shows its users picture and initials without one`() = profileTest { h ->
        h.services.start()
        val withPicture = jellyfin().copy(primaryImageTag = "abc")
        h.services.addMediaBrowserConnection(withPicture)
        val guest = h.services.createLocalProfile("Guest")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-b"), targetProfile = guest)
        val store = ProfilePickerStore(Route.ProfilePicker(required = false), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)

        val tiles = store.state.value.tiles.associateBy { it.name }
        assertEquals(
            "https://jellyfin.local/Users/user-a/Images/Primary?tag=abc&maxWidth=240&maxHeight=240",
            tiles.getValue("User user-a").avatarUrl,
        )
        assertNull(tiles.getValue("Guest").avatarUrl)

        val detail = ProfileDetailStore(Route.ProfileDetail(h.services.active.value!!.id), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        assertEquals(tiles.getValue("User user-a").avatarUrl, detail.state.value.avatarUrl)
    }

    @Test
    fun `a PIN protected profile switches once its PIN is right and shows switching only after that`() = profileTest { h ->
        h.services.start()
        h.store(jellyfin())
        val result = h.services.addMediaBrowserConnection(jellyfin())
        assertIs<MediaBrowserAddResult.Added>(result)
        val kids = h.services.createLocalProfile("Kids", pin = "1234")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-b"), targetProfile = kids)
        val pins = PinPrompter()
        val store = ProfilePickerStore(Route.ProfilePicker(required = false), h.services, h.removal, h.connections, h.bindings, pins, FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        val tiles = store.state.value.tiles
        assertEquals(2, tiles.size)
        assertTrue(tiles.first { it.id == kids.id }.locked)
        assertTrue(tiles.all { it.hasConnections })
        h.mediaBrowser.healthDelay[jellyfin(userId = "user-b").id] = 2.seconds

        store.select(kids.id)
        runCurrent()
        assertFalse(store.state.value.switching, "nothing covers the PIN pad")
        pins.submit("0000")
        runCurrent()
        assertEquals(T.profiles.incorrectPinTryAgain, pins.request.value?.error)
        assertFalse(store.state.value.switching, "nothing covers the PIN pad asked again")
        pins.submit("1234")
        advanceTimeBy(1_000)
        assertTrue(store.state.value.switching)
        advanceTimeBy(5_000)
        assertEquals(kids.id, h.services.active.first()?.id)
        assertFalse(store.state.value.switching)
    }

    @Test
    fun `the tiles keep their places through a switch though the new profile is now used last`() = profileTest { h ->
        h.services.start()
        h.store(jellyfin())
        h.services.addMediaBrowserConnection(jellyfin())
        val guest = h.services.createLocalProfile("Guest")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-b"), targetProfile = guest)
        val store = ProfilePickerStore(Route.ProfilePicker(required = false), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        val before = store.state.value.tiles.map { it.id }
        assertEquals(guest.id, before.last())

        h.clock.now += 60_000
        store.select(guest.id)
        advanceTimeBy(5_000)

        assertEquals(guest.id, h.services.active.first()?.id)
        assertEquals(guest.id, h.services.profiles.value.first().id, "the profiles list the one used last first")
        assertEquals(before, store.state.value.tiles.map { it.id })
    }

    @Test
    fun `a switch another screen started shows no switching on the picker`() = profileTest { h ->
        h.services.start()
        h.store(jellyfin())
        h.services.addMediaBrowserConnection(jellyfin())
        val guest = h.services.createLocalProfile("Guest")
        h.services.addMediaBrowserConnection(jellyfin(userId = "user-b"), targetProfile = guest)
        val store = ProfilePickerStore(Route.ProfilePicker(required = false), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        h.mediaBrowser.healthDelay[jellyfin(userId = "user-b").id] = 2.seconds

        val switch = async { h.services.switchProfile(guest, h.pinPrompt) }
        advanceTimeBy(1_000)

        assertTrue(h.services.switching.value)
        assertFalse(store.state.value.switching)
        switch.await()
    }

    @Test
    fun `show profile link offers the link that switches to the profile with its hint`() = profileTest { h ->
        h.services.start()
        h.store(jellyfin())
        h.services.addMediaBrowserConnection(jellyfin())
        val kids = h.services.createLocalProfile("Kids", pin = "1234")
        val store = ProfilePickerStore(Route.ProfilePicker(required = false), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        assertTrue(store.state.value.tiles.all { ProfileAction.SHOW_LINK in it.actions })

        store.act(kids.id, ProfileAction.SHOW_LINK)
        runCurrent()
        assertEquals(ProfileLinkUi("plezy://open?profile=${kids.id}", T.deepLinks.profileHint), store.state.value.link)
        store.dismissLink()
        assertEquals(null, store.state.value.link)
    }

    @Test
    fun `a required pick offers no profile link`() = profileTest { h ->
        h.services.start()
        h.store(jellyfin())
        h.services.addMediaBrowserConnection(jellyfin())
        val store = ProfilePickerStore(Route.ProfilePicker(required = true), h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        assertTrue(store.state.value.tiles.all { it.actions.isEmpty() })
    }

    @Test
    fun `the picker asks who is watching at a required pick and is titled for the entry that opened it`() = profileTest { h ->
        fun title(route: Route.ProfilePicker) =
            ProfilePickerStore(route, h.services, h.removal, h.connections, h.bindings, PinPrompter(), FakeHost(), backgroundScope).state.value.title
        assertEquals(T.profiles.whosWatching, title(Route.ProfilePicker(required = true)))
        assertEquals(T.screens.switchProfile, title(Route.ProfilePicker(required = false)))
        assertEquals(T.profiles.manageProfiles, title(Route.ProfilePicker(required = false, manage = true)))
    }
}

class AddPlexAccountStoreTest {
    /** plex.tv signs in Ann, whose account has one server and no Home users. */
    private fun ProfileHarness.plexTvSignsInAnn() {
        plexTv = { req ->
            val path = req.url.encodedPath
            when {
                path.endsWith("/pins") -> jsonResponse("""{"id":1,"code":"abc"}""", 201)
                path.endsWith("/pins/1") -> jsonResponse("""{"authToken":"tok"}""")
                path.endsWith("/user") -> jsonResponse("""{"uuid":"ann-uuid","username":"ann","email":"ann@example.com"}""")
                path.endsWith("/resources") -> jsonResponse(resources(serverJson()))
                path.endsWith("/home/users") -> jsonResponse("""{"users":[]}""")
                else -> jsonResponse("{}")
            }
        }
    }

    private suspend fun ProfileHarness.plexAccounts() = connections.list().filter { it.kind == BackendKind.PLEX }.map { it.id }

    @Test
    fun `a declined attach to a profile removes the account it added and closes`() = profileTest { h ->
        h.plexTvSignsInAnn()
        val host = FakeHost().apply { borrowAnswer = false }
        val store = AddPlexAccountStore(Route.AddPlexAccount("local-kids"), h.services, host, backgroundScope)
        runCurrent()
        store.plex.startBrowser()
        advanceTimeBy(5_000)

        assertEquals(listOf("local-kids"), host.borrows)
        assertEquals(emptyList(), h.plexAccounts())
        assertEquals(1, host.backs)
        assertTrue(host.added.isEmpty())
        assertEquals(PlexPinPhase.IDLE, store.plex.state.value.phase)
    }

    @Test
    fun `a declined attach keeps an account that was signed in before`() = profileTest { h ->
        h.plexTvSignsInAnn()
        val first = AddPlexAccountStore(Route.AddPlexAccount(null), h.services, FakeHost(), backgroundScope)
        runCurrent()
        first.plex.startBrowser()
        advanceTimeBy(5_000)
        val before = h.plexAccounts()
        assertEquals(1, before.size)

        val host = FakeHost().apply { borrowAnswer = false }
        val store = AddPlexAccountStore(Route.AddPlexAccount("local-kids"), h.services, host, backgroundScope)
        runCurrent()
        store.plex.startBrowser()
        advanceTimeBy(5_000)

        assertEquals(before, h.plexAccounts())
        assertEquals(1, host.backs)
    }

    @Test
    fun `a borrowed attach closes the whole add flow`() = profileTest { h ->
        h.plexTvSignsInAnn()
        val host = FakeHost()
        val route = Route.AddPlexAccount("local-kids")
        val store = AddPlexAccountStore(route, h.services, host, backgroundScope)
        runCurrent()
        store.plex.startBrowser()
        advanceTimeBy(5_000)

        assertEquals(listOf<Pair<Route, Boolean>>(route to false), host.added)
        assertEquals(1, h.plexAccounts().size)
        assertEquals(0, host.backs)
    }
}

class EditConnectionStoreTest {
    @Test
    fun `a second save while one runs is refused and the screen closes once`() = profileTest { h ->
        h.store(jellyfin())
        val probe = CompletableDeferred<Unit>()
        val http = FakeHttp(this) { req ->
            if (req.url.encodedPath == "/System/Info/Public") {
                probe.await()
                jsonResponse("""{"Id":"jf-machine","ServerName":"Jellyfin","Version":"10.10.7","ProductName":"Jellyfin Server"}""")
            } else {
                respond("", HttpStatusCode.NotFound)
            }
        }
        val host = FakeHost()
        val store = EditConnectionStore(Route.EditConnection(jellyfin().id), h.services, h.connections, http.client, host, backgroundScope)
        runCurrent()
        store.setUrls("https://jellyfin.local")

        store.save()
        runCurrent()
        assertTrue(store.state.value.busy)
        store.save()
        runCurrent()
        probe.complete(Unit)
        advanceTimeBy(30_000)

        assertEquals(1, host.backs)
    }
}

class ProfileDetailStoreTest {
    private suspend fun TestScope.detail(h: ProfileHarness, profile: LocalProfile, pins: PinPrompter = PinPrompter()): ProfileDetailStore {
        val store = ProfileDetailStore(Route.ProfileDetail(profile.id), h.services, h.removal, h.connections, h.bindings, pins, FakeHost(), backgroundScope)
        advanceTimeBy(5_000)
        assertEquals(profile.displayName, store.state.value.name)
        return store
    }

    private suspend fun ProfileHarness.stored(id: String) = data.profiles.list().single { it.id == id }

    @Test
    fun `a rename changes the name alone keeping a PIN and a use stored after the screen read the profile`() = profileTest { h ->
        h.services.start()
        val kids = h.services.createLocalProfile("Kids")
        val store = detail(h, kids)
        h.data.profiles.upsert(kids.copy(pinHash = computePinHash("1234")))
        h.data.profiles.markUsed(kids.id, 5_000)

        store.setName("Children")
        store.saveName()
        advanceTimeBy(5_000)

        val stored = h.stored(kids.id)
        assertEquals("Children", stored.displayName)
        assertEquals(computePinHash("1234"), stored.pinHash)
        assertEquals(5_000, stored.lastUsedAt)
    }

    @Test
    fun `a PIN set while its prompt was open keeps a rename and a use made meanwhile`() = profileTest { h ->
        h.services.start()
        val kids = h.services.createLocalProfile("Kids")
        val pins = PinPrompter()
        val store = detail(h, kids, pins)

        store.setPin()
        runCurrent()
        store.setName("Children")
        store.saveName()
        advanceTimeBy(5_000)
        h.data.profiles.markUsed(kids.id, 5_000)
        pins.submit("1234")
        runCurrent()
        pins.submit("1234")
        advanceTimeBy(5_000)

        val stored = h.stored(kids.id)
        assertEquals("Children", stored.displayName)
        assertEquals(computePinHash("1234"), stored.pinHash)
        assertEquals(5_000, stored.lastUsedAt)
    }

    @Test
    fun `signing out of Plex offers to delete downloads only when it could and deletes them once switched on`() = profileTest { h ->
        h.services.start()
        val kids = h.services.createLocalProfile("Kids")
        h.store(plexAccount())
        h.bindings.upsert(ProfileConnection(kids.id, "plex.account", "token", "user"))
        val store = detail(h, kids)

        store.signOut("plex.account")
        advanceTimeBy(5_000)
        assertEquals(T.profiles.signOutPlexTitle, store.state.value.confirm?.title)
        assertNull(store.state.value.confirm?.toggle)
        store.dismissConfirm()

        h.data.downloadLibrary.addDownloadOwner(kids.id, "srv-1:1")
        store.signOut("plex.account")
        advanceTimeBy(5_000)
        assertEquals(ConfirmToggle(T.profiles.signOutPlexDeleteDownloads, T.profiles.signOutPlexDeleteDownloadsDescription), store.state.value.confirm?.toggle)
        store.setConfirmToggle(true)
        store.confirm()
        advanceTimeBy(5_000)

        assertEquals(listOf("release ${kids.id} srv-1"), h.downloads.calls)
        assertNull(h.connections.get("plex.account"))
    }

    @Test
    fun `make default moves the default to the chosen connection and shows it`() = profileTest { h ->
        h.services.start()
        val kids = h.services.createLocalProfile("Kids")
        h.store(jellyfin("user-a", "jf-a"))
        h.store(jellyfin("user-b", "jf-b"))
        val a = "jf-a/user-a"
        val b = "jf-b/user-b"
        h.bindings.upsert(ProfileConnection(kids.id, a, "token-a", "user-a", isDefault = true))
        h.bindings.upsert(ProfileConnection(kids.id, b, "token-b", "user-b"))
        val store = detail(h, kids)

        store.makeDefault(b)
        advanceTimeBy(5_000)

        assertEquals(listOf(b), h.bindings.listForProfile(kids.id).filter { it.isDefault }.map { it.connectionId })
        assertEquals(listOf(b), store.state.value.connections.filter { it.isDefault }.map { it.connectionId })
    }

    @Test
    fun `deleting a local profile asks first then deletes its downloads with it`() = profileTest { h ->
        h.services.start()
        h.services.createLocalProfile("Main")
        val kids = h.services.createLocalProfile("Kids")
        val store = detail(h, kids)

        store.delete()
        advanceTimeBy(5_000)
        assertEquals(T.profiles.deleteProfileTitle, store.state.value.confirm?.title)
        assertEquals(emptyList(), h.downloads.calls)
        store.confirm()
        advanceTimeBy(5_000)

        assertEquals(listOf("delete ${kids.id}"), h.downloads.calls)
        assertTrue(h.data.profiles.list().none { it.id == kids.id })
    }

    @Test
    fun `clearing the PIN keeps a rename stored after the screen read the profile`() = profileTest { h ->
        h.services.start()
        val kids = h.services.createLocalProfile("Kids", pin = "1234")
        val store = detail(h, kids)
        h.data.profiles.rename(kids.id, "Children")

        store.clearPin()
        advanceTimeBy(5_000)

        val stored = h.stored(kids.id)
        assertEquals("Children", stored.displayName)
        assertNull(stored.pinHash)
    }
}
