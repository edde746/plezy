package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerUrlException
import com.edde746.plezy.jellyfin.JellyfinEndpointDiscovery
import com.edde746.plezy.jellyfin.VirtualTime
import com.edde746.plezy.jellyfin.fakeHttp
import com.edde746.plezy.jellyfin.info
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.seerr.SeerrException
import com.edde746.plezy.seerr.authService
import com.edde746.plezy.seerr.json
import com.edde746.plezy.strings.T
import java.security.cert.CertificateException
import javax.net.ssl.SSLException
import javax.net.ssl.SSLHandshakeException
import javax.net.ssl.SSLPeerUnverifiedException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.test.runTest

/** A typed address without a scheme, against the failures the JVM's TLS stack reports. */
class TypedAddressTest {
    private val time = VirtualTime()

    private fun untrusted(): Nothing =
        throw SSLHandshakeException("PKIX path building failed").apply { initCause(CertificateException("unable to find valid certification path")) }

    @Test
    fun aCertificateTheDeviceRejectsKeepsASeerrAddressOffPlainHttp() = runTest {
        val server = MockServer(this) { request ->
            if (request.url.protocol.name == "https") untrusted() else json("""{"initialized":true,"mediaServerType":2}""")
        }
        val error = assertFailsWith<SeerrException.Url> { authService(server).probeFirstReachable("seerr.lan:5055") }
        assertEquals(T.addServer.untrustedCertificate(url = "https://seerr.lan:5055"), error.display)
    }

    @Test
    fun aCertificateForAnotherHostKeepsAJellyfinAddressOffPlainHttp() = time.test {
        val http = fakeHttp(time) { request ->
            if (request.url.protocol.name == "https") throw SSLPeerUnverifiedException("Hostname jf.lan not verified") else info("srv-1")
        }
        val discovery = JellyfinEndpointDiscovery(http, timeSource = time.timeSource)
        val error = assertFailsWith<MediaServerUrlException> {
            discovery.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("jf.lan:8096")))
        }
        assertEquals(T.addServer.untrustedCertificate(url = "https://jf.lan:8096"), error.display)
    }

    @Test
    fun aPortThatDoesNotSpeakTlsFallsBackToPlainHttp() = time.test {
        // What the JVM reports for a TLS handshake answered in plain HTTP, as Emby's 8096 answers it.
        val http = fakeHttp(time) { request ->
            if (request.url.protocol.name == "https") throw SSLException("Unsupported or unrecognized SSL message") else info("srv-1")
        }
        val discovery = JellyfinEndpointDiscovery(http, MediaBrowserDialect.EMBY, time.timeSource)
        val result = discovery.raceUserInput(JellyfinEndpointDiscovery.buildUserInputCandidates(listOf("emby.lan:8096"), MediaBrowserDialect.EMBY))
        assertEquals("http://emby.lan:8096", result.activeBaseUrl)
    }
}
