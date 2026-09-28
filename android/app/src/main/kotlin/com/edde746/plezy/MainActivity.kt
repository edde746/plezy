package com.edde746.plezy

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.jialim.plezygkui/diagnostics",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getDiagnostics") {
                result.success(readDiagnostics())
            } else {
                result.notImplemented()
            }
        }
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
            "player" to "disabled (M0)",
            "network" to "disabled (M0)",
        )
    }

    private fun formatBytes(bytes: Long): String {
        val mebibytes = bytes / (1024L * 1024L)
        return "$mebibytes MiB"
    }
}
