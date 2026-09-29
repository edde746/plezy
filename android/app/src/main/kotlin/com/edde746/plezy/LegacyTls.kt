package com.edde746.plezy

import android.annotation.SuppressLint
import android.content.Context
import okhttp3.ConnectionSpec
import okhttp3.OkHttpClient
import okhttp3.EventListener
import okhttp3.TlsVersion
import java.util.concurrent.TimeUnit
import java.security.KeyStore
import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

object LegacyTls {
    fun createClient(context: Context, listener: EventListener = EventListener.NONE): OkHttpClient {
        val system = trustManager(null)
        val customStore = KeyStore.getInstance(KeyStore.getDefaultType()).apply { load(null) }
        context.assets.open("flutter_assets/assets/ca/legacy-roots.pem").use { input ->
            val certificates = CertificateFactory.getInstance("X.509").generateCertificates(input)
            certificates.forEachIndexed { index, certificate ->
                customStore.setCertificateEntry("plezy-root-$index", certificate)
            }
        }
        val combined = CompositeTrustManager(system, trustManager(customStore))
        // Supplying our own factory bypasses OkHttp's API 16-21 TLSv1.2 workaround.
        // Select it explicitly AND enable it on sockets before OkHttp intersects protocols.
        val sslContext = SSLContext.getInstance("TLSv1.2")
        sslContext.init(null, arrayOf(combined), null)
        return OkHttpClient.Builder()
            .sslSocketFactory(ModernTlsSocketFactory(sslContext.socketFactory), combined)
            .connectionSpecs(listOf(ConnectionSpec.Builder(ConnectionSpec.MODERN_TLS)
                .tlsVersions(TlsVersion.TLS_1_2, TlsVersion.TLS_1_3).build()))
            .connectTimeout(12, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .writeTimeout(12, TimeUnit.SECONDS)
            .eventListener(listener)
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
