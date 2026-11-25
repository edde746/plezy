package com.edde746.plezy.jellyfin

import com.edde746.plezy.log.Log
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.sizeOf
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import platform.posix.AF_INET
import platform.posix.IPPROTO_UDP
import platform.posix.POLLIN
import platform.posix.SOCK_DGRAM
import platform.posix.SOL_SOCKET
import platform.posix.SO_BROADCAST
import platform.posix.close
import platform.posix.poll
import platform.posix.pollfd
import platform.posix.recv
import platform.posix.sendto
import platform.posix.setsockopt
import platform.posix.sockaddr_in
import platform.posix.socket
import kotlinx.cinterop.IntVar
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.TimeSource
import kotlinx.coroutines.ensureActive

/**
 * BSD sockets: one broadcast-enabled socket on the wildcard address (the system routes the limited broadcast out of
 * the primary interface). iOS and macOS ask for local network permission on the first send
 * (`NSLocalNetworkUsageDescription`).
 */
@OptIn(ExperimentalForeignApi::class)
internal actual suspend fun udpBroadcastExchange(
    payload: ByteArray,
    host: String,
    port: Int,
    repeatDelayMillis: Long,
    listenMillis: Long,
    onDatagram: (ByteArray) -> Unit,
) {
    val fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    if (fd < 0) {
        Log.w(TAG) { "UDP socket failed" }
        return
    }
    try {
        memScoped {
            val on = alloc<IntVar>().apply { value = 1 }
            setsockopt(fd, SOL_SOCKET, SO_BROADCAST, on.ptr, sizeOf<IntVar>().convert())
        }
        fun send() = memScoped {
            val address = alloc<sockaddr_in>().apply {
                sin_family = AF_INET.convert()
                sin_port = networkOrder(port.toUShort())
                sin_addr.s_addr = ipv4NetworkOrder(host)
            }
            val sent = payload.usePinned {
                sendto(fd, it.addressOf(0), payload.size.convert(), 0, address.ptr.reinterpret(), sizeOf<sockaddr_in>().convert())
            }
            if (sent < 0) Log.w(TAG) { "UDP broadcast send failed" }
        }
        send()
        delay(repeatDelayMillis)
        send()
        val end = TimeSource.Monotonic.markNow() + listenMillis.milliseconds
        withContext(Dispatchers.IO) {
            val buffer = ByteArray(8192)
            while (true) {
                ensureActive()
                val remaining = -end.elapsedNow().inWholeMilliseconds
                if (remaining <= 0) break
                val ready = memScoped {
                    val p = alloc<pollfd>().apply { this.fd = fd; events = POLLIN.convert() }
                    poll(p.ptr, 1u, remaining.toInt().coerceAtMost(200))
                }
                if (ready < 0) break
                if (ready == 0) continue
                val n = buffer.usePinned { recv(fd, it.addressOf(0), buffer.size.convert(), 0) }
                if (n > 0) onDatagram(buffer.copyOf(n.toInt()))
            }
        }
    } finally {
        close(fd)
    }
}

/** [port] in network byte order (Apple's arm64 is little-endian; `htons` is a C macro Kotlin can't see). */
private fun networkOrder(port: UShort): UShort = (((port.toInt() and 0xFF) shl 8) or ((port.toInt() shr 8) and 0xFF)).toUShort()

/** A dotted IPv4 address as `in_addr.s_addr`: its bytes in written order. */
private fun ipv4NetworkOrder(host: String): UInt {
    val parts = host.split('.').map { it.toUInt() }
    require(parts.size == 4 && parts.all { it <= 255u }) { "Not an IPv4 address" }
    return parts[0] or (parts[1] shl 8) or (parts[2] shl 16) or (parts[3] shl 24)
}

private const val TAG = "JellyfinLanDiscovery"
