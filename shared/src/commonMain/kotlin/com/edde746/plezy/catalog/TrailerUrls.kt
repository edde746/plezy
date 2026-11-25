package com.edde746.plezy.catalog

// Watch URLs for provider trailer references. These are handed to the platform browser (or, on tvOS, the YouTube app)
// and never fetched by the app's own HTTP stack.

private const val YOUTUBE_WATCH_PREFIX = "https://www.youtube.com/watch?v="
private val uriScheme = Regex("^[A-Za-z][A-Za-z0-9+.-]*:")
private val youTubeVideoIdPattern = Regex("^[A-Za-z0-9_-]{11}$")

/**
 * A provider trailer reference as an absolute URL. Providers send either a bare YouTube video id (AniList
 * `trailer.id`, Simkl `trailer`, Seerr/TMDB `videos[].key`) or an absolute URL; an absolute URL is kept, a bare id
 * becomes a YouTube watch URL. Null for a missing or blank reference.
 */
fun youTubeTrailerUrl(reference: String?): String? {
    val value = reference?.trim()
    if (value.isNullOrEmpty()) return null
    if (uriScheme.containsMatchIn(value)) return value
    return YOUTUBE_WATCH_PREFIX + value
}

/** The 11-character video id of a YouTube watch, shorts, embed, live, v or youtu.be [url]; null for anything else. */
fun youTubeVideoId(url: String?): String? {
    val value = url?.trim() ?: return null
    if (!uriScheme.containsMatchIn(value)) return null
    val hierarchy = value.substringAfter(':')
    if (!hierarchy.startsWith("//")) return null
    val rest = hierarchy.substring(2).substringBefore('#')
    val authorityEnd = rest.indexOfAny(charArrayOf('/', '?')).let { if (it < 0) rest.length else it }
    val host = rest.substring(0, authorityEnd).substringAfterLast('@').substringBefore(':').lowercase()
    val path = rest.substring(authorityEnd).substringBefore('?')
    val query = rest.substring(authorityEnd).substringAfter('?', "")
    val segments = path.split('/').filter { it.isNotEmpty() }
    val id = when {
        host == "youtu.be" -> segments.firstOrNull()
        host == "youtube.com" || host.endsWith(".youtube.com") -> when {
            segments.firstOrNull() == "watch" -> query.split('&').firstNotNullOfOrNull { pair ->
                val parts = pair.split('=', limit = 2)
                if (parts[0] == "v") parts.getOrNull(1) else null
            }
            segments.size >= 2 && segments[0] in setOf("embed", "shorts", "live", "v") -> segments[1]
            else -> null
        }
        else -> null
    }
    return id?.takeIf { youTubeVideoIdPattern.matches(it) }
}

/**
 * A link the YouTube app opens straight on the video of a YouTube [url], for tvOS, which has no browser. The app takes
 * the web watch URL under its own scheme; a bare `youtube://<id>` opens its home screen and plays nothing.
 */
fun youTubeAppUrl(url: String?): String? = youTubeVideoId(url)?.let { "youtube://www.youtube.com/watch?v=$it" }
