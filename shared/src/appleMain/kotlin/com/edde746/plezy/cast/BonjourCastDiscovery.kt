package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import kotlinx.cinterop.ByteVar
import kotlinx.cinterop.CPointer
import kotlinx.cinterop.CPointerVar
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.ObjCSignatureOverride
import kotlinx.cinterop.alloc
import kotlinx.cinterop.allocArray
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.pointed
import kotlinx.cinterop.ptr
import kotlinx.cinterop.readBytes
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.sizeOf
import kotlinx.cinterop.toKString
import kotlinx.cinterop.value
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate
import platform.Foundation.NSData
import platform.Foundation.NSNetService
import platform.Foundation.NSNetServiceBrowser
import platform.Foundation.NSNetServiceBrowserDelegateProtocol
import platform.Foundation.NSNetServiceDelegateProtocol
import platform.Foundation.NSString
import platform.Foundation.NSUTF8StringEncoding
import platform.Foundation.dataUsingEncoding
import platform.darwin.NSObject
import platform.darwin.dispatch_async
import platform.darwin.dispatch_get_main_queue
import platform.darwin.freeifaddrs
import platform.darwin.getifaddrs
import platform.darwin.ifaddrs
import platform.posix.AF_INET
import platform.posix.AF_INET6
import platform.posix.NI_MAXHOST
import platform.posix.NI_NUMERICHOST
import platform.posix.errno
import platform.posix.getnameinfo
import platform.posix.sockaddr
import platform.posix.sockaddr_in
import platform.posix.sockaddr_in6

/**
 * [CastDiscovery] over Bonjour (NSNetService, NSNetServiceBrowser). Both schedule on the run loop of the thread that
 * creates them, so every one is created, and called, on the main thread, where their delegates' callbacks then arrive.
 */
class BonjourCastDiscovery : CastDiscovery {
    override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
        val advertisement = Advertisement(instance)
        onMain {
            val service = NSNetService(domain = DOMAIN, type = TYPE, name = instance, port = port)
            service.delegate = advertisement
            if (!service.setTXTRecordData(NSNetService.dataFromTXTRecordDictionary(txtRecord(txt)))) {
                Log.w(TAG) { "Advertising $instance without its TXT record" }
            }
            service.publish()
            advertisement.service = service
        }
        return AutoCloseable {
            onMain {
                advertisement.service?.stop()
                advertisement.service = null
            }
        }
    }

    @OptIn(ExperimentalForeignApi::class)
    override fun localAddresses(): Set<String> = memScoped {
        val list = alloc<CPointerVar<ifaddrs>>()
        check(getifaddrs(list.ptr) == 0) { "getifaddrs failed: errno $errno" }
        try {
            generateSequence(list.value) { it.pointed.ifa_next }
                .mapNotNull { node -> node.pointed.ifa_addr?.let { hostOf(it) } }
                .toSet()
        } finally {
            freeifaddrs(list.value)
        }
    }

    override fun browse(): Flow<List<CastService>> = callbackFlow {
        val browsing = Browsing { trySend(it) }
        send(emptyList())
        onMain { browsing.start() }
        awaitClose { onMain { browsing.stop() } }
    }.conflate()

    /** A published service and its delegate, which logs how the publish went. Main thread. */
    private class Advertisement(private val instance: String) : NSObject(), NSNetServiceDelegateProtocol {
        var service: NSNetService? = null

        override fun netServiceDidPublish(sender: NSNetService) {
            Log.i(TAG) { "Advertising ${sender.name}" }
        }

        override fun netService(sender: NSNetService, didNotPublish: Map<Any?, *>) {
            Log.w(TAG) { "Advertising $instance failed: $didNotPublish" }
        }
    }

    /**
     * One browse: the browser's delegate and that of every service it finds, which it holds (the delegate references
     * are weak) until the service goes away, and resolves. Main thread.
     */
    private class Browsing(private val publish: (List<CastService>) -> Unit) :
        NSObject(),
        NSNetServiceBrowserDelegateProtocol,
        NSNetServiceDelegateProtocol {
        /** Made in [start], on the main thread, whose run loop it then reports on. */
        private var browser: NSNetServiceBrowser? = null
        private val found = HashMap<String, NSNetService>()
        private val resolved = LinkedHashMap<String, CastService>()

        fun start() {
            val browser = NSNetServiceBrowser()
            browser.delegate = this
            browser.searchForServicesOfType(TYPE, inDomain = DOMAIN)
            this.browser = browser
            Log.i(TAG) { "Browsing for $TYPE" }
        }

        fun stop() {
            browser?.stop()
            browser?.delegate = null
            browser = null
            found.values.forEach {
                it.stop()
                it.delegate = null
            }
            found.clear()
        }

        @ObjCSignatureOverride
        override fun netServiceBrowser(browser: NSNetServiceBrowser, didFindService: NSNetService, moreComing: Boolean) {
            Log.i(TAG) { "Found ${didFindService.name}; resolving" }
            found.put(didFindService.name, didFindService)?.stop()
            didFindService.delegate = this
            didFindService.resolveWithTimeout(RESOLVE_TIMEOUT_SECONDS)
        }

        @ObjCSignatureOverride
        override fun netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService: NSNetService, moreComing: Boolean) {
            found.remove(didRemoveService.name)?.let {
                it.stop()
                it.delegate = null
            }
            if (resolved.remove(didRemoveService.name) != null) publish(resolved.values.toList())
        }

        override fun netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch: Map<Any?, *>) {
            Log.w(TAG) { "Browsing failed: $didNotSearch" }
        }

        override fun netServiceDidResolveAddress(sender: NSNetService) {
            // The same service, as Objective-C compares it: Kotlin's wrapper of the object Bonjour reports isn't the one
            // held, so `===` never matches.
            if (found[sender.name] != sender) return
            val hosts = sender.addresses.orEmpty().filterIsInstance<NSData>().mapNotNull { hostOf(it) }.distinct()
                .sortedBy { ':' in it }
            Log.i(TAG) { "Resolved ${sender.name}: $hosts port ${sender.port}" }
            if (hosts.isEmpty()) return
            val record = sender.TXTRecordData()?.let { NSNetService.dictionaryFromTXTRecordData(it) } ?: emptyMap<Any?, Any?>()
            val txt = buildMap<String, String> {
                for ((key, value) in record) if (key is String) put(key, (value as? NSData)?.let { utf8(it) }.orEmpty())
            }
            resolved[sender.name] = CastService(sender.name, hosts, sender.port.toInt(), txt)
            publish(resolved.values.toList())
        }

        override fun netService(sender: NSNetService, didNotResolve: Map<Any?, *>) {
            Log.w(TAG) { "Resolving ${sender.name} failed: $didNotResolve" }
        }
    }

    private companion object {
        const val TAG = "BonjourCastDiscovery"
        const val TYPE = CastDiscovery.SERVICE_TYPE + "."
        const val DOMAIN = "local."
        const val RESOLVE_TIMEOUT_SECONDS = 5.0

        fun onMain(block: () -> Unit) = dispatch_async(dispatch_get_main_queue(), block)

        /** [txt] as the dictionary Bonjour encodes a TXT record from: each value UTF-8 data. */
        @Suppress("CAST_NEVER_SUCCEEDS")
        fun txtRecord(txt: Map<String, String>): Map<Any?, Any?> = buildMap {
            for ((key, value) in txt) put(key, (value as NSString).dataUsingEncoding(NSUTF8StringEncoding))
        }

        /** The numeric host (IPv4 or IPv6, with its scope) of a socket address Bonjour resolved. */
        @OptIn(ExperimentalForeignApi::class)
        fun hostOf(address: NSData): String? = address.bytes?.reinterpret<sockaddr>()?.let { hostOf(it) }

        /** The numeric host of [socket]; null for an address that isn't IP (a link-layer one). */
        @OptIn(ExperimentalForeignApi::class)
        fun hostOf(socket: CPointer<sockaddr>): String? = memScoped {
            val length = when (socket.pointed.sa_family.toInt()) {
                AF_INET -> sizeOf<sockaddr_in>()
                AF_INET6 -> sizeOf<sockaddr_in6>()
                else -> return null
            }
            val host = allocArray<ByteVar>(NI_MAXHOST)
            val failed = getnameinfo(socket, length.convert(), host, NI_MAXHOST.convert(), null, 0u, NI_NUMERICHOST)
            if (failed != 0) null else host.toKString()
        }

        @OptIn(ExperimentalForeignApi::class)
        fun utf8(data: NSData): String =
            data.bytes?.reinterpret<ByteVar>()?.readBytes(data.length.toInt())?.decodeToString().orEmpty()
    }
}
