package com.edde746.plezy.playback.resolve

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope

/** Deterministic high-entropy bytes (a 64-bit LCG's top byte): a file's content that no compression or pattern hides. */
internal fun lcgBytes(size: Int, seed: Long = 1): ByteArray {
    var x = seed
    return ByteArray(size) {
        x = x * 6364136223846793005L + 1442695040888963407L
        (x ushr 56).toByte()
    }
}

/**
 * A client over MockEngine. By default its engine runs on the test scheduler, so delays in handlers and the code's
 * timeouts use virtual time. Every request is recorded in [requests].
 */
internal class FakeHttp(
    scope: TestScope,
    followRedirects: Boolean = true,
    engineDispatcher: CoroutineDispatcher = StandardTestDispatcher(scope.testScheduler),
    private val handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
) {
    val requests = mutableListOf<HttpRequestData>()

    val client = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = engineDispatcher
                addHandler { request ->
                    requests += request
                    handler(request)
                }
            },
        ),
    ) {
        this.followRedirects = followRedirects
    }
}

/** `bytes=a-b` of a request, or null without a `Range` header. */
internal fun HttpRequestData.requestedRange(): LongRange? {
    val value = headers[HttpHeaders.Range] ?: return null
    val (first, last) = value.removePrefix("bytes=").split('-').map { it.toLong() }
    return first..last
}

/** Answers like a static file server with range support (`tools/media/serve.py`): 206, or 416 past the end. */
internal fun MockRequestHandleScope.serveFile(
    request: HttpRequestData,
    file: ByteArray,
    vararg extraHeaders: Pair<String, String>,
): HttpResponseData {
    val size = file.size.toLong()
    val range = request.requestedRange()
        ?: return respond(file, HttpStatusCode.OK, headers(HttpHeaders.ContentLength to "$size", *extraHeaders))
    if (range.first >= size) {
        return respond(ByteArray(0), HttpStatusCode.RequestedRangeNotSatisfiable, headers(HttpHeaders.ContentRange to "bytes */$size"))
    }
    val last = minOf(range.last, size - 1)
    return respondRange(file, range.first, last, size, *extraHeaders)
}

/** A 206 with `Content-Range: bytes [first]-[last]/[total]` and those bytes of [file]. */
internal fun MockRequestHandleScope.respondRange(
    file: ByteArray,
    first: Long,
    last: Long,
    total: Long = file.size.toLong(),
    vararg extraHeaders: Pair<String, String>,
): HttpResponseData = respond(
    file.copyOfRange(first.toInt(), last.toInt() + 1),
    HttpStatusCode.PartialContent,
    headers(
        HttpHeaders.ContentRange to "bytes $first-$last/$total",
        HttpHeaders.ContentLength to "${last - first + 1}",
        *extraHeaders,
    ),
)

internal fun MockRequestHandleScope.redirect(location: String, status: HttpStatusCode = HttpStatusCode.Found) =
    respond(ByteArray(0), status, headersOf(HttpHeaders.Location, location))

internal fun headers(vararg pairs: Pair<String, String>) = headersOf(*pairs.map { it.first to listOf(it.second) }.toTypedArray())
