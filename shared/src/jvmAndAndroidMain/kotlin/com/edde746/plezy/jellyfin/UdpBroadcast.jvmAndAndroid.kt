package com.edde746.plezy.jellyfin

import com.edde746.plezy.log.Log
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.SocketException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Each socket's receiver blocks until the socket closes: [listenMillis] after the second send, however late that went
 * out, or on cancellation. A receiver that starts late still reads the replies queued before it started.
 * A loopback [host] gets one socket bound to that address: the system may give a wildcard socket the port of a socket
 * bound to the loopback address (macOS does), which would then take the replies.
 */
internal actual suspend fun udpBroadcastExchange(
    payload: ByteArray,
    host: String,
    port: Int,
    repeatDelayMillis: Long,
    listenMillis: Long,
    onDatagram: (ByteArray) -> Unit,
) {
    val target = InetAddress.getByName(host)
    val sockets = if (target.isLoopbackAddress) listOfNotNull(runCatching { open(InetSocketAddress(target, 0)) }.getOrNull()) else bindPerInterface()
    if (sockets.isEmpty()) return
    coroutineScope {
        for (socket in sockets) {
            launch(Dispatchers.IO) {
                val buffer = ByteArray(8192)
                while (true) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    try {
                        socket.receive(packet)
                    } catch (e: SocketException) {
                        if (!socket.isClosed) Log.w(TAG, e) { "UDP receive failed" }
                        break
                    }
                    val data = packet.data.copyOfRange(packet.offset, packet.offset + packet.length)
                    synchronized(sockets) { onDatagram(data) }
                }
            }
        }
        try {
            sendAll(sockets, payload, target, port)
            delay(repeatDelayMillis)
            sendAll(sockets, payload, target, port)
            delay(listenMillis)
        } finally {
            sockets.forEach { it.close() }
        }
    }
}

private fun sendAll(sockets: List<DatagramSocket>, payload: ByteArray, target: InetAddress, port: Int) {
    for (socket in sockets) {
        try {
            socket.send(DatagramPacket(payload, payload.size, target, port))
        } catch (e: Exception) {
            Log.w(TAG, e) { "UDP broadcast send failed" }
        }
    }
}

/** One socket per up, non-loopback IPv4 address; the wildcard address when none binds. */
private fun bindPerInterface(): List<DatagramSocket> {
    val addresses = runCatching {
        NetworkInterface.getNetworkInterfaces().toList()
            .filter { runCatching { it.isUp && !it.isLoopback }.getOrDefault(false) }
            .flatMap { it.inetAddresses.toList() }
            .filterIsInstance<Inet4Address>()
    }.getOrDefault(emptyList())
    val sockets = addresses.mapNotNull { address -> runCatching { open(InetSocketAddress(address, 0)) }.getOrNull() }
    return sockets.ifEmpty { listOfNotNull(runCatching { open(InetSocketAddress(0)) }.getOrNull()) }
}

private fun open(address: InetSocketAddress) = DatagramSocket(null as java.net.SocketAddress?).apply {
    broadcast = true
    reuseAddress = true
    bind(address)
}

private const val TAG = "JellyfinLanDiscovery"
