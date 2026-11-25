package com.edde746.plezy.crypto

import dev.whyoleg.cryptography.CryptographyProvider

/** The one provider every hash in the app uses: a sign-in's PKCE challenge, a parent PIN's hash. */
internal val cryptoProvider: CryptographyProvider by lazy { platformCryptoProvider() }

/** JCA on JVM, Conscrypt on Android, CryptoKit with a CommonCrypto fallback on Apple. */
internal expect fun platformCryptoProvider(): CryptographyProvider
