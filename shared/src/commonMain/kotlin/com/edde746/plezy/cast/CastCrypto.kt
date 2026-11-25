package com.edde746.plezy.cast

import com.edde746.plezy.crypto.cryptoProvider
import dev.whyoleg.cryptography.DelicateCryptographyApi
import dev.whyoleg.cryptography.algorithms.AES
import dev.whyoleg.cryptography.algorithms.EC
import dev.whyoleg.cryptography.algorithms.ECDH
import dev.whyoleg.cryptography.algorithms.HMAC
import dev.whyoleg.cryptography.algorithms.SHA256
import dev.whyoleg.cryptography.random.CryptographyRandom

/**
 * Casting's cryptography. Nothing here is stored but the pairing secret, which [CastPeers] keeps in the secret store.
 *
 * - Pairing: an ECDH P-256 exchange. The transcript is both nonces, both public keys and both ids; the pairing secret
 *   is HKDF(shared secret, salt SHA-256(transcript), `plezy-cast-secret`) and the 4-digit code both devices show is the
 *   first four bytes of HKDF(shared secret, salt SHA-256(transcript), `plezy-cast-code`) mod 10 000. A device in the
 *   middle makes the two codes differ.
 * - A remembered sender proves the secret with HMAC(secret, `plezy-cast-auth|` receiver nonce, sender nonce,
 *   length-prefixed receiver id and sender id).
 * - Session key: HKDF(HKDF(secret, salt receiver nonce ‖ sender nonce, `plezy-cast-session`), no salt, `encryption`).
 * - Frames: AES-256-GCM, the 12-byte nonce the direction (receiver 1, sender 2, u32 BE) and the sender's counter
 *   (u64 BE); the frame is the ciphertext and its 16-byte tag.
 */
internal object CastCrypto {
    const val NONCE_BYTES: Int = 32
    private const val KEY_BYTES = 32
    private const val TAG_BYTES = 16

    /** The direction of a frame, its nonce's first word. */
    enum class Direction(val word: Int) { RECEIVER(1), SENDER(2) }

    fun nonce(): ByteArray = CryptographyRandom.nextBytes(NONCE_BYTES)

    /** One side's ephemeral pairing key: [publicKey] goes to the other side (uncompressed point). */
    class PairingKey internal constructor(private val key: ECDH.KeyPair) {
        val publicKey: ByteArray = key.publicKey.encodeToByteArrayBlocking(EC.PublicKey.Format.RAW)

        /** The ECDH secret with the other side's [peerPublicKey]; throws on a key that isn't a point of the curve. */
        fun agree(peerPublicKey: ByteArray): ByteArray {
            val peer = ecdh.publicKeyDecoder(EC.Curve.P256).decodeFromByteArrayBlocking(EC.PublicKey.Format.RAW, peerPublicKey)
            return key.privateKey.sharedSecretGenerator().generateSharedSecretToByteArrayBlocking(peer)
        }
    }

    private val ecdh get() = cryptoProvider.get(ECDH)

    fun pairingKey(): PairingKey = PairingKey(ecdh.keyPairGenerator(EC.Curve.P256).generateKeyBlocking())

    /** What pairing agreed on: the [secret] both remember and the [code] both show. */
    class Pairing(val secret: ByteArray, val code: String)

    fun pairing(
        shared: ByteArray,
        receiverNonce: ByteArray,
        senderNonce: ByteArray,
        senderKey: ByteArray,
        receiverKey: ByteArray,
        receiverId: String,
        senderId: String,
    ): Pairing {
        val transcript = "plezy-cast-pair|".encodeToByteArray() + receiverNonce + senderNonce + lengthPrefixed(senderKey, receiverKey) +
            lengthPrefixed(receiverId.encodeToByteArray(), senderId.encodeToByteArray())
        val salt = sha256(transcript)
        val code = hkdf(shared, salt, "plezy-cast-code").take(4).fold(0L) { acc, byte -> (acc shl 8) or (byte.toLong() and 0xFFL) } % 10_000
        return Pairing(hkdf(shared, salt, "plezy-cast-secret"), code.toString().padStart(4, '0'))
    }

    fun authTag(secret: ByteArray, receiverNonce: ByteArray, senderNonce: ByteArray, receiverId: String, senderId: String): String =
        hmac(secret, "plezy-cast-auth|".encodeToByteArray() + receiverNonce + senderNonce + lengthPrefixed(receiverId.encodeToByteArray(), senderId.encodeToByteArray()))
            .toHex()

    fun verifyAuthTag(tag: String, secret: ByteArray, receiverNonce: ByteArray, senderNonce: ByteArray, receiverId: String, senderId: String): Boolean =
        constantTimeEquals(authTag(secret, receiverNonce, senderNonce, receiverId, senderId), tag)

    fun sessionKey(secret: ByteArray, receiverNonce: ByteArray, senderNonce: ByteArray): ByteArray =
        hkdf(hkdf(secret, receiverNonce + senderNonce, "plezy-cast-session"), ByteArray(0), "encryption")

    fun frameNonce(direction: Direction, counter: Long): ByteArray {
        val nonce = ByteArray(12)
        for (i in 0..3) nonce[i] = (direction.word ushr (24 - 8 * i)).toByte()
        for (i in 0..7) nonce[4 + i] = (counter ushr (56 - 8 * i)).toByte()
        return nonce
    }

    @OptIn(DelicateCryptographyApi::class)
    fun encrypt(key: ByteArray, plaintext: ByteArray, direction: Direction, counter: Long): ByteArray =
        aesKey(key).cipher().encryptWithIvBlocking(frameNonce(direction, counter), plaintext)

    /** The plaintext of [frame], sent in [direction] as the sender's frame [counter]; throws when it doesn't verify. */
    @OptIn(DelicateCryptographyApi::class)
    fun decrypt(key: ByteArray, frame: ByteArray, direction: Direction, counter: Long): ByteArray {
        require(frame.size >= TAG_BYTES) { "Encrypted data too short" }
        return aesKey(key).cipher().decryptWithIvBlocking(frameNonce(direction, counter), frame)
    }

    private fun aesKey(key: ByteArray) = cryptoProvider.get(AES.GCM).keyDecoder().decodeFromByteArrayBlocking(AES.Key.Format.RAW, key)

    /** RFC 5869 with SHA-256 and a 32-byte output; no salt is the hash's length of zeros, as the RFC says. */
    private fun hkdf(ikm: ByteArray, salt: ByteArray, info: String): ByteArray {
        val prk = hmac(if (salt.isEmpty()) ByteArray(KEY_BYTES) else salt, ikm)
        return hmac(prk, info.encodeToByteArray() + byteArrayOf(1))
    }

    private fun hmac(key: ByteArray, data: ByteArray): ByteArray =
        cryptoProvider.get(HMAC).keyDecoder(SHA256).decodeFromByteArrayBlocking(HMAC.Key.Format.RAW, key).signatureGenerator().generateSignatureBlocking(data)

    private fun sha256(data: ByteArray): ByteArray = cryptoProvider.get(SHA256).hasher().hashBlocking(data)

    private fun lengthPrefixed(vararg fields: ByteArray): ByteArray {
        var out = ByteArray(0)
        for (field in fields) {
            out += byteArrayOf((field.size ushr 24).toByte(), (field.size ushr 16).toByte(), (field.size ushr 8).toByte(), field.size.toByte())
            out += field
        }
        return out
    }

    private fun constantTimeEquals(a: String, b: String): Boolean {
        if (a.length != b.length) return false
        var result = 0
        for (i in a.indices) result = result or (a[i].code xor b[i].code)
        return result == 0
    }

    private fun ByteArray.toHex(): String = joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }
}
