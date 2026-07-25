package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Binder
import android.os.ParcelFileDescriptor
import android.os.Process
import android.system.Os
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class SystemShelfArtworkProvider : ContentProvider() {
  companion object {
    const val AUTHORITY = "com.edde746.plezy.systemshelf.artwork"
  }

  override fun onCreate(): Boolean = context != null

  override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
    if (mode != "r") throw FileNotFoundException("Read-only artwork")
    val appContext = context ?: throw FileNotFoundException("Provider unavailable")
    val callingUid = Binder.getCallingUid()
    if (callingUid != Process.myUid()) {
      val homeIntent = android.content.Intent(android.content.Intent.ACTION_MAIN)
        .addCategory(android.content.Intent.CATEGORY_HOME)
      val homePackage = appContext.packageManager
        .resolveActivity(homeIntent, android.content.pm.PackageManager.MATCH_DEFAULT_ONLY)
        ?.activityInfo
        ?.packageName
      val callerPackages = appContext.packageManager.getPackagesForUid(callingUid)
      if (homePackage == null || callerPackages == null || homePackage !in callerPackages) {
        throw FileNotFoundException("Artwork caller is not the active HOME launcher")
      }
    }
    val file = SystemShelfArtworkStore(appContext.cacheDir).resolve(uri)
      ?: throw FileNotFoundException("Unknown artwork")
    return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
  }

  override fun getType(uri: Uri): String? = if (uri.authority == AUTHORITY) "image/*" else null
  override fun query(
    uri: Uri,
    projection: Array<out String>?,
    selection: String?,
    selectionArgs: Array<out String>?,
    sortOrder: String?
  ): Cursor? = null
  override fun insert(uri: Uri, values: ContentValues?): Uri? = null
  override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
}

internal class SystemShelfSyncSession(
  internal val ownership: SystemShelfLifecycle.Ownership,
  durationMillis: Long,
  private val nanoTime: () -> Long = System::nanoTime,
  internal val budget: SystemShelfArtworkStore.Budget = SystemShelfArtworkStore.Budget()
) {
  private val deadlineNanos = nanoTime() + TimeUnit.MILLISECONDS.toNanos(durationMillis)

  fun isExpired(): Boolean = nanoTime() >= deadlineNanos

  fun isActive(): Boolean = !isExpired() && SystemShelfLifecycle.isCurrent(ownership)

  fun remainingNanos(): Long = (deadlineNanos - nanoTime()).coerceAtLeast(0)

  fun commitIfActive(block: () -> Boolean): Boolean = SystemShelfLifecycle.whileCurrent(ownership) {
    if (isExpired()) false else block()
  } ?: false
}

internal class SystemShelfArtworkStore(private val cacheDir: File) {
  companion object {
    const val MAX_IMAGE_BYTES = 2 * 1024 * 1024
    const val MAX_SYNC_BYTES = 8 * 1024 * 1024
    const val MAX_ITEMS = 20
    const val MAX_SYNC_DURATION_MS = 10_000L
    const val CONNECT_TIMEOUT_MS = 2_500
    const val READ_TIMEOUT_MS = 2_500
    private val opaquePart = Regex("^[a-f0-9]{64}$")
    private val artworkKey = Regex("^(?:[a-f0-9]{32}|[a-f0-9]{64})\\.art$")
    private val deadlineAborter: ScheduledExecutorService =
      Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "system-shelf-deadline").apply { isDaemon = true }
      }
  }

  data class Materialized(val uri: Uri, val file: File)

  sealed class Prepared {
    abstract val materialized: Materialized

    data class Existing(override val materialized: Materialized) : Prepared()

    data class Staged(
      override val materialized: Materialized,
      val stagingFile: File
    ) : Prepared()
  }

  data class Publication(val materialized: Materialized, val newlyPublished: Boolean)

  class Budget(var remaining: Int = MAX_SYNC_BYTES) {
    var consumed: Long = 0
      private set

    fun charge(bytes: Int): Boolean {
      if (bytes <= 0) return true
      consumed += bytes
      if (bytes > remaining) {
        remaining = 0
        return false
      }
      remaining -= bytes
      return true
    }
  }

  private val root: File get() = File(cacheDir, "system_shelf_artwork")

  fun prepare(ownerId: String, source: String, session: SystemShelfSyncSession): Prepared? {
    if (ownerId.isBlank()) return null
    val url = runCatching { URL(source) }.getOrNull() ?: return null
    if (url.protocol != "https" && url.protocol != "http") return null
    if (!session.isActive()) return null

    val ownerKey = sha256(ownerId)
    val key = sha256(ownerId + "\u0000" + source) + ".art"
    val uri = contentUri(ownerKey, key)
    val destination = File(File(root, ownerKey), key)
    val materialized = Materialized(uri, destination)
    resolveOwned(ownerId, uri)?.let { existing ->
      return Prepared.Existing(materialized.copy(file = existing))
    }
    if (session.budget.remaining <= 0) return null

    val remainingNanos = session.remainingNanos()
    if (remainingNanos <= 0) return null
    val connection = runCatching { url.openConnection() as? HttpURLConnection }.getOrNull()
      ?: return null
    val abort = deadlineAborter.schedule(
      { connection.disconnect() },
      remainingNanos,
      TimeUnit.NANOSECONDS
    )
    var stagingFile: File? = null
    var retainStagingFile = false
    return try {
      val remainingMillis = TimeUnit.NANOSECONDS.toMillis(remainingNanos)
        .coerceIn(1, Int.MAX_VALUE.toLong())
        .toInt()
      connection.instanceFollowRedirects = true
      connection.connectTimeout = minOf(CONNECT_TIMEOUT_MS, remainingMillis)
      connection.readTimeout = minOf(READ_TIMEOUT_MS, remainingMillis)
      connection.useCaches = false
      connection.setRequestProperty("Accept", "image/*")
      val status = connection.responseCode
      if (!session.isActive() || status !in 200..299) return null
      if (connection.url.protocol != "https" && connection.url.protocol != "http") return null
      if (!connection.contentType.orEmpty().substringBefore(';').trim().startsWith("image/")) return null
      val contentLength = connection.contentLengthLong
      val cap = minOf(MAX_IMAGE_BYTES, session.budget.remaining)
      if (contentLength > cap) return null
      val bytes = connection.inputStream.use { input ->
        val output = ByteArrayOutputStream(
          minOf(if (contentLength > 0) contentLength.toInt() else 32 * 1024, cap)
        )
        val buffer = ByteArray(16 * 1024)
        var total = 0
        while (true) {
          if (!session.isActive()) return null
          val remaining = minOf(MAX_IMAGE_BYTES - total, session.budget.remaining)
          if (remaining <= 0) {
            if (contentLength >= 0 && total.toLong() == contentLength) break
            return null
          }
          val read = input.read(buffer, 0, minOf(buffer.size, remaining))
          if (read < 0) break
          if (!session.budget.charge(read)) return null
          total += read
          output.write(buffer, 0, read)
        }
        output.toByteArray()
      }
      if (!session.isActive() || !isSupportedImage(bytes)) return null

      val directory = destination.parentFile ?: return null
      if (!directory.mkdirs() && !directory.isDirectory) return null
      val staged = File.createTempFile(".$key.", ".tmp", directory)
      stagingFile = staged
      staged.outputStream().use { output ->
        output.write(bytes)
        output.flush()
        output.fd.sync()
      }
      if (!isSupportedImage(staged) || !session.isActive()) return null
      retainStagingFile = true
      Prepared.Staged(materialized, staged)
    } catch (_: Exception) {
      null
    } finally {
      if (!retainStagingFile) stagingFile?.delete()
      abort.cancel(false)
      connection.disconnect()
    }
  }

  fun publish(prepared: Prepared): Publication? {
    val expected = confinedCandidate(prepared.materialized.uri) ?: return null
    val recorded = runCatching { prepared.materialized.file.canonicalFile }.getOrNull() ?: return null
    if (recorded != expected) return null

    resolve(prepared.materialized.uri)?.let { existing ->
      if (prepared is Prepared.Staged && !deleteStagingFile(prepared.stagingFile, expected)) {
        return null
      }
      return Publication(prepared.materialized.copy(file = existing), newlyPublished = false)
    }
    if (prepared !is Prepared.Staged) return null
    val staged = confinedStagingFile(prepared.stagingFile, expected) ?: return null
    if (!isSupportedImage(staged)) return null

    val renamed = try {
      Os.rename(staged.absolutePath, expected.absolutePath)
      !staged.exists() || staged.renameTo(expected)
    } catch (_: Exception) {
      runCatching { staged.renameTo(expected) }.getOrDefault(false)
    }
    if (!renamed) return null
    return if (!isSupportedImage(expected)) {
      expected.delete()
      null
    } else {
      Publication(prepared.materialized.copy(file = expected), newlyPublished = true)
    }
  }

  fun discard(prepared: Iterable<Prepared>) {
    prepared.forEach { candidate ->
      if (candidate is Prepared.Staged) {
        deleteStagingFile(candidate.stagingFile, candidate.materialized.file)
      }
    }
  }

  fun contentUri(ownerKey: String, key: String): Uri = Uri.Builder()
    .scheme("content")
    .authority(SystemShelfArtworkProvider.AUTHORITY)
    .appendPath("art")
    .appendPath(ownerKey)
    .appendPath(key)
    .build()

  fun resolve(uri: Uri): File? {
    val candidate = confinedCandidate(uri) ?: return null
    return candidate.takeIf(::isSupportedImage)
  }

  fun resolveOwned(ownerId: String, uri: Uri): File? {
    if (ownerId.isBlank() || uri.pathSegments.getOrNull(1) != sha256(ownerId)) return null
    return resolve(uri)
  }

  fun deleteExcept(keep: Set<File>) {
    val canonicalKeep = keep.mapNotNullTo(HashSet()) {
      runCatching { it.canonicalFile }.getOrNull()
    }
    val canonicalRoot = runCatching { root.canonicalFile }.getOrNull() ?: return
    for (ownerDirectory in root.listFiles().orEmpty()) {
      for (file in ownerDirectory.listFiles().orEmpty()) {
        val candidate = confinedCacheFile(file, canonicalRoot) ?: continue
        if (candidate !in canonicalKeep) candidate.delete()
      }
    }
    removeEmptyDirectories()
  }

  fun delete(files: Set<File>) {
    val canonicalRoot = runCatching { root.canonicalFile }.getOrNull() ?: return
    files.forEach { file ->
      confinedCacheFile(file, canonicalRoot)?.delete()
    }
    removeEmptyDirectories()
  }

  fun deleteAll(): Boolean = !root.exists() || root.deleteRecursively()

  private fun confinedCandidate(uri: Uri): File? {
    if (uri.scheme != "content" || uri.authority != SystemShelfArtworkProvider.AUTHORITY) return null
    val segments = uri.pathSegments
    if (segments.size != 3 || segments[0] != "art") return null
    val owner = segments[1]
    val key = segments[2]
    if (!opaquePart.matches(owner) || !artworkKey.matches(key)) return null

    return runCatching {
      val canonicalRoot = root.canonicalFile
      val ownerDirectory = File(canonicalRoot, owner).canonicalFile
      if (ownerDirectory.parentFile != canonicalRoot || ownerDirectory.name != owner) return null
      val candidate = File(ownerDirectory, key).canonicalFile
      if (candidate.parentFile != ownerDirectory || candidate.name != key) return null
      candidate
    }.getOrNull()
  }

  private fun confinedCacheFile(file: File, canonicalRoot: File): File? {
    return runCatching {
      val originalDirectory = file.parentFile ?: return null
      val directory = originalDirectory.canonicalFile
      if (
        directory.parentFile != canonicalRoot ||
        directory.name != originalDirectory.name
      ) {
        return null
      }
      val candidate = file.canonicalFile
      if (candidate.parentFile != directory || candidate.name != file.name) return null
      candidate
    }.getOrNull()
  }

  private fun confinedStagingFile(stagingFile: File, destination: File): File? {
    val staged = runCatching { stagingFile.canonicalFile }.getOrNull() ?: return null
    val canonicalDestination = runCatching { destination.canonicalFile }.getOrNull() ?: return null
    val directory = canonicalDestination.parentFile ?: return null
    if (
      staged == canonicalDestination ||
      staged.parentFile != directory ||
      !staged.name.startsWith(".${canonicalDestination.name}.") ||
      !staged.name.endsWith(".tmp") ||
      !staged.isFile
    ) {
      return null
    }
    return staged
  }

  private fun deleteStagingFile(stagingFile: File, destination: File): Boolean {
    if (!stagingFile.exists()) return true
    return confinedStagingFile(stagingFile, destination)?.delete() == true
  }

  private fun removeEmptyDirectories() {
    root.listFiles()?.forEach { directory ->
      if (directory.listFiles().isNullOrEmpty()) directory.delete()
    }
  }

  private enum class ImageFormat {
    PNG,
    JPEG,
    GIF,
    WEBP
  }

  private fun isSupportedImage(file: File): Boolean {
    val length = file.length()
    if (!file.isFile || length !in 1L..MAX_IMAGE_BYTES.toLong()) return false
    val header = ByteArray(12)
    val headerSize = runCatching {
      file.inputStream().use { input ->
        var total = 0
        while (total < header.size) {
          val read = input.read(header, total, header.size - total)
          if (read <= 0) break
          total += read
        }
        total
      }
    }.getOrNull() ?: return false
    val format = imageFormat(header, headerSize) ?: return false
    if (!hasCompleteContainer(file, format, header, length)) return false

    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    return runCatching {
      BitmapFactory.decodeFile(file.absolutePath, options)
      hasSupportedDimensions(options)
    }.getOrDefault(false)
  }

  private fun isSupportedImage(bytes: ByteArray): Boolean {
    val format = imageFormat(bytes, bytes.size) ?: return false
    if (!hasCompleteContainer(bytes, format)) return false
    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    return runCatching {
      BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
      hasSupportedDimensions(options)
    }.getOrDefault(false)
  }

  private fun imageFormat(bytes: ByteArray, size: Int): ImageFormat? {
    if (
      size >= 8 &&
      bytes[0] == 0x89.toByte() &&
      bytes[1] == 0x50.toByte() &&
      bytes[2] == 0x4e.toByte() &&
      bytes[3] == 0x47.toByte() &&
      bytes[4] == 0x0d.toByte() &&
      bytes[5] == 0x0a.toByte() &&
      bytes[6] == 0x1a.toByte() &&
      bytes[7] == 0x0a.toByte()
    ) {
      return ImageFormat.PNG
    }
    if (
      size >= 3 &&
      bytes[0] == 0xff.toByte() &&
      bytes[1] == 0xd8.toByte() &&
      bytes[2] == 0xff.toByte()
    ) {
      return ImageFormat.JPEG
    }
    if (
      size >= 6 &&
      bytes[0] == 0x47.toByte() &&
      bytes[1] == 0x49.toByte() &&
      bytes[2] == 0x46.toByte() &&
      bytes[3] == 0x38.toByte() &&
      (bytes[4] == 0x37.toByte() || bytes[4] == 0x39.toByte()) &&
      bytes[5] == 0x61.toByte()
    ) {
      return ImageFormat.GIF
    }
    if (
      size >= 12 &&
      bytes[0] == 0x52.toByte() &&
      bytes[1] == 0x49.toByte() &&
      bytes[2] == 0x46.toByte() &&
      bytes[3] == 0x46.toByte() &&
      bytes[8] == 0x57.toByte() &&
      bytes[9] == 0x45.toByte() &&
      bytes[10] == 0x42.toByte() &&
      bytes[11] == 0x50.toByte()
    ) {
      return ImageFormat.WEBP
    }
    return null
  }

  private fun hasCompleteContainer(
    file: File,
    format: ImageFormat,
    header: ByteArray,
    length: Long
  ): Boolean = runCatching {
    if (format == ImageFormat.WEBP) return@runCatching webpLength(header) == length
    RandomAccessFile(file, "r").use { input ->
      when (format) {
        ImageFormat.PNG -> {
          if (length < 12) return@use false
          input.seek(length - 12)
          input.readInt() == 0 &&
            input.readInt() == 0x49454e44 &&
            input.readInt() == 0xae426082.toInt()
        }
        ImageFormat.JPEG -> {
          if (length < 2) return@use false
          input.seek(length - 2)
          input.readUnsignedByte() == 0xff && input.readUnsignedByte() == 0xd9
        }
        ImageFormat.GIF -> {
          input.seek(length - 1)
          input.readUnsignedByte() == 0x3b
        }
        ImageFormat.WEBP -> false
      }
    }
  }.getOrDefault(false)

  private fun hasCompleteContainer(bytes: ByteArray, format: ImageFormat): Boolean {
    val size = bytes.size
    return when (format) {
      ImageFormat.PNG ->
        size >= 12 &&
          bytes[size - 8] == 0x49.toByte() &&
          bytes[size - 7] == 0x45.toByte() &&
          bytes[size - 6] == 0x4e.toByte() &&
          bytes[size - 5] == 0x44.toByte() &&
          bytes[size - 4] == 0xae.toByte() &&
          bytes[size - 3] == 0x42.toByte() &&
          bytes[size - 2] == 0x60.toByte() &&
          bytes[size - 1] == 0x82.toByte()
      ImageFormat.JPEG ->
        size >= 2 &&
          bytes[size - 2] == 0xff.toByte() &&
          bytes[size - 1] == 0xd9.toByte()
      ImageFormat.GIF -> size >= 1 && bytes[size - 1] == 0x3b.toByte()
      ImageFormat.WEBP -> webpLength(bytes) == size.toLong()
    }
  }

  private fun webpLength(header: ByteArray): Long {
    val riffSize = (header[4].toLong() and 0xff) or
      ((header[5].toLong() and 0xff) shl 8) or
      ((header[6].toLong() and 0xff) shl 16) or
      ((header[7].toLong() and 0xff) shl 24)
    return riffSize + 8
  }

  private fun hasSupportedDimensions(options: BitmapFactory.Options): Boolean {
    val width = options.outWidth
    val height = options.outHeight
    return width in 1..4096 &&
      height in 1..4096 &&
      width.toLong() * height <= 16_777_216L
  }

  private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
    .digest(value.toByteArray(Charsets.UTF_8))
    .joinToString("") { byte -> "%02x".format(byte) }
}
