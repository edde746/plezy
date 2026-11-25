package com.edde746.plezy.jellyfin

import com.edde746.plezy.net.UriComponent
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class JellyfinAuthHeaderTest {
    /** The server's own parse: split on top-level commas, strip quotes, URL-decode. */
    private fun parse(header: String): Map<String, String> {
        assertTrue(header.startsWith("MediaBrowser "))
        return header.removePrefix("MediaBrowser ").split(", ").associate { part ->
            val eq = part.indexOf('=')
            part.substring(0, eq) to UriComponent.decode(part.substring(eq + 1).replace("\"", ""))
        }
    }

    @Test fun formatsSdkStyleHeader() = assertEquals(
        "MediaBrowser Client=\"Plezy\", Device=\"Living%20Room%20TV\", DeviceId=\"dev-1\", Version=\"1.2.3\", Token=\"tok\"",
        JellyfinAuthHeader.build("Plezy", "1.2.3", "Living Room TV", "dev-1", "tok"),
    )

    @Test fun omitsTokenWhenNullOrEmpty() = listOf(null, "").forEach {
        assertFalse("Token=" in JellyfinAuthHeader.build("Plezy", "1.2.3", "Plezy", "dev-1", it))
    }

    @Test fun nonAsciiDeviceNameTravelsAsAscii() {
        val name = "Bjørn stue-TV 客厅 📺"
        val header = JellyfinAuthHeader.build("Plezy", "2.10.0", name, "dev-1", "tok")
        assertTrue(header.all { it.code in 0x20..0x7E })
        assertEquals(name, parse(header)["Device"])
    }

    @Test fun grammarHazardsSurvive() {
        val name = "My \"cool\", TV = 1+2 100%"
        val parsed = parse(JellyfinAuthHeader.build("Plezy", "1.2.3", name, "dev-1", "tok"))
        assertEquals(mapOf("Client" to "Plezy", "Device" to name, "DeviceId" to "dev-1", "Version" to "1.2.3", "Token" to "tok"), parsed)
    }

    @Test fun requiredFieldsFallBack() = assertEquals(
        "MediaBrowser Client=\"Plezy\", Device=\"Plezy\", DeviceId=\"dev-1\", Version=\"1.0\"",
        JellyfinAuthHeader.build("", "   ", "\u0000\u007f", "dev-1"),
    )

    @Test fun omitsEmptyDeviceId() {
        val header = JellyfinAuthHeader.build("Plezy", "1.2.3", "Living Room", "", "tok")
        assertFalse("DeviceId=" in header)
        assertTrue("Token=\"tok\"" in header)
    }

    @Test fun rejectsUnsafeUnauthenticatedDeviceId() {
        for (id in listOf("", " dev-1 ", "dev\u0000-1", "\"dev-1\"")) {
            assertFailsWith<IllegalArgumentException> { JellyfinAuthHeader.requireDeviceId(id) }
        }
        assertEquals("dev-1", JellyfinAuthHeader.requireDeviceId("dev-1"))
    }

    @Test fun clientNameAppendsPlatform() {
        for (p in listOf("iOS", "Android", "macOS", "Windows", "Linux")) assertEquals("Plezy $p", JellyfinAuthHeader.clientName(p, false))
        assertEquals("Plezy Android TV", JellyfinAuthHeader.clientName("Android", true))
        assertEquals("Plezy Android TV", JellyfinAuthHeader.clientName("android", true))
        assertEquals("Plezy tvOS", JellyfinAuthHeader.clientName("tvOS", true))
        assertEquals("Plezy Linux", JellyfinAuthHeader.clientName("Linux", true))
        assertEquals("Plezy", JellyfinAuthHeader.clientName("", false))
        assertEquals("Plezy", JellyfinAuthHeader.clientName(" \u0000 ", false))
        val header = JellyfinAuthHeader.build(JellyfinAuthHeader.clientName("Android", true), "2.19.0", "Living Room Shield", "dev-1")
        assertEquals("Plezy Android TV", parse(header)["Client"])
    }

    @Test fun deviceNameFallbacks() {
        assertEquals("Bob's iPhone", JellyfinAuthHeader.deviceName("iOS", "iPhone", "  Bob's iPhone "))
        assertEquals("Apple TV", JellyfinAuthHeader.deviceName("tvOS", "Apple TV"))
        assertEquals("Apple TV", JellyfinAuthHeader.deviceName("tvOS", "Apple TV", "   "))
        assertEquals("Linux", JellyfinAuthHeader.deviceName("Linux"))
        assertEquals("Linux", JellyfinAuthHeader.deviceName("Linux", "\u0000"))
        assertEquals("Plezy", JellyfinAuthHeader.deviceName(""))
    }
}
