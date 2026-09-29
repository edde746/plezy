package com.edde746.plezy

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

class LegacyTrustBundleTest {
    @Test fun bundleContainsOfficialGenerationYChainLinks() {
        val stream = checkNotNull(javaClass.classLoader?.getResourceAsStream("ca/legacy-roots.pem"))
        val certificates = stream.use {
            CertificateFactory.getInstance("X.509").generateCertificates(it)
                .filterIsInstance<X509Certificate>()
        }
        assertEquals(5, certificates.size)

        val rootX1 = certificates.firstOrNull { it.subjectX500Principal.name.contains("CN=ISRG Root X1") }
        val rootYr = certificates.firstOrNull { it.subjectX500Principal.name.contains("CN=Root YR") }
        val rootYe = certificates.firstOrNull { it.subjectX500Principal.name.contains("CN=Root YE") }
        assertNotNull(rootX1)
        assertNotNull(rootYr)
        assertNotNull(rootYe)
        assertEquals("CN=ISRG Root X1,O=Internet Security Research Group,C=US", rootYr!!.issuerX500Principal.name)
        assertEquals("CN=ISRG Root X2,O=Internet Security Research Group,C=US", rootYe!!.issuerX500Principal.name)

        // Proves the bundled RSA bridge is genuinely signed by our existing X1 anchor.
        rootYr.verify(rootX1!!.publicKey)
        certificates.forEach { it.checkValidity() }
    }
}
