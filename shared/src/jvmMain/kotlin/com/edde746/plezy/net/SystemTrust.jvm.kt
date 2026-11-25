package com.edde746.plezy.net

import com.edde746.plezy.log.Log
import okhttp3.OkHttpClient
import java.nio.file.Files
import java.nio.file.Path
import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLSocketFactory
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

private const val TAG = "SystemTrust"

/**
 * The CA bundles Linux distributions keep their trusted roots in (with the CAs the user or the administrator added),
 * the first that exists counting: Debian, Ubuntu, Arch and Flatpak's runtimes; Fedora and RHEL; openSUSE; OpenELEC;
 * CentOS and RHEL 7; Alpine.
 */
internal val LINUX_CA_BUNDLES: List<Path> = listOf(
    "/etc/ssl/certs/ca-certificates.crt",
    "/etc/pki/tls/certs/ca-bundle.crt",
    "/etc/ssl/ca-bundle.pem",
    "/etc/pki/tls/cacert.pem",
    "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
    "/etc/ssl/cert.pem",
).map(Path::of)

private class SystemTrust(val trustManager: X509TrustManager) {
    val socketFactory: SSLSocketFactory = SSLContext.getInstance("TLS").apply { init(null, arrayOf(trustManager), null) }.socketFactory
}

/** The JDK's roots plus the system's, built once; null on a system whose roots the JDK's already are. */
private val systemTrust: SystemTrust? by lazy {
    val os = System.getProperty("os.name")
    val roots = when {
        os.startsWith("Windows") -> windowsRoots()
        os.startsWith("Linux") -> caBundleCertificates(LINUX_CA_BUNDLES)
        else -> return@lazy null
    }
    SystemTrust(trustManagerWith(roots))
}

/**
 * Windows: its certificate store's trusted roots (the machine's and the user's, so a CA the user installed works) and
 * Windows's proxy settings (the app runs with `java.net.useSystemProxies`, which OkHttp's default proxy selector reads).
 * Linux: the distribution's CA bundle. Either on top of the JDK's own roots, which cover a root Windows hasn't fetched yet.
 */
internal actual fun OkHttpClient.Builder.useSystemTrust() {
    val trust = systemTrust ?: return
    sslSocketFactory(trust.socketFactory, trust.trustManager)
}

/** The trusted roots of Windows's certificate store, as the current user sees it (the machine's included). */
private fun windowsRoots(): List<X509Certificate> {
    val store = KeyStore.getInstance("Windows-ROOT").apply { load(null, null) }
    return store.aliases().toList().mapNotNull { store.getCertificate(it) as? X509Certificate }
}

/** The certificates of the first of [bundles] that exists; none when none does. */
internal fun caBundleCertificates(bundles: List<Path>): List<X509Certificate> {
    val bundle = bundles.firstOrNull(Files::isRegularFile) ?: run {
        Log.w(TAG) { "No CA bundle in ${bundles.joinToString()}; only the JDK's roots are trusted" }
        return emptyList()
    }
    return Files.newInputStream(bundle).use { input ->
        CertificateFactory.getInstance("X.509").generateCertificates(input).filterIsInstance<X509Certificate>()
    }
}

/** A trust manager over the JDK's default roots and [roots]. */
internal fun trustManagerWith(roots: Collection<X509Certificate>): X509TrustManager {
    val store = KeyStore.getInstance(KeyStore.getDefaultType()).apply { load(null, null) }
    val anchors = defaultTrustManager().acceptedIssuers.asList() + roots
    anchors.forEachIndexed { index, certificate -> store.setCertificateEntry("root-$index", certificate) }
    val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply { init(store) }
    return factory.trustManagers.filterIsInstance<X509TrustManager>().single()
}

private fun defaultTrustManager(): X509TrustManager {
    val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm()).apply { init(null as KeyStore?) }
    return factory.trustManagers.filterIsInstance<X509TrustManager>().single()
}
