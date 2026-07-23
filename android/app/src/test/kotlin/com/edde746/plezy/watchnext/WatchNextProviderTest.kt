package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentProviderOperation
import android.content.ContentProviderResult
import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor.AutoCloseInputStream
import androidx.tvprovider.media.tv.TvContractCompat
import java.net.InetAddress
import java.net.ServerSocket
import java.util.Base64
import java.util.concurrent.Executor
import kotlin.concurrent.thread
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.shadows.ShadowContentResolver

@RunWith(RobolectricTestRunner::class)
class WatchNextProviderTest {
  private val context get() = RuntimeEnvironment.getApplication()
  private lateinit var tvProvider: CapturingTvProvider
  private val imageBytes = Base64.getDecoder().decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
  )

  @Before
  fun setUp() {
    context.cacheDir.resolve("system_shelf_artwork").deleteRecursively()
    context.getSharedPreferences("system_shelf_state", 0).edit().clear().commit()
    tvProvider = CapturingTvProvider()
    ShadowContentResolver.registerProviderInternal(TvContractCompat.AUTHORITY, tvProvider)
  }

  @After
  fun tearDown() {
    context.cacheDir.resolve("system_shelf_artwork").deleteRecursively()
  }

  @Test
  fun syncPersistsOnlyGrantedLocalUriAndProviderReturnsValidatedBytes() {
    withServer("image/png", imageBytes) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      assertEquals(1, tvProvider.inserted.size)
      val stored = tvProvider.inserted.single()
      val poster = stored.getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
      assertTrue(poster.startsWith("content://${SystemShelfArtworkProvider.AUTHORITY}/art/"))
      assertFalse(poster.contains("http"))

      val artworkProvider = Robolectric.buildContentProvider(SystemShelfArtworkProvider::class.java).create().get()
      val localBytes = AutoCloseInputStream(artworkProvider.openFile(Uri.parse(poster), "r")).use { it.readBytes() }
      assertArrayEquals(imageBytes, localBytes)
    }
  }

  @Test
  fun traversalUnknownOversizeAndMalformedArtworkAreRejectedWithoutDroppingMetadata() {
    val store = SystemShelfArtworkStore(context.cacheDir)
    assertNull(store.resolve(Uri.parse("content://${SystemShelfArtworkProvider.AUTHORITY}/art/../../private")))
    assertNull(store.resolve(Uri.parse("content://${SystemShelfArtworkProvider.AUTHORITY}/art/${"a".repeat(64)}/${"b".repeat(32)}.art")))

    withServer("image/png", ByteArray(SystemShelfArtworkStore.MAX_IMAGE_BYTES + 1)) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      assertNull(tvProvider.inserted.single().getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI))
      assertEquals("Private title", tvProvider.inserted.single().getAsString(TvContractCompat.WatchNextPrograms.COLUMN_TITLE))
    }

    tvProvider.inserted.clear()
    withServer("image/png", "not an image".toByteArray()) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      assertNull(tvProvider.inserted.single().getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI))
    }

    tvProvider.inserted.clear()
    withServer("text/plain", imageBytes) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      assertNull(tvProvider.inserted.single().getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI))
    }

    tvProvider.inserted.clear()
    withServer("image/png", imageBytes, delayMillis = 3_000) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      assertNull(tvProvider.inserted.single().getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI))
    }
  }

  @Test
  fun staleGenerationCannotCommitAndClearRemovesRowsGrantsAndFiles() {
    withServer("image/png", imageBytes) { source ->
      val provider = WatchNextProvider(context)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 3, listOf(item(source))))
      assertFalse(provider.syncWatchNextPrograms("owner-old", 2, listOf(item(source))))
      assertTrue(context.cacheDir.resolve("system_shelf_artwork").walkTopDown().any { it.isFile })

      assertTrue(provider.clearAll("owner-a", 4))
      assertTrue(tvProvider.deleteCount >= 2)
      assertFalse(context.cacheDir.resolve("system_shelf_artwork").exists())
      assertTrue(context.getSharedPreferences("system_shelf_state", 0).getStringSet("granted_uris", null).isNullOrEmpty())
    }
  }

  @Test
  fun packageUpdateCleanupDeletesLegacyRowsAndOwnedFiles() {
    context.cacheDir.resolve("system_shelf_artwork/legacy").apply { mkdirs() }.resolve("legacy.art").writeBytes(imageBytes)
    val receiver = SystemShelfUpdateReceiver(Executor { command -> command.run() })
    receiver.onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))

    assertEquals(1, tvProvider.deleteCount)
    assertFalse(context.cacheDir.resolve("system_shelf_artwork").exists())
  }

  private fun item(source: String) = WatchNextProvider.WatchNextItem(
    contentId = "plezy_server_item",
    title = "Private title",
    episodeTitle = null,
    description = "Private summary",
    posterSourceUri = source,
    type = TvContractCompat.WatchNextPrograms.TYPE_MOVIE,
    duration = 100,
    lastPlaybackPosition = 10,
    lastEngagementTime = 1,
    seriesTitle = null,
    seasonNumber = null,
    episodeNumber = null
  )

  private fun withServer(
    contentType: String,
    body: ByteArray,
    delayMillis: Long = 0,
    block: (String) -> Unit
  ) {
    val server = ServerSocket(0, 1, InetAddress.getByName("127.0.0.1"))
    val responder = thread(start = true, name = "system-shelf-test-http") {
      server.accept().use { socket ->
        val reader = socket.getInputStream().bufferedReader()
        while (reader.readLine()?.isNotEmpty() == true) {
          // Consume the local deterministic request headers.
        }
        if (delayMillis > 0) Thread.sleep(delayMillis)
        val headers = (
          "HTTP/1.1 200 OK\r\n" +
            "Content-Type: $contentType\r\n" +
            "Content-Length: ${body.size}\r\n" +
            "Connection: close\r\n\r\n"
          ).toByteArray()
        socket.getOutputStream().use { output ->
          output.write(headers)
          output.write(body)
          output.flush()
        }
      }
    }
    try {
      block("http://127.0.0.1:${server.localPort}/art")
      responder.join(5_000)
    } finally {
      server.close()
    }
  }
}

private class CapturingTvProvider : ContentProvider() {
  val inserted = mutableListOf<ContentValues>()
  var deleteCount = 0

  override fun onCreate(): Boolean = true
  override fun insert(uri: Uri, values: ContentValues?): Uri {
    inserted += ContentValues(values)
    return uri.buildUpon().appendPath(inserted.size.toString()).build()
  }
  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
    deleteCount++
    inserted.clear()
    return 1
  }
  override fun applyBatch(operations: ArrayList<ContentProviderOperation>): Array<ContentProviderResult> = super.applyBatch(operations)
  override fun getType(uri: Uri): String? = null
  override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
  override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
