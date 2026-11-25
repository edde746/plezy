package com.edde746.plezy.net

/**
 * The device's network as the platform reports it ([com.edde746.plezy.app.AppBootstrap.onNetworkChanged]): Home,
 * Discover and Search show an offline state without it, downloads hold back on a [metered] one with Wi-Fi only on.
 *
 * @param online some network is up that may reach the internet.
 * @param metered the network costs per byte (cellular, a hotspot, a constrained or expensive path).
 */
data class NetworkState(val online: Boolean, val metered: Boolean) {
    companion object {
        /** Until the platform reports otherwise (and on desktop, which assumes an unmetered network). */
        val ONLINE: NetworkState = NetworkState(online = true, metered = false)
        val OFFLINE: NetworkState = NetworkState(online = false, metered = false)
    }
}
