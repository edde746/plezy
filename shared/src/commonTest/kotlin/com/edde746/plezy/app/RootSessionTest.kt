package com.edde746.plezy.app

import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.jellyfin.FakeResponse
import com.edde746.plezy.jellyfin.JellyfinTestServer
import com.edde746.plezy.net.NetworkState
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.ProfileConnectionRegistry
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.settings.AppLocale
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.strings.InterfaceLocale
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

class RootSessionTest {
    @Test
    fun aFreshInstallShowsTheSignInOnceTheDatabaseIsOpenAndCloseEndsIt() = runTest {
        val startup = Startup(backgroundScope, Duration.ZERO)
        val root = RootSession(testGraph(), FakeAppPlatform(), startup)
        runCurrent()

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(listOf<Route>(Route.SignIn), main.app.navigator.backStack.value)
        assertEquals(StartupUiState(null, null), startup.state.value)

        root.close()
        assertNull(root.app)
    }

    @Test
    fun aFreshInstallEntersAtTheSignIn() = runTest {
        val root = RootSession(testGraph(), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.SIGN_IN, main.entry)
        assertEquals(false, main.recoveryRequired)
        root.close()
    }

    @Test
    fun aLinkTheAppDoesNotOpenIsDropped() = runTest {
        val platform = FakeAppPlatform()
        val root = RootSession(testGraph(), platform, Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        root.openUrl("plezy://play?type=movie&tmdb=603")

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(listOf<Route>(Route.SignIn), main.app.navigator.backStack.value)
        assertEquals(emptyList(), platform.opened)
        root.close()
    }

    @Test
    fun aLinkHandedOverWhileTheAppIsPreparedElsewhereReachesTheApp() = runTest {
        val root = RootSession(testGraph(), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO), StandardTestDispatcher(testScheduler))
        root.openUrl("plezy://not-a-link")
        runCurrent()

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(T.deepLinks.invalid, main.app.links.message.value)
        root.close()
    }

    @Test
    fun theStoredLanguageShowsFromTheFirstFrameAndAPickSwitchesTheRunningApp() = runTest {
        InterfaceLocale.setSystemLanguages(listOf("en-US"))
        val data = testData()
        data.deviceSettings.set(AppSettings.appLocale, AppLocale.DE.storedName)
        val root = RootSession(testGraph(data), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        assertIs<RootScreen.Main>(root.screen.value)
        assertEquals("de", InterfaceLocale.tag.value)
        assertEquals("Abspielen", T.common.play)

        data.deviceSettings.set(AppSettings.appLocale, AppLocale.ZH_HANT.storedName)
        runCurrent()
        assertEquals("zh-Hant", InterfaceLocale.tag.value)
        // Reset: the device's languages again.
        data.deviceSettings.reset(AppSettings.appLocale)
        runCurrent()
        assertEquals("en-US", InterfaceLocale.tag.value)
        root.close()
    }

    @Test
    fun aStoredLanguageThisBuildDoesNotKnowIsEnglishNotTheDevices() = runTest {
        InterfaceLocale.setSystemLanguages(listOf("fr-FR"))
        val data = testData()
        data.deviceSettings.set(AppSettings.appLocale, "tlh")
        val root = RootSession(testGraph(data), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        assertEquals("en", InterfaceLocale.tag.value)
        assertEquals("Play", T.common.play)
        root.close()
    }

    @Test
    fun withANetworkTheMainScreenShowsWhileTheStartupBindWaitsForTheServer() = runTest {
        val answering = CompletableDeferred<Unit>()
        val server = JellyfinTestServer(handler = {
            answering.await()
            FakeResponse(503)
        })
        val root = RootSession(signedInGraph(server), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.MAIN, main.entry)
        assertTrue(main.app.profiles.bindState.value.binding, "the bind goes on under the app")

        answering.complete(Unit)
        main.app.profiles.bindState.first { !it.binding }
        root.close()
    }

    @Test
    fun withoutANetworkTheSplashWaitsForTheStartupBindUpToTheCap() = runTest {
        val server = JellyfinTestServer(handler = { awaitCancellation() })
        val graph = signedInGraph(server)
        graph.setNetwork(NetworkState.OFFLINE)
        val root = RootSession(graph, FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()
        assertEquals(RootScreen.Starting, root.screen.value)

        advanceTimeBy(NO_NETWORK_STARTUP_BIND + 1.milliseconds)
        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.MAIN, main.entry)
        root.close()
    }

    /** A graph whose active profile is bound to one Jellyfin user of [server]. */
    private suspend fun TestScope.signedInGraph(server: JellyfinTestServer): AppGraph {
        val data = testData()
        val secrets = MemorySecretStore()
        val connection = server.connection()
        ConnectionStore(data, secrets).upsert(StoredConnection(connection.id, connection.kind, connection.toConfigJson(), connection.createdAt))
        data.profiles.upsert(LocalProfile(id = "profile-1", displayName = "Me", createdAt = 0))
        ProfileConnectionRegistry(data, secrets).upsert(
            ProfileConnection(profileId = "profile-1", connectionId = connection.id, userIdentifier = "user-1"),
            makeDefault = true,
        )
        ProfileIdentity(data).setActiveProfileId("profile-1")
        return testGraph(data, http = server.http, secrets = secrets)
    }

    @AfterTest
    fun resetLanguage() {
        InterfaceLocale.setChosen(null)
        InterfaceLocale.setSystemLanguages(listOf("en"))
    }
}
