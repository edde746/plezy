package com.edde746.plezy

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * `com.plezy/app_update`: in-app updates for the GitHub build (lib/services/android_self_update.dart).
 * Dart downloads and extracts the release APK; this side reports the ABIs, checks the APK is an
 * update Android will accept, and hands it to the system package installer, which asks the user
 * to confirm.
 *
 * Only builds that declare `REQUEST_INSTALL_PACKAGES` (the GitHub release build, see
 * android/app/build.gradle.kts) report [isSupported]; the Play Store and Amazon builds do not.
 */
internal class AppUpdateChannel(private val activity: Activity) {
  companion object {
    private const val TAG = "AppUpdateChannel"
    private const val CHANNEL = "com.plezy/app_update"
    private const val FILE_PROVIDER_AUTHORITY = "com.edde746.plezy.fileprovider"
    private const val APK_MIME_TYPE = "application/vnd.android.package-archive"
  }

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler(::onMethodCall)
  }

  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "isSupported" -> result.success(declaresInstallPermission())
        "getAbis" -> result.success(abis())
        "canRequestInstall" -> result.success(canRequestInstall())
        "openInstallPermissionSettings" -> result.success(openInstallPermissionSettings())
        "inspectApk" -> withApk(call, result) { result.success(inspectApk(it)) }
        "install" -> withApk(call, result) { install(it, result) }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      Log.w(TAG, "${call.method} failed", e)
      result.error("failed", e.message, null)
    }
  }

  private inline fun withApk(call: MethodCall, result: MethodChannel.Result, block: (File) -> Unit) {
    val path = call.argument<String>("path")
    val file = path?.let(::File)
    if (file == null || !file.isFile) {
      result.error("missing_apk", "No APK at $path", null)
      return
    }
    block(file)
  }

  @Suppress("DEPRECATION")
  private fun declaresInstallPermission(): Boolean {
    val info = activity.packageManager.getPackageInfo(activity.packageName, PackageManager.GET_PERMISSIONS)
    return info.requestedPermissions?.contains(Manifest.permission.REQUEST_INSTALL_PACKAGES) == true
  }

  /**
   * The ABI this process runs as and the device's ABIs. A TV with a 64-bit SoC and a 32-bit
   * userland lists only 32-bit ABIs; a 32-bit APK on a 64-bit device runs as the 32-bit ABI, and
   * the update keeps it.
   */
  private fun abis(): Map<String, Any?> {
    val running = if (Process.is64Bit()) Build.SUPPORTED_64_BIT_ABIS.firstOrNull() else Build.SUPPORTED_32_BIT_ABIS.firstOrNull()
    return mapOf("running" to running, "supported" to Build.SUPPORTED_ABIS.toList())
  }

  @Suppress("DEPRECATION")
  private fun canRequestInstall(): Boolean = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
    activity.packageManager.canRequestPackageInstalls()
  } else {
    // Android 7.1 has one device-wide "Unknown sources" switch instead of a per-app permission.
    Settings.Secure.getInt(activity.contentResolver, Settings.Secure.INSTALL_NON_MARKET_APPS, 0) == 1
  }

  /**
   * Opens the "Install unknown apps" page for Plezy, or the security settings on Android 7.1.
   * Some TV builds have no per-app page, so fall back to the device-wide one before giving up.
   */
  private fun openInstallPermissionSettings(): Boolean {
    val intents = buildList {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        add(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")))
        add(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES))
      }
      add(Intent(Settings.ACTION_SECURITY_SETTINGS))
    }
    for (intent in intents) {
      try {
        activity.startActivity(intent)
        return true
      } catch (_: ActivityNotFoundException) {
      } catch (e: SecurityException) {
        Log.w(TAG, "Settings page ${intent.action} refused", e)
      }
    }
    return false
  }

  /**
   * Whether [apk] is this app, signed by the installed copy's key. Android refuses any other APK
   * as an update with a bare "App not installed", after the user has confirmed.
   */
  private fun inspectApk(apk: File): Map<String, Any?> {
    val archive = archiveInfo(apk) ?: throw IllegalArgumentException("Not a readable APK")
    val installed = packageInfoWithSigners(activity.packageName)
    val archiveSigners = signerDigests(archive)
    val installedSigners = signerDigests(installed)
    return mapOf(
      "packageName" to archive.packageName,
      "versionName" to archive.versionName,
      "samePackage" to (archive.packageName == activity.packageName),
      // A pre-check for a clear message only: the package manager enforces the real rule.
      "sameSigner" to archiveSigners.any(installedSigners::contains)
    )
  }

  @Suppress("DEPRECATION")
  private fun archiveInfo(apk: File): PackageInfo? {
    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      PackageManager.GET_SIGNING_CERTIFICATES
    } else {
      PackageManager.GET_SIGNATURES
    }
    val info = activity.packageManager.getPackageArchiveInfo(apk.path, flags) ?: return null
    // Before API 28 the archive's signatures are only read once the source path is set.
    info.applicationInfo?.let {
      it.sourceDir = apk.path
      it.publicSourceDir = apk.path
    }
    return info
  }

  @Suppress("DEPRECATION")
  private fun packageInfoWithSigners(packageName: String): PackageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
    activity.packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
  } else {
    activity.packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
  }

  /**
   * SHA-256 of each signing certificate: all signers of a multi-signer APK, or the whole lineage
   * of a single signer, so an update signed after a key rotation still matches.
   */
  @Suppress("DEPRECATION")
  private fun signerDigests(info: PackageInfo): Set<String> {
    val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      val signing = info.signingInfo ?: return emptySet()
      if (signing.hasMultipleSigners()) signing.apkContentsSigners else signing.signingCertificateHistory
    } else {
      info.signatures
    } ?: return emptySet()
    val sha256 = MessageDigest.getInstance("SHA-256")
    return signatures.map { signature -> sha256.digest(signature.toByteArray()).joinToString("") { "%02x".format(it) } }.toSet()
  }

  private fun install(apk: File, result: MethodChannel.Result) {
    val uri = FileProvider.getUriForFile(activity, FILE_PROVIDER_AUTHORITY, apk)

    @Suppress("DEPRECATION")
    val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
      setDataAndType(uri, APK_MIME_TYPE)
      addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    val fallback = Intent(Intent.ACTION_VIEW).apply {
      setDataAndType(uri, APK_MIME_TYPE)
      addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    for (candidate in listOf(intent, fallback)) {
      try {
        activity.startActivity(candidate)
        result.success(null)
        return
      } catch (_: ActivityNotFoundException) {
      }
    }
    result.error("no_installer", "No activity handles $APK_MIME_TYPE", null)
  }
}
