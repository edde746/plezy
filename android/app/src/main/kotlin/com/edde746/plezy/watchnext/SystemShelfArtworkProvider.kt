package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Binder
import android.os.ParcelFileDescriptor
import android.os.Process
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileNotFoundException
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.UUID
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
    private val artworkKey = Regex("^[a-f0-9]{32}\\.art$")
    private val deadlineAborter: ScheduledExecutorService =
      Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "system-shelf-deadline").apply { isDaemon = true }
      }
  }

  data class Materialized(val key: String, val uri: Uri, val file: File)
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

  fun materialize(ownerId: String, source: String, session: SystemShelfSyncSession): Materialized? {
    if (ownerId.isBlank() || session.budget.remaining <= 0 || !session.isActive()) return null
    val url = runCatching { URL(source) }.getOrNull() ?: return null
    if (url.protocol != "https" && url.protocol != "http") return null
    val connection = (url.openConnection() as? HttpURLConnection) ?: return null
    val remainingNanos = session.remainingNanos()
    if (remainingNanos <= 0) return null
    val abort = deadlineAborter.schedule(
      { connection.disconnect() },
      remainingNanos,
      TimeUnit.NANOSECONDS
    )
    return try {
      val remainingMillis = TimeUnit.NANOSECONDS.toMillis(remainingNanos).coerceIn(1, Int.MAX_VALUE.toLong()).toInt()
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
          session.budget.charge(read)
          total += read
          output.write(buffer, 0, read)
        }
        output.toByteArray()
      }
      if (!session.isActive() || !isSupportedImage(bytes)) return null
      val ownerKey = sha256(ownerId)
      val directory = File(root, ownerKey)
      if (!directory.mkdirs() && !directory.isDirectory) return null
      val key = UUID.randomUUID().toString().replace("-", "") + ".art"
      val staged = File(directory, ".$key.tmp")
      staged.outputStream().use { output ->
        output.write(bytes)
        output.flush()
        output.fd.sync()
      }
      if (!session.isActive()) {
        staged.delete()
        return null
      }
      val destination = File(directory, key)
      if (!session.commitIfActive { staged.renameTo(destination) }) {
        staged.delete()
        return null
      }
      Materialized(key, contentUri(ownerKey, key), destination)
    } catch (_: Exception) {
      null
    } finally {
      abort.cancel(false)
      connection.disconnect()
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
    if (uri.scheme != "content" || uri.authority != SystemShelfArtworkProvider.AUTHORITY) return null
    val segments = uri.pathSegments
    if (segments.size != 3 || segments[0] != "art") return null
    val owner = segments[1]
    val key = segments[2]
    if (!opaquePart.matches(owner) || !artworkKey.matches(key)) return null
    val canonicalRoot = root.canonicalFile
    val candidate = File(File(canonicalRoot, owner), key).canonicalFile
    if (candidate.parentFile?.parentFile != canonicalRoot || !candidate.isFile) return null
    return candidate
  }

  fun deleteExcept(keep: Set<File>) {
    val canonicalKeep = keep.mapTo(HashSet()) { it.canonicalFile }
    root.listFiles()?.forEach { ownerDirectory ->
      ownerDirectory.listFiles()?.forEach { file ->
        if (file.canonicalFile !in canonicalKeep) file.delete()
      }
      if (ownerDirectory.listFiles().isNullOrEmpty()) ownerDirectory.delete()
    }
  }

  fun delete(files: Set<File>) {
    val canonicalRoot = root.canonicalFile
    files.forEach { file ->
      val candidate = runCatching { file.canonicalFile }.getOrNull() ?: return@forEach
      if (candidate.parentFile?.parentFile == canonicalRoot) candidate.delete()
    }
    root.listFiles()?.forEach { directory ->
      if (directory.listFiles().isNullOrEmpty()) directory.delete()
    }
  }

  fun deleteAll(): Boolean = !root.exists() || root.deleteRecursively()

  private fun isSupportedImage(bytes: ByteArray): Boolean {
    if (bytes.size < 4) return false
    val png = bytes.size >= 8 &&
      bytes[0] == 0x89.toByte() &&
      bytes[1] == 0x50.toByte() &&
      bytes[2] == 0x4e.toByte() &&
      bytes[3] == 0x47.toByte()
    val jpeg = bytes[0] == 0xff.toByte() && bytes[1] == 0xd8.toByte() && bytes[2] == 0xff.toByte()
    val gif = bytes[0] == 0x47.toByte() && bytes[1] == 0x49.toByte() && bytes[2] == 0x46.toByte()
    val webp = bytes.size >= 12 &&
      bytes.copyOfRange(0, 4).contentEquals("RIFF".toByteArray()) &&
      bytes.copyOfRange(8, 12).contentEquals("WEBP".toByteArray())
    if (!png && !jpeg && !gif && !webp) return false

    val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    val width = options.outWidth
    val height = options.outHeight
    return width in 1..4096 && height in 1..4096 && width.toLong() * height <= 16_777_216L
  }

  private fun sha256(value: String): String = MessageDigest.getInstance("SHA-256")
    .digest(value.toByteArray(Charsets.UTF_8))
    .joinToString("") { byte -> "%02x".format(byte) }
}
