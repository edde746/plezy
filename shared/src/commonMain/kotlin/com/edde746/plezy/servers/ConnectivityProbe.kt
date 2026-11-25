package com.edde746.plezy.servers

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.NetworkState
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.retryWhen
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** A kind of network link the platform reports. */
enum class ConnectivityLink { WIFI, ETHERNET, MOBILE, VPN, BLUETOOTH, OTHER, NONE }

/**
 * One connectivity report: the links that are up, in the order the platform listed them. Empty: nothing reported yet.
 *
 * The link-type answers are the app's one definition of a metered connection (the cellular playback default, the
 * Wi-Fi-only download gate, the sync-rule cooldown). Wi-Fi and Ethernet count as unmetered; a metered Wi-Fi hotspot
 * breaks that, and no platform tells the two apart.
 */
data class Connectivity(val links: Set<ConnectivityLink>) {
    /** Some network is up: [ConnectivityLink.NONE] is not reported. An empty report counts as connected. */
    val hasNetwork: Boolean get() = ConnectivityLink.NONE !in links

    val hasWifiOrEthernet: Boolean get() = ConnectivityLink.WIFI in links || ConnectivityLink.ETHERNET in links

    /** Cellular is the only link. An empty or unknown report is not, so callers keep their unmetered behaviour. */
    val isCellularOnly: Boolean get() = ConnectivityLink.MOBILE in links && !hasWifiOrEthernet

    companion object {
        val NOT_REPORTED: Connectivity = Connectivity(emptySet())

        /** The platform could not answer: neither "no network" nor a metered link, so the app assumes online. */
        val UNKNOWN: Connectivity = Connectivity(setOf(ConnectivityLink.OTHER))

        fun of(vararg links: ConnectivityLink): Connectivity = Connectivity(links.toSet())
    }
}

/** Where the platform's connectivity comes from. */
interface ConnectivitySource {
    suspend fun current(): Connectivity

    /** Every later report. */
    val changes: Flow<Connectivity>
}

/**
 * The connectivity the platform reports to [com.edde746.plezy.app.AppGraph.network]. [NetworkState] carries no link
 * type: an unmetered network reads as Wi-Fi and a metered one as cellular, which is how every consumer reads a link.
 */
class NetworkStateConnectivitySource(private val network: StateFlow<NetworkState>) : ConnectivitySource {
    override suspend fun current(): Connectivity = network.value.toConnectivity()

    override val changes: Flow<Connectivity> = network.drop(1).map { it.toConnectivity() }
}

fun NetworkState.toConnectivity(): Connectivity = when {
    !online -> Connectivity.of(ConnectivityLink.NONE)
    metered -> Connectivity.of(ConnectivityLink.MOBILE)
    else -> Connectivity.of(ConnectivityLink.WIFI)
}

/**
 * The app's one view of [source]: a source that hangs or fails reads as [Connectivity.UNKNOWN] (assume online) instead
 * of failing its caller. The first failure is logged as a warning, later ones at debug.
 */
class ConnectivityProbe(private val source: ConnectivitySource) {
    private var warned = false

    /** The current connectivity, or [Connectivity.UNKNOWN] when [source] fails or does not answer within [timeout]. */
    suspend fun check(timeout: Duration = 3.seconds): Connectivity = try {
        withTimeoutOrNull(timeout) { source.current() } ?: Connectivity.UNKNOWN
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        warnOnce(e)
        Connectivity.UNKNOWN
    }

    /**
     * Connectivity changes. A failing [source] is logged and subscribed to again after [RESUBSCRIBE_DELAY]; its error
     * never reaches the collector.
     */
    val changes: Flow<Connectivity> = source.changes.retryWhen { cause, _ ->
        if (cause is CancellationException) return@retryWhen false
        warnOnce(cause)
        delay(RESUBSCRIBE_DELAY)
        true
    }

    private fun warnOnce(error: Throwable) {
        if (warned) {
            Log.d(TAG, error) { "Connectivity probe unavailable; assuming online" }
            return
        }
        warned = true
        Log.w(TAG, error) { "Connectivity probe unavailable; assuming online" }
    }

    companion object {
        val RESUBSCRIBE_DELAY: Duration = 5.seconds
        private const val TAG = "ConnectivityProbe"
    }
}
