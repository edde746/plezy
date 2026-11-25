package com.edde746.plezy.cast

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import com.edde746.plezy.log.Log
import java.net.Inet4Address
import java.net.InetAddress
import kotlin.concurrent.thread
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.conflate

/**
 * [CastDiscovery] over Android's NsdManager, which runs the system's mDNS responder (no multicast lock needed).
 * NsdManager resolves one service at a time before Android 14 (a second resolve fails with FAILURE_ALREADY_ACTIVE), so
 * a browse resolves the services it finds in turn.
 */
class NsdCastDiscovery(context: Context) : CastDiscovery {
    // Before Android 13 NsdManager's constructor waits for the system's NSD service to answer (over 200 ms on a Fire TV
    // as the app starts), so it is made on a thread of its own as discovery is built, not on the main thread.
    private val nsd: NsdManager by lazy { context.applicationContext.getSystemService(NsdManager::class.java) }

    init {
        thread(name = "NsdManager start") { nsd }
    }

    override fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable {
        val info = NsdServiceInfo().apply {
            serviceName = instance
            serviceType = CastDiscovery.SERVICE_TYPE
            this.port = port
            txt.forEach { (key, value) -> setAttribute(key, value) }
        }
        val listener = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(serviceInfo: NsdServiceInfo) = Unit

            override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG) { "Advertising $instance failed: $errorCode" }
            }

            override fun onServiceUnregistered(serviceInfo: NsdServiceInfo) = Unit

            override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                Log.w(TAG) { "Withdrawing $instance failed: $errorCode" }
            }
        }
        nsd.registerService(info, NsdManager.PROTOCOL_DNS_SD, listener)
        return AutoCloseable {
            try {
                nsd.unregisterService(listener)
            } catch (e: IllegalArgumentException) {
                // NsdManager forgets a listener whose registration failed, and one already unregistered.
                Log.w(TAG, e) { "$instance was not advertised" }
            }
        }
    }

    override fun localAddresses(): Set<String> = interfaceAddresses()

    override fun browse(): Flow<List<CastService>> = callbackFlow {
        val lock = Any()
        val services = LinkedHashMap<String, CastService>()
        val found = HashSet<String>()
        val pending = ArrayDeque<NsdServiceInfo>()
        var resolving = false
        var stopped = false

        fun publish() {
            trySend(services.values.toList())
        }

        fun resolveNext() {
            if (resolving || stopped) return
            val next = pending.removeFirstOrNull() ?: return
            resolving = true
            @Suppress("DEPRECATION") // resolveService's replacement, registerServiceInfoCallback, is API 34+.
            nsd.resolveService(next, object : NsdManager.ResolveListener {
                override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                    synchronized(lock) {
                        resolving = false
                        val hosts = hostsOf(serviceInfo).sortedBy { it !is Inet4Address }.mapNotNull { it.hostAddress }
                        // A service lost while it resolved stays out.
                        if (serviceInfo.serviceName in found && hosts.isNotEmpty()) {
                            services[serviceInfo.serviceName] = CastService(
                                instance = serviceInfo.serviceName,
                                hosts = hosts,
                                port = serviceInfo.port,
                                txt = serviceInfo.attributes.mapValues { (_, value) -> value?.decodeToString().orEmpty() },
                            )
                            publish()
                        }
                        resolveNext()
                    }
                }

                override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                    synchronized(lock) {
                        resolving = false
                        Log.w(TAG) { "Resolving ${serviceInfo.serviceName} failed: $errorCode" }
                        resolveNext()
                    }
                }
            })
        }

        val listener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) = Unit

            override fun onDiscoveryStopped(serviceType: String) = Unit

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG) { "Browsing failed: $errorCode" }
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.w(TAG) { "Stopping browsing failed: $errorCode" }
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                synchronized(lock) {
                    found += serviceInfo.serviceName
                    pending.removeAll { it.serviceName == serviceInfo.serviceName }
                    pending.addLast(serviceInfo)
                    resolveNext()
                }
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                synchronized(lock) {
                    found -= serviceInfo.serviceName
                    pending.removeAll { it.serviceName == serviceInfo.serviceName }
                    if (services.remove(serviceInfo.serviceName) != null) publish()
                }
            }
        }
        publish()
        nsd.discoverServices(CastDiscovery.SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, listener)
        awaitClose {
            synchronized(lock) { stopped = true }
            try {
                nsd.stopServiceDiscovery(listener)
            } catch (e: IllegalArgumentException) {
                // NsdManager forgets the listener of a browse that failed to start.
                Log.w(TAG, e) { "Browsing had not started" }
            }
        }
    }.conflate()

    private companion object {
        const val TAG = "NsdCastDiscovery"

        /** A resolved service's addresses: every one from Android 14, the one [NsdServiceInfo.getHost] has before. */
        fun hostsOf(info: NsdServiceInfo): List<InetAddress> =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                info.hostAddresses
            } else {
                @Suppress("DEPRECATION")
                listOfNotNull(info.host)
            }
    }
}
