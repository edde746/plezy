package com.edde746.plezy.backend.net

import io.ktor.client.engine.darwin.DarwinHttpRequestException
import platform.Foundation.NSURLErrorClientCertificateRejected
import platform.Foundation.NSURLErrorClientCertificateRequired
import platform.Foundation.NSURLErrorDomain
import platform.Foundation.NSURLErrorServerCertificateHasBadDate
import platform.Foundation.NSURLErrorServerCertificateHasUnknownRoot
import platform.Foundation.NSURLErrorServerCertificateNotYetValid
import platform.Foundation.NSURLErrorServerCertificateUntrusted

/**
 * URLSession: one of its certificate errors (an untrusted, expired or not yet valid server certificate, or a client
 * certificate the server asked for). A port that doesn't speak TLS fails as `NSURLErrorSecureConnectionFailed`, which
 * isn't one.
 */
internal actual fun isCertificateFailure(error: Throwable): Boolean = generateSequence(error) { it.cause }.any {
    it is DarwinHttpRequestException && it.origin.domain == NSURLErrorDomain && it.origin.code in CERTIFICATE_ERRORS
}

private val CERTIFICATE_ERRORS = setOf(
    NSURLErrorServerCertificateHasBadDate,
    NSURLErrorServerCertificateUntrusted,
    NSURLErrorServerCertificateHasUnknownRoot,
    NSURLErrorServerCertificateNotYetValid,
    NSURLErrorClientCertificateRejected,
    NSURLErrorClientCertificateRequired,
)
