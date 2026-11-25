package com.edde746.plezy.log

/**
 * The media-server credentials a URL carries in its query: Plex's `X-Plex-Token` and Jellyfin's and Emby's `api_key`
 * and `ApiKey`, in any case, also inside a nested URL percent-encoded once (`%3D`) or twice (`%253D`), as in the `url=`
 * of Plex's photo transcoder. A value runs to the next `&`, `#` or `%`.
 */
object UrlTokens {
    private val VALUE = Regex("""((?:X-Plex-Token|api_key|ApiKey)(?:=|%3D|%253D))[^&#%]+""", RegexOption.IGNORE_CASE)

    /** [url] with each credential's value replaced by [mark]: blanked by default, the rest of the URL as it was. */
    fun redact(url: String, mark: String = ""): String = VALUE.replace(url) { it.groupValues[1] + mark }
}
