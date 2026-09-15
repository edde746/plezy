package com.edde746.plezy

import java.security.KeyStore
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class UserCertificateChannelTest {
  private val factory = CertificateFactory.getInstance("X.509")
  private val privateAuthority = certificate(PRIVATE_AUTHORITY_PEM)
  private val serverLeaf = certificate(SERVER_LEAF_PEM)

  @Test
  fun bundlesOnlyUserInstalledAuthorities() {
    val store = keyStore("system:3513523f.0" to serverLeaf, "user:8f0c3a2b.0" to privateAuthority)

    val pem = UserCertificateChannel.userAuthoritiesPem(store)

    // The bundle is consumed by BoringSSL's PEM reader; a standard X.509 parser reading it back
    // to the same DER is the closest a JVM test gets to that boundary.
    val parsed = factory.generateCertificates(pem.byteInputStream()).map { it as X509Certificate }
    assertEquals(listOf(privateAuthority), parsed)
    assertTrue(pem.lines().all { it.length <= 64 })
  }

  @Test
  fun deviceWithoutUserAuthoritiesYieldsAnEmptyBundle() {
    val store = keyStore("system:3513523f.0" to serverLeaf)

    assertEquals("", UserCertificateChannel.userAuthoritiesPem(store))
  }

  private fun certificate(pem: String): X509Certificate = factory.generateCertificate(pem.byteInputStream()) as X509Certificate

  private fun keyStore(vararg entries: Pair<String, X509Certificate>): KeyStore = KeyStore.getInstance("PKCS12").apply {
    load(null)
    entries.forEach { (alias, certificate) -> setCertificateEntry(alias, certificate) }
  }

  private companion object {
    // Self-signed CA, valid until 2126; mirrors test/utils/certificate_trust_test.dart.
    const val PRIVATE_AUTHORITY_PEM = """-----BEGIN CERTIFICATE-----
MIIBpjCCAU2gAwIBAgIUE2B0ftvgw24qfGGZDgg9ahCt6W4wCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAgMR4wHAYDVQQDDBVQbGV6eSBUZXN0IFByaXZh
dGUgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATRtBIaHTld7jouEH7XGewU
K0lQXk04cKOtASHwiJ4yeaG3IwqwUzKprnIbJ9LO8j8Yug6Z3b6UuFmmR9nCy3Z0
o2MwYTAdBgNVHQ4EFgQUMkopaSNoRnirfv98G1AIU57Bfd8wHwYDVR0jBBgwFoAU
MkopaSNoRnirfv98G1AIU57Bfd8wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8E
BAMCAQYwCgYIKoZIzj0EAwIDRwAwRAIgZ05Qu7LVaJYl3CabUJ0FvJVe6lHTsbNk
2rBsxeQin20CIHTBFcdyUpAop/I2fotqNzyyP6Awz6V5B8E6phpnwoa5
-----END CERTIFICATE-----
"""

    // Leaf for localhost issued by the authority above.
    const val SERVER_LEAF_PEM = """-----BEGIN CERTIFICATE-----
MIIBxjCCAWugAwIBAgIUELPXCK88VPZica3MS4eHc+WP0cEwCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwWTATBgcq
hkjOPQIBBggqhkjOPQMBBwNCAARyNHegHEHgV3jdV3igrqT2XMTZdUUGJS8seSTH
Ef5c0SbWphL3bkaJkJrmwkG2zLeztPkpcShdhF9NhmFDuFiVo4GMMIGJMBoGA1Ud
EQQTMBGCCWxvY2FsaG9zdIcEfwAAATAJBgNVHRMEAjAAMAsGA1UdDwQEAwIHgDAT
BgNVHSUEDDAKBggrBgEFBQcDATAdBgNVHQ4EFgQUza0Nj5xZ8PAzmrIZqtwLKp1E
9lAwHwYDVR0jBBgwFoAUMkopaSNoRnirfv98G1AIU57Bfd8wCgYIKoZIzj0EAwID
SQAwRgIhAK5tJYi21adtGCItM7NMz2s+feAwx0jyGICU5B1s88DCAiEArPUwqZSl
5yJJLTVYtdCVgZrAH3SJ8eau3/uKmx7uXSo=
-----END CERTIFICATE-----
"""
  }
}
