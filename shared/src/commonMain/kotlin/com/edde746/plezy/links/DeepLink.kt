package com.edde746.plezy.links

import com.edde746.plezy.livetv.LiveLink
import com.edde746.plezy.livetv.LiveTvStartPosition
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.Profile

/**
 * A `plezy://` link. The one grammar for every platform: the platforms hand the URL over unchanged
 * ([com.edde746.plezy.app.RootSession.openUrl]) and only this file reads it.
 *
 * ```text
 * plezy://open
 * plezy://play?server=<serverId>&id=<itemId>[&mode=next|shuffle]
 * plezy://play?type=movie|show&tmdb=<n>|tvdb=<n>|imdb=tt<n>|plex=<hash>[&mode=next|shuffle]
 * plezy://play?content_id=plezy_<serverId>_<itemId>      (launcher shelf rows)
 * plezy://live?channel=<channel>[&server=<serverId>][&start=beginning|live]
 * plezy://external-player/<result>/<session>?...           (external player return links)
 * ```
 *
 * Every link except the external-player return link may add `profile=<profile>`, matched by [resolveLinkProfile]. The
 * app switches to that profile before acting on the link; a protected profile still asks for its PIN.
 *
 * Every parameter value is trimmed and a blank one counts as absent. Once a link is written onto an NFC tag or into a
 * home automation it is a contract: parameters may be added, never renamed.
 */
sealed interface DeepLink {
    /** The profile the link names, as written in the link. */
    val profile: String?

    /** This link as a URL. Parsing the result yields an equal link. */
    fun toUrl(): String

    /** `plezy://open`: bring the app forward, as [profile] when the link names one. */
    data class Open(override val profile: String? = null) : DeepLink {
        override fun toUrl(): String = url(OPEN, profileParam(profile))
    }

    /**
     * `plezy://play`: play one title. [mode] is used when the target is a show or season; movies and episodes ignore
     * it.
     */
    data class Play(val target: PlayTarget, val mode: PlayMode = PlayMode.NEXT, override val profile: String? = null) : DeepLink {
        override fun toUrl(): String = url(
            PLAY,
            target.params() + listOfNotNull(if (mode == PlayMode.SHUFFLE) "mode" to "shuffle" else null) + profileParam(profile),
        )
    }

    /**
     * `plezy://live`: tune a live TV channel. [channel] is matched against the channel key, identifier, number and call
     * sign; [serverId] restricts the lookup to one server; [start] answers the "watch from start" prompt.
     */
    data class Live(
        val channel: String,
        val serverId: ServerId? = null,
        val start: LiveTvStartPosition = LiveTvStartPosition.ASK,
        override val profile: String? = null,
    ) : DeepLink {
        /** The channel and start Live TV tunes ([LiveLink.resolve]). */
        val channelLink: LiveLink get() = LiveLink(channel, serverId, start)

        override fun toUrl(): String = url(
            LIVE,
            buildList {
                add("channel" to channel)
                serverId?.let { add("server" to it.value) }
                when (start) {
                    LiveTvStartPosition.ASK -> Unit
                    LiveTvStartPosition.BEGINNING -> add("start" to "beginning")
                    LiveTvStartPosition.LIVE -> add("start" to "live")
                }
                addAll(profileParam(profile))
            },
        )
    }

    /**
     * `plezy://external-player/<result>/<session>`: an external player handing control back (x-callback-url). The
     * player appends its own query parameters, so the whole [url] is kept. It never names a profile.
     */
    data class ExternalPlayerReturn(val url: String) : DeepLink {
        override val profile: String? get() = null

        override fun toUrl(): String = url
    }

    companion object {
        const val SCHEME = "plezy"
        private const val OPEN = "open"
        private const val PLAY = "play"
        private const val LIVE = "live"
        private const val EXTERNAL_PLAYER = "external-player"

        /** [link] as a Plezy link, or null when it is not a well-formed one. */
        fun parse(link: String): DeepLink? {
            val url = link.trim()
            val colon = url.indexOf(':')
            if (colon <= 0 || !url.substring(0, colon).equals(SCHEME, ignoreCase = true)) return null
            val rest = url.substring(colon + 1).substringBefore('#')
            if (!rest.startsWith("//")) return null
            val afterSlashes = rest.substring(2)
            val authorityEnd = afterSlashes.indexOfFirst { it == '/' || it == '?' }.let { if (it < 0) afterSlashes.length else it }
            val host = afterSlashes.substring(0, authorityEnd).substringAfterLast('@').substringBefore(':').lowercase()
            val query = afterSlashes.substring(authorityEnd).substringAfter('?', missingDelimiterValue = "")
            val params = QueryString.parse(query) ?: return null
            fun param(name: String): String? = params[name]?.trim()?.takeIf { it.isNotEmpty() }
            val profile = param("profile")
            return when (host) {
                OPEN -> Open(profile)
                PLAY -> parsePlay(::param, profile)
                LIVE -> parseLive(::param, profile)
                EXTERNAL_PLAYER -> ExternalPlayerReturn(url)
                else -> null
            }
        }

        private fun parsePlay(param: (String) -> String?, profile: String?): Play? {
            val mode = when (param("mode")?.lowercase()) {
                null, "next" -> PlayMode.NEXT
                "shuffle" -> PlayMode.SHUFFLE
                else -> return null
            }
            val target = parseTarget(param) ?: return null
            return Play(target, mode, profile)
        }

        private fun parseTarget(param: (String) -> String?): PlayTarget? {
            param("content_id")?.let { contentId ->
                val (serverId, itemId) = ShelfContentId.parse(contentId) ?: return null
                return PlayTarget.Item(serverId, itemId)
            }
            val server = param("server")
            val id = param("id")
            if (server != null || id != null) {
                // Item ids are per server, so an id means nothing without its server.
                if (server == null || id == null) return null
                return PlayTarget.Item(ServerId(server), id)
            }
            val kind = when (param("type")?.lowercase()) {
                "movie" -> MediaKind.MOVIE
                "show" -> MediaKind.SHOW
                else -> return null
            }
            val tmdb = param("tmdb")
            val tvdb = param("tvdb")
            val imdb = param("imdb")
            val plex = param("plex")
            if (tmdb != null && !NUMBER.matches(tmdb)) return null
            if (tvdb != null && !NUMBER.matches(tvdb)) return null
            if (imdb != null && !IMDB_ID.matches(imdb)) return null
            if (plex != null && !PLEX_HASH.matches(plex)) return null
            val tmdbId = tmdb?.let { it.toIntOrNull() ?: return null }
            val tvdbId = tvdb?.let { it.toIntOrNull() ?: return null }
            val ids = ExternalIds(imdb = imdb?.lowercase(), tmdb = tmdbId, tvdb = tvdbId)
            if (!ids.hasCatalogIds && plex == null) return null
            return PlayTarget.Catalog(kind, ids, plex)
        }

        private fun parseLive(param: (String) -> String?, profile: String?): Live? {
            val channel = param("channel") ?: return null
            val start = when (param("start")?.lowercase()) {
                null -> LiveTvStartPosition.ASK
                "beginning", "start" -> LiveTvStartPosition.BEGINNING
                "live", "now" -> LiveTvStartPosition.LIVE
                else -> return null
            }
            return Live(channel, param("server")?.let(::ServerId), start, profile)
        }

        private fun profileParam(profile: String?): List<Pair<String, String>> = listOfNotNull(profile?.let { "profile" to it })

        private fun url(host: String, params: List<Pair<String, String>>): String =
            if (params.isEmpty()) "$SCHEME://$host" else "$SCHEME://$host?" + QueryString.encode(params)

        private val NUMBER = Regex("^[0-9]+$")
        private val IMDB_ID = Regex("^tt[0-9]+$", RegexOption.IGNORE_CASE)
        private val PLEX_HASH = Regex("^[0-9a-zA-Z]+$")
    }
}

/** How a link to a show or season picks what to play. */
enum class PlayMode {
    /** The episode the viewer is on: the On Deck/Next Up episode, otherwise the first episode. */
    NEXT,

    /** Every episode of the show in random order. */
    SHUFFLE,
}

/** What a [DeepLink.Play] names. */
sealed interface PlayTarget {
    fun params(): List<Pair<String, String>>

    /** One item on one server, of any backend. */
    data class Item(val serverId: ServerId, val itemId: String) : PlayTarget {
        override fun params(): List<Pair<String, String>> = listOf("server" to serverId.value, "id" to itemId)
    }

    /**
     * A movie or show ([kind]) by catalogue identity: every copy on every server of every backend that knows one of
     * the [ids]. [plexHash] is the Plex GUID after `plex://movie/` or `plex://show/`; only Plex servers can match it.
     */
    data class Catalog(val kind: MediaKind, val ids: ExternalIds = ExternalIds(), val plexHash: String? = null) : PlayTarget {
        init {
            require(kind == MediaKind.MOVIE || kind == MediaKind.SHOW) { "A catalogue link names a movie or a show" }
        }

        /** The full Plex GUID, or null when the link has none. */
        val plexGuid: String? get() = plexHash?.let { "plex://${kind.id}/$it" }

        override fun params(): List<Pair<String, String>> = buildList {
            add("type" to kind.id)
            ids.tmdb?.let { add("tmdb" to it.toString()) }
            ids.tvdb?.let { add("tvdb" to it.toString()) }
            ids.imdb?.let { add("imdb" to it) }
            plexHash?.let { add("plex" to it) }
        }
    }
}

/**
 * The id a launcher shelf row carries for an item (Android TV's Watch Next, the Apple TV's Top Shelf):
 * `plezy_<serverId>_<itemId>`, opened as `plezy://play?content_id=<id>`.
 */
object ShelfContentId {
    private const val PREFIX = "plezy_"

    fun build(serverId: ServerId, itemId: String): String = "$PREFIX${serverId.value}_$itemId"

    /** The link that opens [contentId]'s item. */
    fun playUrl(contentId: String): String = "${DeepLink.SCHEME}://play?" + QueryString.encode(listOf("content_id" to contentId))

    /**
     * [contentId]'s server and item, split at the first `_` after the prefix: the item id is the rest and may hold
     * `_`. Null without the prefix, a server or an item id.
     */
    fun parse(contentId: String): Pair<ServerId, String>? {
        if (!contentId.startsWith(PREFIX)) return null
        val rest = contentId.substring(PREFIX.length)
        val split = rest.indexOf('_')
        if (split < 0) return null
        val serverId = ServerId.tryParse(rest.substring(0, split)) ?: return null
        val itemId = rest.substring(split + 1).takeIf { it.isNotEmpty() } ?: return null
        return serverId to itemId
    }
}

/**
 * The profile [ref] names: a profile id, else the one Plex Home user with that UUID, else the one profile with that
 * display name (both ignoring case and surrounding spaces). Null when nothing matches or a rule matches several
 * profiles.
 */
fun resolveLinkProfile(profiles: List<Profile>, ref: String): Profile? {
    profiles.firstOrNull { it.id == ref }?.let { return it }
    val wanted = ref.trim().lowercase()
    val rules = listOf<(Profile) -> Boolean>(
        { (it as? PlexHomeProfile)?.plexHomeUserUuid?.lowercase() == wanted },
        { it.displayName.trim().lowercase() == wanted },
    )
    for (rule in rules) {
        val matches = profiles.filter(rule)
        if (matches.size == 1) return matches.single()
        if (matches.size > 1) {
            Log.w(TAG) { "Profile \"$ref\" is ambiguous (${matches.size} matches)" }
            return null
        }
    }
    return null
}

/**
 * The `profile` value a generated link uses for [profile]: the Plex Home user UUID, which survives signing the account
 * in again, else the profile id.
 */
fun linkProfileRef(profile: Profile): String = (profile as? PlexHomeProfile)?.plexHomeUserUuid ?: profile.id

/**
 * A URL query as links write it: `name=value` pairs joined by `&`, a space as `+`, every byte but ASCII letters, digits
 * and `-._~` percent-encoded. Reading is strict: a `%` without two hex digits or bytes that aren't UTF-8 make the
 * query malformed. A name given twice keeps its last value.
 */
internal object QueryString {
    private const val HEX = "0123456789ABCDEF"

    fun encode(params: List<Pair<String, String>>): String = params.joinToString("&") { (name, value) -> component(name) + "=" + component(value) }

    private fun component(value: String): String = buildString {
        for (byte in value.encodeToByteArray()) {
            val b = byte.toInt() and 0xFF
            val c = b.toChar()
            when {
                b < 0x80 && (c in 'a'..'z' || c in 'A'..'Z' || c in '0'..'9' || c == '-' || c == '.' || c == '_' || c == '~') -> append(c)
                c == ' ' -> append('+')
                else -> append('%').append(HEX[b shr 4]).append(HEX[b and 0x0F])
            }
        }
    }

    /** [query]'s parameters, or null when it is malformed. */
    fun parse(query: String): Map<String, String>? {
        val params = LinkedHashMap<String, String>()
        for (pair in query.split('&')) {
            if (pair.isEmpty()) continue
            val eq = pair.indexOf('=')
            val name = decode(if (eq < 0) pair else pair.substring(0, eq)) ?: return null
            val value = if (eq < 0) "" else decode(pair.substring(eq + 1)) ?: return null
            params[name] = value
        }
        return params
    }

    private fun decode(value: String): String? {
        if ('%' !in value && '+' !in value) return value
        val bytes = value.encodeToByteArray()
        val out = ByteArray(bytes.size)
        var i = 0
        var n = 0
        while (i < bytes.size) {
            val b = bytes[i]
            when (b) {
                '+'.code.toByte() -> {
                    out[n++] = ' '.code.toByte()
                    i++
                }
                '%'.code.toByte() -> {
                    if (i + 2 >= bytes.size) return null
                    val hi = hex(bytes[i + 1])
                    val lo = hex(bytes[i + 2])
                    if (hi < 0 || lo < 0) return null
                    out[n++] = ((hi shl 4) or lo).toByte()
                    i += 3
                }
                else -> {
                    out[n++] = b
                    i++
                }
            }
        }
        return try {
            out.decodeToString(0, n, throwOnInvalidSequence = true)
        } catch (_: CharacterCodingException) {
            null
        }
    }

    private fun hex(b: Byte): Int = when (val c = b.toInt().toChar()) {
        in '0'..'9' -> c - '0'
        in 'a'..'f' -> c - 'a' + 10
        in 'A'..'F' -> c - 'A' + 10
        else -> -1
    }
}

private const val TAG = "DeepLink"
