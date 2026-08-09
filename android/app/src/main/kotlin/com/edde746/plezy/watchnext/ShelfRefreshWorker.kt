package com.edde746.plezy.watchnext

import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.annotation.VisibleForTesting
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Owns the WorkManager registration for the periodic launcher-shelf refresh.
 *
 * Registration is best-effort by design: it runs inside the plugin's sync/clear
 * result path, and a WorkManager failure must not turn a committed shelf write
 * into a channel error.
 */
internal object ShelfRefreshScheduler {
  private const val TAG = "ShelfRefreshScheduler"
  internal const val WORK_NAME = "plezy_shelf_refresh"
  private const val REFRESH_INTERVAL_HOURS = 6L

  fun schedule(context: Context) {
    try {
      val request = PeriodicWorkRequestBuilder<ShelfRefreshWorker>(REFRESH_INTERVAL_HOURS, TimeUnit.HOURS)
        .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
        .build()
      WorkManager.getInstance(context.applicationContext)
        .enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
    } catch (e: Exception) {
      Log.e(TAG, "Failed to schedule shelf refresh work", e)
    }
  }

  fun cancel(context: Context) {
    try {
      WorkManager.getInstance(context.applicationContext).cancelUniqueWork(WORK_NAME)
    } catch (e: Exception) {
      Log.e(TAG, "Failed to cancel shelf refresh work", e)
    }
  }
}

/**
 * Refreshes the Android TV Watch Next row while the app is not running.
 *
 * Boots a headless [FlutterEngine], runs the Dart `systemShelfBackgroundMain`
 * entrypoint (`lib/services/system_shelf_background.dart`), and resolves with
 * the bool that isolate reports through the `backgroundSyncComplete` method on
 * `com.plezy/watch_next`. The run is hard-capped at [RUN_TIMEOUT_MS]; the
 * engine is always destroyed on the main thread, timeout included.
 */
class ShelfRefreshWorker(
  appContext: Context,
  params: WorkerParameters
) : CoroutineWorker(appContext, params) {
  companion object {
    private const val TAG = "ShelfRefreshWorker"
    internal const val RUN_TIMEOUT_MS = 90_000L

    /** Test seam: replaces the headless Flutter launch so tests never boot an engine. */
    @Volatile
    @VisibleForTesting
    internal var engineLauncherOverride: (suspend (Context) -> Boolean)? = null
  }

  override suspend fun doWork(): Result {
    val context = applicationContext
    // Same support gate as WatchNextPlugin.handleIsSupported: no leanback
    // launcher, no Watch Next row worth refreshing.
    if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)) return Result.success()
    // A live engine (the foreground app) owns the shelf and keeps it fresh
    // itself; a concurrent headless engine would only fight it for ownership.
    if (SystemShelfLifecycle.hasLiveLease()) return Result.success()

    val launcher = engineLauncherOverride ?: ::runHeadlessShelfSync
    val success = try {
      withTimeoutOrNull(RUN_TIMEOUT_MS) { launcher(context) } ?: false
    } catch (e: Exception) {
      Log.e(TAG, "Background shelf refresh failed", e)
      false
    }
    return if (success) Result.success() else Result.retry()
  }
}

private suspend fun runHeadlessShelfSync(context: Context): Boolean {
  val appContext = context.applicationContext
  val completion = CompletableDeferred<Boolean>()
  val engine = withContext(Dispatchers.Main) {
    val loader = FlutterInjector.instance().flutterLoader()
    if (!loader.initialized()) {
      loader.startInitialization(appContext)
    }
    loader.ensureInitializationComplete(appContext, null)
    // The engine constructor auto-registers GeneratedPluginRegistrant plugins
    // (shared_preferences, path_provider, connectivity, sqlite, ...);
    // WatchNextPlugin is app-local and must be added explicitly.
    val engine = FlutterEngine(appContext)
    try {
      WatchNextPlugin.backgroundSyncCompletionListener = { success ->
        completion.complete(success)
      }
      engine.plugins.add(WatchNextPlugin())
      engine.dartExecutor.executeDartEntrypoint(
        DartExecutor.DartEntrypoint(
          loader.findAppBundlePath(),
          "package:plezy/services/system_shelf_background.dart",
          "systemShelfBackgroundMain"
        )
      )
    } catch (e: Throwable) {
      WatchNextPlugin.backgroundSyncCompletionListener = null
      engine.destroy()
      throw e
    }
    engine
  }
  return try {
    completion.await()
  } finally {
    withContext(NonCancellable + Dispatchers.Main) {
      WatchNextPlugin.backgroundSyncCompletionListener = null
      engine.destroy()
    }
  }
}
