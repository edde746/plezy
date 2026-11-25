package com.edde746.plezy.crypto

import dev.whyoleg.cryptography.CryptographyProvider
import dev.whyoleg.cryptography.providers.jdk.JDK
import java.security.Security

/**
 * Conscrypt, named explicitly. With the default JCA lookup, a `KeyFactory` that rejects a key (e.g. an off-curve
 * point) fails over to the next provider and keeps it; cryptography-kotlin pools that instance, so after one bad key
 * every later EC key import in the process went to AndroidKeyStore's factory and failed (seen on API 36).
 */
internal actual fun platformCryptoProvider(): CryptographyProvider {
    val conscrypt = checkNotNull(Security.getProvider("AndroidOpenSSL")) { "Conscrypt (AndroidOpenSSL) is missing" }
    return CryptographyProvider.JDK(conscrypt)
}
