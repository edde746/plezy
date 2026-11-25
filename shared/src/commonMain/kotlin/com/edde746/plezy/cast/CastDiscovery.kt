package com.edde746.plezy.cast

import kotlinx.coroutines.flow.Flow

/**
 * A receiver as DNS-SD resolved it: its service [instance] name, its addresses ([hosts], IP literals, IPv4 first), its
 * link's [port] and its TXT record ([txt]: `id`, `name`, `platform`, `kind`).
 */
data class CastService(val instance: String, val hosts: List<String>, val port: Int, val txt: Map<String, String>)

/**
 * DNS-SD (Bonjour) for [SERVICE_TYPE] on the local network: a receiver advertises itself, a sender browses for
 * receivers. The platform's own service where it has one (Apple's Bonjour, Android's NsdManager), an mDNS library on
 * the desktop.
 */
interface CastDiscovery {
    /**
     * Advertises this receiver as [instance] on [port] with [txt] until the returned handle closes. The system may
     * rename the instance on a clash; the TXT record's `id` is what senders go by.
     */
    fun advertise(instance: String, port: Int, txt: Map<String, String>): AutoCloseable

    /**
     * The receivers on the network, resolved, for as long as the flow is collected: a service is in the list once it
     * resolved and leaves it once it goes away. The first emission may be empty.
     */
    fun browse(): Flow<List<CastService>>

    /**
     * This machine's own interface addresses (loopback included) as IP literals, written as [browse] writes a service's
     * hosts: a receiver found only there runs on this machine (another app or install here) and is never a target.
     */
    fun localAddresses(): Set<String>

    companion object {
        /** The service type, as Apple's `NSBonjourServices` lists it too. */
        const val SERVICE_TYPE: String = "_plezy-cast._tcp"
    }
}
