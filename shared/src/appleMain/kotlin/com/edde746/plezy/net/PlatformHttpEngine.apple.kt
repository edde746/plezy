package com.edde746.plezy.net

import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngineConfig
import io.ktor.client.engine.HttpClientEngineFactory
import io.ktor.client.engine.darwin.Darwin

internal actual val platformHttpEngine: HttpClientEngineFactory<HttpClientEngineConfig> = Darwin

// URLSession closes its connections itself when the device's network path changes.
internal actual fun HttpClient.closeIdleConnections() = Unit
