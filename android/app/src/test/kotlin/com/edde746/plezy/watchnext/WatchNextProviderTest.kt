package com.edde746.plezy.watchnext

import android.content.ComponentName
import android.content.ContentProvider
import android.content.ContentProviderOperation
import android.content.ContentProviderResult
import android.content.ContentValues
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ActivityInfo
import android.content.pm.ApplicationInfo
import android.content.pm.ResolveInfo
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor.AutoCloseInputStream
import androidx.tvprovider.media.tv.TvContractCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.Closeable
import java.lang.reflect.Proxy
import java.net.InetAddress
import java.net.ServerSocket
import java.util.ArrayDeque
import java.util.Base64
import java.util.concurrent.AbstractExecutorService
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.ExecutorService
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
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
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
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
  fun replacementEngineInvalidatesArtworkWorkBeforeRowsCanCommit() {
    val requestReceived = CountDownLatch(1)
    val releaseResponse = CountDownLatch(1)
    val server = ServerSocket(0, 1, InetAddress.getByName("127.0.0.1"))
    val responder = thread(start = true, name = "system-shelf-owner-test-http") {
      server.accept().use { socket ->
        val reader = socket.getInputStream().bufferedReader()
        while (reader.readLine()?.isNotEmpty() == true) {
          // Consume request headers before handing ownership to a replacement engine.
        }
        requestReceived.countDown()
        releaseResponse.await(2, TimeUnit.SECONDS)
        val headers = (
          "HTTP/1.1 200 OK\r\n" +
            "Content-Type: image/png\r\n" +
            "Content-Length: ${imageBytes.size}\r\n" +
            "Connection: close\r\n\r\n"
          ).toByteArray()
        socket.getOutputStream().use { output ->
          output.write(headers)
          output.write(imageBytes)
        }
      }
    }
    try {
      val oldLease = SystemShelfLifecycle.acquire()
      val oldProvider = WatchNextProvider(context, oldLease)
      val result = AtomicReference<Boolean>()
      val worker = thread(start = true, name = "system-shelf-stale-owner") {
        result.set(
          oldProvider.syncWatchNextPrograms(
            "owner-old",
            1,
            listOf(item("http://127.0.0.1:${server.localPort}/art"))
          )
        )
      }
      assertTrue(requestReceived.await(2, TimeUnit.SECONDS))
      SystemShelfLifecycle.acquire()
      releaseResponse.countDown()
      worker.join(2_000)

      assertFalse(worker.isAlive)
      assertEquals(false, result.get())
      assertTrue(tvProvider.inserted.isEmpty())
      assertFalse(context.cacheDir.resolve("system_shelf_artwork").walkTopDown().any { it.isFile })
    } finally {
      releaseResponse.countDown()
      server.close()
      responder.join(2_000)
    }
  }

  @Test
  fun supersededSyncDeletesOnlyArtworkMaterializedByThatOperation() {
    val secondRequestReceived = CountDownLatch(1)
    val releaseSecondResponse = CountDownLatch(1)
    val server = ServerSocket(0, 2, InetAddress.getByName("127.0.0.1"))
    val responder = thread(start = true, name = "system-shelf-superseded-http") {
      runCatching {
        repeat(2) { requestIndex ->
          server.accept().use { socket ->
            val reader = socket.getInputStream().bufferedReader()
            while (reader.readLine()?.isNotEmpty() == true) {
              // Consume request headers.
            }
            if (requestIndex == 1) {
              secondRequestReceived.countDown()
              releaseSecondResponse.await(2, TimeUnit.SECONDS)
            }
            val headers = (
              "HTTP/1.1 200 OK\r\n" +
                "Content-Type: image/png\r\n" +
                "Content-Length: ${imageBytes.size}\r\n" +
                "Connection: close\r\n\r\n"
              ).toByteArray()
            socket.getOutputStream().use { output ->
              output.write(headers)
              output.write(imageBytes)
            }
          }
        }
      }
    }
    val provider = WatchNextProvider(context)
    val result = AtomicReference<Boolean>()
    val worker = thread(start = true, name = "system-shelf-superseded-sync") {
      val source = "http://127.0.0.1:${server.localPort}"
      result.set(
        provider.syncWatchNextPrograms(
          "owner-a",
          1,
          listOf(item("$source/first"), item("$source/second").copy(contentId = "second"))
        )
      )
    }
    try {
      assertTrue(secondRequestReceived.await(2, TimeUnit.SECONDS))
      assertEquals(1, artworkFiles().size)
      assertTrue(artworkFiles().single().name.endsWith(".tmp"))
      SystemShelfLifecycle.acquire()
      releaseSecondResponse.countDown()
      worker.join(2_000)

      assertFalse(worker.isAlive)
      assertEquals(false, result.get())
      assertTrue(tvProvider.inserted.isEmpty())
      assertTrue(artworkFiles().isEmpty())
    } finally {
      releaseSecondResponse.countDown()
      server.close()
      worker.join(2_000)
      responder.join(2_000)
    }
  }

  @Test
  fun ownershipClaimWaitsForCurrentCommitBoundary() {
    val lease = SystemShelfLifecycle.acquire()
    val ownership = SystemShelfLifecycle.claim(lease, "owner-a", 1)
    assertTrue(ownership != null)
    val operationStarted = CountDownLatch(1)
    val releaseOperation = CountDownLatch(1)
    val claimAttempted = CountDownLatch(1)
    val claimCompleted = CountDownLatch(1)
    val replacement = AtomicReference<SystemShelfLifecycle.Ownership?>()
    val operation = thread(start = true, name = "system-shelf-blocked-commit") {
      SystemShelfLifecycle.whileCurrent(ownership!!) {
        operationStarted.countDown()
        releaseOperation.await(2, TimeUnit.SECONDS)
      }
    }
    assertTrue(operationStarted.await(1, TimeUnit.SECONDS))
    val claimant = thread(start = true, name = "system-shelf-owner-claim") {
      claimAttempted.countDown()
      replacement.set(SystemShelfLifecycle.claim(lease, "owner-b", 2))
      claimCompleted.countDown()
    }

    try {
      assertTrue(claimAttempted.await(1, TimeUnit.SECONDS))
      assertFalse("ownership changed during an active commit", claimCompleted.await(100, TimeUnit.MILLISECONDS))
      releaseOperation.countDown()
      assertTrue("claim did not resume after commit", claimCompleted.await(1, TimeUnit.SECONDS))
      assertTrue(replacement.get() != null)
    } finally {
      releaseOperation.countDown()
      operation.join(2_000)
      claimant.join(2_000)
    }
  }

  @Test
  fun detachFencesQueuedSyncWithoutWaitingForBlockedActiveCommit() {
    val plugin = WatchNextPlugin()
    val binding = pluginBinding()
    plugin.onAttachedToEngine(binding)
    val executor = pluginIoExecutor(plugin)
    tvProvider.blockNextBatch = true

    val activeResult = RecordingResult()
    plugin.onMethodCall(
      MethodCall(
        "sync",
        mapOf(
          "schemaVersion" to 3,
          "ownerId" to "active-owner",
          "generation" to 1L,
          "items" to listOf(mapOf("contentId" to "active", "title" to "Active"))
        )
      ),
      activeResult
    )
    assertTrue(tvProvider.batchStarted.await(1, TimeUnit.SECONDS))

    val queuedResult = RecordingResult()
    val channelReturned = CountDownLatch(1)
    thread(start = true, name = "system-shelf-plugin-queued-channel") {
      plugin.onMethodCall(
        MethodCall(
          "sync",
          mapOf(
            "schemaVersion" to 3,
            "ownerId" to "queued-owner",
            "generation" to 2L,
            "items" to listOf(mapOf("contentId" to "queued", "title" to "Queued"))
          )
        ),
        queuedResult
      )
      channelReturned.countDown()
    }
    assertTrue("queued channel claim waited for provider work", channelReturned.await(500, TimeUnit.MILLISECONDS))

    val detachReturned = CountDownLatch(1)
    thread(start = true, name = "system-shelf-plugin-detach") {
      plugin.onDetachedFromEngine(binding)
      detachReturned.countDown()
    }
    try {
      assertTrue("engine detach waited for provider work", detachReturned.await(500, TimeUnit.MILLISECONDS))
    } finally {
      tvProvider.releaseBatch.countDown()
    }
    assertTrue(executor.awaitTermination(2, TimeUnit.SECONDS))
    shadowOf(android.os.Looper.getMainLooper()).idle()

    assertTrue(activeResult.completed.await(1, TimeUnit.SECONDS))
    assertTrue(queuedResult.completed.await(1, TimeUnit.SECONDS))
    assertEquals(true, activeResult.successValue)
    assertEquals(false, queuedResult.successValue)
    assertEquals(
      listOf("Active"),
      tvProvider.inserted.map { it.getAsString(TvContractCompat.WatchNextPrograms.COLUMN_TITLE) }
    )
  }

  @Test
  fun closedStaleEngineInitializationCannotInvalidateNewEngineLease() {
    val staleExecutor = ManualExecutorService()
    val stalePlugin = WatchNextPlugin { staleExecutor }
    val staleBinding = pluginBinding()
    stalePlugin.onAttachedToEngine(staleBinding)
    stalePlugin.onDetachedFromEngine(staleBinding)

    val currentPlugin = WatchNextPlugin()
    val currentBinding = pluginBinding()
    currentPlugin.onAttachedToEngine(currentBinding)
    val firstResult = RecordingResult()
    currentPlugin.onMethodCall(syncCall("current-owner", 1), firstResult)
    awaitResult(firstResult)
    assertEquals(true, firstResult.successValue)

    staleExecutor.runNext()

    val secondResult = RecordingResult()
    currentPlugin.onMethodCall(syncCall("current-owner", 2), secondResult)
    awaitResult(secondResult)
    assertEquals(true, secondResult.successValue)

    staleExecutor.runNext()
    val currentExecutor = pluginIoExecutor(currentPlugin)
    currentPlugin.onDetachedFromEngine(currentBinding)
    assertTrue(currentExecutor.awaitTermination(2, TimeUnit.SECONDS))
  }

  @Test
  fun oneSynchronizationDeadlineCoversSerialArtworkAndAbortsDripResponses() {
    val server = ServerSocket(0, 2, InetAddress.getByName("127.0.0.1"))
    val responder = thread(start = true, name = "system-shelf-drip-test-http") {
      runCatching {
        repeat(2) { requestIndex ->
          server.accept().use { socket ->
            val reader = socket.getInputStream().bufferedReader()
            while (reader.readLine()?.isNotEmpty() == true) {
              // Consume request headers.
            }
            val output = socket.getOutputStream()
            if (requestIndex == 0) {
              Thread.sleep(500)
              output.write(
                (
                  "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: image/png\r\n" +
                    "Content-Length: ${imageBytes.size}\r\n" +
                    "Connection: close\r\n\r\n"
                  ).toByteArray()
              )
              output.write(imageBytes)
              output.flush()
            } else {
              output.write(
                (
                  "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: image/png\r\n" +
                    "Transfer-Encoding: chunked\r\n" +
                    "Connection: close\r\n\r\n"
                  ).toByteArray()
              )
              repeat(100) {
                output.write("1\r\nX\r\n".toByteArray())
                output.flush()
                Thread.sleep(50)
              }
            }
          }
        }
      }
    }
    try {
      val lease = SystemShelfLifecycle.acquire()
      val provider = WatchNextProvider(context, lease, syncDurationMillis = 800)
      val source = "http://127.0.0.1:${server.localPort}"
      val started = System.nanoTime()
      val committed = provider.syncWatchNextPrograms(
        "owner",
        1,
        listOf(item("$source/first"), item("$source/second").copy(contentId = "second"))
      )
      val elapsedMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - started)

      assertFalse(committed)
      assertTrue(tvProvider.inserted.isEmpty())
      assertTrue("shared deadline took ${elapsedMillis}ms", elapsedMillis < 1_100)
    } finally {
      server.close()
      responder.join(2_000)
    }
  }

  @Test
  fun rejectedOrUnwritableImageBytesStillConsumeTheSharedSyncBudget() {
    val malformed = "not an image".toByteArray()
    withServer("image/png", malformed) { source ->
      val budget = SystemShelfArtworkStore.Budget(100)
      val ownership = SystemShelfLifecycle.claim(SystemShelfLifecycle.acquire(), "owner", 1)!!
      val session = SystemShelfSyncSession(ownership, 2_000, budget = budget)

      assertNull(SystemShelfArtworkStore(context.cacheDir).prepare("owner", source, session))
      assertEquals(malformed.size.toLong(), budget.consumed)
      assertEquals(100 - malformed.size, budget.remaining)
    }

    val blockedRoot = context.cacheDir.resolve("system_shelf_artwork")
    blockedRoot.writeText("not a directory")
    withServer("image/png", imageBytes) { source ->
      val budget = SystemShelfArtworkStore.Budget(100)
      val ownership = SystemShelfLifecycle.claim(SystemShelfLifecycle.acquire(), "owner", 1)!!
      val session = SystemShelfSyncSession(ownership, 2_000, budget = budget)

      assertNull(SystemShelfArtworkStore(context.cacheDir).prepare("owner", source, session))
      assertEquals(imageBytes.size.toLong(), budget.consumed)
      assertEquals(100 - imageBytes.size, budget.remaining)
    }
    blockedRoot.delete()
  }

  @Test
  fun everyHomeHandlerIsAnArtworkGrantConsumer() {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val selected = registerHandler(homeIntent, "selected.home.launcher")
    val sideloaded = registerHandler(homeIntent, "sideloaded.home.launcher")
    selectDefaultHome(selected, selected, sideloaded)
    registerHandler(
      Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER),
      "unrelated.leanback.app"
    )

    assertEquals(
      setOf("selected.home.launcher", "sideloaded.home.launcher"),
      WatchNextProvider(context).consumerPackages()
    )
  }

  @Test
  fun homeHandlersAreArtworkGrantConsumersWithoutASelectedDefault() {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    registerHandler(homeIntent, "first.home.launcher")
    registerHandler(homeIntent, "second.home.launcher")

    assertEquals(
      setOf("first.home.launcher", "second.home.launcher"),
      WatchNextProvider(context).consumerPackages()
    )
  }

  @Test
  fun syncGrantsArtworkToAHomeLauncherThatIsNotTheSystemDefault() {
    withServer("image/png", imageBytes) { source ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      val systemDefault = registerHandler(homeIntent, "system.default.launcher")
      val sideloaded = registerHandler(homeIntent, "sideloaded.home.launcher")
      selectDefaultHome(systemDefault, systemDefault, sideloaded)
      val grantContext = RecordingGrantContext(context)

      assertTrue(
        WatchNextProvider(grantContext).syncWatchNextPrograms("owner-a", 1, listOf(item(source)))
      )

      val poster = committedPoster()!!
      assertEquals(
        setOf(
          Grant("system.default.launcher", poster, Intent.FLAG_GRANT_READ_URI_PERMISSION),
          Grant("sideloaded.home.launcher", poster, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        ),
        grantContext.grants.toSet()
      )
      assertEquals(
        setOf("system.default.launcher", "sideloaded.home.launcher"),
        context.getSharedPreferences("system_shelf_state", 0)
          .getStringSet("granted_packages", emptySet())
      )
      assertArrayEquals(imageBytes, openArtwork(poster))
    }
  }

  @Test
  fun syncIsAbandonedWhenNoLauncherCanBeGrantedArtwork() {
    withServer("image/png", imageBytes) { source ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      registerHandler(homeIntent, "rejecting.home.launcher")
      val grantContext = RecordingGrantContext(context, setOf("rejecting.home.launcher"))

      assertFalse(
        WatchNextProvider(grantContext).syncWatchNextPrograms("owner-a", 1, listOf(item(source)))
      )

      assertTrue(tvProvider.inserted.isEmpty())
      assertTrue(artworkFiles().isEmpty())
      assertTrue(
        context.getSharedPreferences("system_shelf_state", 0)
          .getStringSet("granted_uris", null)
          .isNullOrEmpty()
      )
    }
  }

  @Test
  fun syncPublishesWhenOneLauncherRejectsTheGrantAndAnotherAcceptsIt() {
    withServer("image/png", imageBytes) { source ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      registerHandler(homeIntent, "rejecting.home.launcher")
      registerHandler(homeIntent, "accepting.home.launcher")
      val grantContext = RecordingGrantContext(context, setOf("rejecting.home.launcher"))

      assertTrue(
        WatchNextProvider(grantContext).syncWatchNextPrograms("owner-a", 1, listOf(item(source)))
      )

      val poster = committedPoster()!!
      assertEquals(
        setOf(Grant("accepting.home.launcher", poster, Intent.FLAG_GRANT_READ_URI_PERMISSION)),
        grantContext.grants.toSet()
      )
      assertArrayEquals(imageBytes, openArtwork(poster))
    }
  }

  @Test
  fun syncIsAbandonedWhenOnePosterOfManyReachesNoLauncher() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      registerHandler(homeIntent, "only.home.launcher")
      // The first poster is granted, the second reaches nobody. A global "something was granted"
      // check would happily publish the second as a broken tile.
      val grantContext = RecordingGrantContext(context, acceptedGrantLimit = 1)

      assertFalse(
        WatchNextProvider(grantContext).syncWatchNextPrograms(
          "owner-a",
          1,
          listOf(
            item("${server.baseUrl}/first"),
            item("${server.baseUrl}/second").copy(contentId = "second")
          )
        )
      )

      assertEquals(1, grantContext.grants.size)
      assertTrue(tvProvider.inserted.isEmpty())
      assertTrue(artworkFiles().isEmpty())
    }
  }

  @Test
  fun bootRestoresConfinedArtworkGrantsToEveryHomeLauncher() {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val selected = registerHandler(homeIntent, "selected.home.launcher")
    val sideloaded = registerHandler(homeIntent, "sideloaded.home.launcher")
    selectDefaultHome(selected, selected, sideloaded)
    val owner = "a".repeat(64)
    val legacyKey = "${"b".repeat(32)}.art"
    val contentKey = "${"c".repeat(64)}.art"
    val corruptKey = "${"d".repeat(64)}.art"
    val directory = context.cacheDir.resolve("system_shelf_artwork/$owner").apply { mkdirs() }
    directory.resolve(legacyKey).writeBytes(imageBytes)
    directory.resolve(contentKey).writeBytes(imageBytes)
    directory.resolve(corruptKey).writeText("corrupt")
    val store = SystemShelfArtworkStore(context.cacheDir)
    val legacy = store.contentUri(owner, legacyKey)
    val contentAddressed = store.contentUri(owner, contentKey)
    val corrupt = store.contentUri(owner, corruptKey)
    val malformed = Uri.parse(
      "content://${SystemShelfArtworkProvider.AUTHORITY}/art/$owner/${"e".repeat(48)}.art"
    )
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putStringSet(
        "granted_uris",
        setOf(
          legacy.toString(),
          contentAddressed.toString(),
          corrupt.toString(),
          malformed.toString()
        )
      )
      .putInt("shelf_schema_version", WatchNextProvider.SHELF_SCHEMA_VERSION)
      .commit()
    val recordingContext = RecordingGrantContext(context)

    SystemShelfUpdateReceiver(Executor { command -> command.run() })
      .onReceive(recordingContext, Intent(Intent.ACTION_BOOT_COMPLETED))

    assertEquals(
      setOf(
        Grant("selected.home.launcher", legacy, Intent.FLAG_GRANT_READ_URI_PERMISSION),
        Grant("selected.home.launcher", contentAddressed, Intent.FLAG_GRANT_READ_URI_PERMISSION),
        Grant("sideloaded.home.launcher", legacy, Intent.FLAG_GRANT_READ_URI_PERMISSION),
        Grant("sideloaded.home.launcher", contentAddressed, Intent.FLAG_GRANT_READ_URI_PERMISSION)
      ),
      recordingContext.grants.toSet()
    )
    assertEquals(
      setOf(legacy.toString(), contentAddressed.toString()),
      context.getSharedPreferences("system_shelf_state", 0)
        .getStringSet("granted_uris", emptySet())
    )
    assertArrayEquals(imageBytes, openArtwork(legacy))
    assertArrayEquals(imageBytes, openArtwork(contentAddressed))
    assertNull(store.resolve(corrupt))
    assertEquals(
      WatchNextProvider.SHELF_SCHEMA_VERSION,
      context.getSharedPreferences("system_shelf_state", 0)
        .getInt("shelf_schema_version", 0)
    )
  }

  @Test
  @Config(sdk = [25])
  fun api25RevocationUsesUriWideFallback() {
    val stale = Uri.parse("content://${SystemShelfArtworkProvider.AUTHORITY}/art/stale/file.art")
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putStringSet("granted_uris", setOf(stale.toString()))
      .putStringSet("granted_packages", setOf("selected.home.launcher"))
      .putInt("shelf_schema_version", WatchNextProvider.SHELF_SCHEMA_VERSION)
      .commit()
    val recordingContext = RecordingGrantContext(context)

    assertTrue(WatchNextProvider.forMaintenance(recordingContext).restoreReadGrants())

    assertEquals(listOf(stale), recordingContext.uriWideRevocations)
    assertTrue(recordingContext.packageRevocations.isEmpty())
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
  fun packageUpdatePreservesRowsAndArtworkAtCurrentShelfSchema() {
    val directory = context.cacheDir.resolve("system_shelf_artwork/${"a".repeat(64)}")
      .apply { mkdirs() }
    val legacyFile = directory.resolve("${"b".repeat(32)}.art")
    val contentAddressedFile = directory.resolve("${"c".repeat(64)}.art")
    legacyFile.writeBytes(imageBytes)
    contentAddressedFile.writeBytes(imageBytes)
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putInt("shelf_schema_version", WatchNextProvider.SHELF_SCHEMA_VERSION)
      .commit()

    val receiver = SystemShelfUpdateReceiver(Executor { command -> command.run() })
    receiver.onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))

    assertEquals(0, tvProvider.deleteCount)
    assertTrue(legacyFile.isFile)
    assertTrue(contentAddressedFile.isFile)
    assertEquals(1, WatchNextProvider.SHELF_SCHEMA_VERSION)
  }

  @Test
  fun packageUpdateCleanupDeletesLegacyRowsAndOwnedFiles() {
    context.cacheDir.resolve("system_shelf_artwork/legacy").apply { mkdirs() }.resolve("legacy.art").writeBytes(imageBytes)
    val receiver = SystemShelfUpdateReceiver(Executor { command -> command.run() })
    receiver.onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))

    assertEquals(1, tvProvider.deleteCount)
    assertFalse(context.cacheDir.resolve("system_shelf_artwork").exists())
  }

  @Test
  fun providerFailureDeletesNewArtworkAndPreservesCommittedArtwork() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      val selectedHome = registerHandler(homeIntent, "selected.home.launcher")
      selectDefaultHome(selectedHome, selectedHome)
      val grantContext = RecordingGrantContext(context)
      val provider = WatchNextProvider(grantContext)
      val sourceA = "${server.baseUrl}/a"
      val sourceB = "${server.baseUrl}/b"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val committedPoster = committedPoster()!!
      val committedArtwork = SystemShelfArtworkStore(context.cacheDir)
        .resolveOwned("owner-a", committedPoster)!!
        .canonicalFile
      tvProvider.failBatch = true

      assertFalse(provider.syncWatchNextPrograms("owner-a", 2, listOf(item(sourceB))))

      assertEquals(2, server.requestCount.get())
      assertEquals(committedPoster, committedPoster())
      assertEquals(setOf(committedArtwork), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertArrayEquals(imageBytes, openArtwork(committedPoster))
      assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
      val uncommittedPoster = grantContext.grants
        .map(Grant::uri)
        .first { it != committedPoster }
      val revokedUris = grantContext.packageRevocations.map(PackageRevocation::uri) +
        grantContext.uriWideRevocations
      assertFalse(committedPoster in revokedUris)
      assertTrue(uncommittedPoster in revokedUris)
      assertEquals(
        setOf(committedPoster.toString()),
        context.getSharedPreferences("system_shelf_state", 0)
          .getStringSet("granted_uris", emptySet())
      )
    }
  }

  @Test
  fun repeatedSameSourceSyncReusesValidatedArtwork() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      val selectedHome = registerHandler(homeIntent, "selected.home.launcher")
      selectDefaultHome(selectedHome, selectedHome)
      val grantContext = RecordingGrantContext(context)
      val provider = WatchNextProvider(grantContext)
      val store = SystemShelfArtworkStore(context.cacheDir)
      val stableSource = "${server.baseUrl}/stable"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(stableSource))))
      val firstPoster = committedPoster()!!
      val firstFile = store.resolveOwned("owner-a", firstPoster)!!.canonicalFile
      val stableTimestamp = 1_600_000_000_000L
      assertTrue(firstFile.setLastModified(stableTimestamp))
      assertTrue(Regex("[a-f0-9]{64}\\.art").matches(firstPoster.lastPathSegment.orEmpty()))

      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-a",
          2,
          listOf(item(stableSource).copy(title = "Updated title", lastPlaybackPosition = 20))
        )
      )

      assertEquals(1, server.requestCount.get())
      assertEquals(firstPoster, committedPoster())
      assertEquals(setOf(firstFile), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertEquals(stableTimestamp, firstFile.lastModified())
      assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
      assertTrue(grantContext.uriWideRevocations.isEmpty())
      assertTrue(grantContext.packageRevocations.isEmpty())
      val zeroBudget = SystemShelfArtworkStore.Budget(0)
      val cachedOwnership = provider.claimOwnership("owner-a", 3)!!
      val cached = store.prepare(
        "owner-a",
        stableSource,
        SystemShelfSyncSession(cachedOwnership, 2_000, budget = zeroBudget)
      )
      assertTrue(cached is SystemShelfArtworkStore.Prepared.Existing)
      assertEquals(0L, zeroBudget.consumed)
      assertEquals(0, zeroBudget.remaining)

      val sharedSource = "${server.baseUrl}/shared"
      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-a",
          4,
          listOf(
            item(sharedSource).copy(contentId = "first"),
            item(sharedSource).copy(contentId = "second")
          )
        )
      )
      assertEquals(2, server.requestCount.get())
      val sharedPosters = tvProvider.inserted.map {
        it.getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
      }.toSet()
      assertEquals(1, sharedPosters.size)
      val sharedPoster = Uri.parse(sharedPosters.single())
      assertEquals(1, artworkFiles().size)
      assertArrayEquals(imageBytes, openArtwork(sharedPoster))
      grantContext.uriWideRevocations.clear()
      grantContext.packageRevocations.clear()

      val firstRemoved = provider.removeItem("owner-a", 5, "first")
      assertEquals(listOf("first", "second"), tvProvider.lastQueryContentIds)
      assertEquals(
        listOf(
          TvContractCompat.WatchNextPrograms._ID,
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
          TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
          TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI,
          TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI
        ),
        tvProvider.lastQueryProjection
      )
      assertEquals(
        listOf(sharedPoster.toString(), sharedPoster.toString()),
        tvProvider.lastQueryPosters
      )
      assertTrue(firstRemoved)
      assertTrue(grantContext.uriWideRevocations.isEmpty())
      assertTrue(grantContext.packageRevocations.isEmpty())
      assertEquals(listOf("second"), tvProvider.contentIds())
      assertArrayEquals(imageBytes, openArtwork(sharedPoster))
      assertEquals(
        setOf(sharedPoster.toString()),
        context.getSharedPreferences("system_shelf_state", 0)
          .getStringSet("granted_uris", emptySet())
      )

      assertTrue(provider.removeItem("owner-a", 6, "second"))
      val finalReferenceRevocations =
        grantContext.packageRevocations.map(PackageRevocation::uri) +
          grantContext.uriWideRevocations
      assertEquals(listOf(sharedPoster), finalReferenceRevocations)
      assertTrue(artworkFiles().isEmpty())
      assertTrue(
        runCatching {
          Robolectric.buildContentProvider(SystemShelfArtworkProvider::class.java)
            .create()
            .get()
            .openFile(sharedPoster, "r")
            .close()
        }.isFailure
      )
    }
  }

  @Test
  fun changedSourceFetchFailureRetainsLastKnownGoodArtwork() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(status = 503, contentType = "text/plain", body = "retry".toByteArray()),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
      val selectedHome = registerHandler(homeIntent, "selected.home.launcher")
      selectDefaultHome(selectedHome, selectedHome)
      val grantContext = RecordingGrantContext(context)
      val provider = WatchNextProvider(grantContext)
      val sourceA = "${server.baseUrl}/a"
      val sourceB = "${server.baseUrl}/b"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val originalPoster = committedPoster()!!
      val originalFile = SystemShelfArtworkStore(context.cacheDir)
        .resolveOwned("owner-a", originalPoster)!!
        .canonicalFile

      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-a",
          2,
          listOf(item(sourceB).copy(title = "Progress update", lastPlaybackPosition = 40))
        )
      )
      assertEquals(2, server.requestCount.get())
      assertEquals(listOf("plezy_server_item"), tvProvider.lastQueryContentIds)
      assertEquals(listOf(originalPoster.toString()), tvProvider.lastQueryPosters)
      assertEquals(originalPoster, committedPoster())
      assertEquals(
        "Progress update",
        tvProvider.inserted.single()
          .getAsString(TvContractCompat.WatchNextPrograms.COLUMN_TITLE)
      )
      assertTrue(originalFile.isFile)
      assertArrayEquals(imageBytes, openArtwork(originalPoster))

      tvProvider.blockNextBatch = true
      val retryResult = AtomicReference<Boolean>()
      val retry = thread(start = true, name = "system-shelf-source-retry") {
        retryResult.set(
          provider.syncWatchNextPrograms(
            "owner-a",
            3,
            listOf(item(sourceB).copy(title = "Replacement ready"))
          )
        )
      }
      try {
        assertTrue(tvProvider.batchStarted.await(2, TimeUnit.SECONDS))
        assertTrue(originalFile.isFile)
        assertArrayEquals(imageBytes, openArtwork(originalPoster))
        assertEquals(2, artworkFiles().count { it.name.endsWith(".art") })
        assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
        val revokedBeforeCommit =
          grantContext.packageRevocations.map(PackageRevocation::uri) +
            grantContext.uriWideRevocations
        assertFalse(originalPoster in revokedBeforeCommit)
      } finally {
        tvProvider.releaseBatch.countDown()
        retry.join(2_000)
      }
      assertEquals(true, retryResult.get())
      assertEquals(3, server.requestCount.get())
      val replacementPoster = committedPoster()!!
      assertFalse(replacementPoster == originalPoster)
      assertFalse(originalFile.exists())
      assertArrayEquals(imageBytes, openArtwork(replacementPoster))
      val revokedAfterCommit =
        grantContext.packageRevocations.map(PackageRevocation::uri) +
          grantContext.uriWideRevocations
      assertTrue(originalPoster in revokedAfterCommit)

      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-a",
          4,
          listOf(item(sourceB).copy(posterSourceUri = null))
        )
      )
      assertNull(committedPoster())
      assertTrue(artworkFiles().isEmpty())
      assertEquals(3, server.requestCount.get())
    }
  }

  @Test
  fun malformedReplacementRetainsLastKnownGoodArtwork() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = "not an image".toByteArray())
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val sourceA = "${server.baseUrl}/valid"
      val sourceB = "${server.baseUrl}/malformed"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val originalPoster = committedPoster()!!
      val originalFile = artworkFiles().single().canonicalFile

      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-a",
          2,
          listOf(item(sourceB).copy(lastPlaybackPosition = 50))
        )
      )

      assertEquals(2, server.requestCount.get())
      assertEquals(listOf("plezy_server_item"), tvProvider.lastQueryContentIds)
      assertEquals(listOf(originalPoster.toString()), tvProvider.lastQueryPosters)
      assertEquals(originalPoster, committedPoster())
      assertEquals(setOf(originalFile), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertArrayEquals(imageBytes, openArtwork(originalPoster))
      assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
    }
  }

  @Test
  fun corruptContentAddressIsRefetchedWithoutPartialPublish() {
    val replacementRequested = CountDownLatch(1)
    val releaseReplacement = CountDownLatch(1)
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(
          body = imageBytes,
          beforeResponse = {
            replacementRequested.countDown()
            releaseReplacement.await(2, TimeUnit.SECONDS)
          }
        ),
        ScriptedResponse(status = 503, contentType = "text/plain"),
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(status = 503, contentType = "text/plain")
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val store = SystemShelfArtworkStore(context.cacheDir)
      val source = "${server.baseUrl}/stable"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      val stablePoster = committedPoster()!!
      val deterministicFile = store.resolveOwned("owner-a", stablePoster)!!
      val corruptBytes = "corrupt-cache".toByteArray()
      deterministicFile.writeBytes(corruptBytes)
      assertNull(store.resolveOwned("owner-a", stablePoster))
      assertTrue(runCatching { openArtwork(stablePoster) }.isFailure)

      val refetchResult = AtomicReference<Boolean>()
      val refetch = thread(start = true, name = "system-shelf-corrupt-refetch") {
        refetchResult.set(
          provider.syncWatchNextPrograms("owner-a", 2, listOf(item(source)))
        )
      }
      try {
        assertTrue(replacementRequested.await(2, TimeUnit.SECONDS))
        assertArrayEquals(corruptBytes, deterministicFile.readBytes())
        assertEquals(1, artworkFiles().size)
        assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
      } finally {
        releaseReplacement.countDown()
        refetch.join(2_000)
      }

      assertEquals(true, refetchResult.get())
      assertEquals(stablePoster, committedPoster())
      assertArrayEquals(imageBytes, deterministicFile.readBytes())
      assertArrayEquals(imageBytes, openArtwork(stablePoster))
      assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })

      deterministicFile.writeBytes(corruptBytes)
      assertTrue(provider.syncWatchNextPrograms("owner-a", 3, listOf(item(source))))
      assertEquals(3, server.requestCount.get())
      assertNull(committedPoster())
      assertTrue(artworkFiles().isEmpty())

      assertTrue(provider.syncWatchNextPrograms("owner-a", 4, listOf(item(source))))
      assertEquals(stablePoster, committedPoster())
      assertTrue(deterministicFile.delete())
      assertTrue(provider.syncWatchNextPrograms("owner-a", 5, listOf(item(source))))
      assertEquals(5, server.requestCount.get())
      assertNull(committedPoster())
      assertTrue(artworkFiles().isEmpty())
    }
  }

  @Test
  fun committedRowQueryFailureAbortsBeforeArtworkOrShelfMutation() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val sourceA = "${server.baseUrl}/a"
      val sourceB = "${server.baseUrl}/b"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val originalPoster = committedPoster()!!
      val originalFile = artworkFiles().single().canonicalFile
      val preferences = context.getSharedPreferences("system_shelf_state", 0)
      val grantedBefore = preferences.getStringSet("granted_uris", emptySet())!!.toSet()
      val packagesBefore = preferences.getStringSet("granted_packages", emptySet())!!.toSet()

      tvProvider.failQuery = true
      assertFalse(provider.syncWatchNextPrograms("owner-a", 2, listOf(item(sourceB))))
      tvProvider.failQuery = false
      tvProvider.returnNullQuery = true
      assertFalse(provider.syncWatchNextPrograms("owner-a", 3, listOf(item(sourceB))))
      tvProvider.returnNullQuery = false

      assertEquals(1, server.requestCount.get())
      assertEquals(3, tvProvider.queryCount)
      assertEquals(originalPoster, committedPoster())
      assertEquals(setOf(originalFile), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertEquals(grantedBefore, preferences.getStringSet("granted_uris", emptySet()))
      assertEquals(packagesBefore, preferences.getStringSet("granted_packages", emptySet()))
      assertArrayEquals(imageBytes, openArtwork(originalPoster))
    }
  }

  @Test
  fun interruptedPublishLeavesCommittedArtworkAndUniqueStagesUntouched() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes)
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val store = SystemShelfArtworkStore(context.cacheDir)
      val sourceA = "${server.baseUrl}/a"
      val sourceB = "${server.baseUrl}/b"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val originalPoster = committedPoster()!!
      val originalFile = store.resolveOwned("owner-a", originalPoster)!!.canonicalFile

      val firstOwnership = provider.claimOwnership("owner-a", 2)!!
      val firstStage = store.prepare(
        "owner-a",
        sourceB,
        SystemShelfSyncSession(firstOwnership, 2_000)
      ) as SystemShelfArtworkStore.Prepared.Staged
      val secondOwnership = provider.claimOwnership("owner-a", 3)!!
      val secondStage = store.prepare(
        "owner-a",
        sourceB,
        SystemShelfSyncSession(secondOwnership, 2_000)
      ) as SystemShelfArtworkStore.Prepared.Staged
      assertFalse(firstStage.stagingFile.canonicalFile == secondStage.stagingFile.canonicalFile)
      assertFalse(firstStage.materialized.file.exists())

      assertTrue(secondStage.stagingFile.delete())
      val publication = SystemShelfLifecycle.whileCurrent(secondOwnership) {
        store.publish(secondStage)
      }
      assertNull(publication)
      store.discard(listOf(firstStage, secondStage))

      assertEquals(3, server.requestCount.get())
      assertEquals(originalPoster, committedPoster())
      assertTrue(originalFile.isFile)
      assertFalse(firstStage.materialized.file.exists())
      assertEquals(setOf(originalFile), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertArrayEquals(imageBytes, openArtwork(originalPoster))
    }
  }

  @Test
  fun contentAddressesAndFallbackAreOwnerIsolated() {
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(status = 503, contentType = "text/plain")
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val source = "${server.baseUrl}/shared"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
      val ownerAPoster = committedPoster()!!

      assertTrue(provider.syncWatchNextPrograms("owner-b", 2, listOf(item(source))))
      val ownerBPoster = committedPoster()!!
      assertFalse(ownerAPoster == ownerBPoster)
      assertFalse(ownerAPoster.pathSegments[1] == ownerBPoster.pathSegments[1])
      assertEquals(2, server.requestCount.get())
      assertArrayEquals(imageBytes, openArtwork(ownerBPoster))

      assertTrue(
        provider.syncWatchNextPrograms(
          "owner-c",
          3,
          listOf(item(source).copy(title = "Owner C metadata"))
        )
      )
      assertEquals(3, server.requestCount.get())
      assertNull(committedPoster())
      assertTrue(artworkFiles().isEmpty())
    }
  }

  @Test
  fun staleOperationCannotPublishOrPruneCommittedArtwork() {
    val replacementRequest = CountDownLatch(1)
    val releaseReplacement = CountDownLatch(1)
    ScriptedHttpServer(
      listOf(
        ScriptedResponse(body = imageBytes),
        ScriptedResponse(
          body = imageBytes,
          beforeResponse = {
            replacementRequest.countDown()
            releaseReplacement.await(2, TimeUnit.SECONDS)
          }
        )
      )
    ).use { server ->
      val provider = WatchNextProvider(context)
      val sourceA = "${server.baseUrl}/a"
      val sourceB = "${server.baseUrl}/b"
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(sourceA))))
      val originalPoster = committedPoster()!!
      val originalFile = artworkFiles().single().canonicalFile
      val staleResult = AtomicReference<Boolean>()
      val staleWorker = thread(start = true, name = "system-shelf-stale-artwork") {
        staleResult.set(
          provider.syncWatchNextPrograms("owner-a", 2, listOf(item(sourceB)))
        )
      }
      try {
        assertTrue(replacementRequest.await(2, TimeUnit.SECONDS))
        assertTrue(provider.claimOwnership("owner-a", 3) != null)
      } finally {
        releaseReplacement.countDown()
        staleWorker.join(2_000)
      }

      assertFalse(staleWorker.isAlive)
      assertEquals(false, staleResult.get())
      assertEquals(originalPoster, committedPoster())
      assertEquals(setOf(originalFile), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
      assertFalse(artworkFiles().any { it.name.endsWith(".tmp") })
      assertArrayEquals(imageBytes, openArtwork(originalPoster))
    }
  }

  private fun committedPoster(): Uri? = tvProvider.inserted.singleOrNull()
    ?.getAsString(TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
    ?.let(Uri::parse)

  private fun openArtwork(uri: Uri): ByteArray {
    val provider = Robolectric.buildContentProvider(SystemShelfArtworkProvider::class.java)
      .create()
      .get()
    return AutoCloseInputStream(provider.openFile(uri, "r")).use { it.readBytes() }
  }

  private fun registerHandler(intent: Intent, packageName: String): ComponentName {
    val component = ComponentName(packageName, "$packageName.HomeActivity")
    val result = ResolveInfo().apply {
      activityInfo = ActivityInfo().apply {
        this.packageName = component.packageName
        name = component.className
        applicationInfo = ApplicationInfo().apply { this.packageName = component.packageName }
      }
    }
    shadowOf(context.packageManager).addResolveInfoForIntent(intent, result)
    return component
  }

  private fun selectDefaultHome(selected: ComponentName, vararg candidates: ComponentName) {
    val filter = IntentFilter(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_HOME) }
    context.packageManager.addPreferredActivity(filter, IntentFilter.MATCH_CATEGORY_EMPTY, candidates, selected)
  }

  private fun artworkFiles() = context.cacheDir.resolve("system_shelf_artwork").walkTopDown().filter { it.isFile }.toList()

  private fun pluginBinding(): FlutterPlugin.FlutterPluginBinding {
    val messenger = Proxy.newProxyInstance(
      BinaryMessenger::class.java.classLoader,
      arrayOf(BinaryMessenger::class.java)
    ) { _, _, _ -> null } as BinaryMessenger
    val constructor = FlutterPlugin.FlutterPluginBinding::class.java.constructors.single()
    val arguments = constructor.parameterTypes.map { type ->
      when {
        Context::class.java.isAssignableFrom(type) -> context
        BinaryMessenger::class.java.isAssignableFrom(type) -> messenger
        else -> null
      }
    }.toTypedArray()
    return constructor.newInstance(*arguments) as FlutterPlugin.FlutterPluginBinding
  }
  private fun syncCall(ownerId: String, generation: Long) = MethodCall(
    "sync",
    mapOf(
      "schemaVersion" to 3,
      "ownerId" to ownerId,
      "generation" to generation,
      "items" to emptyList<Map<String, Any?>>()
    )
  )

  private fun awaitResult(result: RecordingResult) {
    repeat(100) {
      shadowOf(android.os.Looper.getMainLooper()).idle()
      if (result.completed.await(10, TimeUnit.MILLISECONDS)) return
    }
    assertTrue("Watch Next result never completed", false)
  }

  private fun pluginIoExecutor(plugin: WatchNextPlugin): ExecutorService = WatchNextPlugin::class.java.getDeclaredField("ioExecutor").run {
    isAccessible = true
    get(plugin) as ExecutorService
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

private data class ScriptedResponse(
  val status: Int = 200,
  val contentType: String = "image/png",
  val body: ByteArray = ByteArray(0),
  val beforeResponse: (() -> Unit)? = null
)

private class ScriptedHttpServer(responses: List<ScriptedResponse>) : Closeable {
  private val server = ServerSocket(0, 8, InetAddress.getByName("127.0.0.1"))
  private val scriptedResponses = ArrayDeque<ScriptedResponse>().apply { addAll(responses) }
  val requestCount = AtomicInteger()
  val baseUrl = "http://127.0.0.1:${server.localPort}"
  private val responder = thread(start = true, name = "system-shelf-scripted-http") {
    while (!server.isClosed) {
      val socket = runCatching { server.accept() }.getOrNull() ?: break
      runCatching {
        socket.use {
          val reader = it.getInputStream().bufferedReader()
          while (reader.readLine()?.isNotEmpty() == true) {
            // Consume request headers.
          }
          requestCount.incrementAndGet()
          val response = synchronized(scriptedResponses) {
            if (scriptedResponses.isEmpty()) {
              ScriptedResponse(status = 500, contentType = "text/plain")
            } else {
              scriptedResponses.removeFirst()
            }
          }
          response.beforeResponse?.invoke()
          val reason = if (response.status in 200..299) "OK" else "Injected"
          val headers = (
            "HTTP/1.1 ${response.status} $reason\r\n" +
              "Content-Type: ${response.contentType}\r\n" +
              "Content-Length: ${response.body.size}\r\n" +
              "Connection: close\r\n\r\n"
            ).toByteArray()
          it.getOutputStream().use { output ->
            output.write(headers)
            output.write(response.body)
            output.flush()
          }
        }
      }
    }
  }

  override fun close() {
    server.close()
    responder.join(2_000)
  }
}

private data class Grant(val packageName: String, val uri: Uri, val modeFlags: Int)

private data class PackageRevocation(val packageName: String, val uri: Uri, val modeFlags: Int)

private class RecordingGrantContext(
  base: Context,
  private val rejectingPackages: Set<String> = emptySet(),
  private val acceptedGrantLimit: Int = Int.MAX_VALUE
) : ContextWrapper(base) {
  val grants = mutableListOf<Grant>()
  val uriWideRevocations = mutableListOf<Uri>()
  val packageRevocations = mutableListOf<PackageRevocation>()

  override fun getApplicationContext(): Context = this

  override fun grantUriPermission(toPackage: String?, uri: Uri?, modeFlags: Int) {
    if (toPackage in rejectingPackages || grants.size >= acceptedGrantLimit) {
      throw SecurityException("Cannot grant to $toPackage")
    }
    if (toPackage != null && uri != null) grants += Grant(toPackage, uri, modeFlags)
  }

  override fun revokeUriPermission(uri: Uri?, modeFlags: Int) {
    if (uri != null) uriWideRevocations += uri
  }

  override fun revokeUriPermission(targetPackage: String?, uri: Uri?, modeFlags: Int) {
    if (targetPackage != null && uri != null) {
      packageRevocations += PackageRevocation(targetPackage, uri, modeFlags)
    }
  }
}

private class CapturingTvProvider : ContentProvider() {
  val inserted = mutableListOf<ContentValues>()
  fun contentIds(): List<String?> = inserted.map { values ->
    valueAsString(values, TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID)
      ?.takeIf(String::isNotBlank)
      ?: valueAsString(
        values,
        TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA
      )?.takeIf(String::isNotBlank)
      ?: valueAsString(values, TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI)
        ?.let(Uri::parse)
        ?.takeIf { uri -> uri.scheme == "plezy" && uri.authority == "play" }
        ?.getQueryParameter("content_id")
  }
  private val rowIds = mutableListOf<Long>()
  private var nextRowId = 1L
  var deleteCount = 0
  var queryCount = 0
  var lastQueryContentIds: List<String?> = emptyList()
  var lastQueryPosters: List<String?> = emptyList()
  var lastQueryProjection: List<String> = emptyList()
  var failQuery = false
  var returnNullQuery = false
  var failBatch = false
  var blockNextBatch = false
  val batchStarted = CountDownLatch(1)
  val releaseBatch = CountDownLatch(1)

  override fun onCreate(): Boolean = true

  override fun insert(uri: Uri, values: ContentValues?): Uri {
    val id = nextRowId++
    inserted += ContentValues(values)
    rowIds += id
    return uri.buildUpon().appendPath(id.toString()).build()
  }

  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
    deleteCount++
    if (uri == TvContractCompat.WatchNextPrograms.CONTENT_URI) {
      val deleted = inserted.size
      inserted.clear()
      rowIds.clear()
      return deleted
    }
    val id = uri.lastPathSegment?.toLongOrNull() ?: return 0
    val index = rowIds.indexOf(id)
    if (index < 0) return 0
    rowIds.removeAt(index)
    inserted.removeAt(index)
    return 1
  }

  override fun applyBatch(
    operations: ArrayList<ContentProviderOperation>
  ): Array<ContentProviderResult> {
    if (failBatch) throw IllegalStateException("Injected provider failure")
    if (blockNextBatch) {
      blockNextBatch = false
      batchStarted.countDown()
      releaseBatch.await(2, TimeUnit.SECONDS)
    }
    return super.applyBatch(operations)
  }

  override fun query(
    uri: Uri,
    projection: Array<out String>?,
    selection: String?,
    selectionArgs: Array<out String>?,
    sortOrder: String?
  ): Cursor? {
    queryCount++
    if (failQuery) throw IllegalStateException("Injected query failure")
    if (returnNullQuery) return null
    val columns = projection ?: arrayOf(
      TvContractCompat.WatchNextPrograms._ID,
      TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
      TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
      TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI,
      TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI
    )
    lastQueryProjection = columns.toList()
    lastQueryContentIds = contentIds()
    lastQueryPosters = inserted.map { values ->
      valueAsString(values, TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI)
    }
    return MatrixCursor(columns).apply {
      inserted.indices.forEach { index ->
        addRow(
          columns.map { column ->
            when (column) {
              TvContractCompat.WatchNextPrograms._ID -> rowIds[index]
              TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA ->
                inserted[index].get(column)
              TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
              TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI,
              TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI ->
                valueAsString(inserted[index], column)
              else -> inserted[index].get(column)
            }
          }.toTypedArray()
        )
      }
    }
  }

  private fun valueAsString(values: ContentValues, column: String): String? = when (val value = values.get(column)) {
    is ByteArray -> value.toString(Charsets.UTF_8)
    else -> values.getAsString(column)
  }

  override fun getType(uri: Uri): String? = null
  override fun update(
    uri: Uri,
    values: ContentValues?,
    selection: String?,
    selectionArgs: Array<out String>?
  ): Int = 0
}

private class RecordingResult : MethodChannel.Result {
  val completed = CountDownLatch(1)
  var successValue: Any? = null

  override fun success(result: Any?) {
    successValue = result
    completed.countDown()
  }

  override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
    completed.countDown()
  }

  override fun notImplemented() {
    completed.countDown()
  }
}

private class ManualExecutorService : AbstractExecutorService() {
  private val tasks = ArrayDeque<Runnable>()
  private var shutdown = false

  override fun execute(command: Runnable) {
    if (shutdown) throw RejectedExecutionException()
    tasks.addLast(command)
  }

  override fun shutdown() {
    shutdown = true
  }

  override fun shutdownNow(): MutableList<Runnable> {
    shutdown = true
    return tasks.toMutableList().also { tasks.clear() }
  }

  override fun isShutdown(): Boolean = shutdown

  override fun isTerminated(): Boolean = shutdown && tasks.isEmpty()

  override fun awaitTermination(timeout: Long, unit: TimeUnit): Boolean = isTerminated

  fun runNext() {
    tasks.removeFirst().run()
  }
}
