package com.edde746.plezy

import okhttp3.Call
import okhttp3.EventListener
import okhttp3.Handshake
import okhttp3.Response
import java.io.IOException
import java.net.InetAddress
import java.net.UnknownHostException
import java.net.ConnectException
import java.net.SocketTimeoutException
import javax.net.ssl.SSLException

/** Never record request URLs, headers, addresses, server names, or response bodies. */
internal class PlaybackDiagnostics : EventListener() {
    private val lines = ArrayDeque<String>()

    @Synchronized fun add(message: String) {
        if (lines.size >= 32) lines.removeFirst()
        lines.addLast(message.take(700))
    }

    @Synchronized fun snapshot(): ArrayList<String> = ArrayList(lines)

    override fun dnsStart(call: Call, domainName: String) = add("Network: resolving server")
    override fun dnsEnd(call: Call, domainName: String, inetAddressList: List<InetAddress>) =
        add("Network: DNS returned ${inetAddressList.size} addresses")
    override fun secureConnectStart(call: Call) = add("Network: TLS handshake started")
    override fun secureConnectEnd(call: Call, handshake: Handshake?) =
        add("Network: TLS verified (${handshake?.tlsVersion()?.javaName() ?: "unknown"})")
    override fun responseHeadersEnd(call: Call, response: Response) =
        add("Network: HTTP ${response.code()}")
    override fun callFailed(call: Call, ioe: IOException) = add("Network failed: ${describe(ioe)}")

    companion object {
        fun causes(error: Throwable): List<Throwable> {
            val result = mutableListOf<Throwable>()
            var current: Throwable? = error
            while (current != null && result.size < 10 && result.none { it === current }) {
                result.add(current)
                current = current.cause
            }
            return result
        }

        fun isConnectionFailure(error: Throwable): Boolean = causes(error).any {
            it is SSLException || it is UnknownHostException || it is ConnectException ||
                it is SocketTimeoutException
        }

        fun describe(error: Throwable): String = causes(error).joinToString(" -> ") {
            // Class names are enough to distinguish TLS, DNS, timeout and socket causes.
            // Exception messages can contain tokens, URLs, IPs or server-returned content.
            it.javaClass.simpleName
        }
    }
}
