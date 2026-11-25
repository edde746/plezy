package com.edde746.plezy.presentation.libraries

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.plex.PlexClient
import com.edde746.plezy.plex.analyzeLibrary
import com.edde746.plezy.plex.emptyLibraryTrash
import com.edde746.plezy.strings.T

/**
 * A library's admin action in Manage libraries' ⋮ menu. Each asks for confirmation ([confirmTitle], [confirmMessage],
 * [destructive]) before it runs.
 */
enum class LibraryAdminAction(val destructive: Boolean) {
    /** Scans for new, changed and removed files (every backend). */
    SCAN(false),

    /** Plex only. */
    ANALYZE(false),

    /** Refreshes every item's metadata (every backend). */
    REFRESH_METADATA(true),

    /** Plex only. */
    EMPTY_TRASH(true),
    ;

    val label: String get() = when (this) {
        SCAN -> T.libraries.scanLibraryFiles
        ANALYZE -> T.libraries.analyze
        REFRESH_METADATA -> T.libraries.refreshMetadata
        EMPTY_TRASH -> T.libraries.emptyTrash
    }

    val confirmTitle: String get() = when (this) {
        SCAN -> T.libraries.scanLibrary
        ANALYZE -> T.libraries.analyzeLibrary
        REFRESH_METADATA -> T.libraries.refreshMetadata
        EMPTY_TRASH -> T.libraries.emptyTrash
    }

    fun confirmMessage(library: MediaLibrary): String = when (this) {
        SCAN -> T.libraries.scanLibraryConfirm(library.title)
        ANALYZE -> T.libraries.analyzeLibraryConfirm(library.title)
        REFRESH_METADATA -> T.libraries.refreshMetadataConfirm(library.title)
        EMPTY_TRASH -> T.libraries.emptyTrashConfirm(library.title)
    }

    internal fun progress(library: MediaLibrary): String = when (this) {
        SCAN -> T.messages.libraryScanning(library.title)
        ANALYZE -> T.libraries.analyzing(library.title)
        REFRESH_METADATA -> T.messages.metadataRefreshing(library.title)
        EMPTY_TRASH -> T.libraries.emptyingTrash(library.title)
    }

    internal fun started(library: MediaLibrary): String = when (this) {
        SCAN -> T.messages.libraryScanStarted(library.title)
        ANALYZE -> T.libraries.analysisStarted(library.title)
        REFRESH_METADATA -> T.messages.metadataRefreshStarted(library.title)
        EMPTY_TRASH -> T.libraries.trashEmptied(library.title)
    }

    internal fun failed(error: String): String = when (this) {
        SCAN -> T.messages.libraryScanFailed(error)
        ANALYZE -> T.libraries.failedToAnalyze(error)
        REFRESH_METADATA -> T.messages.metadataRefreshFailed(error)
        EMPTY_TRASH -> T.libraries.failedToEmptyTrash(error)
    }

    /** Runs the action against [client], the library's own server. */
    internal suspend fun run(client: MediaBackend, library: MediaLibrary) {
        when (this) {
            SCAN -> client.scanLibrary(library.id)
            REFRESH_METADATA -> client.refreshLibraryMetadata(library.id)
            ANALYZE -> plex(client).analyzeLibrary(library.id)
            EMPTY_TRASH -> plex(client).emptyLibraryTrash(library.id)
        }
    }

    private fun plex(client: MediaBackend): PlexClient =
        client as? PlexClient ?: throw IllegalStateException("$name needs a Plex server, not ${client.backend}")

    companion object {
        /** What [library]'s menu offers an admin: scan and refresh everywhere, analyze and empty trash on Plex. */
        fun offeredFor(library: MediaLibrary): List<LibraryAdminAction> =
            if (library.backend == BackendKind.PLEX) listOf(SCAN, ANALYZE, REFRESH_METADATA, EMPTY_TRASH) else listOf(SCAN, REFRESH_METADATA)
    }
}
