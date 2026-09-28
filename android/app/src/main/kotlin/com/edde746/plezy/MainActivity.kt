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
                    val intent = Intent(this, PlayerActivity::class.java).apply {
                        putExtra(PlayerActivity.EXTRA_URL, url)
                        putExtra(PlayerActivity.EXTRA_TITLE, arguments["title"] as? String ?: "Plezy")
                        putExtra(PlayerActivity.EXTRA_START_MS, (arguments["startMs"] as? Number)?.toLong() ?: 0L)
                        putExtra(PlayerActivity.EXTRA_RATING_KEY, arguments["ratingKey"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_DURATION_MS, (arguments["durationMs"] as? Number)?.toLong() ?: 0L)
                        putExtra(PlayerActivity.EXTRA_TIMELINE_URL, arguments["timelineUrl"] as? String ?: "")
                        putExtra(PlayerActivity.EXTRA_HEADERS_KEYS, headers.keys.toTypedArray())
                        putExtra(PlayerActivity.EXTRA_HEADERS_VALUES, headers.values.toTypedArray())
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
