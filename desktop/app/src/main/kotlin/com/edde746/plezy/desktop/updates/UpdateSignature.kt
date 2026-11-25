package com.edde746.plezy.desktop.updates

import java.nio.file.Files
import java.nio.file.Path
import java.security.KeyFactory
import java.security.PublicKey
import java.security.Signature
import java.security.spec.X509EncodedKeySpec
import java.util.Base64

/**
 * Sparkle's EdDSA signatures, which the release workflow makes of each installer with Plezy's update key: Ed25519 over
 * the file's bytes, the 64-byte signature and the 32-byte public key each in base64.
 */
internal object UpdateSignature {
    /** Plezy's update key: the public half of the release workflow's signing key. */
    const val PUBLIC_KEY = "q7t6eu1txRrqv1PeWDCRV95rFxnmD/D3GZWbUPMwUyU="

    /**
     * Whether [signature] is [publicKey]'s signature of [file]. A signature or key that isn't base64 of the right size
     * throws [IllegalArgumentException].
     */
    fun verify(file: Path, signature: String, publicKey: String): Boolean {
        val bytes = Base64.getDecoder().decode(signature.trim())
        require(bytes.size == 64) { "an Ed25519 signature is 64 bytes, not ${bytes.size}" }
        val verifier = Signature.getInstance("Ed25519")
        verifier.initVerify(publicKey(publicKey))
        Files.newInputStream(file).use { input ->
            val buffer = ByteArray(1 shl 16)
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                verifier.update(buffer, 0, read)
            }
        }
        return verifier.verify(bytes)
    }

    /** The raw 32-byte Ed25519 key [base64] as the JDK's key: its X.509 form is a fixed 12-byte header and the key. */
    private fun publicKey(base64: String): PublicKey {
        val raw = Base64.getDecoder().decode(base64.trim())
        require(raw.size == 32) { "an Ed25519 public key is 32 bytes, not ${raw.size}" }
        return KeyFactory.getInstance("Ed25519").generatePublic(X509EncodedKeySpec(X509_HEADER + raw))
    }

    /** SubjectPublicKeyInfo's DER for Ed25519 (OID 1.3.101.112) up to the key's 32 bytes. */
    private val X509_HEADER = byteArrayOf(0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00)
}
