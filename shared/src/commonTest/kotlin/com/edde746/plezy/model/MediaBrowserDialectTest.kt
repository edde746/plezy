package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Detection inputs are the discriminating fields of real `/System/Info/Public` bodies (Jellyfin 10.10.7, Emby 4.9.5). */
class MediaBrowserDialectTest {
    @Test fun fromIdReadsTheStoredIds() {
        assertEquals(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.fromId("jellyfin"))
        assertEquals(MediaBrowserDialect.EMBY, MediaBrowserDialect.fromId("emby"))
    }

    @Test fun fromIdThrowsOnUnknownId() { assertFailsWith<IllegalArgumentException> { MediaBrowserDialect.fromId("plex") } }

    @Test fun idsMatchBackendIds() = MediaBrowserDialect.entries.forEach {
        assertEquals(it.id, it.backend.id)
        assertEquals(it, it.backend.dialect)
    }

    @Test fun fromIdOrJellyfinToleratesLegacyRows() {
        assertEquals(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.fromIdOrJellyfin(null))
        assertEquals(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.fromIdOrJellyfin(""))
        assertEquals(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.fromIdOrJellyfin("nonsense"))
        assertEquals(MediaBrowserDialect.EMBY, MediaBrowserDialect.fromIdOrJellyfin("emby"))
    }

    @Test fun detectsJellyfinByProductName() =
        assertEquals(MediaBrowserDialect.JELLYFIN, MediaBrowserDialect.detectFromPublicSystemInfo("Jellyfin Server", false))

    @Test fun detectsEmbyByRemoteAddresses() =
        assertEquals(MediaBrowserDialect.EMBY, MediaBrowserDialect.detectFromPublicSystemInfo(null, true))

    @Test fun explicitEmbyProductNameWins() =
        assertEquals(MediaBrowserDialect.EMBY, MediaBrowserDialect.detectFromPublicSystemInfo("Emby Server", false))

    @Test fun nullWithoutSignal() {
        assertNull(MediaBrowserDialect.detectFromPublicSystemInfo(null, false))
        assertNull(MediaBrowserDialect.detectFromPublicSystemInfo("", false))
    }

    @Test fun mediaBrowserPredicate() {
        assertFalse(BackendKind.PLEX.usesMediaBrowserApi)
        assertTrue(BackendKind.JELLYFIN.usesMediaBrowserApi)
        assertTrue(BackendKind.EMBY.usesMediaBrowserApi)
        assertNull(BackendKind.PLEX.dialect)
        assertEquals(BackendKind.EMBY, BackendKind.fromId("emby"))
        assertEquals(BackendKind.EMBY, BackendKind.fromString("emby"))
        assertEquals(BackendKind.PLEX, BackendKind.fromString(null))
    }
}
