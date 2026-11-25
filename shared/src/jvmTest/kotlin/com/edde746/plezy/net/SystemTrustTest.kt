package com.edde746.plezy.net

import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import kotlin.io.path.createTempDirectory
import kotlin.io.path.writeText
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** A CA only the system's bundle has (a user's or a company's) makes its servers trusted, on top of the JDK's roots. */
class SystemTrustTest {
    private val dir = createTempDirectory("ca-bundles")

    @AfterTest
    fun cleanUp() {
        dir.toFile().deleteRecursively()
    }

    private val server: X509Certificate =
        CertificateFactory.getInstance("X.509").generateCertificate(SERVER_PEM.byteInputStream()) as X509Certificate

    @Test
    fun theFirstBundleThatExistsCountsAndItsCaIsTrusted() {
        val missing = dir.resolve("missing.crt")
        val bundle = dir.resolve("ca-bundle.crt").apply { writeText(CA_PEM) }
        val later = dir.resolve("later.pem").apply { writeText(SERVER_PEM) }

        val roots = caBundleCertificates(listOf(missing, bundle, later))

        assertEquals(listOf("CN=Plezy Test Root"), roots.map { it.subjectX500Principal.name })
        trustManagerWith(roots).checkServerTrusted(arrayOf(server), "RSA")
    }

    @Test
    fun withoutTheBundleOnlyTheJdkRootsCount() {
        val roots = caBundleCertificates(listOf(dir.resolve("none.crt")))
        val trust = trustManagerWith(roots)

        assertEquals(emptyList(), roots)
        assertFailsWith<CertificateException> { trust.checkServerTrusted(arrayOf(server), "RSA") }
        assertTrue(trust.acceptedIssuers.isNotEmpty())
    }

    private companion object {
        const val CA_PEM = """-----BEGIN CERTIFICATE-----
MIIDBjCCAe6gAwIBAgIUVn7NFZ5zL96P6jsRICT+gLZ44VQwDQYJKoZIhvcNAQEL
BQAwGjEYMBYGA1UEAwwPUGxlenkgVGVzdCBSb290MCAXDTI2MTEwNzA0Mjc0MFoY
DzIxMjYxMDE0MDQyNzQwWjAaMRgwFgYDVQQDDA9QbGV6eSBUZXN0IFJvb3QwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC9Ne4iHaCfewSwKgk65MVZrYtF
TNDHsE9SsRzY4gTpK7QJwh/NsUUOtVUKKVD7ElcD0TzkmRn7UQ151sYQck7i/b/s
qtctQqOcoghTlYVmUqdxRFrZTucHE3qpRYXfEBxcQomkU3KV+KLx8YgFz++RmWlC
toF+CwHNc1FPKnoHRJqMD+gN/AlOSPIAwwVdL7PTprvimHiZ0yXevPjZ+wvvJ8tk
4jRbqFQMQLP3uD7OGwbzM7voBeunSG30uAkM9apmLoBuTWXDLc5CZkb9nyV1CYdC
CUywmJvMHi+HfrTDB2y/VOoacPNXDaFCqWwey/bUoh7BU16PhSHU87m8Wq6nAgMB
AAGjQjBAMB0GA1UdDgQWBBQxLIgXD4xO+0v/Gwe1iKDzARbJLjAPBgNVHRMBAf8E
BTADAQH/MA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQsFAAOCAQEADWZIUOVn
JletAQftscJm4sR3ym8z6l51F/n8Au/llGYKkSNLvUf5SDyuRGThtx0qcHwPm4zI
vwHMnaRDZ+fVRLSXYATt3iWX2Zacs+mpE2tJ6uLRLVJOoNwcjI04a50PXsoEccfr
4H8iiJCAvaFVnpUOIijUGAbBgNxqGlXk9Qb48pihLDm9GXJmgp16HT2Trw8MRXqj
71c/GcKveIYcQvvNYAXIGlyE1CHapey56apzk+LtdpVsY1KTnJS2G4KoLKOhGQ7m
Vo38KmM7zOqa4ytjuHuNdZzfVdqCToY/5yEkGhRsMLkfXYKojFoIRMnqltqJ30zh
d2/JMcnCRm2QHA==
-----END CERTIFICATE-----
"""

        /** `server.test`, issued by [CA_PEM]'s root, valid until 2126. */
        const val SERVER_PEM = """-----BEGIN CERTIFICATE-----
MIIDCjCCAfKgAwIBAgIUfjr/oif0fjgYZk5HAVK8QDPe3gwwDQYJKoZIhvcNAQEL
BQAwGjEYMBYGA1UEAwwPUGxlenkgVGVzdCBSb290MCAXDTI2MTEwNzA0Mjc0MFoY
DzIxMjYxMDE0MDQyNzQwWjAWMRQwEgYDVQQDDAtzZXJ2ZXIudGVzdDCCASIwDQYJ
KoZIhvcNAQEBBQADggEPADCCAQoCggEBALko4Dfew8qD05Gs73GyKJUyNk8yU/YD
/NlKJlKqekEhuQZYop/OnW5xSn4AEvI3K+72ixV9GfWEpIurOe/G7Dc5LlxrZRzx
pkjHq/uI5jIZA46zNfpCemEunqzdsthsmqfK9RfkveQ0I+LEbVuyptoZqiYhHAv2
CmLmSYKcxpM4pGXN0duy3FwiKFTgr88f7tg5o8FGuEJ33nLUo+rvBqHP/8p4lJ6y
mJXrTQXR/TOrHbH7yvIFzaiRiyVzC0lsXZiKLCJSlnLGdjLJh3tqhDr3Jl1GuooI
ffOwEPy/6NEDlNDLTI7nB11DKGG5deEYCpQq/VvNPgaoiBacTX7qxzMCAwEAAaNK
MEgwCQYDVR0TBAIwADAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUH
AwEwFgYDVR0RBA8wDYILc2VydmVyLnRlc3QwDQYJKoZIhvcNAQELBQADggEBAFA6
2gh0wv3hUgOFxdUDFbAN1U2VE1OjnkCyFuOXS6mnCh8J6YMwHt0yzcpQWJz3EiKO
5rKNSu1ZlA9ItNpMRF1e9vn1om5hHOjv0Vv/D/4CteekiStERjqMMt1PrzrM0HvG
k0JG8YSeoK/8LwjXG30JtIhhSwVUrdLgjIXkLwXF+4sB6t4hJxbN74YVhVW0KuQg
A415q+/Ne5070DVScqy97L1MWWs78+Yon/vExCsfJ5gTnwpFIHkWx1LxY4r9XHOQ
DC1zJ95OUcfBNllubxMypQ639TdxfLvpbbNdSUwIEaQKbFWu28AkgKeFjR7tW9VP
WaG/nAbSECSoPBnomSw=
-----END CERTIFICATE-----
"""
    }
}
