package com.edde746.plezy.backend.net

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.darwin.DarwinClientEngineConfig
import io.ktor.http.Url
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.convert
import kotlinx.cinterop.reinterpret
import kotlinx.coroutines.suspendCancellableCoroutine
import platform.CFNetwork.CFNetworkCopyProxiesForURL
import platform.CFNetwork.CFNetworkCopySystemProxySettings
import platform.CFNetwork.kCFProxyTypeKey
import platform.CFNetwork.kCFProxyTypeNone
import platform.CoreFoundation.CFArrayGetCount
import platform.CoreFoundation.CFArrayGetValueAtIndex
import platform.CoreFoundation.CFDictionaryGetValue
import platform.CoreFoundation.CFRelease
import platform.CoreFoundation.CFStringCompare
import platform.CoreFoundation.CFStringCreateWithCString
import platform.CoreFoundation.CFURLCreateWithString
import platform.CoreFoundation.kCFCompareEqualTo
import platform.CoreFoundation.kCFStringEncodingUTF8
import platform.Network.nw_connection_cancel
import platform.Network.nw_connection_create
import platform.Network.nw_connection_set_queue
import platform.Network.nw_connection_set_state_changed_handler
import platform.Network.nw_connection_start
import platform.Network.nw_connection_state_ready
import platform.Network.nw_endpoint_create_host
import platform.Network.nw_parameters_copy_default_protocol_stack
import platform.Network.nw_parameters_create
import platform.Network.nw_protocol_stack_set_transport_protocol
import platform.Network.nw_tcp_create_options
import platform.darwin.dispatch_get_global_queue
import platform.posix.QOS_CLASS_UTILITY
import kotlin.coroutines.resume

/**
 * URLSession has no connect timeout, so for the Darwin engine a Network framework TCP connection to the request's host
 * and port (which, like URLSession, races the host's addresses) stands in for its connect. A URL the system sends
 * through a proxy returns at once: the direct path says nothing about it. Any other engine is not URLSession: it bounds
 * its own connect, or (MockEngine) makes none to bound.
 */
internal actual fun connectProbe(engine: HttpClientEngine): (suspend (Url) -> Unit)? =
    if (engine.config is DarwinClientEngineConfig) ::awaitDirectConnect else null

@OptIn(ExperimentalForeignApi::class)
private suspend fun awaitDirectConnect(url: Url) {
    if (goesThroughProxy(url)) return
    val endpoint = nw_endpoint_create_host(url.host.removeSurrounding("[", "]"), url.port.toString())
    // A plain TCP stack: nw_parameters_create_secure_tcp's "disable TLS" marker is a block compared by identity, which
    // doesn't survive the trip through a Kotlin lambda.
    val parameters = nw_parameters_create()
    nw_protocol_stack_set_transport_protocol(nw_parameters_copy_default_protocol_stack(parameters), nw_tcp_create_options())
    val connection = nw_connection_create(endpoint, parameters)
    try {
        suspendCancellableCoroutine { continuation ->
            nw_connection_set_state_changed_handler(connection) { state, _ ->
                if (state == nw_connection_state_ready) continuation.resume(Unit)
            }
            nw_connection_set_queue(connection, dispatch_get_global_queue(QOS_CLASS_UTILITY.convert(), 0u))
            nw_connection_start(connection)
        }
    } finally {
        nw_connection_cancel(connection)
    }
}

@OptIn(ExperimentalForeignApi::class)
private fun goesThroughProxy(url: Url): Boolean {
    val settings = CFNetworkCopySystemProxySettings() ?: return false
    val string = CFStringCreateWithCString(null, url.toString(), kCFStringEncodingUTF8)
    val target = CFURLCreateWithString(null, string, null)
    val proxies = CFNetworkCopyProxiesForURL(target, settings)
    val first = proxies?.takeIf { CFArrayGetCount(it) > 0 }?.let { CFArrayGetValueAtIndex(it, 0) }
    val type = first?.let { CFDictionaryGetValue(it.reinterpret(), kCFProxyTypeKey) }
    val proxied = type != null && CFStringCompare(type.reinterpret(), kCFProxyTypeNone, 0u) != kCFCompareEqualTo
    proxies?.let(::CFRelease)
    target?.let(::CFRelease)
    string?.let(::CFRelease)
    CFRelease(settings)
    return proxied
}
