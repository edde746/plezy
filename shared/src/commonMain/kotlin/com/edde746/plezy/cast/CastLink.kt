package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import io.ktor.websocket.Frame
import io.ktor.websocket.readBytes
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

/** One WebSocket as the handshake and the link see it: its frames in, a queue out, and where it comes from. */
internal interface FrameTransport {
    /** The other end's frames; closes when the connection ends. */
    val incoming: ReceiveChannel<Frame>

    /** Queues [frame]; false once the connection is closing. */
    fun send(frame: Frame): Boolean

    /** Closes the connection after the frames already queued. */
    fun close()

    /** The other end's IP address (the receiver's lockouts go by it). */
    val remoteAddress: String
}

/**
 * An open, authenticated link to [peer]: [CastMessage]s both ways, each JSON in an AES-256-GCM frame under [key]
 * ([CastCrypto]), in order. A frame that doesn't verify ends the link. [incoming] ends when the link does; it has one
 * collector.
 *
 * @param received the frames of the other end already read in the handshake (the counter its next frame takes).
 */
internal class CastLink(
    val peer: CastPeerInfo,
    private val transport: FrameTransport,
    private val key: ByteArray,
    private val sending: CastCrypto.Direction,
    scope: CoroutineScope,
    received: Long = 0,
) {
    private val outbox = Channel<CastMessage>(Channel.UNLIMITED)
    private val inbox = Channel<CastMessage>(Channel.UNLIMITED)
    private val job = Job(scope.coroutineContext[Job])

    val incoming: Flow<CastMessage> = inbox.receiveAsFlow()

    init {
        val linkScope = CoroutineScope(scope.coroutineContext + job)
        linkScope.launch {
            var counter = 0L
            for (message in outbox) {
                val plaintext = castJson.encodeToString(CastMessage.serializer(), message).encodeToByteArray()
                if (!transport.send(Frame.Binary(true, CastCrypto.encrypt(key, plaintext, sending, counter++)))) break
            }
            transport.close()
        }
        linkScope.launch {
            val direction = if (sending == CastCrypto.Direction.RECEIVER) CastCrypto.Direction.SENDER else CastCrypto.Direction.RECEIVER
            var counter = received
            try {
                for (frame in transport.incoming) {
                    if (frame !is Frame.Binary) continue
                    val message = try {
                        castJson.decodeFromString(CastMessage.serializer(), CastCrypto.decrypt(key, frame.readBytes(), direction, counter++).decodeToString())
                    } catch (e: Exception) {
                        Log.w(TAG, e) { "A frame from ${peer.name} didn't verify: closing the link" }
                        break
                    }
                    inbox.send(message)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, e) { "The link to ${peer.name} failed" }
            } finally {
                close()
            }
        }
    }

    /** Queues [message]; false once the link is closed. */
    fun send(message: CastMessage): Boolean = outbox.trySend(message).isSuccess

    /** Ends the link: the queued messages go first; [incoming] ends. */
    fun close() {
        outbox.close()
        inbox.close()
        job.complete()
    }

    private companion object {
        const val TAG = "CastLink"
    }
}
