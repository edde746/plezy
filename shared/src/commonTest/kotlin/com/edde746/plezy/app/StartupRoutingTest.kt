package com.edde746.plezy.app

import app.cash.sqldelight.db.QueryResult
import app.cash.sqldelight.db.SqlCursor
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.db.SqlPreparedStatement
import com.edde746.plezy.crash.FailureBoundary
import com.edde746.plezy.crash.StartupPhase
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.presentation.navigation.Route
import com.edde746.plezy.profiles.BootRoute
import com.edde746.plezy.secrets.MemorySecretStore
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpStatusCode
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class StartupRoutingTest {
    @Test
    fun aDatabaseThatFailsToOpenShowsTheStartupFailureAndRetryStartsAgain() = runTest {
        val driver = FailingDriver { true }
        val graph = graph(driver)
        val startup = Startup(backgroundScope, Duration.ZERO)
        val root = RootSession(graph, FakeAppPlatform(), startup)
        runCurrent()

        val failed = assertIs<RootScreen.Failed>(root.screen.value)
        assertEquals(StartupPhase.DATABASE, failed.record.phase)
        assertEquals(failed.record, graph.startupFailures.pending)
        assertEquals(StartupUiState(null, null), startup.state.value)

        driver.failing = { false }
        root.retry()
        runCurrent()
        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.SIGN_IN, main.entry)
        root.close()
    }

    @Test
    fun aSettingThatCanNotBeReadAfterTheOpenShowsTheStartupFailureAndRetryStartsAgain() = runTest {
        // The open succeeds; the stored settings' reads after it fail.
        val driver = FailingDriver { sql -> "FROM device_setting" in sql }
        val graph = graph(driver)
        val startup = Startup(backgroundScope, Duration.ZERO)
        val root = RootSession(graph, FakeAppPlatform(), startup)
        runCurrent()

        val failed = assertIs<RootScreen.Failed>(root.screen.value)
        assertEquals(StartupPhase.PREFERENCES, failed.record.phase)
        assertEquals(failed.record, graph.startupFailures.pending)
        assertEquals(StartupUiState(null, null), startup.state.value)

        driver.failing = { false }
        root.retry()
        runCurrent()
        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.SIGN_IN, main.entry)
        root.close()
    }

    @Test
    fun aFailureLoadingTheConnectionsGoesToTheSignInInsteadOfLeavingTheSplash() = runTest {
        val driver = FailingDriver { sql -> "connections" in sql }
        val root = RootSession(graph(driver), FakeAppPlatform(), Startup(backgroundScope, Duration.ZERO))
        runCurrent()

        val main = assertIs<RootScreen.Main>(root.screen.value)
        assertEquals(BootRoute.SIGN_IN, main.entry)
        assertEquals(listOf<Route>(Route.SignIn), main.app.navigator.backStack.value)
        root.close()
    }

    @Test
    fun withoutANetworkTheStartupBindCountsOnlyUpToTheCap() = runTest {
        val never = CompletableDeferred<Boolean>()
        val capped = async { awaitStartupBindSettle(hasNetwork = false) { never.await() } }
        val waiting = async { awaitStartupBindSettle(hasNetwork = true) { never.await() } }

        advanceTimeBy(NO_NETWORK_STARTUP_BIND - 1.milliseconds)
        assertFalse(capped.isCompleted)
        advanceTimeBy(2.milliseconds)
        assertTrue(capped.isCompleted)
        assertFalse(capped.await(), "a timeout counts as a failed bind")

        advanceTimeBy(60.seconds)
        assertFalse(waiting.isCompleted, "with a network the bind's outcome waits however long it takes")
        never.complete(true)
        assertTrue(waiting.await())
    }

    @Test
    fun aBindThatSettlesInTimeWithoutANetworkKeepsItsOutcome() = runTest {
        assertTrue(awaitStartupBindSettle(hasNetwork = false) { true })
    }

    @Test
    fun theAppStartsOfflineOnlyWhenTheBindFailedWithNoServerOnline() {
        assertTrue(shouldStartOffline(bindingSucceeded = false, hasOnlineServers = false))
        assertFalse(shouldStartOffline(bindingSucceeded = false, hasOnlineServers = true))
        assertFalse(shouldStartOffline(bindingSucceeded = true, hasOnlineServers = false))
        assertFalse(shouldStartOffline(bindingSucceeded = true, hasOnlineServers = true))
    }

    /** A graph on [driver]'s database whose failures are reported, as the product's are, and whose record is its own. */
    private fun TestScope.graph(driver: FailingDriver): AppGraph {
        val clock = TestClock()
        val data = LocalData({ schema -> driver.open(inMemoryDatabase().createDriver(schema)) }, { clock.now }, StandardTestDispatcher(testScheduler), {}, null)
        val files = Path(SystemTemporaryDirectory, "plezy-startup-routing-${Random.nextLong().toULong()}")
        SystemFileSystem.createDirectories(files)
        return AppGraph(
            data = data,
            secrets = MemorySecretStore(),
            flavor = BuildFlavor.SIDELOADED,
            appVersion = "test",
            http = HttpClient(MockEngine { respond("", HttpStatusCode.NotFound) }),
            scope = CoroutineScope(backgroundScope.coroutineContext + Job(backgroundScope.coroutineContext[Job]) + FailureBoundary(crash = false)),
            clock = kotlin.time.Clock.System,
            filesDirectory = files.toString(),
            requestDispatcher = StandardTestDispatcher(testScheduler),
            timeSource = testScheduler.timeSource,
        )
    }
}

/** A database whose statements fail ("database is locked") while [failing] says so of their SQL. */
private class FailingDriver(var failing: (String) -> Boolean) {
    fun open(driver: SqlDriver): SqlDriver = object : SqlDriver by driver {
        override fun <R> executeQuery(
            identifier: Int?,
            sql: String,
            mapper: (SqlCursor) -> QueryResult<R>,
            parameters: Int,
            binders: (SqlPreparedStatement.() -> Unit)?,
        ): QueryResult<R> {
            check(!failing(sql)) { "database is locked" }
            return driver.executeQuery(identifier, sql, mapper, parameters, binders)
        }

        override fun execute(identifier: Int?, sql: String, parameters: Int, binders: (SqlPreparedStatement.() -> Unit)?): QueryResult<Long> {
            check(!failing(sql)) { "database is locked" }
            return driver.execute(identifier, sql, parameters, binders)
        }
    }
}
