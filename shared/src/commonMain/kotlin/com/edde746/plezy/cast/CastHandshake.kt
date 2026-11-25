package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import io.ktor.websocket.Frame
import io.ktor.websocket.readBytes
import io.ktor.websocket.readText
import kotlin.io.encoding.Base64
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withTimeoutOrNull

/** The bounds of a handshake; tests shorten them. */
internal data class HandshakeLimits(
    /** The longest a handshake message (pre-authentication) may be. */
    val maxMessageBytes: Int = 65_536,
    /** How long each step waits for the other side's next message. */
    val stepTimeoutMs: Long = 10_000,
    /** How long a sender waits for the receiver's user to decide. */
    val approvalTimeoutMs: Long = 75_000,
)

/** How a receiver's handshake ended: a [link], or a rejection ([failedAttempt]: counts toward the source's lockout). */
internal sealed interface Admission {
    data class Linked(val link: CastLink, val paired: Boolean) : Admission

    data class Rejected(val failedAttempt: Boolean) : Admission
}

/**
 * The receiver's side of a handshake over [transport]: hello, then a remembered sender's proof or a pairing that
 * [approve] decides (shown with its code; cancelled when the sender goes or speaks meanwhile). A paired sender is
 * [remember]ed before it's welcomed.
 */
internal suspend fun receiverHandshake(
    transport: FrameTransport,
    me: CastPeerInfo,
    known: suspend (senderId: String) -> RememberedPeer?,
    approve: suspend (sender: CastPeerInfo, code: String) -> Boolean,
    remember: suspend (RememberedPeer) -> Unit,
    scope: CoroutineScope,
    limits: HandshakeLimits = HandshakeLimits(),
): Admission {
    val nonce = CastCrypto.nonce()
    if (!transport.send(text(Handshake.Hello(CAST_PROTOCOL_VERSION, me, Base64.encode(nonce))))) return Admission.Rejected(false)
    var toldUnknown = false
    while (true) {
        val message = transport.nextHandshake(limits) ?: return Admission.Rejected(true)
        when (message) {
            is Handshake.Auth -> {
                if (toldUnknown) return Admission.Rejected(true)
                val senderNonce = decodeNonce(message.nonce) ?: return Admission.Rejected(true)
                val peer = known(message.device.id)
                if (peer == null) {
                    toldUnknown = true
                    transport.send(text(Handshake.Unknown))
                    continue
                }
                if (!CastCrypto.verifyAuthTag(message.tag, peer.secretBytes, nonce, senderNonce, me.id, message.device.id)) {
                    transport.send(text(Handshake.Refused))
                    return Admission.Rejected(true)
                }
                // The sender's name and system as it says them now; the secret stays the paired one.
                if (peer.device != message.device) remember(peer.copy(device = message.device))
                return welcome(transport, message.device, peer.secretBytes, nonce, senderNonce, scope, paired = false)
            }
            is Handshake.Pair -> {
                val senderNonce = decodeNonce(message.nonce) ?: return Admission.Rejected(true)
                val senderKey = decodeBase64(message.key) ?: return Admission.Rejected(true)
                val key = CastCrypto.pairingKey()
                val shared = try {
                    key.agree(senderKey)
                } catch (e: Exception) {
                    Log.w(TAG, e) { "A pairing key didn't decode" }
                    return Admission.Rejected(true)
                }
                transport.send(text(Handshake.PairKey(Base64.encode(key.publicKey))))
                val pairing = CastCrypto.pairing(shared, nonce, senderNonce, senderKey, key.publicKey, me.id, message.device.id)
                val approved = coroutineScope {
                    val answer = async { approve(message.device, pairing.code) }
                    // Anything from the sender meanwhile (it closing, mostly) withdraws the question.
                    val withdrawn = async { transport.incoming.receiveCatching() }
                    select {
                        answer.onAwait { withdrawn.cancel(); it }
                        withdrawn.onAwait { answer.cancel(); false }
                    }
                }
                if (!approved) {
                    transport.send(text(Handshake.Refused))
                    return Admission.Rejected(true)
                }
                remember(RememberedPeer(message.device, Base64.encode(pairing.secret)))
                return welcome(transport, message.device, pairing.secret, nonce, senderNonce, scope, paired = true)
            }
            else -> return Admission.Rejected(true)
        }
    }
}

private fun welcome(
    transport: FrameTransport,
    sender: CastPeerInfo,
    secret: ByteArray,
    nonce: ByteArray,
    senderNonce: ByteArray,
    scope: CoroutineScope,
    paired: Boolean,
): Admission {
    val link = CastLink(sender, transport, CastCrypto.sessionKey(secret, nonce, senderNonce), CastCrypto.Direction.RECEIVER, scope)
    link.send(CastMessage.Welcome)
    return Admission.Linked(link, paired)
}

/** Why a sender's handshake failed. */
internal class CastHandshakeException(val reason: Reason, message: String) : Exception(message) {
    enum class Reason {
        /** The receiver's user refused, or the receiver refused this device's proof. */
        REFUSED,

        /** The receiver doesn't know this device and the handshake mayn't pair. */
        NOT_PAIRED,

        /** Anything else: the wrong device answered, a timeout, a malformed message, the connection closing. */
        FAILED,
    }
}

/**
 * The sender's side of a handshake over [transport] with the receiver [expectedId] (any when null): a remembered
 * receiver's proof, else (when [pair]) a pairing whose code goes to [onCode] while the receiver's user decides. A
 * receiver that forgot this device is forgotten here too. Throws [CastHandshakeException]. Unless a link takes it, the
 * connection closes as the handshake ends, cancelled too: the receiver's question goes at once.
 */
internal suspend fun senderHandshake(
    transport: FrameTransport,
    me: CastPeerInfo,
    expectedId: String?,
    known: suspend (receiverId: String) -> RememberedPeer?,
    pair: Boolean,
    onCode: (receiver: CastPeerInfo, code: String) -> Unit,
    remember: suspend (RememberedPeer) -> Unit,
    forget: suspend (receiverId: String) -> Unit,
    scope: CoroutineScope,
    limits: HandshakeLimits = HandshakeLimits(),
): CastLink {
    fun fail(reason: CastHandshakeException.Reason, why: String): Nothing = throw CastHandshakeException(reason, why)
    try {
        val hello = transport.nextHandshake(limits) as? Handshake.Hello ?: fail(CastHandshakeException.Reason.FAILED, "no hello")
        val receiver = hello.device
        if (hello.v != CAST_PROTOCOL_VERSION) fail(CastHandshakeException.Reason.FAILED, "protocol ${hello.v}")
        if (expectedId != null && receiver.id != expectedId) fail(CastHandshakeException.Reason.FAILED, "another device answered")
        val receiverNonce = decodeNonce(hello.nonce) ?: fail(CastHandshakeException.Reason.FAILED, "bad nonce")
        val nonce = CastCrypto.nonce()
        val peer = known(receiver.id)
        if (peer != null) {
            val tag = CastCrypto.authTag(peer.secretBytes, receiverNonce, nonce, receiver.id, me.id)
            transport.send(text(Handshake.Auth(me, Base64.encode(nonce), tag)))
            val key = CastCrypto.sessionKey(peer.secretBytes, receiverNonce, nonce)
            when (val answer = transport.nextFrame(limits.stepTimeoutMs)) {
                is Frame.Binary -> {
                    if (!welcomed(answer, key)) fail(CastHandshakeException.Reason.FAILED, "no welcome")
                    if (peer.device != receiver) remember(peer.copy(device = receiver))
                    return CastLink(receiver, transport, key, CastCrypto.Direction.SENDER, scope, received = 1)
                }
                is Frame.Text -> when (decode(answer, limits)) {
                    Handshake.Unknown -> {
                        forget(receiver.id)
                        if (!pair) fail(CastHandshakeException.Reason.NOT_PAIRED, "the receiver forgot this device")
                    }
                    Handshake.Refused -> fail(CastHandshakeException.Reason.REFUSED, "the receiver refused the proof")
                    else -> fail(CastHandshakeException.Reason.FAILED, "unexpected answer")
                }
                else -> fail(CastHandshakeException.Reason.FAILED, "the connection closed")
            }
        } else if (!pair) {
            fail(CastHandshakeException.Reason.NOT_PAIRED, "not paired")
        }
        val key = CastCrypto.pairingKey()
        transport.send(text(Handshake.Pair(me, Base64.encode(nonce), Base64.encode(key.publicKey))))
        val receiverKey = (transport.nextHandshake(limits) as? Handshake.PairKey)?.key?.let(::decodeBase64)
            ?: fail(CastHandshakeException.Reason.FAILED, "no pairing key")
        val pairing = try {
            CastCrypto.pairing(key.agree(receiverKey), receiverNonce, nonce, key.publicKey, receiverKey, receiver.id, me.id)
        } catch (e: Exception) {
            fail(CastHandshakeException.Reason.FAILED, "bad pairing key: $e")
        }
        onCode(receiver, pairing.code)
        val sessionKey = CastCrypto.sessionKey(pairing.secret, receiverNonce, nonce)
        when (val answer = transport.nextFrame(limits.approvalTimeoutMs)) {
            is Frame.Binary -> {
                if (!welcomed(answer, sessionKey)) fail(CastHandshakeException.Reason.FAILED, "no welcome")
                remember(RememberedPeer(receiver, Base64.encode(pairing.secret)))
                return CastLink(receiver, transport, sessionKey, CastCrypto.Direction.SENDER, scope, received = 1)
            }
            is Frame.Text -> fail(CastHandshakeException.Reason.REFUSED, "refused")
            else -> fail(CastHandshakeException.Reason.REFUSED, "closed while asking")
        }
    } catch (e: Throwable) {
        transport.close()
        throw e
    }
}

private fun welcomed(frame: Frame.Binary, key: ByteArray): Boolean = try {
    val text = CastCrypto.decrypt(key, frame.readBytes(), CastCrypto.Direction.RECEIVER, 0).decodeToString()
    castJson.decodeFromString(CastMessage.serializer(), text) == CastMessage.Welcome
} catch (e: Exception) {
    Log.w(TAG, e) { "The welcome didn't verify" }
    false
}

private fun text(message: Handshake): Frame = Frame.Text(castJson.encodeToString(Handshake.serializer(), message))

/** The next frame within [timeoutMs]; null when the connection closed or the time ran out. */
private suspend fun FrameTransport.nextFrame(timeoutMs: Long): Frame? = withTimeoutOrNull(timeoutMs) { incoming.receiveCatching().getOrNull() }

/** The next handshake message; null for a timeout, a close, a binary frame, an oversized or malformed message. */
private suspend fun FrameTransport.nextHandshake(limits: HandshakeLimits): Handshake? =
    (nextFrame(limits.stepTimeoutMs) as? Frame.Text)?.let { decode(it, limits) }

private fun decode(frame: Frame.Text, limits: HandshakeLimits): Handshake? {
    if (frame.data.size > limits.maxMessageBytes) return null
    return try {
        castJson.decodeFromString(Handshake.serializer(), frame.readText())
    } catch (e: Exception) {
        Log.d(TAG, e) { "A malformed handshake message" }
        null
    }
}

private fun decodeBase64(text: String): ByteArray? = try {
    Base64.decode(text)
} catch (e: IllegalArgumentException) {
    null
}

private fun decodeNonce(text: String): ByteArray? = decodeBase64(text)?.takeIf { it.size == CastCrypto.NONCE_BYTES }

private const val TAG = "CastHandshake"
