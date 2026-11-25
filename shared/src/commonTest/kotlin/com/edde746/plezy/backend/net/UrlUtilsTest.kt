package com.edde746.plezy.backend.net

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class UrlUtilsTest {
    private val guesses = listOf(BaseUrlGuess("https", null), BaseUrlGuess("http", null), BaseUrlGuess("http", 5055))

    @Test
    fun stripTrailingSlashRemovesOneSlashAndTrims() {
        assertEquals("https://host", stripTrailingSlash("https://host/"))
        assertEquals("https://host", stripTrailingSlash("  https://host  "))
        assertEquals("", stripTrailingSlash(""))
    }

    // FFmpeg's protocol lookup is case-sensitive: "Https://" handed to the player fails with "Protocol not found".
    @Test
    fun canonicalizeBaseUrlLowercasesAMixedCaseScheme() {
        assertEquals("https://jellyfin.example.com", canonicalizeBaseUrl("Https://jellyfin.example.com"))
        assertEquals("https://jellyfin.example.com", canonicalizeBaseUrl("HTTPS://jellyfin.example.com"))
    }

    @Test
    fun canonicalizeBaseUrlTouchesOnlyTheScheme() {
        assertEquals("http://Host.Example.com:8096/JellyFin", canonicalizeBaseUrl("HTTP://Host.Example.com:8096/JellyFin"))
    }

    @Test
    fun canonicalizeBaseUrlStripsTrailingSlashAndWhitespace() {
        assertEquals("https://host:8096/jellyfin", canonicalizeBaseUrl(" Https://host:8096/jellyfin/ "))
    }

    @Test
    fun canonicalizeBaseUrlLeavesSchemelessInputUnchanged() {
        assertEquals("host:8096", canonicalizeBaseUrl("host:8096"))
        assertEquals("Host.example.com", canonicalizeBaseUrl("Host.example.com"))
        assertEquals("", canonicalizeBaseUrl(""))
    }

    @Test
    fun anExplicitSchemeIsAuthoritativeAndComesBackAlone() {
        assertEquals(listOf("https://seerr.example.com"), expandBaseUrlCandidates("HTTPS://seerr.example.com/", guesses))
        assertEquals(listOf("http://192.168.1.5:5055"), expandBaseUrlCandidates("http://192.168.1.5:5055", guesses))
    }

    @Test
    fun everyGuessAppliesInOrderToABareHost() {
        assertEquals(
            listOf("https://seerr.example.com", "http://seerr.example.com", "http://seerr.example.com:5055"),
            expandBaseUrlCandidates("seerr.example.com", guesses),
        )
    }

    @Test
    fun aTypedPortBeatsTheGuessedOneAndCollapsesDuplicates() {
        assertEquals(listOf("https://192.168.1.5:5055", "http://192.168.1.5:5055"), expandBaseUrlCandidates("192.168.1.5:5055", guesses))
    }

    @Test
    fun aSubPathStaysOnEveryCandidateWhileQueryAndFragmentDrop() {
        assertEquals(
            listOf("https://example.com/seerr", "http://example.com/seerr", "http://example.com:5055/seerr"),
            expandBaseUrlCandidates("example.com/seerr?a=1#top", guesses),
        )
    }

    @Test
    fun inputWithNothingToReachExpandsToNothing() {
        assertEquals(emptyList(), expandBaseUrlCandidates("   ", guesses))
        // Hostless: no guess could build a URL that resolves anywhere.
        assertEquals(emptyList(), expandBaseUrlCandidates("/seerr", guesses))
    }

    @Test
    fun hasUrlSchemeRecognizesOnlyARealLeadingScheme() {
        assertTrue(hasUrlScheme("https://host"))
        assertTrue(hasUrlScheme("jellyfin+tls://host"))
        assertFalse(hasUrlScheme("host:8096"))
        assertFalse(hasUrlScheme("host/https://nested"))
    }

    @Test
    fun queryParametersKeepTheirOrderAndEncodeBothSidesAsEncodeUriComponent() {
        val query = linkedMapOf<String, Any?>("sort" to "addedAt:desc", "title" to "Tom & Jerry", "a b" to "ü/?#=")
        assertEquals("sort=addedAt%3Adesc&title=Tom%20%26%20Jerry&a%20b=%C3%BC%2F%3F%23%3D", encodeQueryParameters(query))
    }

    @Test
    fun nullValuesAreSkippedAndAnIterableRepeatsItsKey() {
        val query = linkedMapOf<String, Any?>("skip" to null, "id" to listOf(1, 2), "start" to 0)
        assertEquals("id=1&id=2&start=0", encodeQueryParameters(query))
        assertEquals("", encodeQueryParameters(null))
        assertEquals("", encodeQueryParameters(mapOf("only" to null)))
    }
}
