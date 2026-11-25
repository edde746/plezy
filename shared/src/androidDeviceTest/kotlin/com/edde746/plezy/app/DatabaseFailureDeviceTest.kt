package com.edde746.plezy.app

import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.crash.FailureBoundary
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.DatabaseFactory
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.secrets.MemorySecretStore
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import java.io.File
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** The start on Android's own driver, which opens the database at its first statement, against a real file. */
class DatabaseFailureDeviceTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val name = "failing-start-test.db"
    private val file: File = context.getDatabasePath(name)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default + FailureBoundary(crash = false))

    @Test
    fun aDatabaseThatCannotOpenShowsTheStartupFailureAndRetryStartsOnceItCan() = runBlocking {
        // A directory where the file goes: SQLite can't open it (a corrupt file would be replaced by the framework).
        file.mkdirs()
        val root = root()

        val failed = assertIs<RootScreen.Failed>(withTimeout(30.seconds) { root.screen.first { it !is RootScreen.Starting } })
        assertEquals(StartupPhase.DATABASE, failed.record.phase)

        file.deleteRecursively()
        root.retry()
        val main = assertIs<RootScreen.Main>(withTimeout(30.seconds) { root.screen.first { it is RootScreen.Main } })
        assertEquals(BootRoute.SIGN_IN, main.entry)
        root.close()
    }

    @Test
    fun orphanedSidecarsOfAMissingDatabaseDoNotStopTheStart() = runBlocking {
        file.parentFile?.mkdirs()
        File(file.path + "-wal").writeBytes(ByteArray(4096) { 0x5A })
        File(file.path + "-shm").writeBytes(ByteArray(32768) { 0x5A })
        val root = root()

        assertIs<RootScreen.Main>(withTimeout(30.seconds) { root.screen.first { it !is RootScreen.Starting } })
        root.close()
    }

    private fun root(): RootSession {
        val data = LocalData(DatabaseFactory.named(context, name))
        val graph = AppGraph(
            data = data,
            secrets = MemorySecretStore(),
            flavor = BuildFlavor.SIDELOADED,
            appVersion = "test",
            http = HttpClient(MockEngine { respond("", HttpStatusCode.NotFound) }),
            scope = CoroutineScope(scope.coroutineContext + Job(scope.coroutineContext[Job])),
            clock = kotlin.time.Clock.System,
            filesDirectory = context.cacheDir.path,
        )
        return RootSession(graph, FakeAppPlatform(), Startup(scope, Duration.ZERO))
    }

    @AfterTest
    fun cleanUp() {
        scope.cancel()
        file.deleteRecursively()
        context.deleteDatabase(name)
    }
}
