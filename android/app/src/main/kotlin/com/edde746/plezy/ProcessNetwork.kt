package com.edde746.plezy

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import com.edde746.plezy.app.AppBootstrap
import com.edde746.plezy.net.NetworkState

/**
 * The device's default network, for the whole process: one callback, registered as the process starts ([start]), so
 * the shared cores hear it with or without an activity. Every core the process has ([boots]: the product's, a debug
 * launch's dev session) gets each change ([AppBootstrap.onNetworkChanged]: offline states, Wi-Fi only downloads); one
 * built later is told the current state ([tell]). Main thread.
 */
internal class ProcessNetwork(context: Context, private val boots: () -> List<AppBootstrap>) {
    private val connectivity = context.getSystemService(ConnectivityManager::class.java)

    /** The default network now: from the system at [start], [NetworkState.ONLINE] before. */
    var state: NetworkState = NetworkState.ONLINE
        private set

    /** The default network the state is about; a lost network that isn't it (one replaced already) changes nothing. */
    private var current: Network? = null

    private val main = Handler(Looper.getMainLooper())

    // Registered without a Handler (that overload is API 26; this one API 24), so each callback comes on the system's
    // thread and moves to the main thread.
    private val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
            val state = capabilities.state()
            main.post {
                current = network
                report(state)
            }
        }

        override fun onLost(network: Network) {
            main.post {
                if (network == current) {
                    current = null
                    report(NetworkState.OFFLINE)
                }
            }
        }
    }

    /** Reads the default network and follows it from now on; its callbacks come on the main thread. */
    fun start() {
        val connectivity = connectivity ?: return
        val active = connectivity.activeNetwork
        current = active
        state = active?.let(connectivity::getNetworkCapabilities)?.state() ?: NetworkState.OFFLINE
        connectivity.registerDefaultNetworkCallback(callback)
    }

    /** [boot] was just built: it learns the network as it is. */
    fun tell(boot: AppBootstrap) {
        boot.onNetworkChanged(state.online, state.metered)
    }

    private fun report(state: NetworkState) {
        if (state == this.state) return
        this.state = state
        boots().forEach { it.onNetworkChanged(state.online, state.metered) }
    }

    private fun NetworkCapabilities.state() = NetworkState(
        online = hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET),
        metered = metered(link(), if (hasTransport(NetworkCapabilities.TRANSPORT_VPN)) others() else emptyList()),
    )

    // The device's networks besides the default; allNetworks is deprecated for callbacks, which a one-off read doesn't need.
    @Suppress("DEPRECATION")
    private fun others(): List<NetworkLink> = connectivity?.allNetworks.orEmpty().mapNotNull { connectivity?.getNetworkCapabilities(it)?.link() }

    private fun NetworkCapabilities.link() = NetworkLink(
        transports = TRANSPORTS.filterTo(mutableSetOf(), ::hasTransport),
        unmetered = hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED),
    )

    private companion object {
        val TRANSPORTS = listOf(
            NetworkCapabilities.TRANSPORT_CELLULAR,
            NetworkCapabilities.TRANSPORT_WIFI,
            NetworkCapabilities.TRANSPORT_ETHERNET,
            NetworkCapabilities.TRANSPORT_BLUETOOTH,
            NetworkCapabilities.TRANSPORT_VPN,
        )
    }
}

/** A network as [metered] reads it: its transports (`NetworkCapabilities.TRANSPORT_*`) and whether it is unmetered. */
internal class NetworkLink(val transports: Set<Int>, val unmetered: Boolean)

/**
 * Whether the [default] network costs per byte. A VPN counts as metered unless its app declares it unmetered, which many
 * VPN apps don't, whatever it runs over; it costs what the networks under it cost: those of [others] (the device's other
 * networks) that aren't VPNs and have a transport the VPN lists beside its own (a VPN over Wi-Fi lists Wi-Fi). A VPN with
 * none of them under it, or one metered, is metered.
 */
internal fun metered(default: NetworkLink, others: List<NetworkLink>): Boolean {
    if (default.unmetered) return false
    val vpn = NetworkCapabilities.TRANSPORT_VPN
    if (vpn !in default.transports) return true
    val under = others.filter { vpn !in it.transports && it.transports.any { t -> t in default.transports } }
    return under.isEmpty() || under.any { !it.unmetered }
}
