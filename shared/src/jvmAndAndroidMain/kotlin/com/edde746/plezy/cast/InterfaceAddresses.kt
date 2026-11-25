package com.edde746.plezy.cast

import java.net.NetworkInterface

/** Every address of this machine's interfaces, loopback included, as [java.net.InetAddress.getHostAddress] writes it. */
internal fun interfaceAddresses(): Set<String> =
    NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
        .flatMap { it.inetAddresses.toList() }
        .mapNotNullTo(HashSet()) { it.hostAddress }
