package com.edde746.plezy.crypto

import dev.whyoleg.cryptography.CryptographyProvider

internal actual fun platformCryptoProvider(): CryptographyProvider = CryptographyProvider.Default
