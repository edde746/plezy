@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.NetworkState
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class ConnectivityProbeTest {
    private class Record(val level: Log.Level, val error: String?)

    private val records = mutableListOf<Record>()
    private val previousSink = Log.sink
    private val previousLevel = Log.minLevel

    @BeforeTest
    fun captureLogs() {
        Log.sink = Log.Sink { level, tag, _, error -> if (tag == "ConnectivityProbe") records += Record(level, error) }
        Log.minLevel = Log.Level.DEBUG
    }

    @AfterTest
    fun restoreLogs() {
        Log.sink = previousSink
        Log.minLevel = previousLevel
    }

    private fun logs(level: Log.Level) = records.filter { it.level == level }

    private class FakeSource(
        val answer: suspend () -> Connectivity = { Connectivity.of(ConnectivityLink.WIFI) },
        override val changes: Flow<Connectivity> = MutableSharedFlow(),
    ) : ConnectivitySource {
        override suspend fun current(): Connectivity = answer()
    }

    @Test
    fun aFailingPlatformResolvesToUnknown() = runTest {
        val probe = ConnectivityProbe(FakeSource(answer = { throw IllegalStateException("no system bus") }))

        assertEquals(Connectivity.UNKNOWN, probe.check())
        assertTrue(logs(Log.Level.WARN).single().error.orEmpty().contains("no system bus"))
    }

    @Test
    fun aHungPlatformResolvesToUnknownAtTheTimeout() = runTest {
        val probe = ConnectivityProbe(FakeSource(answer = { awaitCancellation() }))

        val result = async { probe.check() }
        advanceTimeBy(3.seconds - 1.milliseconds)
        runCurrent()
        assertFalse(result.isCompleted)
        advanceTimeBy(1.milliseconds)
        runCurrent()

        assertEquals(Connectivity.UNKNOWN, result.await())
    }

    @Test
    fun aWorkingPlatformAnswersAsItReports() = runTest {
        val probe = ConnectivityProbe(FakeSource(answer = { Connectivity.of(ConnectivityLink.MOBILE) }))

        assertEquals(Connectivity.of(ConnectivityLink.MOBILE), probe.check())
        assertTrue(records.isEmpty())
    }

    @Test
    fun onlyTheFirstFailureWarns() = runTest {
        val probe = ConnectivityProbe(FakeSource(answer = { throw IllegalStateException("NetworkManager::StartListen") }))

        repeat(3) { assertEquals(Connectivity.UNKNOWN, probe.check()) }

        assertEquals(1, logs(Log.Level.WARN).size)
        assertEquals(2, logs(Log.Level.DEBUG).size)
    }

    @Test
    fun aChangeStreamFailingAtSubscriptionIsContainedAndLaterReportsStillArrive() = runTest {
        val reports = MutableSharedFlow<Connectivity>()
        var subscriptions = 0
        val probe = ConnectivityProbe(
            FakeSource(
                changes = flow {
                    if (subscriptions++ == 0) throw IllegalStateException("ServiceUnknown")
                    emitAll(reports)
                },
            ),
        )
        val received = mutableListOf<Connectivity>()
        val collector = backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { probe.changes.collect { received += it } }

        advanceTimeBy(ConnectivityProbe.RESUBSCRIBE_DELAY)
        runCurrent()
        reports.emit(Connectivity.of(ConnectivityLink.WIFI))
        runCurrent()

        assertTrue(logs(Log.Level.WARN).single().error.orEmpty().contains("ServiceUnknown"))
        assertEquals(listOf(Connectivity.of(ConnectivityLink.WIFI)), received)
        assertFalse(collector.isCompleted)
    }

    @Test
    fun changeStreamErrorsAreLoggedNotForwarded() = runTest {
        var subscriptions = 0
        val probe = ConnectivityProbe(
            FakeSource(
                changes = flow {
                    if (subscriptions++ > 0) awaitCancellation()
                    emit(Connectivity.of(ConnectivityLink.MOBILE))
                    throw IllegalStateException("listener failed")
                },
            ),
        )
        val received = mutableListOf<Connectivity>()
        val collector = backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { probe.changes.collect { received += it } }

        advanceTimeBy(ConnectivityProbe.RESUBSCRIBE_DELAY)
        runCurrent()

        assertEquals(listOf(Connectivity.of(ConnectivityLink.MOBILE)), received)
        assertFalse(collector.isCancelled, "the error never reached the collector")
        assertEquals(1, logs(Log.Level.WARN).size)
    }

    // Link types.

    @Test
    fun cellularAloneIsTheOnlyMeteredCase() {
        val cellular = Connectivity.of(ConnectivityLink.MOBILE)
        assertTrue(cellular.isCellularOnly)
        assertFalse(cellular.hasWifiOrEthernet)
    }

    @Test
    fun anyWifiOrEthernetLinkAlongsideCellularWins() {
        for (unmetered in listOf(ConnectivityLink.WIFI, ConnectivityLink.ETHERNET)) {
            val links = Connectivity.of(ConnectivityLink.MOBILE, unmetered)
            assertFalse(links.isCellularOnly, "$unmetered outranks cellular")
            assertTrue(links.hasWifiOrEthernet)
        }
    }

    @Test
    fun anUnknownReportIsNeitherMeteredNorUnmetered() {
        // The Wi-Fi-only download gate and the cellular playback default rely on this.
        assertFalse(Connectivity.NOT_REPORTED.isCellularOnly)
        assertFalse(Connectivity.NOT_REPORTED.hasWifiOrEthernet)
        assertFalse(Connectivity.of(ConnectivityLink.NONE).isCellularOnly)
        assertFalse(Connectivity.UNKNOWN.isCellularOnly)
        assertTrue(Connectivity.UNKNOWN.hasNetwork, "unknown assumes online")
    }

    @Test
    fun aWifiOnlyLinkIsUnmetered() {
        val wifi = Connectivity.of(ConnectivityLink.WIFI)
        assertTrue(wifi.hasWifiOrEthernet)
        assertFalse(wifi.isCellularOnly)
    }

    @Test
    fun theReportedNetworkStateReadsAsTheLinkItImplies() {
        assertFalse(NetworkState.OFFLINE.toConnectivity().hasNetwork)
        assertTrue(NetworkState(online = true, metered = true).toConnectivity().isCellularOnly)
        val unmetered = NetworkState.ONLINE.toConnectivity()
        assertTrue(unmetered.hasNetwork)
        assertTrue(unmetered.hasWifiOrEthernet)
    }
}
