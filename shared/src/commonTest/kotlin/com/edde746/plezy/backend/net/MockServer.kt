package com.edde746.plezy.backend.net

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockEngineConfig
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope

/**
 * A media server behind MockEngine, run on the test scheduler so handler delays and the client's timeouts share virtual
 * time. Every request is recorded in [requests].
 */
internal class MockServer(scope: TestScope, private val handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData) {
    private val recorded = MutableStateFlow(emptyList<HttpRequestData>())

    /**
     * The requests so far, oldest first: a snapshot, safe to read from any thread while the scheduler's thread records
     * more (a test waiting for one in real time reads it off the test thread).
     */
    val requests: List<HttpRequestData> get() = recorded.value

    fun clearRequests() = recorded.update { emptyList() }

    val http = HttpClient(
        MockEngine(
            MockEngineConfig().apply {
                dispatcher = StandardTestDispatcher(scope.testScheduler)
                addHandler { request ->
                    recorded.update { it + request }
                    handler(request)
                }
            },
        ),
    ) { install(HttpTimeout) }
}

internal fun MockRequestHandleScope.respondJson(body: String, status: HttpStatusCode = HttpStatusCode.OK) =
    respond(body, status, headersOf(HttpHeaders.ContentType, "application/json"))
