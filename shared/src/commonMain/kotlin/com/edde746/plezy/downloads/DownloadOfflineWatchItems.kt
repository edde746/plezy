package com.edde746.plezy.downloads

import com.edde746.plezy.data.downloads.DownloadLibraryRepository
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.DownloadedWatchItem
import com.edde746.plezy.servers.OfflineWatchDownloads

/**
 * Offline watch state's view of the downloads: rows and owners from the library, metadata from [controller], which is
 * read at each call: the app builds the controller after the offline watch services this view is given to.
 */
class DownloadOfflineWatchItems internal constructor(
    private val library: DownloadLibraryRepository,
    private val controller: () -> DownloadsController,
) : OfflineWatchDownloads {
    override suspend fun downloadedClientScopeId(globalKey: String): String? = library.getDownloadedMedia(globalKey)?.client_scope_id

    override suspend fun ownedDownloads(profileId: String): List<DownloadedWatchItem> {
        library.adoptLegacyDownloadsForProfile(profileId)
        val owned = library.getDownloadOwnerKeysForProfile(profileId)
        return library.getAllDownloads().filter { it.global_key in owned }.mapNotNull { row ->
            val serverId = ServerId.tryParse(row.server_id) ?: return@mapNotNull null
            DownloadedWatchItem(serverId, row.rating_key, MediaKind.fromString(row.type), row.parent_rating_key)
        }
    }

    override suspend fun downloadedEpisodesForShow(showGlobalKey: String): List<MediaItem> = controller().getDownloadedEpisodesForShow(showGlobalKey)

    override suspend fun metadata(globalKey: String): MediaItem? = controller().getMetadata(globalKey)

    override suspend fun deleteWatchedDownload(globalKey: String) = controller().deleteWatchedDownload(globalKey)
}
