package com.edde746.plezy

import android.net.NetworkCapabilities.TRANSPORT_CELLULAR
import android.net.NetworkCapabilities.TRANSPORT_ETHERNET
import android.net.NetworkCapabilities.TRANSPORT_VPN
import android.net.NetworkCapabilities.TRANSPORT_WIFI
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** A VPN costs what the networks under it cost, not what the system says of a VPN whose app declares nothing. */
class MeteredTest {
    private val wifi = NetworkLink(setOf(TRANSPORT_WIFI), unmetered = true)
    private val hotspot = NetworkLink(setOf(TRANSPORT_WIFI), unmetered = false)
    private val cellular = NetworkLink(setOf(TRANSPORT_CELLULAR), unmetered = false)
    private val ethernet = NetworkLink(setOf(TRANSPORT_ETHERNET), unmetered = true)

    private fun vpnOver(vararg transports: Int) = NetworkLink(setOf(TRANSPORT_VPN, *transports.toTypedArray()), unmetered = false)

    @Test
    fun aVpnOverAnUnmeteredWifiIsUnmetered() {
        assertFalse(metered(vpnOver(TRANSPORT_WIFI), listOf(wifi, cellular)))
        assertFalse(metered(vpnOver(TRANSPORT_ETHERNET), listOf(ethernet)))
    }

    @Test
    fun aVpnOverCellularOrAMeteredWifiIsMetered() {
        assertTrue(metered(vpnOver(TRANSPORT_CELLULAR), listOf(wifi, cellular)))
        assertTrue(metered(vpnOver(TRANSPORT_WIFI), listOf(hotspot)))
        assertTrue(metered(vpnOver(TRANSPORT_WIFI, TRANSPORT_CELLULAR), listOf(wifi, cellular)))
    }

    @Test
    fun aVpnWithNothingKnownUnderItIsMetered() {
        assertTrue(metered(vpnOver(), listOf(wifi)))
        assertTrue(metered(vpnOver(TRANSPORT_WIFI), emptyList()))
    }

    @Test
    fun aNetworkThatIsNoVpnIsWhatItSays() {
        assertFalse(metered(wifi, emptyList()))
        assertTrue(metered(hotspot, listOf(wifi)))
        assertFalse(metered(NetworkLink(setOf(TRANSPORT_VPN, TRANSPORT_WIFI), unmetered = true), emptyList()))
    }
}
