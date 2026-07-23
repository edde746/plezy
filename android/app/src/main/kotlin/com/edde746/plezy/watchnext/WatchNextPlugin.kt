package com.edde746.plezy.watchnext

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.tvprovider.media.tv.TvContractCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class WatchNextPlugin() :
  FlutterPlugin,
  MethodChannel.MethodCallHandler {
  internal constructor(executorFactory: () -> ExecutorService) : this() {
    this.executorFactory = executorFactory
  }

  companion object {
    private const val TAG = "WatchNextPlugin"
    private const val METHOD_CHANNEL = "com.plezy/watch_next"
    private const val SCHEMA_VERSION = 2
    private var pendingDeepLink: String? = null

    fun handleIntent(intent: Intent?): String? {
      val data = intent?.data ?: return null
      return if (data.scheme == "plezy" && data.authority == "play") {
        data.getQueryParameter("content_id")
      } else {
        null
      }
    }
  }

  private var executorFactory: () -> ExecutorService = { Executors.newSingleThreadExecutor() }

  private class EngineSession(val context: Context) {
    private val closed = AtomicBoolean(false)
    var lease: SystemShelfLifecycle.Lease? = null
    var provider: WatchNextProvider? = null

    fun close() {
      closed.set(true)
    }

    fun isOpen(): Boolean = !closed.get()
  }

  private lateinit var methodChannel: MethodChannel
  private var applicationContext: Context? = null
  private var engineSession: EngineSession? = null
  private var ioExecutor: ExecutorService? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    val executor = executorFactory()
    val session = EngineSession(binding.applicationContext)
    ioExecutor = executor
    engineSession = session
    applicationContext = binding.applicationContext
    methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
    methodChannel.setMethodCallHandler(this)
    executor.execute {
      val lease = SystemShelfLifecycle.acquireIf(session::isOpen) ?: return@execute
      session.lease = lease
      if (session.isOpen()) {
        session.provider = WatchNextProvider(session.context, lease)
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    val session = engineSession
    val executor = ioExecutor
    session?.close()
    engineSession = null
    ioExecutor = null
    applicationContext = null
    if (session != null && executor != null) {
      try {
        executor.execute {
          session.lease?.let(SystemShelfLifecycle::invalidate)
          session.lease = null
          session.provider = null
        }
      } catch (_: java.util.concurrent.RejectedExecutionException) {
        Log.e(TAG, "System shelf lifecycle executor rejected detach")
      } finally {
        executor.shutdown()
      }
    }
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "isSupported" -> handleIsSupported(result)
      "sync" -> handleSync(call, result)
      "clear" -> handleClear(call, result)
      "remove" -> handleRemove(call, result)
      "getInitialDeepLink" -> handleGetInitialDeepLink(result)
      else -> result.notImplemented()
    }
  }

  private fun handleIsSupported(result: MethodChannel.Result) {
    val context = applicationContext
    result.success(context?.packageManager?.hasSystemFeature(PackageManager.FEATURE_LEANBACK) == true)
  }

  private fun ownerArguments(call: MethodCall): Pair<String, Long>? {
    if (call.argument<Number>("schemaVersion")?.toInt() != SCHEMA_VERSION) return null
    val owner = call.argument<String>("ownerId")?.takeIf(String::isNotBlank) ?: return null
    val generation = call.argument<Number>("generation")?.toLong()?.takeIf { it > 0 } ?: return null
    return owner to generation
  }

  private fun handleSync(call: MethodCall, result: MethodChannel.Result) {
    val session = engineSession ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val executor = ioExecutor ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val (owner, generation) = ownerArguments(call)
      ?: return result.error("INVALID_ARGS", "Invalid shelf envelope", null)
    val itemsData = call.argument<List<Map<String, Any?>>>("items")
      ?: return result.error("INVALID_ARGS", "Missing items", null)
    if (itemsData.size > SystemShelfArtworkStore.MAX_ITEMS) {
      return result.error("INVALID_ARGS", "Too many items", null)
    }
    val items = itemsData.mapNotNull(::parseWatchNextItem)
    executeOnIo(executor, result) {
      if (!session.isOpen()) return@executeOnIo false
      val provider = session.provider ?: return@executeOnIo false
      val ownership = provider.claimOwnership(owner, generation) ?: return@executeOnIo false
      if (!session.isOpen()) return@executeOnIo false
      provider.syncWatchNextPrograms(owner, generation, items, ownership, session::isOpen)
    }
  }

  private fun handleClear(call: MethodCall, result: MethodChannel.Result) {
    val session = engineSession ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val executor = ioExecutor ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val (owner, generation) = ownerArguments(call)
      ?: return result.error("INVALID_ARGS", "Invalid shelf envelope", null)
    executeOnIo(executor, result) {
      if (!session.isOpen()) return@executeOnIo false
      val provider = session.provider ?: return@executeOnIo false
      val ownership = provider.claimOwnership(owner, generation) ?: return@executeOnIo false
      if (!session.isOpen()) return@executeOnIo false
      provider.clearAll(owner, generation, ownership, session::isOpen)
    }
  }

  private fun handleRemove(call: MethodCall, result: MethodChannel.Result) {
    val session = engineSession ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val executor = ioExecutor ?: return result.error("NOT_INITIALIZED", "Provider unavailable", null)
    val (owner, generation) = ownerArguments(call)
      ?: return result.error("INVALID_ARGS", "Invalid shelf envelope", null)
    val contentId = call.argument<String>("contentId")
      ?: return result.error("INVALID_ARGS", "Missing contentId", null)
    executeOnIo(executor, result) {
      if (!session.isOpen()) return@executeOnIo false
      val provider = session.provider ?: return@executeOnIo false
      val ownership = provider.claimOwnership(owner, generation) ?: return@executeOnIo false
      if (!session.isOpen()) return@executeOnIo false
      provider.removeItem(owner, generation, contentId, ownership, session::isOpen)
    }
  }

  private fun executeOnIo(executor: ExecutorService, result: MethodChannel.Result, block: () -> Any?) {
    try {
      executor.execute {
        try {
          val value = block()
          mainHandler.post { result.success(value) }
        } catch (_: Exception) {
          Log.e(TAG, "System shelf IO operation failed")
          mainHandler.post { result.error("IO_ERROR", "System shelf operation failed", null) }
        }
      }
    } catch (_: java.util.concurrent.RejectedExecutionException) {
      result.error("SHUTDOWN", "Plugin is shutting down", null)
    }
  }

  private fun handleGetInitialDeepLink(result: MethodChannel.Result) {
    val contentId = pendingDeepLink
    pendingDeepLink = null
    result.success(contentId)
  }

  private fun parseWatchNextItem(data: Map<String, Any?>): WatchNextProvider.WatchNextItem? {
    val contentId = (data["contentId"] as? String)?.takeIf(String::isNotBlank) ?: return null
    val title = data["title"] as? String ?: return null
    val type = when ((data["type"] as? String)?.lowercase()) {
      "episode" -> TvContractCompat.WatchNextPrograms.TYPE_TV_EPISODE
      else -> TvContractCompat.WatchNextPrograms.TYPE_MOVIE
    }
    return WatchNextProvider.WatchNextItem(
      contentId = contentId,
      title = title,
      episodeTitle = data["episodeTitle"] as? String,
      description = data["description"] as? String,
      posterSourceUri = data["posterSourceUri"] as? String,
      type = type,
      duration = (data["duration"] as? Number)?.toLong() ?: 0L,
      lastPlaybackPosition = (data["lastPlaybackPosition"] as? Number)?.toLong() ?: 0L,
      lastEngagementTime = (data["lastEngagementTime"] as? Number)?.toLong() ?: System.currentTimeMillis(),
      seriesTitle = data["seriesTitle"] as? String,
      seasonNumber = (data["seasonNumber"] as? Number)?.toInt(),
      episodeNumber = (data["episodeNumber"] as? Number)?.toInt()
    )
  }

  fun notifyDeepLink(contentId: String) {
    pendingDeepLink = contentId
    try {
      methodChannel.invokeMethod("onWatchNextTap", mapOf("contentId" to contentId))
    } catch (_: Exception) {
      Log.d(TAG, "Method channel not ready; deep link retained")
    }
  }
}
