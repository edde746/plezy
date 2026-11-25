package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.net.PlezyHttpClient
import io.ktor.client.engine.darwin.DarwinHttpRequestException
import io.ktor.network.selector.SelectorManager
import io.ktor.network.sockets.aSocket
import io.ktor.network.sockets.openWriteChannel
import io.ktor.network.sockets.port
import io.ktor.utils.io.writeStringUtf8
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import platform.Foundation.NSError
import platform.Foundation.NSURLErrorDomain
import platform.Foundation.NSURLErrorSecureConnectionFailed
import platform.Foundation.NSURLErrorServerCertificateUntrusted
import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** URLSession's TLS failures, as the HTTPS-first address policy reads them. */
class AppleTypedAddressTest {
    @Test
    fun aPlainHttpPortProbedOverHttpsCouldNotConnect() = runBlocking {
        val selector = SelectorManager(Dispatchers.IO)
        val server = aSocket(selector).tcp().bind("127.0.0.1", 0)
        val serving = launch(Dispatchers.IO) {
            while (true) {
                val socket = server.accept()
                launch {
                    socket.use {
                        val output = socket.openWriteChannel(autoFlush = true)
                        output.writeStringUtf8("HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
                        output.flushAndClose()
                    }
                }
            }
        }
        try {
            val client = MediaServerHttpClient(PlezyHttpClient.create("test"), "https://127.0.0.1:${server.port}")
            val error = assertFailsWith<MediaServerHttpException> { client.get("/System/Info/Public") }
            assertTrue(couldNotConnect(error), "$error")
        } finally {
            serving.cancel()
            server.close()
            selector.close()
        }
    }

    @Test
    fun anUntrustedCertificateIsACertificateFailureAndAFailedHandshakeIsNot() {
        fun failure(code: Long) = DarwinHttpRequestException(NSError.errorWithDomain(NSURLErrorDomain, code, null))
        assertTrue(isCertificateFailure(MediaServerHttpException.from(failure(NSURLErrorServerCertificateUntrusted))))
        assertFalse(couldNotConnect(failure(NSURLErrorServerCertificateUntrusted)))
        assertFalse(isCertificateFailure(failure(NSURLErrorSecureConnectionFailed)))
        assertTrue(couldNotConnect(failure(NSURLErrorSecureConnectionFailed)))
    }
}
