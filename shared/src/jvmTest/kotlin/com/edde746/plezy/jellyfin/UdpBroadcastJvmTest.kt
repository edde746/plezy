package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.MediaBrowserDialect
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import kotlin.concurrent.thread
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

class UdpBroadcastJvmTest {
    /**
     * A loopback server answering the discovery payload the way Jellyfin does, received through the exchange. The
     * exchange is stopped once both replies are in, so a slow machine only makes the test slower; the window is a guard.
     */
    @Test fun exchangeDeliversRepliesToTheSentPayload() = runBlocking {
        val server = DatagramSocket(0, InetAddress.getLoopbackAddress())
        val responder = thread {
            val buf = ByteArray(1024)
            repeat(2) {
                val packet = DatagramPacket(buf, buf.size)
                server.receive(packet)
                val text = String(packet.data, 0, packet.length)
                val reply = """{"Address":"http://127.0.0.1:8096","Id":"id-$it","Name":"$text"}""".toByteArray()
                server.send(DatagramPacket(reply, reply.size, packet.socketAddress))
            }
        }
        val received = mutableListOf<String>()
        launch {
            udpBroadcastExchange("who is JellyfinServer?".toByteArray(), "127.0.0.1", server.localPort, 50, 30_000) {
                received += it.decodeToString()
                if (received.size == 2) this@launch.cancel()
            }
        }.join()
        server.close()
        responder.join()
        val parsed = received.mapNotNull { JellyfinLanDiscovery.parseResponse(it.encodeToByteArray(), MediaBrowserDialect.JELLYFIN) }
        assertEquals(setOf("who is JellyfinServer?"), parsed.map { it.name }.toSet())
    }
}
