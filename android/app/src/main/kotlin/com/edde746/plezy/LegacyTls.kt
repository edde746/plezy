package com.edde746.plezy

import android.annotation.SuppressLint
import android.content.Context
import okhttp3.ConnectionSpec
import okhttp3.OkHttpClient
import java.security.KeyStore
import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

object LegacyTls {
    fun createClient(context: Context): OkHttpClient {
        val system = trustManager(null)
        val customStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply { load(null) }
        context.assets.open("flutter_assets/assets/ca/legacy-roots.pem").use { input ->
            val certificates = CertificateFactory.getInstance("X.509").generateCertificates(input)
            certificates.forEachIndexed { index, certificate ->
                customStore.setCertificateEntry("plezy-root-$index", certificate)
            }
        }
        val combined = CompositeTrustManager(system, trustManager(customStore))
        val sslContext = SSLContext.getInstance("TLS")
        sslContext.init(null, arrayOf(combined), null)
        return OkHttpClient.Builder()
            .sslSocketFactory(sslContext.socketFactory, combined)
            .connectionSpecs(listOf(ConnectionSpec.MODERN_TLS, ConnectionSpec.COMPATIBLE_TLS))
            .followRedirects(false)
            .followSslRedirects(false)
            .build()
    }

    private fun trustManager(keyStore: KeyStore?): X509TrustManager {
        val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        factory.init(keyStore)
        return factory.trustManagers.filterIsInstance<X509TrustManager>().first()
    }
}

@SuppressLint("CustomX509TrustManager")
private class CompositeTrustManager(
    private val system: X509TrustManager,
    private val bundled: X509TrustManager,
) : X509TrustManager {
    override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {
        system.checkClientTrusted(chain, authType)
    }

    override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {
        try {
            system.checkServerTrusted(chain, authType)
        } catch (systemError: CertificateException) {
            try {
                bundled.checkServerTrusted(chain, authType)
            } catch (_: CertificateException) {
                throw systemError
            }
        }
    }

    override fun getAcceptedIssuers(): Array<X509Certificate> =
        system.acceptedIssuers + bundled.acceptedIssuers
}
