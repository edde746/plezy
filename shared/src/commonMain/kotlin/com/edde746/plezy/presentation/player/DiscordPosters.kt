package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import io.ktor.client.HttpClient
import io.ktor.client.plugins.timeout
import io.ktor.client.request.get
import io.ktor.client.request.headers
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsBytes
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.Url
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlin.time.Clock
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

/**
 * The posters Discord shows beside Rich Presence. Discord fetches its image itself from a public URL, and a media
 * server's artwork is private (behind the server's token, often on a LAN), so the app fetches the poster from the server
 * and hands its bytes to Plezy's poster host, which answers the public URL and how long it keeps it.
 *
 * The poster is a track's own art (its album's, never the artist's portrait), an episode's series poster (else the
 * episode's thumbnail), anything else's own poster, sized for Discord at one pixel per pixel: a 512×512 square, a
 * 960×540 thumbnail, a 512×768 poster. Fetched in 10 s, with the server's headers only from the server's own origin,
 * at most [MAX_BYTES], posted as `application/octet-stream` to [uploadUrl] in 15 s. Each server's poster URL is kept
 * for the time the host gives ([expiry]). Every failure is logged and gives no poster.
 */
class DiscordPosters(private val http: HttpClient, private val clock: Clock, private val uploadUrl: String = UPLOAD_URL) {
    private class Hosted(val url: String, val expiresAt: Instant)

    private val cache = HashMap<String, Hosted>()

    /** [item]'s poster at a public URL, from [backend], its server; null when it has none or the upload failed. */
    suspend fun posterFor(item: MediaItem, backend: MediaBackend): String? {
        val path = thumbPath(item)?.takeIf { it.isNotEmpty() } ?: return null
        val key = "${item.serverId}:$path"
        cache[key]?.let { if (clock.now() < it.expiresAt) return it.url }
        return try {
            upload(key, item, path, backend)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.d(TAG, e) { "the Discord poster upload failed" }
            null
        }
    }

    private suspend fun upload(key: String, item: MediaItem, path: String, backend: MediaBackend): String? {
        val (width, height) = size(item)
        val imageUrl = backend.thumbnailUrl(path, width, height).ifEmpty { return null }
        val onServer = sameOrigin(imageUrl, backend.thumbnailUrl("/"))
        val image = http.get(imageUrl) {
            if (onServer) headers { backend.streamHeaders.forEach { (name, value) -> append(name, value) } }
            timeout { requestTimeoutMillis = FETCH_TIMEOUT.inWholeMilliseconds }
        }
        if (!image.status.isSuccess()) return null
        val bytes = image.bodyAsBytes()
        if (bytes.isEmpty()) return null
        if (bytes.size > MAX_BYTES) {
            Log.d(TAG) { "Discord poster skipped: the image is ${bytes.size} bytes" }
            return null
        }
        val response = http.post(uploadUrl) {
            contentType(ContentType.Application.OctetStream)
            setBody(bytes)
            timeout { requestTimeoutMillis = UPLOAD_TIMEOUT.inWholeMilliseconds }
        }
        if (!response.status.isSuccess()) return null
        val text = response.bodyAsText()
        val body = runCatching { Json.parseToJsonElement(text) as? JsonObject }.getOrNull() ?: return null
        val hosted = hostedUrl((body["url"] as? JsonPrimitive)?.takeIf { it.isString }?.content, uploadUrl) ?: return null
        val now = clock.now()
        val expiresAt = expiry(body["expiresIn"], now)
        if (expiresAt > now) cache[key] = Hosted(hosted, expiresAt)
        return hosted
    }

    companion object {
        const val UPLOAD_URL = "https://ice.plezy.app/posters"
        const val MAX_BYTES = 5 * 1024 * 1024
        private const val TAG = "discord"
        private val FETCH_TIMEOUT = 10.seconds
        private val UPLOAD_TIMEOUT = 15.seconds
        private val DEFAULT_TTL = 3.hours
        private val MAX_TTL = 365.days

        /** The artwork Discord shows for [item]: a track's own, an episode's series poster or its own, else its own. */
        internal fun thumbPath(item: MediaItem): String? =
            if (item.kind == MediaKind.TRACK) item.thumbPath else item.grandparentThumbPath ?: item.thumbPath

        /** The pixels Discord gets: a square for a track, a 16:9 thumbnail for an episode without a series poster. */
        internal fun size(item: MediaItem): Pair<Int, Int> = when {
            item.kind == MediaKind.TRACK -> 512 to 512
            item.kind == MediaKind.EPISODE && item.grandparentThumbPath == null -> 960 to 540
            else -> 512 to 768
        }

        /** Whether [a] and [b] share scheme, host and port. */
        private fun sameOrigin(a: String, b: String): Boolean {
            val x = Url(a)
            val y = Url(b)
            return x.protocol == y.protocol && x.host.equals(y.host, ignoreCase = true) && x.port == y.port
        }

        /**
         * When a hosted poster expires: [expiresIn] seconds after [receivedAt]; at once when not positive; 3 hours when
         * missing, not a whole number, or over a year.
         */
        internal fun expiry(expiresIn: JsonElement?, receivedAt: Instant): Instant {
            val seconds = (expiresIn as? JsonPrimitive)?.takeIf { !it.isString }?.longOrNull ?: return receivedAt + DEFAULT_TTL
            val ttl: Duration = seconds.seconds
            return when {
                seconds <= 0 -> receivedAt
                ttl > MAX_TTL -> receivedAt + DEFAULT_TTL
                else -> receivedAt + ttl
            }
        }

        /** The host's answer as an absolute URL: http(s) as is, a `/posters/…` path against [uploadUrl]; else none. */
        internal fun hostedUrl(url: String?, uploadUrl: String): String? {
            if (url.isNullOrEmpty()) return null
            if (url.startsWith("https://") || url.startsWith("http://")) return url
            if (!url.startsWith("/posters/")) return null
            return uploadUrl.substringBefore("://") + "://" + uploadUrl.substringAfter("://").substringBefore('/') + url
        }
    }
}
