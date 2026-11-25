package com.edde746.plezy.jellyfin

import com.edde746.plezy.model.ArtistDiscographyGroup
import com.edde746.plezy.model.DiscographyGroupKind
import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import kotlinx.serialization.json.JsonObject

/** Artist albums, album tracks, instant mixes and lyrics. */
internal class JellyfinMusic(private val core: JellyfinCore) {
    /** Newest first. By `AlbumArtistIds`: albums link to artists by tag, rarely as folder children. */
    suspend fun fetchArtistAlbums(artist: MediaItem): List<MediaItem> = items(
        "/Items",
        listOf(
            "userId" to core.userId,
            "AlbumArtistIds" to artist.id,
            "IncludeItemTypes" to "MusicAlbum",
            "Recursive" to "true",
            "SortBy" to "PremiereDate,ProductionYear,SortName",
            "SortOrder" to "Descending",
            "Fields" to core.musicAlbumRowFields,
            "EnableUserData" to "false",
        ),
    )

    /** One albums group: MediaBrowser items carry no single/EP/live/compilation taxonomy. */
    suspend fun fetchArtistDiscography(artist: MediaItem): List<ArtistDiscographyGroup> {
        val albums = fetchArtistAlbums(artist)
        return if (albums.isEmpty()) emptyList() else listOf(ArtistDiscographyGroup(DiscographyGroupKind.ALBUMS, albums))
    }

    /** Disc then track order. By `AlbumIds`, so tag-based albums sharing one folder still resolve. */
    suspend fun fetchAlbumTracks(albumId: String): List<MediaItem> = items(
        "/Items",
        listOf(
            "userId" to core.userId,
            "AlbumIds" to albumId,
            "IncludeItemTypes" to "Audio",
            "Recursive" to "true",
            "SortBy" to "ParentIndexNumber,IndexNumber,SortName",
            "SortOrder" to "Ascending",
            "Fields" to core.musicTrackRowFields,
        ),
    )

    suspend fun fetchInstantMix(itemId: String, limit: Int = 100): List<MediaItem> = items(
        "/Items/${JellyfinCore.segment(itemId)}/InstantMix",
        listOf("userId" to core.userId, "Limit" to limit.toString(), "Fields" to core.browseFields),
    )

    /**
     * Jellyfin only: Emby binds `Lyrics` as an audio container and starts a failing transcode. Synced when any line
     * has a `Start` (`IsSynced` is missing on some versions); a 404 means no lyrics.
     */
    suspend fun fetchLyrics(track: MediaItem): Lyrics? {
        if (!core.dialect.supportsLyrics) return null
        val response = core.get("/Audio/${JellyfinCore.segment(track.id)}/Lyrics")
        if (response.status == 404) return null
        response.throwIfError()
        val lines = response.obj?.array("Lyrics")?.filterIsInstance<JsonObject>()?.map {
            LyricLine(it.str("Text") ?: "", JellyfinTime.ticksToMs(it.long("Start")))
        }
        if (lines.isNullOrEmpty()) return null
        return Lyrics(synced = lines.any { it.startMs != null }, lines = lines)
    }

    private suspend fun items(path: String, query: List<Pair<String, String?>>): List<MediaItem> {
        val response = core.get(path, query + JellyfinCore.IMAGE_PARAMS).throwIfError()
        return core.mapItems(core.itemsArray(response.data))
    }
}
