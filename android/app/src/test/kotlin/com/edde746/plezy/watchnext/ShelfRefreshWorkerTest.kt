package com.edde746.plezy.watchnext

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import androidx.tvprovider.media.tv.TvContractCompat
import androidx.work.NetworkType
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.testing.WorkManagerTestInitHelper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Proxy
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowContentResolver

@RunWith(RobolectricTestRunner::class)
class ShelfRefreshWorkerTest {
  private val context: Context get() = RuntimeEnvironment.getApplication()

  @Before
  fun setUp() {
    context.getSharedPreferences("system_shelf_state", 0).edit().clear().commit()
    context.cacheDir.resolve("system_shelf_artwork").deleteRecursively()
    ShadowContentResolver.registerProviderInternal(TvContractCompat.AUTHORITY, StubTvProvider())
    WorkManagerTestInitHelper.initializeTestWorkManager(context)
  }

  @After
  fun tearDown() {
    ShelfRefreshWorker.engineLauncherOverride = null
    // Leave no live lease behind for the next test in this sandbox.
    SystemShelfLifecycle.invalidate(SystemShelfLifecycle.acquire())
    context.cacheDir.resolve("system_shelf_artwork").deleteRecursively()
  }

  @Test
  fun successfulSyncSchedulesUniquePeriodicRefreshWithKeepAndNetworkConstraint() {
    val plugin = WatchNextPlugin()
    val binding = pluginBinding()
    plugin.onAttachedToEngine(binding)
    try {
      val first = ShelfRecordingResult()
      plugin.onMethodCall(syncCall(generation = 1), first)
      awaitResult(first)
      assertEquals(true, first.successValue)

      val infos = uniqueWorkInfos()
      assertEquals(1, infos.size)
      val info = infos.single()
      assertEquals(WorkInfo.State.ENQUEUED, info.state)
      assertEquals(NetworkType.CONNECTED, info.constraints.requiredNetworkType)
      assertEquals(TimeUnit.HOURS.toMillis(6), info.periodicityInfo?.repeatIntervalMillis)

      // KEEP: a second successful sync must not replace the pending request.
      val second = ShelfRecordingResult()
      plugin.onMethodCall(syncCall(generation = 2), second)
      awaitResult(second)
      assertEquals(true, second.successValue)
      assertEquals(info.id, uniqueWorkInfos().single().id)
    } finally {
      plugin.onDetachedFromEngine(binding)
    }
  }

  @Test
  fun clearCancelsScheduledRefresh() {
    val plugin = WatchNextPlugin()
    val binding = pluginBinding()
    plugin.onAttachedToEngine(binding)
    try {
      val sync = ShelfRecordingResult()
      plugin.onMethodCall(syncCall(generation = 1), sync)
      awaitResult(sync)
      assertEquals(true, sync.successValue)
      assertEquals(WorkInfo.State.ENQUEUED, uniqueWorkInfos().single().state)

      val clear = ShelfRecordingResult()
      plugin.onMethodCall(
        MethodCall("clear", mapOf("schemaVersion" to 3, "ownerId" to "owner-a", "generation" to 2L)),
        clear
      )
      awaitResult(clear)
      assertEquals(true, clear.successValue)
      assertEquals(WorkInfo.State.CANCELLED, uniqueWorkInfos().single().state)
    } finally {
      plugin.onDetachedFromEngine(binding)
    }
  }

  @Test
  fun receiverDoesNotArmRefreshWithoutPersistedShelfState() {
    SystemShelfUpdateReceiver(directExecutor).onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
    assertTrue(uniqueWorkInfos().isEmpty())
  }

  @Test
  fun receiverRearmsRefreshOnBootWhenShelfStateIsPersisted() {
    // granted_uris is only written by a committed sync (clear removes it), so
    // its presence — even as an empty set — marks a prior sync.
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putStringSet("granted_uris", emptySet())
      .putInt("shelf_schema_version", 1)
      .commit()
    SystemShelfUpdateReceiver(directExecutor).onReceive(context, Intent(Intent.ACTION_BOOT_COMPLETED))
    assertEquals(WorkInfo.State.ENQUEUED, uniqueWorkInfos().single().state)
  }

  @Test
  fun receiverRearmsRefreshOnPackageReplacedWhenShelfStateIsPersisted() {
    context.getSharedPreferences("system_shelf_state", 0).edit()
      .putStringSet("granted_uris", emptySet())
      .putInt("shelf_schema_version", 1)
      .commit()
    SystemShelfUpdateReceiver(directExecutor).onReceive(context, Intent(Intent.ACTION_MY_PACKAGE_REPLACED))
    assertEquals(WorkInfo.State.ENQUEUED, uniqueWorkInfos().single().state)
  }

  @Test
  fun workerSkipsWithoutLaunchingEngineWhenLiveEngineHoldsLease() {
    shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_LEANBACK, true)
    val launched = AtomicBoolean(false)
    ShelfRefreshWorker.engineLauncherOverride = {
      launched.set(true)
      true
    }
    val lease = SystemShelfLifecycle.acquire()
    try {
      val result = TestListenableWorkerBuilder<ShelfRefreshWorker>(context).build().startWork().get()
      assertEquals(androidx.work.ListenableWorker.Result.success(), result)
      assertFalse(launched.get())
    } finally {
      SystemShelfLifecycle.invalidate(lease)
    }
  }

  @Test
  fun workerSkipsWithoutLaunchingEngineOnNonLeanbackDevices() {
    val launched = AtomicBoolean(false)
    ShelfRefreshWorker.engineLauncherOverride = {
      launched.set(true)
      true
    }
    val result = TestListenableWorkerBuilder<ShelfRefreshWorker>(context).build().startWork().get()
    assertEquals(androidx.work.ListenableWorker.Result.success(), result)
    assertFalse(launched.get())
  }

  @Test
  fun unattendedWorkerRunsInjectedLauncherAndMapsCompletionToResult() {
    shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_LEANBACK, true)
    val launched = AtomicBoolean(false)
    ShelfRefreshWorker.engineLauncherOverride = {
      launched.set(true)
      true
    }
    val success = TestListenableWorkerBuilder<ShelfRefreshWorker>(context).build().startWork().get()
    assertEquals(androidx.work.ListenableWorker.Result.success(), success)
    assertTrue(launched.get())

    ShelfRefreshWorker.engineLauncherOverride = { false }
    val failure = TestListenableWorkerBuilder<ShelfRefreshWorker>(context).build().startWork().get()
    assertEquals(androidx.work.ListenableWorker.Result.retry(), failure)
  }

  private val directExecutor = Executor { it.run() }

  private fun uniqueWorkInfos(): List<WorkInfo> =
    WorkManager.getInstance(context).getWorkInfosForUniqueWork(ShelfRefreshScheduler.WORK_NAME).get()

  private fun syncCall(generation: Long) = MethodCall(
    "sync",
    mapOf(
      "schemaVersion" to 3,
      "ownerId" to "owner-a",
      "generation" to generation,
      "items" to emptyList<Map<String, Any?>>()
    )
  )

  private fun awaitResult(result: ShelfRecordingResult) {
    repeat(100) {
      shadowOf(android.os.Looper.getMainLooper()).idle()
      if (result.completed.await(10, TimeUnit.MILLISECONDS)) return
    }
    assertTrue("Watch Next result never completed", false)
  }

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
}

/** Just enough TV provider for an empty-items sync/clear to commit. */
private class StubTvProvider : ContentProvider() {
  private val inserted = mutableListOf<ContentValues>()
  private var nextRowId = 1L

  override fun onCreate(): Boolean = true

  override fun insert(uri: Uri, values: ContentValues?): Uri {
    inserted += ContentValues(values)
    return uri.buildUpon().appendPath((nextRowId++).toString()).build()
  }

  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
    val deleted = inserted.size
    inserted.clear()
    return deleted
  }

  override fun query(
    uri: Uri,
    projection: Array<out String>?,
    selection: String?,
    selectionArgs: Array<out String>?,
    sortOrder: String?
  ): Cursor = MatrixCursor(
    projection ?: arrayOf(
      TvContractCompat.WatchNextPrograms._ID,
      TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_ID,
      TvContractCompat.WatchNextPrograms.COLUMN_INTERNAL_PROVIDER_DATA,
      TvContractCompat.WatchNextPrograms.COLUMN_INTENT_URI,
      TvContractCompat.PreviewPrograms.COLUMN_POSTER_ART_URI
    )
  )

  override fun getType(uri: Uri): String? = null

  override fun update(
    uri: Uri,
    values: ContentValues?,
    selection: String?,
    selectionArgs: Array<out String>?
  ): Int = 0
}

private class ShelfRecordingResult : MethodChannel.Result {
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
