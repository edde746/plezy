package com.edde746.plezy.watch

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import party.openwatch.Media
import party.openwatch.MediaFile
import party.openwatch.MediaKind
import party.openwatch.Series
import party.openwatch.checkMedia
import com.edde746.plezy.model.MediaKind as ItemKind

/** Why a file could not be described for a room. */
enum class DescribeFailure {
    /** Neither the server nor the player knows the file's length. */
    NO_DURATION,

    /** The descriptor breaks a rule the relay checks (logged). */
    INVALID,
}

/** A copy's descriptor, or why there is none. */
data class DescribeResult(val media: Media?, val failure: DescribeFailure?)

/** The server, item and version a received descriptor's `app.plezy` member names. */
data class PlezyRef(val server: String, val item: String, val version: String?)

/**
 * How a Plezy item is described to a room (the protocol's media descriptor). Movies and episodes carry their catalogue
 * identity and match on any server and in any Open Watch Party app; every other video (Plex clips, home videos,
 * Jellyfin/Emby `Video` items) goes out as a `video` without ids, which only participants on the same server, or with a
 * file of the same size and name, find. The `app.plezy` member names the server, item and version shared, so a guest
 * who reaches the same server opens that exact file; other apps ignore it.
 */
internal object MediaDescriptor {
    /** Plezy's reverse-DNS `ext` member. */
    const val EXT_NAME = "app.plezy"

    fun roomKindOf(kind: ItemKind): MediaKind = when (kind) {
        ItemKind.MOVIE -> MediaKind.MOVIE
        ItemKind.EPISODE -> MediaKind.EPISODE
        else -> MediaKind.VIDEO
    }

    /**
     * The descriptor for [copy] (whose item must be set): its item, the catalogue ids [client] knows for it and its
     * show, and the version's length ([playerDurationMs] when the server reports none). Lookups that fail leave their
     * part out: a movie the server can't map stays a `movie` without ids.
     */
    suspend fun describe(client: MediaBackend, copy: WatchCopy, playerDurationMs: Long?): DescribeResult {
        val item = requireNotNull(copy.item) { "describing a copy needs its item" }
        val durationMs = copy.durationMs ?: playerDurationMs?.takeIf { it > 0 }
            ?: return DescribeResult(null, DescribeFailure.NO_DURATION)
        val kind = roomKindOf(item.kind)
        val episode = kind == MediaKind.EPISODE
        val ids = if (kind == MediaKind.VIDEO) emptyMap() else idsOf(client, item.id, item.guid)
        val series = if (episode) seriesOf(client, item) else null
        val ext = buildJsonObject {
            putJsonObject(EXT_NAME) {
                put("server", copy.serverId)
                put("item", copy.itemId)
                if (copy.versionId.isNotEmpty()) put("version", copy.versionId)
            }
        }
        val file = fileHints(copy.version)
        var media = Media(
            kind = kind,
            title = titleOf(item),
            durationMs = durationMs,
            year = if (episode) null else item.year?.toLong(),
            ids = ids,
            series = series,
            season = if (episode) number(item.parentIndex) else null,
            episode = if (episode) number(item.index) else null,
            file = file,
            ext = ext,
        )
        var problem = checkMedia(media)
        if (problem != null && file?.name != null) {
            // A file name the relay refuses is only a hint: send the rest.
            media = media.copy(file = file.sizeBytes?.let { MediaFile(sizeBytes = it) })
            problem = checkMedia(media)
        }
        if (problem != null) {
            Log.w(TAG) { "${copy.serverId}:${copy.itemId} has no valid descriptor: $problem" }
            return DescribeResult(null, DescribeFailure.INVALID)
        }
        return DescribeResult(media, null)
    }

    /**
     * [text] as protocol text: line breaks and tabs become spaces, other control and bidi-control characters (direction
     * marks are common in Hebrew and Arabic titles) and unpaired surrogates are dropped, and runs of spaces fold. Null
     * when nothing is left.
     */
    fun descriptorText(text: String?): String? {
        if (text == null) return null
        val out = StringBuilder()
        var space = false
        var i = 0
        while (i < text.length) {
            val c = text[i]
            if (c.isHighSurrogate() && i + 1 < text.length && text[i + 1].isLowSurrogate()) {
                if (space) out.append(' ')
                space = false
                out.append(c).append(text[i + 1])
                i += 2
                continue
            }
            i++
            if (c == '\t' || c == '\n' || c == '\u000B' || c == '\u000C' || c == '\r' || c == ' ') {
                space = out.isNotEmpty()
                continue
            }
            if (forbidden(c)) continue
            if (space) out.append(' ')
            space = false
            out.append(c)
        }
        return out.toString().ifEmpty { null }
    }

    /** The `app.plezy` member of a received descriptor, when it is Plezy's shape. Untrusted: only ever looked up on this user's own servers. */
    fun plezyRef(media: Media): PlezyRef? {
        val member = media.ext?.get(EXT_NAME) as? JsonObject ?: return null
        fun string(key: String) = (member[key] as? JsonPrimitive)?.takeIf { it.isString }?.content?.takeIf { it.isNotEmpty() }
        val server = string("server") ?: return null
        val item = string("item") ?: return null
        return PlezyRef(server, item, string("version"))
    }

    /** [ids] in the descriptor's namespaces, every value a string, plus a Plex `plex://` GUID. */
    fun descriptorIds(ids: ExternalIds, plexGuid: String?): Map<String, String> = buildMap {
        ids.imdb?.takeIf { it.isNotEmpty() }?.let { put("imdb", it) }
        ids.tmdb?.let { put("tmdb", it.toString()) }
        ids.tvdb?.let { put("tvdb", it.toString()) }
        ids.anidb?.let { put("anidb", it.toString()) }
        if (plexGuid != null && plexGuid.startsWith("plex://")) put("plex", plexGuid)
    }

    /** The last segment of a server-side [path], whichever separator it uses. */
    fun fileBaseName(path: String?): String? {
        if (path == null) return null
        val name = path.split('/', '\\').last().trim()
        return if (name.isEmpty() || name == "." || name == "..") null else name
    }

    private fun forbidden(c: Char): Boolean {
        val code = c.code
        return code <= 0x1F || code in 0x7F..0x9F || code == 0x061C || code == 0x200E || code == 0x200F ||
            code in 0x202A..0x202E || code in 0x2066..0x2069 || c.isSurrogate()
    }

    private fun titleOf(item: MediaItem): String {
        descriptorText(item.title)?.let { return it }
        if (item.kind == ItemKind.EPISODE && item.index != null) return T.watchTogether.untitledEpisode(item.index.toString())
        return descriptorText(item.displayTitle) ?: T.common.unknown
    }

    private fun number(value: Int?): Long? = value?.takeIf { it >= 0 }?.toLong()

    private suspend fun seriesOf(client: MediaBackend, episode: MediaItem): Series {
        val showId = episode.grandparentId?.takeIf { it.isNotEmpty() }
        val show = showId?.let { id ->
            try {
                client.fetchItem(id)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "Could not read show $id" }
                null
            }
        }
        val ids = if (showId == null) emptyMap() else idsOf(client, showId, show?.guid)
        val title = descriptorText(episode.grandparentTitle) ?: descriptorText(show?.title) ?: T.common.unknown
        return Series(title = title, year = show?.year?.toLong(), ids = ids)
    }

    private suspend fun idsOf(client: MediaBackend, itemId: String, guid: String?): Map<String, String> {
        val external = try {
            client.fetchExternalIds(itemId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "No external ids for $itemId" }
            ExternalIds()
        }
        return descriptorIds(external, guid)
    }

    /** File hints for [version]: its total size, and its file name when it is one file. Null when neither is known. */
    private fun fileHints(version: MediaVersion?): MediaFile? {
        val parts = version?.parts.orEmpty()
        if (parts.isEmpty()) return null
        val sizeBytes = if (parts.all { (it.sizeBytes ?: -1) >= 0 }) parts.sumOf { it.sizeBytes!! } else null
        val name = if (parts.size == 1) fileBaseName(parts.single().file) else null
        if (sizeBytes == null && name == null) return null
        return MediaFile(sizeBytes = sizeBytes, name = name)
    }

    private const val TAG = "WatchTogether"
}
