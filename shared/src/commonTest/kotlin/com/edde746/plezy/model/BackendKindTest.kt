package com.edde746.plezy.model

import com.edde746.plezy.backend.HubFetchDiagnostics
import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import kotlinx.coroutines.CancellationException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BackendKindTest {
    @Test
    fun idsAreExactAndFromIdRejectsAnythingElse() {
        assertEquals(listOf("plex", "jellyfin", "emby"), BackendKind.entries.map { it.id })
        for (kind in BackendKind.entries) assertEquals(kind, BackendKind.fromId(kind.id))
        assertFailsWith<IllegalArgumentException> { BackendKind.fromId("Plex") }
        assertFailsWith<IllegalArgumentException> { BackendKind.fromId("") }
    }

    @Test
    fun fromStringReadsOldAndUnknownRowsAsPlex() {
        assertEquals(BackendKind.PLEX, BackendKind.fromString(null))
        assertEquals(BackendKind.PLEX, BackendKind.fromString("kodi"))
        assertEquals(BackendKind.JELLYFIN, BackendKind.fromString("jellyfin"))
        assertEquals(BackendKind.EMBY, BackendKind.fromString("emby"))
    }

    @Test
    fun mediaBrowserKindsCarryTheirDialect() {
        assertFalse(BackendKind.PLEX.usesMediaBrowserApi)
        assertNull(BackendKind.PLEX.dialect)
        assertTrue(BackendKind.JELLYFIN.usesMediaBrowserApi)
        assertEquals(MediaBrowserDialect.JELLYFIN, BackendKind.JELLYFIN.dialect)
        assertEquals(MediaBrowserDialect.EMBY, BackendKind.EMBY.dialect)
        for (dialect in MediaBrowserDialect.entries) assertEquals(dialect, dialect.backend.dialect)
    }

    @Test
    fun capabilityPresetsPerBackend() {
        val defaults = ServerCapabilities()
        assertTrue(defaults.videoTranscoding)
        assertEquals(ServerCapabilities(videoTranscoding = true), defaults)
        assertFalse(listOf(defaults.liveTv, defaults.richHubs, defaults.userFavorites, defaults.libraryChangeEvents).any { it })

        val plex = ServerCapabilities.PLEX
        assertTrue(plex.richHubs && plex.numericUserRating && plex.continueWatchingRemoval && plex.externalSubtitleSearch)
        assertFalse(plex.userFavorites)

        val jellyfin = ServerCapabilities.JELLYFIN
        assertTrue(jellyfin.userFavorites && jellyfin.liveTvDvr && jellyfin.instantMix && jellyfin.libraryChangeEvents && jellyfin.downloadTranscoding)
        assertFalse(jellyfin.richHubs || jellyfin.numericUserRating || jellyfin.externalSubtitleSearch || jellyfin.continueWatchingRemoval)
        assertFalse(ServerCapabilities.PLEX.downloadTranscoding)

        assertEquals(jellyfin.copy(continueWatchingRemoval = true, downloadTranscoding = false), ServerCapabilities.EMBY)
        assertEquals(ServerCapabilities.EMBY, ServerCapabilities.forBackend(BackendKind.EMBY))
    }

    @Test
    fun hubDiagnosticsTellCancellationFromFailure() {
        val cancelled = HubFetchDiagnostics()
        cancelled.recordFailure(MediaServerHttpException(MediaServerHttpErrorType.CANCELLED))
        cancelled.recordFailure(CancellationException("left"))
        assertTrue(cancelled.cancelled)
        assertFalse(cancelled.failed)

        val failed = HubFetchDiagnostics()
        failed.recordFailure(MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_ERROR))
        assertTrue(failed.failed)
        assertFalse(failed.cancelled)
    }
}
