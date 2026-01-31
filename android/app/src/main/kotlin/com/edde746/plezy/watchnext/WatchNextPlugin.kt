package com.edde746.plezy.watchnext

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.tvprovider.media.tv.TvContractCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin for Android TV Watch Next integration.
 * Syncs Plex "On Deck" content to the Android TV launcher's Watch Next row.
 */
class WatchNextPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "WatchNextPlugin"
        private const val METHOD_CHANNEL = "app.plezy/watch_next"

        private var pendingDeepLink: String? = null

        /**
         * Parse a Watch Next deep link intent.
         * Returns the content ID if this was a Watch Next intent, null otherwise.
         */
        fun handleIntent(intent: Intent?): String? {
            val data = intent?.data ?: return null
            if (data.scheme == "plezy" && data.authority == "play") {
                return data.getQueryParameter("content_id")
            }
            return null
        }
    }

    private lateinit var methodChannel: MethodChannel
    private var applicationContext: Context? = null
    private var watchNextProvider: WatchNextProvider? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        watchNextProvider = WatchNextProvider(binding.applicationContext)
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        applicationContext = null
        watchNextProvider = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> handleIsSupported(result)
            "sync" -> handleSync(call, result)
            "clear" -> handleClear(result)
            "remove" -> handleRemove(call, result)
            "getInitialDeepLink" -> handleGetInitialDeepLink(result)
            else -> result.notImplemented()
        }
    }

    private fun handleIsSupported(result: MethodChannel.Result) {
        val context = applicationContext
        if (context == null) {
            result.success(false)
            return
        }
        result.success(context.packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK))
    }

    private fun handleSync(call: MethodCall, result: MethodChannel.Result) {
        val provider = watchNextProvider
        if (provider == null) {
            result.error("NOT_INITIALIZED", "WatchNextProvider not initialized", null)
            return
        }

        val itemsData = call.argument<List<Map<String, Any?>>>("items")
        if (itemsData == null) {
            result.error("INVALID_ARGS", "Missing 'items' argument", null)
            return
        }

        val items = itemsData.mapNotNull { parseWatchNextItem(it) }
        result.success(provider.syncWatchNextPrograms(items))
    }

    private fun handleClear(result: MethodChannel.Result) {
        val provider = watchNextProvider
        if (provider == null) {
            result.error("NOT_INITIALIZED", "WatchNextProvider not initialized", null)
            return
        }
        result.success(provider.clearAll())
    }

    private fun handleRemove(call: MethodCall, result: MethodChannel.Result) {
        val provider = watchNextProvider
        if (provider == null) {
            result.error("NOT_INITIALIZED", "WatchNextProvider not initialized", null)
            return
        }

        val contentId = call.argument<String>("contentId")
        if (contentId == null) {
            result.error("INVALID_ARGS", "Missing 'contentId' argument", null)
            return
        }
        result.success(provider.removeItem(contentId))
    }

    private fun handleGetInitialDeepLink(result: MethodChannel.Result) {
        val contentId = pendingDeepLink
        pendingDeepLink = null
        result.success(contentId)
    }

    private fun parseWatchNextItem(data: Map<String, Any?>): WatchNextProvider.WatchNextItem? {
        val contentId = data["contentId"] as? String ?: return null
        val title = data["title"] as? String ?: return null

        val typeString = data["type"] as? String ?: "movie"
        val type = when (typeString.lowercase()) {
            "episode" -> TvContractCompat.WatchNextPrograms.TYPE_TV_EPISODE
            "movie" -> TvContractCompat.WatchNextPrograms.TYPE_MOVIE
            else -> TvContractCompat.WatchNextPrograms.TYPE_MOVIE
        }

        return WatchNextProvider.WatchNextItem(
            contentId = contentId,
            title = title,
            episodeTitle = data["episodeTitle"] as? String,
            description = data["description"] as? String,
            posterUri = data["posterUri"] as? String,
            type = type,
            duration = (data["duration"] as? Number)?.toLong() ?: 0L,
            lastPlaybackPosition = (data["lastPlaybackPosition"] as? Number)?.toLong() ?: 0L,
            lastEngagementTime = (data["lastEngagementTime"] as? Number)?.toLong() ?: System.currentTimeMillis(),
            seriesTitle = data["seriesTitle"] as? String,
            seasonNumber = (data["seasonNumber"] as? Number)?.toInt(),
            episodeNumber = (data["episodeNumber"] as? Number)?.toInt()
        )
    }

    /**
     * Store a deep link content ID for delivery to Flutter.
     * Called from MainActivity on intent receipt.
     */
    fun notifyDeepLink(contentId: String) {
        pendingDeepLink = contentId
        try {
            methodChannel.invokeMethod("onWatchNextTap", mapOf("contentId" to contentId))
        } catch (e: Exception) {
            Log.d(TAG, "Method channel not ready, stored as pending deep link")
        }
    }
}
