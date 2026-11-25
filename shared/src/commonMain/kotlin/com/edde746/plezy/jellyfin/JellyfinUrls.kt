package com.edde746.plezy.jellyfin

import com.edde746.plezy.net.UriComponent

/** URL builders for stream and tile routes. Token in the query: players and image loaders send no headers. */
object JellyfinUrls {
    private val SAFE_EXTENSION = Regex("^[A-Za-z0-9]+$")

    /**
     * `{base}/{Videos|Audio}/{id}/stream?Static=true&{token}&DeviceId&…`. [mediaSourceId] is always passed when the
     * server named one (without it the server may pick another version) and never invented. [containerExtension]
     * gives external players `stream.{container}`, the only payload hint they get; the container must be plain
     * alphanumerics, else the bare `stream` path is used.
     */
    fun directStream(
        baseUrl: String,
        accessToken: String,
        tokenQueryParam: String,
        deviceId: String,
        itemId: String,
        mediaSegment: String = "Videos",
        container: String? = null,
        mediaSourceId: String? = null,
        playSessionId: String? = null,
        liveStreamId: String? = null,
        audioStreamIndex: Int? = null,
        containerExtension: Boolean = false,
    ): String {
        val params = buildList {
            add("Static" to "true")
            add(tokenQueryParam to accessToken)
            add("DeviceId" to deviceId)
            container?.let { add("Container" to it) }
            mediaSourceId?.let { add("MediaSourceId" to it) }
            playSessionId?.let { add("PlaySessionId" to it) }
            liveStreamId?.let { add("LiveStreamId" to it) }
            audioStreamIndex?.let { add("AudioStreamIndex" to it.toString()) }
        }
        val extension = if (containerExtension) container?.trim()?.takeIf { SAFE_EXTENSION.matches(it) }?.lowercase() else null
        val streamPath = if (extension == null) "stream" else "stream.$extension"
        return "$baseUrl/$mediaSegment/${UriComponent.encode(itemId)}/$streamPath?${query(params)}"
    }

    /** `{base}/Videos/{id}/Trickplay/{width}/{sheet}.jpg?{token}&DeviceId[&MediaSourceId]`. */
    fun trickplayTile(
        baseUrl: String,
        accessToken: String,
        tokenQueryParam: String,
        deviceId: String,
        itemId: String,
        width: Int,
        sheetIndex: Int,
        mediaSourceId: String? = null,
    ): String {
        val params = buildList {
            add(tokenQueryParam to accessToken)
            add("DeviceId" to deviceId)
            mediaSourceId?.let { add("MediaSourceId" to it) }
        }
        return "$baseUrl/Videos/${UriComponent.encode(itemId)}/Trickplay/$width/$sheetIndex.jpg?${query(params)}"
    }

    /** `name=value&…` with values form-encoded (space as `+`), names as given. */
    fun query(params: List<Pair<String, String>>): String = params.joinToString("&") { (k, v) -> k + "=" + queryComponent(v) }

    /** Form encoding of a query value: letters, digits and `-._~` kept, space as `+`, the rest `%XX`. */
    fun queryComponent(value: String): String {
        val out = StringBuilder(value.length + 8)
        for (byte in value.encodeToByteArray()) {
            val b = byte.toInt() and 0xFF
            val c = b.toChar()
            when {
                b < 0x80 && (c.isLetterOrDigit() || c in "-._~") -> out.append(c)
                c == ' ' -> out.append('+')
                else -> out.append('%').append(HEX[b shr 4]).append(HEX[b and 0xF])
            }
        }
        return out.toString()
    }

    private const val HEX = "0123456789ABCDEF"
}
