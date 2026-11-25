package com.edde746.plezy.app

import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.input.InputProfile
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.music.engine.AudioPlayer
import com.edde746.plezy.playback.session.PlayRequest
import com.edde746.plezy.presentation.player.PlayerConfig
import com.edde746.plezy.presentation.settings.DeviceFeatures
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.ProfileSwitchResult
import com.edde746.plezy.secrets.SecretStore
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.cast.CastItem
import com.edde746.plezy.presentation.cast.CastLinkStatus
import kotlinx.coroutines.flow.first
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.TextContent
import io.ktor.http.headersOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.job
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.util.Collections
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

class DevServersTest {
    private val server = DevServer(MediaBrowserDialect.JELLYFIN, "maestro", "secret", "http://media.test:8096")

    /**
     * Each request the fake Jellyfin answered, `<method> <path>`. Copy-on-write, as [logged]: the tests read them while
     * the app's background work still requests and logs on other threads.
     */
    private val requests: MutableList<String> = CopyOnWriteArrayList()
    private val logged: MutableList<String> = CopyOnWriteArrayList()
    private val sink = Log.sink
    private val dir: Path = Files.createTempDirectory("dev-servers")

    /** Called with each line logged, as it is logged. */
    @Volatile private var onLogged: (String) -> Unit = {}

    @BeforeTest
    fun captureLog() {
        Log.sink = Log.Sink { _, tag, message, _ ->
            logged += "$tag: $message"
            onLogged(message)
        }
    }

    @AfterTest
    fun restore() {
        Log.sink = sink
        dir.toFile().deleteRecursively()
    }

    @Test
    fun aJellyfinUserSignsInOnAFirstProfileThatBindsAndItsLibrariesAreLogged() = session(DatabaseFactory.inMemory(), Secrets()) { app ->
        val signedIn = app.signInDevServers(listOf(server), DevEntry.MAIN).single()

        assertEquals(listOf("Movies", "Shows"), signedIn.libraries.map { it.title })
        assertEquals("machine-1/user-1", signedIn.connection.id)
        val profile = app.profiles.active.value
        assertTrue(profile is LocalProfile && profile.displayName == "maestro", "$profile")
        assertTrue(app.profiles.bindState.value.let { !it.binding && it.succeeded })
        assertTrue(app.servers.manager.isServerOnline(ServerId("machine-1")))
        assertEquals(1, requests.count { it == "POST /Users/AuthenticateByName" })
        assertTrue(logged.any { it.startsWith("DevServers: Test Jellyfin (") && it.endsWith("as maestro: libraries Movies, Shows") }, "$logged")
    }

    @Test
    fun `the demo tv pairs with a code and plays the version this app plays while casting to it`() {
        val launch = DevLaunch.parse(listOf("--dev", "--dev-setting", "cast.demo=receiver"))
        session(DatabaseFactory.inMemory(), Secrets(), app = { it.devAppSession(launch, Platform) { why -> error(why) } }) { app ->
            app.signInDevServers(listOf(server), DevEntry.MAIN)
            val sender = app.castSender
            sender.openPicker(fromPlayer = true)
            val tv = sender.state.first { state -> state.picker?.devices.orEmpty().any { it.device.name == "Demo TV" } }
                .picker!!.devices.single { it.device.name == "Demo TV" }.device
            sender.choose(tv.id)
            val pairing = sender.state.first { it.picker?.pairing != null }.picker!!.pairing!!
            assertTrue(pairing.code.length == 4 && pairing.code.all { it.isDigit() }, pairing.code)
            sender.state.first { it.status == CastLinkStatus.CONNECTED }

            app.play(PlayRequest.Item(ServerId("machine-1"), "item-1", mediaIndex = 1, mediaSourceId = "src-2", strictMediaSelection = true))
            assertEquals("Demo Movie", sender.state.first { it.nowPlaying != null }.nowPlaying!!.title)
            val cast = CastItem.Video("item-1", mediaIndex = 1, mediaSourceId = "src-2", strict = true)
            assertTrue(logged.any { it.startsWith("DevCastDemo: Demo TV plays $cast from ") }, "$logged")
            sender.togglePause()
            sender.state.first { it.nowPlaying?.paused == true }
        }
    }

    @Test
    fun `the demo phone asks this app to let it cast`() {
        val launch = DevLaunch.parse(listOf("--dev", "--dev-setting", "cast.demo=sender"))
        session(DatabaseFactory.inMemory(), Secrets(), app = { it.devAppSession(launch, Platform) { why -> error(why) } }) { app ->
            val prompt = app.castReceiver.state.first { it.prompt != null }.prompt!!
            assertEquals("Demo Phone", prompt.senderName)
            app.castReceiver.approve()
            app.castReceiver.state.first { it.prompt == null }
        }
    }

    @Test
    fun aKeptDatabaseUsesItsStoredConnectionWhileItsTokensAreHeldAndSignsInAgainWhenTheyAreGone() {
        val secrets = Secrets()
        session(DatabaseFactory(dir.resolve("plezy.db")), secrets) { app -> app.signInDevServers(listOf(server), DevEntry.MAIN) }
        requests.clear()

        session(DatabaseFactory(dir.resolve("plezy.db")), secrets) { app ->
            assertEquals(listOf("Movies", "Shows"), app.signInDevServers(listOf(server), DevEntry.MAIN).single().libraries.map { it.title })
            assertTrue(requests.none { it == "POST /Users/AuthenticateByName" }, "$requests")
        }

        // A development session's tokens live in memory: the next launch's are gone, so it signs in again.
        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app ->
            assertEquals(listOf("Movies", "Shows"), app.signInDevServers(listOf(server), DevEntry.MAIN).single().libraries.map { it.title })
            assertEquals(1, requests.count { it == "POST /Users/AuthenticateByName" })
            assertEquals(listOf("maestro"), app.profiles.profiles.value.map { it.displayName })
        }
    }

    @Test
    fun offlineAKeptDatabaseKeepsItsStoredConnectionWhoseTokensAreGone() {
        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app -> app.signInDevServers(listOf(server), DevEntry.MAIN) }
        requests.clear()
        offline = true

        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app ->
            app.graph.holdOffline(true)
            val kept = app.signInDevServers(listOf(server), DevEntry.MAIN).single()
            assertEquals("machine-1/user-1", kept.connection.id)
            assertEquals(emptyList(), kept.libraries)
            assertTrue(requests.isEmpty(), "$requests")
            assertEquals(listOf("maestro"), app.profiles.profiles.value.map { it.displayName })
        }
    }

    @Test
    fun offlineWithoutAStoredConnectionFailsTheLaunch() = session(DatabaseFactory.inMemory(), Secrets()) { app ->
        offline = true
        app.graph.holdOffline(true)
        val failure = runCatching { app.signInDevServers(listOf(server), DevEntry.MAIN) }.exceptionOrNull()
        assertTrue(failure is IllegalStateException && "no connection of its user is stored" in failure.message.orEmpty(), "$failure")
    }

    @Test
    fun aLaunchWhoseSignInFailsEndsTheLaunchRatherThanCrashingThroughTheGraphsScope() {
        val launch = DevLaunch.parse(listOf("--dev", "--dev-server", "jellyfin=maestro:secret@http://media.test:8096"))
        val failed = CompletableDeferred<String>()
        offline = true
        session(DatabaseFactory.inMemory(), Secrets(), app = { graph ->
            graph.holdOffline(true)
            graph.devAppSession(launch, Platform) { failed.complete(it) }
        }) {
            val reason = failed.await()
            assertTrue("no connection of its user is stored" in reason, reason)
            assertEquals(emptyList(), crashed.toList())
        }
    }

    @Test
    fun theDeviceGoingOfflineWhileTheSignedInProfileBindsKeepsTheConnection() = offlineOnceLogged { it.startsWith("Signed in as maestro") }

    @Test
    fun theDeviceGoingOfflineOnceTheProfileBoundKeepsTheConnectionWithoutLibraries() = offlineOnceLogged {
        it.startsWith("Bind of ") && !it.startsWith("Bind of null") && it.endsWith("success=true")
    }

    /**
     * The device held offline (a UI test's `offline=true`) as soon as a line [trigger] picks is logged, during the
     * sign-in: the session keeps the user's connection, as an offline start does, rather than failing the launch.
     */
    private fun offlineOnceLogged(trigger: (String) -> Boolean) = session(DatabaseFactory.inMemory(), Secrets()) { app ->
        onLogged = { message ->
            if (!offline && trigger(message)) {
                offline = true
                app.graph.holdOffline(true)
            }
        }
        val kept = app.signInDevServers(listOf(server), DevEntry.MAIN).single()

        assertTrue(offline, "the sign-in logged no line that took the device offline: $logged")
        assertEquals("machine-1/user-1", kept.connection.id)
        assertEquals(emptyList(), kept.libraries)
        assertEquals(listOf("maestro"), app.profiles.profiles.value.map { it.displayName })
    }

    @Test
    fun aRefusedSignInFailsTheLaunch() = session(DatabaseFactory.inMemory(), Secrets()) { app ->
        val wrong = DevServer(MediaBrowserDialect.JELLYFIN, "maestro", "wrong", "http://media.test:8096")
        val failure = runCatching { app.signInDevServers(listOf(wrong), DevEntry.MAIN) }.exceptionOrNull()
        assertTrue(failure != null && "Invalid username or password" in failure.message.orEmpty(), "$failure")
        assertEquals(null, app.profiles.active.value)
    }

    @Test
    fun askedForAProfileOnOpenAndEnteredAtBootTheSignInWaitsForThePickersPickThenBinds() {
        keepTwoProfilesAskingForOne()
        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app ->
            val waiting = CompletableDeferred<Unit>()
            onLogged = { if (it.startsWith("Signed in: the bind waits for the profile picker")) waiting.complete(Unit) }
            coroutineScope {
                val signIn = async { app.signInDevServers(listOf(server), DevEntry.BOOT) }
                waiting.await()
                assertEquals(BootRoute.PICK_PROFILE, app.profiles.bootRoute())
                assertTrue(signIn.isActive)
                assertTrue(!app.servers.manager.isServerOnline(ServerId("machine-1")))

                // The user picks maestro in the picker.
                val maestro = app.profiles.profiles.value.single { it.displayName == "maestro" }
                assertEquals(ProfileSwitchResult.SWITCHED, app.profiles.switchProfile(maestro) { _, _ -> null })
                assertEquals(listOf("Movies", "Shows"), signIn.await().single().libraries.map { it.title })
            }
            assertEquals(1, requests.count { it == "POST /Users/AuthenticateByName" })
        }
    }

    @Test
    fun askedForAProfileOnOpenAndEnteredAtMainTheSignInPicksTheActiveProfileItself() {
        keepTwoProfilesAskingForOne()
        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app ->
            assertEquals(listOf("Movies", "Shows"), app.signInDevServers(listOf(server), DevEntry.MAIN).single().libraries.map { it.title })
            assertEquals("maestro", app.profiles.active.value?.displayName)
            assertTrue(app.servers.manager.isServerOnline(ServerId("machine-1")))
        }
    }

    /** A kept database of two profiles, maestro (signed in, active) and Guest, with "ask for profile on app open" on. */
    private fun keepTwoProfilesAskingForOne() {
        session(DatabaseFactory(dir.resolve("plezy.db")), Secrets()) { app ->
            app.signInDevServers(listOf(server), DevEntry.MAIN)
            app.profiles.createLocalProfile("Guest")
            app.graph.data.deviceSettings.set(AppSettings.requireProfileSelectionOnOpen, true)
        }
        requests.clear()
    }

    /** Each exception that reached the session's scope: the app's failure boundary, which crashes a dev session. */
    private val crashed: MutableList<Throwable> = Collections.synchronizedList(mutableListOf())

    /**
     * A dev session's app ([app]'s, by default a bare one) on [database] and [secrets], talking to the fake Jellyfin,
     * closed after [block]. The app and [block] run on one thread, as an app and its UI share the main thread: the app's
     * state is confined to it. Its work is stopped and waited for before its database closes, so the next session on the
     * same file never meets a write of this one still holding the file's lock.
     */
    private fun session(
        database: DatabaseFactory,
        secrets: SecretStore,
        app: (AppGraph) -> AppSession = { AppSession(it, Platform) },
        block: suspend (AppSession) -> Unit,
    ) {
        val main = Dispatchers.Default.limitedParallelism(1)
        runBlocking(main) {
            val boundary = CoroutineExceptionHandler { _, e -> crashed += e }
            val scope = CoroutineScope(SupervisorJob() + main + boundary)
            val graph = AppGraph(database, secrets, BuildFlavor.SIDELOADED, "test", http = jellyfin(), scope = scope)
            val session = app(graph)
            try {
                withTimeout(30.seconds) { block(session) }
            } finally {
                session.close()
                scope.coroutineContext.job.cancelAndJoin()
                graph.close()
            }
        }
    }

    /** The fake Jellyfin unreachable, as a device without a network finds it. */
    @Volatile private var offline = false

    private fun jellyfin() = HttpClient(
        MockEngine { request ->
            if (offline) throw IOException("${request.url.host}: no network")
            requests += "${request.method.value} ${request.url.encodedPath}"
            val user = """{"Id":"user-1","Name":"maestro","Policy":{"IsAdministrator":true}}"""
            fun json(body: String) = respond(body, HttpStatusCode.OK, headersOf(HttpHeaders.ContentType, "application/json"))
            when (request.url.encodedPath) {
                "/System/Info/Public" -> json("""{"Id":"machine-1","ServerName":"Test Jellyfin","Version":"10.11.0","ProductName":"Jellyfin Server"}""")
                "/Users/AuthenticateByName" -> {
                    val body = (request.body as? TextContent)?.text.orEmpty()
                    if ("\"Pw\":\"secret\"" in body) json("""{"AccessToken":"token-1","User":$user}""") else respond("", HttpStatusCode.Unauthorized)
                }
                "/Users/user-1", "/Users/Me" -> json(user)
                "/Users/user-1/Views" -> json(
                    """{"Items":[{"Id":"lib-movies","Name":"Movies","CollectionType":"movies","Type":"CollectionFolder"},""" +
                        """{"Id":"lib-shows","Name":"Shows","CollectionType":"tvshows","Type":"CollectionFolder"}]}""",
                )
                else -> respond("", HttpStatusCode.NotFound)
            }
        },
    ) {
        install(HttpTimeout)
        expectSuccess = false
    }

    private class Secrets : SecretStore {
        private val entries = Collections.synchronizedMap(HashMap<String, ByteArray>())

        override suspend fun get(key: String): ByteArray? = entries[key]?.copyOf()

        override suspend fun put(key: String, value: ByteArray) {
            entries[key] = value.copyOf()
        }

        override suspend fun delete(key: String) {
            entries.remove(key)
        }

        override suspend fun deleteAll(prefix: String) {
            synchronized(entries) { entries.keys.removeAll { it.startsWith(prefix) } }
        }
    }

    /** A desktop that never plays: these tests only sign in. */
    private object Platform : AppPlatform {
        override val formFactor = FormFactor.DESKTOP
        override val device = DeviceIdentity(platform = "Linux", platformVersion = "6.1", deviceModel = "Linux", deviceName = "test-box", isTv = false)
        override val appleTv = false
        override val playerConfig = PlayerConfig.defaults(InputProfile.DESKTOP, doubleClickIntervalMillis = 500)

        override fun createPlayback(settings: DeviceSettings): PlatformPlayback = throw UnsupportedOperationException("no playback here")

        override fun createMusicAudioPlayer(): AudioPlayer = throw UnsupportedOperationException("no playback here")

        override fun setFullscreen(fullscreen: Boolean) {}

        override fun openUrl(url: String): Boolean = false

        override fun setClipboardText(text: String, sensitive: Boolean) {}

        override fun deviceFeatures() = DeviceFeatures(hardwareDecoding = false, hdr = false, matchFrameRate = false, audioPassthrough = false)

        override fun bundledTexts(folder: String): List<BundledText> = emptyList()

        override fun exit() {}
    }
}
