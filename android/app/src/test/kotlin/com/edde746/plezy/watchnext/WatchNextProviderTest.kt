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
import android.net.Uri
import android.os.ParcelFileDescriptor.AutoCloseInputStream
import androidx.tvprovider.media.tv.TvContractCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
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
          "schemaVersion" to 2,
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
            "schemaVersion" to 2,
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

      assertNull(SystemShelfArtworkStore(context.cacheDir).materialize("owner", source, session))
      assertEquals(malformed.size.toLong(), budget.consumed)
      assertEquals(100 - malformed.size, budget.remaining)
    }

    val blockedRoot = context.cacheDir.resolve("system_shelf_artwork")
    blockedRoot.writeText("not a directory")
    withServer("image/png", imageBytes) { source ->
      val budget = SystemShelfArtworkStore.Budget(100)
      val ownership = SystemShelfLifecycle.claim(SystemShelfLifecycle.acquire(), "owner", 1)!!
      val session = SystemShelfSyncSession(ownership, 2_000, budget = budget)

      assertNull(SystemShelfArtworkStore(context.cacheDir).materialize("owner", source, session))
      assertEquals(imageBytes.size.toLong(), budget.consumed)
      assertEquals(100 - imageBytes.size, budget.remaining)
    }
    blockedRoot.delete()
  }

  @Test
  fun onlySelectedHomeHandlerIsAnArtworkGrantConsumer() {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val selected = registerHandler(homeIntent, "selected.home.launcher")
    val inactive = registerHandler(homeIntent, "inactive.home.launcher")
    selectDefaultHome(selected, selected, inactive)
    registerHandler(
      Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER),
      "unrelated.leanback.app"
    )

    assertEquals(setOf("selected.home.launcher"), WatchNextProvider(context).consumerPackages())
  }

  @Test
  fun bootRestoresConfinedArtworkGrantOnlyToSelectedHomeLauncher() {
    val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
    val selected = registerHandler(homeIntent, "selected.home.launcher")
    val inactive = registerHandler(homeIntent, "inactive.home.launcher")
    selectDefaultHome(selected, selected, inactive)
    val owner = "a".repeat(64)
    val key = "${"b".repeat(32)}.art"
    context.cacheDir.resolve("system_shelf_artwork/$owner").mkdirs()
    context.cacheDir.resolve("system_shelf_artwork/$owner/$key").writeBytes(imageBytes)
    val valid = SystemShelfArtworkStore(context.cacheDir).contentUri(owner, key)
    val invalid = Uri.parse("content://${SystemShelfArtworkProvider.AUTHORITY}/art/not/confined.art")
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putStringSet("granted_uris", setOf(valid.toString(), invalid.toString()))
      .putInt("shelf_schema_version", WatchNextProvider.SHELF_SCHEMA_VERSION)
      .commit()
    val recordingContext = RecordingGrantContext(context)

    SystemShelfUpdateReceiver(Executor { command -> command.run() })
      .onReceive(recordingContext, Intent(Intent.ACTION_BOOT_COMPLETED))

    assertEquals(
      listOf(Grant("selected.home.launcher", valid, Intent.FLAG_GRANT_READ_URI_PERMISSION)),
      recordingContext.grants
    )
    assertEquals(
      setOf(valid.toString()),
      context.getSharedPreferences("system_shelf_state", 0).getStringSet("granted_uris", emptySet())
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
    val file = context.cacheDir.resolve("system_shelf_artwork/${"a".repeat(64)}/${"b".repeat(32)}.art")
    file.parentFile?.mkdirs()
    file.writeBytes(imageBytes)
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putInt("shelf_schema_version", WatchNextProvider.SHELF_SCHEMA_VERSION)
      .commit()

    val receiver = SystemShelfUpdateReceiver(Executor { command -> command.run() })
    receiver.onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))

    assertEquals(0, tvProvider.deleteCount)
    assertTrue(file.isFile)
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
    val provider = WatchNextProvider(context)
    withServer("image/png", imageBytes) { source ->
      assertTrue(provider.syncWatchNextPrograms("owner-a", 1, listOf(item(source))))
    }
    val committedArtwork = artworkFiles().single().canonicalFile
    tvProvider.failBatch = true

    withServer("image/png", imageBytes) { source ->
      assertFalse(provider.syncWatchNextPrograms("owner-a", 2, listOf(item(source))))
    }

    assertEquals(setOf(committedArtwork), artworkFiles().mapTo(HashSet()) { it.canonicalFile })
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
      "schemaVersion" to 2,
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

private data class Grant(val packageName: String, val uri: Uri, val modeFlags: Int)

private data class PackageRevocation(val packageName: String, val uri: Uri, val modeFlags: Int)

private class RecordingGrantContext(base: Context) : ContextWrapper(base) {
  val grants = mutableListOf<Grant>()
  val uriWideRevocations = mutableListOf<Uri>()
  val packageRevocations = mutableListOf<PackageRevocation>()

  override fun getApplicationContext(): Context = this

  override fun grantUriPermission(toPackage: String?, uri: Uri?, modeFlags: Int) {
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
  var deleteCount = 0
  var failBatch = false
  var blockNextBatch = false
  val batchStarted = CountDownLatch(1)
  val releaseBatch = CountDownLatch(1)
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
  override fun applyBatch(operations: ArrayList<ContentProviderOperation>): Array<ContentProviderResult> {
    if (failBatch) throw IllegalStateException("Injected provider failure")
    if (blockNextBatch) {
      blockNextBatch = false
      batchStarted.countDown()
      releaseBatch.await(2, TimeUnit.SECONDS)
    }
    return super.applyBatch(operations)
  }
  override fun getType(uri: Uri): String? = null
  override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
  override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
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
