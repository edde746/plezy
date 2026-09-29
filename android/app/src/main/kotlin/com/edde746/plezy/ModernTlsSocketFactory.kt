package com.edde746.plezy

import java.net.InetAddress
import java.net.Socket
import javax.net.ssl.SSLException
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory

/** Keep the provider's socket (including SNI support), enabling TLS 1.2 on KitKat. */
internal class ModernTlsSocketFactory(private val delegate: SSLSocketFactory) : SSLSocketFactory() {
    private fun configure(socket: Socket): Socket {
        val ssl = socket as SSLSocket
        val enabled = ssl.supportedProtocols.filter { it == "TLSv1.2" || it == "TLSv1.3" }
        if (enabled.isEmpty()) {
            ssl.close()
            throw SSLException("TLS 1.2 is unavailable on this security provider")
        }
        ssl.enabledProtocols = enabled.toTypedArray()
        return ssl
    }

    override fun getDefaultCipherSuites(): Array<String> = delegate.defaultCipherSuites
    override fun getSupportedCipherSuites(): Array<String> = delegate.supportedCipherSuites
    override fun createSocket(): Socket = configure(delegate.createSocket())
    override fun createSocket(s: Socket, host: String, port: Int, autoClose: Boolean): Socket =
        configure(delegate.createSocket(s, host, port, autoClose))
    override fun createSocket(host: String, port: Int): Socket =
        configure(delegate.createSocket(host, port))
    override fun createSocket(host: String, port: Int, local: InetAddress, localPort: Int): Socket =
        configure(delegate.createSocket(host, port, local, localPort))
    override fun createSocket(host: InetAddress, port: Int): Socket =
        configure(delegate.createSocket(host, port))
    override fun createSocket(host: InetAddress, port: Int, local: InetAddress, localPort: Int): Socket =
        configure(delegate.createSocket(host, port, local, localPort))
}
