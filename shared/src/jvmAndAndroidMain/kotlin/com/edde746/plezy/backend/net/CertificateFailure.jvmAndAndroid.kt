package com.edde746.plezy.backend.net

import java.security.cert.CertPathBuilderException
import java.security.cert.CertPathValidatorException
import java.security.cert.CertificateException
import javax.net.ssl.SSLPeerUnverifiedException

/**
 * OkHttp: the trust manager's verdict (a [CertificateException] or a failed certificate path, wrapped in the
 * handshake's exception) or a host name the certificate doesn't cover ([SSLPeerUnverifiedException]). A port that
 * doesn't speak TLS fails the handshake with neither.
 */
internal actual fun isCertificateFailure(error: Throwable): Boolean = generateSequence(error) { it.cause }.any {
    it is CertificateException || it is CertPathValidatorException || it is CertPathBuilderException || it is SSLPeerUnverifiedException
}
