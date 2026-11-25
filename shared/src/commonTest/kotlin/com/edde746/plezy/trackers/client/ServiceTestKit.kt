package com.edde746.plezy.trackers.client

import com.edde746.plezy.trackers.MAX_APP_ANSWER_BYTES
import com.edde746.plezy.trackers.TrackerCredentials
import com.edde746.plezy.trackers.TrackerException
import com.edde746.plezy.trackers.TrackerService
import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.respond
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.Url
import io.ktor.http.content.OutgoingContent
import io.ktor.http.content.TextContent
import io.ktor.http.parseQueryString
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

/** A request a scripted service received; [contentType] is its body's, as sent. */
internal class Recorded(val method: String, val url: Url, val headers: Headers, val body: String, val contentType: String? = null) {
    val path: String get() = url.encodedPath

    fun json(): JsonObject = Json.parseToJsonElement(body).jsonObject

    /** A top-level string or number of the JSON body. */
    fun field(name: String): String? = (json()[name] as? JsonPrimitive)?.content

    fun form(): Map<String, String> = parseQueryString(body).entries().associate { it.key to it.value.single() }

    override fun toString(): String = "$method $url $body"
}

/** What a scripted service answers. */
internal class Answer(val status: Int = 200, val body: String = "", val headers: Map<String, String> = emptyMap())

internal fun json(body: String, status: Int = 200, headers: Map<String, String> = emptyMap()) = Answer(status, body, headers)

/**
 * A tracker service scripted from its documented answers: [answer] maps each request to a reply (or throws, for a
 * transport failure; it may suspend, for a slow answer), and every request is kept in [requests]. The engine runs on the test scheduler, so request
 * timeouts use virtual time.
 */
internal class ScriptedService(private val scope: TestScope, private val answer: suspend (Recorded) -> Answer) {
    val requests = ArrayList<Recorded>()

    val client = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = StandardTestDispatcher(scope.testScheduler)
                addHandler { request ->
                    val body = when (val content = request.body) {
                        is TextContent -> content.text
                        is OutgoingContent.ByteArrayContent -> content.bytes().decodeToString()
                        else -> ""
                    }
                    val recorded = Recorded(request.method.value, request.url, request.headers, body, request.body.contentType?.toString())
                    requests += recorded
                    val reply = answer(recorded)
                    val headers = Headers.build {
                        append(HttpHeaders.ContentType, "application/json")
                        reply.headers.forEach { (k, v) -> append(k, v) }
                    }
                    respond(reply.body, HttpStatusCode.fromValue(reply.status), headers)
                }
            },
        ),
    )

    /** [service]'s transport on the test's virtual clock. */
    fun http(service: TrackerService, userAgent: String? = null) =
        TrackerHttp(client, service, scope.testScheduler.timeSource, MAX_APP_ANSWER_BYTES, userAgent)

    /** The requests to [path], in order. */
    fun to(path: String): List<Recorded> = requests.filter { it.path == path }
}

/** An account's credentials: a 401 swaps [token] for [refreshed], or throws [refreshFailure]. */
internal class FakeCredentials(
    override val service: TrackerService,
    var token: String = "access-1",
    private val refreshed: String = "access-2",
) : TrackerCredentials {
    var refreshes = 0
    var invalidated = false
    var refreshFailure: TrackerException? = null

    override suspend fun accessToken(): String = token

    override suspend fun refreshAfterUnauthorized(rejected: String): String {
        refreshes++
        refreshFailure?.let { throw it }
        token = refreshed
        return token
    }

    override suspend fun invalidate(rejected: String) {
        invalidated = true
    }
}

/** Parses [text] for comparing JSON bodies regardless of formatting. */
internal fun parse(text: String): JsonElement = Json.parseToJsonElement(text)
