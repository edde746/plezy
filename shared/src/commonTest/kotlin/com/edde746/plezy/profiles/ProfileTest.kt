package com.edde746.plezy.profiles

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ProfileTest {
    @Test
    fun pinHashesMatchTheStoredFormat() {
        assertEquals("a2779ae69839fea3247e7f508276ea5a588d45734004bced89590b08549d37fe", computePinHash("1234"))
        assertEquals("2a8bfa6148755622ed9cd520a5ce7808c2b271028108cc9e076edbf43eef3c17", computePinHash("0000"))
        assertNotEquals(computePinHash("1234"), computePinHash("5678"))
    }

    @Test
    fun verifyPinAcceptsOnlyThePinTheHashCameFrom() {
        val hash = computePinHash("4242")
        assertTrue(verifyPin("4242", hash))
        assertFalse(verifyPin("1111", hash))
    }

    @Test
    fun aLocalProfileIsPinProtectedOnlyWithANonEmptyHash() {
        assertTrue(LocalProfile("local-1", "Kids", pinHash = computePinHash("1234"), createdAt = 0).isPinProtected)
        assertFalse(LocalProfile("local-1", "Kids", pinHash = "", createdAt = 0).isPinProtected)
        assertFalse(LocalProfile("local-1", "Kids", createdAt = 0).isPinProtected)
    }

    @Test
    fun plexHomeProfileIdIsDeterministic() {
        assertEquals("plex-home-plex.dev1-uuid-1", plexHomeProfileId("plex.dev1", "uuid-1"))
    }

    @Test
    fun parseRoundTripsARealSixteenHexUuid() {
        val parsed = parsePlexHomeProfileId(plexHomeProfileId("plex.e443d57860076fc3", "379704d0c6601309"))
        assertEquals(PlexHomeProfileIdParts("plex.e443d57860076fc3", "379704d0c6601309"), parsed)
    }

    @Test
    fun parseRoundTripsADashedUuidUnderAHyphenatedAccountId() {
        val parsed = parsePlexHomeProfileId(plexHomeProfileId("plex.client-id-123", "a1b2c3d4-e5f6-7890-abcd-ef0123456789"))
        assertEquals(PlexHomeProfileIdParts("plex.client-id-123", "a1b2c3d4-e5f6-7890-abcd-ef0123456789"), parsed)
    }

    @Test
    fun parseTakesTheTrailingUuidWhenTheAccountIdEndsInHex() {
        val parsed = parsePlexHomeProfileId(plexHomeProfileId("acct-aaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbb"))
        assertEquals(PlexHomeProfileIdParts("acct-aaaaaaaaaaaaaaaa", "bbbbbbbbbbbbbbbb"), parsed)
    }

    @Test
    fun parseRejectsIdsThatAreNotPlexHomeIds() {
        assertNull(parsePlexHomeProfileId("local-1"))
        assertNull(parsePlexHomeProfileId("plex-home-only"))
        assertNull(parsePlexHomeProfileId("plex-home-acct-not-a-uuid"))
        assertNull(parsePlexHomeProfileId("plex-home-acct-aaaaaaaaaaaaaaa"))
        assertNull(parsePlexHomeProfileId("plex-home-acct-aaaaaaaaaaaaaaaaa"))
        assertNull(parsePlexHomeProfileId("plex-home--aaaaaaaaaaaaaaaa"))
    }

    @Test
    fun aPlexHomeProfileIsScopedByItsHomeUserAndOthersByTheirId() {
        assertEquals("379704d0c6601309", profileUserScope("plex-home-plex.acct-379704d0c6601309"))
        assertEquals("local-1", profileUserScope("local-1"))
    }

    @Test
    fun aVirtualPlexHomeProfileComesFromItsHomeUser() {
        val user = PlexHomeUser(
            id = 7, uuid = "379704d0c6601309", title = "kid", friendlyName = " ", thumb = "",
            hasPassword = true, restricted = true, protected = false,
        )
        val profile = PlexHomeProfile.virtualPlexHome("plex.acct", user, lastUsedAt = 5)
        assertEquals("plex-home-plex.acct-379704d0c6601309", profile.id)
        assertEquals("kid", profile.displayName, "a blank friendly name falls back to the title")
        assertNull(profile.avatarThumbUrl)
        assertEquals("plex.acct", profile.parentConnectionId)
        assertEquals(1, profile.sortOrder)
        assertEquals(0, profile.createdAt)
        assertEquals(5, profile.lastUsedAt)
        assertFalse(profile.isPinProtected, "Plex's protected flag gates the profile, not hasPassword")
        val admin = PlexHomeProfile.virtualPlexHome("plex.acct", user.copy(admin = true, protected = true, friendlyName = "Mum", thumb = "https://plex.tv/a"))
        assertEquals(0, admin.sortOrder)
        assertEquals("Mum", admin.displayName)
        assertEquals("https://plex.tv/a", admin.avatarThumbUrl)
        assertTrue(admin.isPinProtected)
    }
}
