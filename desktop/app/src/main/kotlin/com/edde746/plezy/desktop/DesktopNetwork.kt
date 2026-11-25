package com.edde746.plezy.desktop

import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ProtocolFamily
import java.net.StandardProtocolFamily
import java.nio.channels.DatagramChannel

/**
 * Whether the computer is online, for [com.edde746.plezy.app.AppBootstrap.onNetworkChanged]: checked every few
 * seconds on a daemon thread, online while the system has a route out to the internet, for IPv4 or IPv6. Each check
 * connects a UDP socket to a documentation address (192.0.2.1, 2001:db8::1), which sends nothing: the OS only picks
 * the route, and refuses when there is none (a default route is the usual one). So an adapter that is up with an
 * address but no way out, as Hyper-V's and WSL's vEthernet, Docker's and VMware's are, doesn't keep the app online with
 * the network gone. [report] hears the first answer and each change, on that thread. The desktop can't tell a metered
 * network, so it reports none.
 */
internal class DesktopNetwork(private val report: (online: Boolean) -> Unit) : AutoCloseable {
    @Volatile
    private var running = true

    private val thread = Thread(::watch, "network-monitor").apply { isDaemon = true }

    fun start() {
        thread.start()
    }

    override fun close() {
        running = false
        thread.interrupt()
    }

    private fun watch() {
        var last: Boolean? = null
        while (running) {
            val online = online()
            if (online != last) {
                last = online
                report(online)
            }
            try {
                Thread.sleep(INTERVAL_MILLIS)
            } catch (_: InterruptedException) {
                return
            }
        }
    }

    private companion object {
        const val INTERVAL_MILLIS = 5_000L
        const val DISCARD_PORT = 9
        val PROBES: List<Pair<ProtocolFamily, InetAddress>> = listOf(
            StandardProtocolFamily.INET to InetAddress.getByName("192.0.2.1"),
            StandardProtocolFamily.INET6 to InetAddress.getByName("2001:db8::1"),
        )

        fun online(): Boolean = PROBES.any { (family, address) -> routeTo(family, address) }

        /**
         * Whether the OS has a route to [address]; false also where it has no [family] at all, and true when no socket
         * opens to ask (can't tell: the app goes on as online, and requests fail on their own when it isn't).
         */
        fun routeTo(family: ProtocolFamily, address: InetAddress): Boolean {
            val channel = try {
                DatagramChannel.open(family)
            } catch (_: UnsupportedOperationException) {
                return false // No IPv6 on this computer.
            } catch (_: IOException) {
                return true
            }
            return channel.use {
                try {
                    it.connect(InetSocketAddress(address, DISCARD_PORT))
                    true
                } catch (_: IOException) {
                    false // No route: "Network is unreachable".
                }
            }
        }
    }
}
