package com.edde746.plezy.cast

import com.edde746.plezy.log.Log
import java.io.IOException
import java.net.Inet4Address
import java.net.NetworkInterface
import java.net.SocketException
import java.util.concurrent.Executors
import javax.jmdns.JmDNS
import javax.jmdns.ServiceEvent
import javax.jmdns.ServiceInfo
import javax.jmdns.ServiceListener
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate

/**
 * [CastDiscovery] over JmDNS on the desktop. A JmDNS responder binds one address, so there is one per IPv4 address of
 * every interface that is up (loopback and link-local addresses aside). The advertising ones are created on first use
 * and kept for the process; each browse makes its own and closes them when it ends: a listener added to a responder
 * that has run a while finds only what that responder announces itself (seen on Windows), while a new responder
 * queries the network. Every JmDNS call runs on one background thread: creating, closing a responder and registering
 * a service block.
 */
class JmdnsCastDiscovery : CastDiscovery {
    private val worker = Executors.newSingleThreadExecutor { Thread(it, "cast-discovery").apply { isDaemon = true } }

    /** Read on [worker] only. */
    private val responders: List<JmDNS> by lazy { createResponders() }

    override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
        val registered = ArrayList<Pair<JmDNS, ServiceInfo>>()
        worker.execute {
            for (responder in responders) {
                val info = ServiceInfo.create(TYPE, instance, port, 0, 0, txt)
                try {
                    responder.registerService(info)
                    registered += responder to info
                } catch (e: IOException) {
                    Log.w(TAG, e) { "Advertising $instance on ${responder.inetAddress} failed" }
                }
            }
        }
        return AutoCloseable {
            worker.execute {
                registered.forEach { (responder, info) -> responder.unregisterService(info) }
                registered.clear()
            }
        }
    }

    override fun localAddresses(): Set<String> = interfaceAddresses()

    override fun browse(): Flow<List<CastService>> = callbackFlow {
        // Each responder's resolved services by instance name; one service seen on several interfaces is one entry.
        val found = HashMap<JmDNS, MutableMap<String, CastService>>()

        fun publish() {
            val merged = LinkedHashMap<Pair<String, Int>, CastService>()
            for (service in found.values.flatMap { it.values }) {
                val key = service.instance to service.port
                val known = merged[key]
                merged[key] = known?.copy(hosts = (known.hosts + service.hosts).distinct()) ?: service
            }
            trySend(merged.values.map { it.copy(hosts = it.hosts.sortedBy { host -> ':' in host }) })
        }

        val listener = object : ServiceListener {
            override fun serviceAdded(event: ServiceEvent) {
                Log.i(TAG) { "Found ${event.name} on ${event.dns.name}; resolving" }
                // Asks for the service's records without waiting: serviceResolved follows once they arrive.
                event.dns.requestServiceInfo(event.type, event.name, 1)
            }

            override fun serviceRemoved(event: ServiceEvent) {
                synchronized(found) {
                    if (found[event.dns]?.remove(event.name) != null) publish()
                }
            }

            override fun serviceResolved(event: ServiceEvent) {
                val info = event.info
                val hosts = (info.inet4Addresses.toList() + info.inet6Addresses.toList()).mapNotNull { it.hostAddress }
                Log.i(TAG) { "Resolved ${info.name}: $hosts port ${info.port}" }
                if (hosts.isEmpty()) return
                val txt = info.propertyNames.toList().associateWith { info.getPropertyBytes(it)?.decodeToString().orEmpty() }
                synchronized(found) {
                    found.getOrPut(event.dns) { HashMap() }[info.name] = CastService(info.name, hosts, info.port, txt)
                    publish()
                }
            }
        }
        send(emptyList())
        // Read on [worker] only.
        var browsers: List<JmDNS> = emptyList()
        worker.execute {
            browsers = createResponders()
            if (browsers.isEmpty()) Log.w(TAG) { "No mDNS responder: no IPv4 interface that is up and multicasts" }
            Log.i(TAG) { "Browsing on ${browsers.size} responder(s)" }
            browsers.forEach { it.addServiceListener(TYPE, listener) }
        }
        awaitClose {
            worker.execute {
                browsers.forEach { browser ->
                    browser.removeServiceListener(TYPE, listener)
                    try {
                        browser.close()
                    } catch (e: IOException) {
                        Log.d(TAG, e) { "Closing a browsing responder failed" }
                    }
                }
            }
        }
    }.conflate()

    private companion object {
        const val TAG = "JmdnsCastDiscovery"
        const val TYPE = CastDiscovery.SERVICE_TYPE + ".local."

        fun createResponders(): List<JmDNS> = localAddresses().mapNotNull { address ->
            try {
                JmDNS.create(address).also { Log.i(TAG) { "mDNS responder on $address" } }
            } catch (e: IOException) {
                Log.w(TAG, e) { "No mDNS responder on $address" }
                null
            }
        }

        fun localAddresses(): List<Inet4Address> = try {
            NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
                .filter { it.isUp && !it.isLoopback && it.supportsMulticast() }
                .flatMap { it.inetAddresses.toList() }
                .filterIsInstance<Inet4Address>()
                .filter { !it.isLoopbackAddress && !it.isLinkLocalAddress }
        } catch (e: SocketException) {
            Log.w(TAG, e) { "Listing the network interfaces failed" }
            emptyList()
        }
    }
}
