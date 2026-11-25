package com.edde746.plezy

import android.security.NetworkSecurityPolicy
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** The app's network security config as the system applies it: fixed endpoints refuse plain HTTP, the LAN keeps it. */
class NetworkSecurityTest {
    private val policy = NetworkSecurityPolicy.getInstance()

    @Test
    fun fixedEndpointsRefusePlainHttp() {
        assertFalse(policy.isCleartextTrafficPermitted("plex.tv"))
        assertFalse(policy.isCleartextTrafficPermitted("clients.plex.tv"))
    }

    @Test
    fun aServerOnTheLanKeepsPlainHttp() {
        assertTrue(policy.isCleartextTrafficPermitted("192.168.1.10"))
    }
}
