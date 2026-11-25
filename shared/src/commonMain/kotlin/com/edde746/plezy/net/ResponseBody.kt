package com.edde746.plezy.net

import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsChannel
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.cancel
import io.ktor.utils.io.readBuffer
import kotlinx.io.readString

/**
 * Reads [this] response's body with [read], then cancels what [read] left unread. Inside `HttpStatement.execute`
 * (`prepareGet`, `prepareRequest`), where the body streams from the engine, every read of the body goes through it.
 *
 * `bodyAsChannel()` is a copy of the body that a coroutine of the client fills, at most 1 MiB ahead of the reader, and
 * `execute`'s cleanup cancels the engine's body but not that copy. A copy left uncancelled with its buffer full keeps
 * that coroutine waiting for a reader: when the block given to `execute` returns, the cleanup waits for the coroutine,
 * so `execute` returns only when its caller times out; when the block fails, the coroutine stays suspended, holding its
 * buffer, as long as the client lives. Cancelling the copy ends the coroutine and, with it, the request.
 */
internal suspend fun <T> HttpResponse.readBody(read: suspend (body: ByteReadChannel) -> T): T {
    val body = bodyAsChannel()
    try {
        return read(body)
    } finally {
        body.cancel()
    }
}

/** [this] response's body as UTF-8 text ([readBody]), or null when it is longer than [maxBytes]. */
internal suspend fun HttpResponse.readText(maxBytes: Long): String? {
    val body = readBody { it.readBuffer(maxBytes + 1) }
    return if (body.size > maxBytes) null else body.readString()
}
