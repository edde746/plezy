package com.edde746.plezy

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal class AppUpdateChannel(private val activity: Activity) {
  companion object {
    private const val PERMISSION_REQUEST = 7462
  }

  private var pendingPermission: MethodChannel.Result? = null
  private var channel: MethodChannel? = null
  private val updateDirectory get() = File(activity.cacheDir, "app-updates")

  fun attach(messenger: BinaryMessenger) {
    channel = MethodChannel(messenger, "com.plezy/app_update").also {
      it.setMethodCallHandler(::onMethodCall)
    }
  }

  internal fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "getSupportedAbis" -> result.success(
          Build.SUPPORTED_ABIS.filter { it.contains("64") == Process.is64Bit() }
        )
        "requestInstallPermission" -> requestPermission(result)
        "prepareUpdateDirectory" -> {
          check(updateDirectory.isDirectory || updateDirectory.mkdirs()) { "Cannot create update cache" }
          listOf("update.apk", "update.tar.gz", "update.tar.gz.part").forEach { name ->
            val file = File(updateDirectory, name)
            check(!file.exists() || file.delete()) { "Cannot clear previous update" }
          }
          result.success(updateDirectory.absolutePath)
        }
        "installUpdate" -> install(call.argument<String>("path"), result)
        else -> result.notImplemented()
      }
    } catch (error: Exception) {
      result.error("UPDATE_FAILED", error.message, null)
    }
  }

  private fun canInstall(): Boolean =
    Build.VERSION.SDK_INT < Build.VERSION_CODES.O || activity.packageManager.canRequestPackageInstalls()

  private fun requestPermission(result: MethodChannel.Result) {
    if (canInstall()) {
      result.success(true)
      return
    }
    if (pendingPermission != null) {
      result.error("UPDATE_BUSY", "An installation permission request is already active", null)
      return
    }
    pendingPermission = result
    activity.startActivityForResult(
      Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")),
      PERMISSION_REQUEST,
    )
  }

  fun onActivityResult(requestCode: Int): Boolean {
    if (requestCode != PERMISSION_REQUEST) return false
    val result = pendingPermission
    pendingPermission = null
    result?.success(canInstall())
    return true
  }

  @Suppress("DEPRECATION")
  private fun install(path: String?, result: MethodChannel.Result) {
    val apk = File(updateDirectory, "update.apk").canonicalFile
    require(path != null && File(path).canonicalFile == apk && apk.isFile) { "Invalid update path" }
    if (!canInstall()) {
      result.error("INSTALL_PERMISSION_DENIED", "Allow installs from Plezy in Android settings", null)
      return
    }

    val pm = activity.packageManager
    val candidate = pm.getPackageArchiveInfo(apk.path, PackageManager.GET_SIGNATURES)
    val installed = pm.getPackageInfo(activity.packageName, PackageManager.GET_SIGNATURES)
    if (candidate == null || candidate.packageName != activity.packageName) {
      result.error("INVALID_APK", "The APK is not an update for this application", null)
      return
    }
    val newCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) candidate.longVersionCode else candidate.versionCode.toLong()
    val oldCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) installed.longVersionCode else installed.versionCode.toLong()
    if (newCode <= oldCode) {
      result.error("VERSION_NOT_NEWER", "The APK version code must be higher than the installed version", null)
      return
    }
    if (installed.signatures?.toSet().isNullOrEmpty() || installed.signatures?.toSet() != candidate.signatures?.toSet()) {
      result.error("SIGNATURE_MISMATCH", "The APK must use the same signing key as this installation", null)
      return
    }

    val uri = FileProvider.getUriForFile(activity, "com.edde746.plezy.fileprovider", apk)
    activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
      setDataAndType(uri, "application/vnd.android.package-archive")
      clipData = ClipData.newRawUri("Plezy update", uri)
      addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    })
    result.success(null)
  }

  fun dispose() {
    channel?.setMethodCallHandler(null)
    channel = null
    pendingPermission?.error("ACTIVITY_DESTROYED", "Activity closed during installation permission request", null)
    pendingPermission = null
  }
}
