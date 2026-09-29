package com.edde746.plezy

import android.app.ActivityManager
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPlaybackResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.jialim.plezygkui/diagnostics",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDiagnostics" -> result.success(readDiagnostics())
                "playVideo" -> {
                    if (pendingPlaybackResult != null) {
                        result.error("PLAYER_BUSY", "A video is already playing", null)
                        return@setMethodCallHandler
                    }
                    val arguments = call.arguments as? Map<*, *>
                    val url = arguments?.get("url") as? String
                    if (url.isNullOrBlank()) {
                        result.error("INVALID_URL", "A playback URL is required", null)
                        return@setMethodCallHandler
                    }
                    @Suppress("UNCHECKED_CAST")
                    val headers = arguments["headers"] as? Map<String, String> ?: emptyMap()
                    val markers = arguments["markers"] as? List<*> ?: emptyList<Any>()
                    val markerTypes = arrayListOf<String>()
                    val markerStarts = arrayListOf<Long>()
                    val markerEnds = arrayListOf<Long>()
                    for (raw in markers) {
                        val marker = raw as? Map<*, *> ?: continue
                        markerTypes.add(marker["type"] as? String ?: "marker")
                        markerStarts.add((marker["startMs"] as? Number)?.toLong() ?: 0L)
                        markerEnds.add((marker["endMs"] as? Number)?.toLong() ?: 0L)
                    }
                    val intent = Intent(this, PlayerActivity::class.java).apply {
                        putExtra(PlayerActivity.EXTRA_URL, url)
                        putExtra(PlayerActivity.EXTRA_TITLE, arguments["title"] as? String ?: "Plezy")
                        putExtra(PlayerActivity.EXTRA_START_MS, (arguments["startMs"] as? Number)?.toLong() ?: 0L)
                        putExtra(PlayerActivity.EXTRA_RATING_KEY, arguments["ratingKey"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_DURATION_MS, (arguments["durationMs"] as? Number)?.toLong() ?: 0L)
                        putExtra(PlayerActivity.EXTRA_TIMELINE_URL, arguments["timelineUrl"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_SESSION_ID, arguments["sessionId"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_HEADERS_KEYS, headers.keys.toTypedArray())
                        putExtra(PlayerActivity.EXTRA_HEADERS_VALUES, headers.values.toTypedArray())
                        putExtra(PlayerActivity.EXTRA_AUDIO_LANGUAGE, arguments["audioLanguage"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_SUBTITLE_LANGUAGE, arguments["subtitleLanguage"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_AUDIO_TRACK_ID, arguments["audioTrackId"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_SUBTITLE_TRACK_ID, arguments["subtitleTrackId"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_SKIP_MODE, arguments["skipMode"] as? String ?: "button")
                        putExtra(PlayerActivity.EXTRA_STARTUP_HARD_TIMEOUT_MS, (arguments["startupHardTimeoutMs"] as? Number)?.toLong() ?: 120_000L)
                        putExtra(PlayerActivity.EXTRA_SEEK_BACK_MS, (arguments["seekBackMs"] as? Number)?.toLong() ?: 10_000L)
                        putExtra(PlayerActivity.EXTRA_SEEK_FORWARD_MS, (arguments["seekForwardMs"] as? Number)?.toLong() ?: 30_000L)
                        putStringArrayListExtra(PlayerActivity.EXTRA_MARKER_TYPES, markerTypes)
                        putExtra(PlayerActivity.EXTRA_MARKER_STARTS, markerStarts.toLongArray())
                        putExtra(PlayerActivity.EXTRA_MARKER_ENDS, markerEnds.toLongArray())
                    }
                    pendingPlaybackResult = result
                    startActivityForResult(intent, PLAYER_REQUEST)
                }
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PLAYER_REQUEST) return
        val payload = linkedMapOf<String, Any?>(
            "positionMs" to (data?.getLongExtra(PlayerActivity.RESULT_POSITION_MS, 0L) ?: 0L),
            "durationMs" to (data?.getLongExtra(PlayerActivity.RESULT_DURATION_MS, 0L) ?: 0L),
            "ended" to (data?.getBooleanExtra(PlayerActivity.RESULT_ENDED, false) ?: false),
            "error" to data?.getStringExtra(PlayerActivity.RESULT_ERROR),
            "failureKind" to data?.getStringExtra(PlayerActivity.RESULT_FAILURE_KIND),
            "renderedFrame" to (data?.getBooleanExtra(PlayerActivity.RESULT_RENDERED_FRAME, false) ?: false),
            "firstFrameMs" to (data?.getLongExtra(PlayerActivity.RESULT_FIRST_FRAME_MS, -1L)?.takeIf { it >= 0L }),
            "decoder" to data?.getStringExtra(PlayerActivity.RESULT_DECODER),
            "videoFormat" to data?.getStringExtra(PlayerActivity.RESULT_VIDEO_FORMAT),
            "diagnostics" to (data?.getStringArrayListExtra(PlayerActivity.RESULT_DIAGNOSTICS) ?: arrayListOf<String>()),
        )
        pendingPlaybackResult?.success(payload)
        pendingPlaybackResult = null
    }

    @Suppress("DEPRECATION")
    private fun readDiagnostics(): Map<String, Any> {
        val activityManager =
            getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)

        val abis = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Build.SUPPORTED_ABIS.toList()
        } else {
            listOf(Build.CPU_ABI, Build.CPU_ABI2).filter { it.isNotBlank() }
        }
        val packageInfo = packageManager.getPackageInfo(packageName, 0)

        return linkedMapOf(
            "app" to "${packageInfo.versionName} (${packageInfo.versionCode})",
            "android" to "${Build.VERSION.RELEASE} / API ${Build.VERSION.SDK_INT}",
            "abi" to abis.joinToString(", "),
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "memory class" to "${activityManager.memoryClass} MiB",
            "large memory class" to "${activityManager.largeMemoryClass} MiB",
            "available memory" to formatBytes(memoryInfo.availMem),
            "total memory" to formatBytes(memoryInfo.totalMem),
            "low memory" to memoryInfo.lowMemory,
            "clock" to java.util.Date().toString(),
            "renderer" to "Flutter hardware-accelerated surface",
            "player" to "ExoPlayer 2.19.1 / HLS",
            "network" to "HTTPS only",
        )
    }

    private fun formatBytes(bytes: Long): String {
        val mebibytes = bytes / (1024L * 1024L)
        return "$mebibytes MiB"
    }

    companion object {
        private const val PLAYER_REQUEST = 7401
    }
}
