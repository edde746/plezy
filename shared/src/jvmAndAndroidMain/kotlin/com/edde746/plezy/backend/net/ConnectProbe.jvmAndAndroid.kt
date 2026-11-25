package com.edde746.plezy.backend.net

import io.ktor.client.engine.HttpClientEngine
import io.ktor.http.Url

// OkHttp bounds the connect to the request's connect timeout itself.
internal actual fun connectProbe(engine: HttpClientEngine): (suspend (Url) -> Unit)? = null
