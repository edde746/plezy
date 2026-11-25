package com.edde746.plezy.cast

import io.ktor.websocket.Frame
import kotlinx.coroutines.channels.Channel

/** The two ends of a connection in memory: the receiver's (from [senderAddress]) first, then the sender's. */
internal fun memoryConnection(senderAddress: String, receiverAddress: String): Pair<FrameTransport, FrameTransport> {
    val toReceiver = Channel<Frame>(Channel.UNLIMITED)
    val toSender = Channel<Frame>(Channel.UNLIMITED)
    return MemoryTransport(toReceiver, toSender, senderAddress) to MemoryTransport(toSender, toReceiver, receiverAddress)
}

/** One end: the other end's frames arrive on [incoming]; closing it ends both directions. */
private class MemoryTransport(
    override val incoming: Channel<Frame>,
    private val outgoing: Channel<Frame>,
    override val remoteAddress: String,
) : FrameTransport {
    override fun send(frame: Frame): Boolean = outgoing.trySend(frame).isSuccess

    override fun close() {
        outgoing.close()
        incoming.close()
    }
}
