package com.edde746.plezy.watchnext

import android.content.ContentResolver
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import com.edde746.plezy.log.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * The Watch Next posters, which the app downloads itself: the poster URLs carry the media server's address and token,
 * which never reach a launcher. Each poster is a file under the cache, `system_shelf_artwork/<sha256(owner)>/<sha256(owner
 * \0 source)>.art`, served read-only by [ShelfArtworkProvider] as `content://<authority>/art/<owner key>/<key>.art` to
 * every app that may read the TV provider's rows, which carry those URIs (a launcher that isn't the home app included).
 *
 * A download ([fetch]) takes http(s) only, each image within its timeouts and the whole publish within one deadline and
 * byte budget ([Budget]); it keeps an image only if its bytes are a whole PNG, JPEG, GIF or WebP ([imageFormatOf]) of
 * sane bounds. A poster fetched once is reused for as long as its source stays the same, and one that fails keeps the
 * row without a poster. Files no row uses go after each publish ([prune]).
 */
internal class ShelfArtwork(private val context: Context) {
    private val root = File(context.cacheDir, ROOT)
    private val authority = authority(context)

    /** One publish's limits: [DEADLINE_MILLIS] in all and [BUDGET_BYTES] read (refused bytes count too). */
    class Budget(private val start: Long = System.nanoTime()) {
        var bytesLeft: Long = BUDGET_BYTES
        fun millisLeft(): Long = DEADLINE_MILLIS - (System.nanoTime() - start) / 1_000_000
    }

    /**
     * The content URI of [ownerId]'s poster from [source], downloading it first if this source has no file yet; null
     * when it can't be had within [budget].
     */
    fun fetch(ownerId: String, source: String, budget: Budget): Uri? {
        val ownerKey = sha256(ownerId)
        val key = sha256("$ownerId\u0000$source")
        val file = File(File(root, ownerKey), "$key$SUFFIX")
        if (file.isFile) return uri(ownerKey, key)
        val bytes = download(source, budget) ?: return null
        if (!isUsableImage(bytes)) {
            Log.w(TAG) { "A Watch Next poster isn't a usable image" }
            return null
        }
        return try {
            file.parentFile!!.mkdirs()
            val staging = File.createTempFile(".$key.", ".tmp", file.parentFile)
            FileOutputStream(staging).use { out ->
                out.write(bytes)
                out.fd.sync()
            }
            if (!staging.renameTo(file)) {
                staging.delete()
                throw IOException("rename failed")
            }
            uri(ownerKey, key)
        } catch (e: IOException) {
            Log.w(TAG) { "Storing a Watch Next poster failed: ${e::class.simpleName}" }
            null
        }
    }

    /** Deletes every poster file but those [kept] (content URIs [fetch] gave), other owners' included. */
    fun prune(kept: Set<String>) {
        val keep = kept.mapNotNullTo(HashSet()) { file(Uri.parse(it))?.canonicalPath }
        root.listFiles()?.forEach { ownerDir ->
            ownerDir.listFiles()?.forEach { if (it.canonicalPath !in keep) it.delete() }
            if (ownerDir.list().isNullOrEmpty()) ownerDir.delete()
        }
    }

    /** The poster file [uri] names, confined to the artwork folder; null for any other URI. */
    fun file(uri: Uri): File? {
        if (uri.scheme != ContentResolver.SCHEME_CONTENT || uri.authority != authority) return null
        val segments = uri.pathSegments
        if (segments.size != 3 || segments[0] != "art" || !OWNER_KEY.matches(segments[1]) || !FILE_NAME.matches(segments[2])) return null
        return File(File(root, segments[1]), segments[2])
    }

    private fun uri(ownerKey: String, key: String): Uri = Uri.Builder()
        .scheme(ContentResolver.SCHEME_CONTENT).authority(authority).appendPath("art").appendPath(ownerKey).appendPath("$key$SUFFIX").build()

    private fun download(source: String, budget: Budget): ByteArray? {
        if (!source.startsWith("http://") && !source.startsWith("https://")) {
            Log.w(TAG) { "A Watch Next poster's source isn't http(s)" }
            return null
        }
        val left = budget.millisLeft()
        if (left <= 0 || budget.bytesLeft <= 0) {
            Log.w(TAG) { "No time or bytes left for a Watch Next poster" }
            return null
        }
        val timeout = minOf(IMAGE_TIMEOUT_MILLIS, left).toInt()
        val connection = try {
            URL(source).openConnection() as HttpURLConnection
        } catch (e: IOException) {
            return null
        }
        return try {
            connection.connectTimeout = timeout
            connection.readTimeout = timeout
            connection.setRequestProperty("Accept", "image/*")
            val status = connection.responseCode
            val type = connection.contentType.orEmpty()
            if (status !in 200..299 || !type.startsWith("image/")) {
                Log.w(TAG) { "A Watch Next poster answered $status ($type)" }
                return null
            }
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(16 * 1024)
            connection.inputStream.use { input ->
                while (true) {
                    if (budget.millisLeft() <= 0) {
                        Log.w(TAG) { "A Watch Next poster outlasted the publish's deadline" }
                        return null
                    }
                    val read = input.read(buffer)
                    if (read < 0) break
                    budget.bytesLeft -= read
                    if (out.size() + read > MAX_IMAGE_BYTES || budget.bytesLeft < 0) {
                        Log.w(TAG) { "A Watch Next poster is past its size or the publish's budget" }
                        return null
                    }
                    out.write(buffer, 0, read)
                }
            }
            out.toByteArray()
        } catch (e: IOException) {
            // The address carries a token: only the failure's kind is logged.
            Log.w(TAG) { "Downloading a Watch Next poster failed: ${e::class.simpleName}" }
            null
        } finally {
            connection.disconnect()
        }
    }

    private fun isUsableImage(bytes: ByteArray): Boolean {
        if (imageFormatOf(bytes) == null) return false
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val (w, h) = bounds.outWidth to bounds.outHeight
        return w in 1..MAX_SIDE && h in 1..MAX_SIDE && w.toLong() * h <= MAX_PIXELS
    }

    companion object {
        private const val TAG = "WatchNext"
        private const val ROOT = "system_shelf_artwork"
        private const val SUFFIX = ".art"
        private const val DEADLINE_MILLIS = 10_000L
        private const val IMAGE_TIMEOUT_MILLIS = 2_500L
        private const val MAX_IMAGE_BYTES = 2 * 1024 * 1024
        private const val BUDGET_BYTES = 8L * 1024 * 1024
        private const val MAX_SIDE = 4096
        private const val MAX_PIXELS = 16_777_216L
        private val OWNER_KEY = Regex("^[0-9a-f]{64}$")
        private val FILE_NAME = Regex("^[0-9a-f]{64}\\.art$")

        /** The artwork provider's authority ([ShelfArtworkProvider], the manifest's). */
        fun authority(context: Context): String = "${context.packageName}.systemshelf.artwork"

        fun sha256(value: String): String =
            MessageDigest.getInstance("SHA-256").digest(value.toByteArray()).joinToString("") { "%02x".format(it) }
    }
}

/** The image formats a Watch Next poster may be. */
internal enum class ImageFormat { PNG, JPEG, GIF, WEBP }

/**
 * The format of [bytes] by their magic bytes, and only for a whole file: a PNG ending in its IEND chunk, a JPEG in its
 * end marker, a GIF in its trailer, a WebP as long as its RIFF header says. Null for anything else or a cut-off file.
 */
internal fun imageFormatOf(bytes: ByteArray): ImageFormat? {
    fun at(index: Int, vararg expected: Int) = bytes.size >= index + expected.size && expected.indices.all { bytes[index + it].toInt() and 0xFF == expected[it] }
    val n = bytes.size
    return when {
        at(0, 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A) -> ImageFormat.PNG.takeIf { n >= 20 && at(n - 8, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82) }
        at(0, 0xFF, 0xD8, 0xFF) -> ImageFormat.JPEG.takeIf { n >= 5 && at(n - 2, 0xFF, 0xD9) }
        at(0, 0x47, 0x49, 0x46, 0x38) -> ImageFormat.GIF.takeIf { n >= 14 && at(n - 1, 0x3B) }
        at(0, 0x52, 0x49, 0x46, 0x46) && at(8, 0x57, 0x45, 0x42, 0x50) -> {
            val length = (bytes[4].toInt() and 0xFF) or ((bytes[5].toInt() and 0xFF) shl 8) or ((bytes[6].toInt() and 0xFF) shl 16) or ((bytes[7].toInt() and 0xFF) shl 24)
            ImageFormat.WEBP.takeIf { length.toLong() + 8 == n.toLong() }
        }
        else -> null
    }
}
