package com.edde746.plezy.servers

import com.edde746.plezy.model.ServerId
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ActiveClientScopeTest {
    private val jellyfin = ServerId("jf-machine")
    private val plex = ServerId("plex-machine")

    @Test
    fun noBoundClientHasNoActiveScope() {
        assertNull(resolveActiveClientScopeId(jellyfin, null))
    }

    @Test
    fun anEmptyCacheScopeIsRejected() {
        assertNull(resolveActiveClientScopeId(jellyfin, ""))
    }

    @Test
    fun theBareServerScopeIsRejected() {
        assertNull(resolveActiveClientScopeId(jellyfin, "jf-machine"))
    }

    @Test
    fun emptyAndForeignCompoundScopesAreRejected() {
        assertNull(resolveActiveClientScopeId(jellyfin, "jf-machine/"))
        assertNull(resolveActiveClientScopeId(jellyfin, "other-machine/user-a"))
    }

    @Test
    fun usersOnTheSameServerKeepDistinctActiveScopes() {
        assertEquals("jf-machine/user-a", resolveActiveClientScopeId(jellyfin, mediaBrowserScopeId(jellyfin, "user-a")))
        assertEquals("jf-machine/user-b", resolveActiveClientScopeId(jellyfin, "jf-machine/user-b"))
    }

    @Test
    fun theTransferScopeBelongsToNoOne() {
        assertNull(resolveActiveClientScopeId(plex, PlexTransferScopeId.of(plex).value))
    }

    @Test
    fun plexProfileScopesAreDeterministicProfileSpecificAndPubliclyProjected() {
        val a = PlexProfileScopeId.of(plex, "profile-a")
        assertEquals("plex-machine/~plex-profile/profile-a", a.value)
        assertEquals(a, PlexProfileScopeId.of(plex, "profile-a"))
        assertNotEquals(a, PlexProfileScopeId.of(plex, "profile-b"))
        assertEquals(plex, a.publicServerId)
        assertEquals("profile-a", a.profileId)
        assertEquals(a, PlexProfileScopeId.tryParse(a.value))
        assertEquals(plex, publicPlexServerIdFromScope(a.value))
        assertEquals(a.value, resolveActiveClientScopeId(plex, a.value))
        assertNull(resolveActiveClientScopeId(ServerId("other"), a.value))
        assertFailsWith<IllegalArgumentException> { PlexProfileScopeId.of(plex, "") }
    }

    @Test
    fun profileIdsAreUriComponentEncodedSoAScopeNeverReadsAsAJellyfinUser() {
        val scope = PlexProfileScopeId.of(plex, "profile/a b!*'()~é")
        assertEquals("plex-machine/~plex-profile/profile%2Fa%20b!*'()~%C3%A9", scope.value)
        assertEquals("profile/a b!*'()~é", PlexProfileScopeId.tryParse(scope.value)?.profileId)
        assertTrue(isPlexProfileScopeId(scope.value))
        assertFalse(isJellyfinUserScopeId(plex, scope.value))
        assertNull(publicPlexServerIdFromScope("plex-machine/user-a"))
    }

    @Test
    fun malformedProfileScopesDoNotParse() {
        for (value in listOf(
            "   /~plex-profile/profile-a",
            "/~plex-profile/profile-a",
            "plex-machine/~plex-profile/",
            "plex-machine/~plex-profile/a/b",
            "plex-machine/~plex-profile/%zz",
            "plex-machine/~plex-profile/%4",
            "plex-machine/~plex-profile/%FF",
        )) {
            assertNull(PlexProfileScopeId.tryParse(value), value)
            assertNull(publicPlexServerIdFromScope(value), value)
            assertFalse(isPlexProfileScopeId(value), value)
        }
    }

    @Test
    fun transferScopesNameTheirPublicServer() {
        val transfer = PlexTransferScopeId.of(plex).value
        assertEquals("plex-machine/~plex-transfer", transfer)
        assertEquals(plex, publicPlexServerIdFromCacheScope(transfer))
        assertEquals(plex, publicPlexServerIdFromCacheScope(PlexProfileScopeId.of(plex, "p").value))
        assertNull(publicPlexServerIdFromScope(transfer), "not a profile scope")
        assertNull(publicPlexServerIdFromCacheScope("/~plex-transfer"))
        assertFalse(isJellyfinUserScopeId(plex, transfer))
    }
}
