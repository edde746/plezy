package com.edde746.plezy

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal class ExternalPlayerChannel(private val activity: Activity) {
  companion object {
    private const val CHANNEL = "com.plezy/external_player"
    const val REQUEST_CODE = 7461

    private const val API_MX_RETURN_RESULT = "return_result"
    private const val API_MX_RESULT_ID = "com.mxtech.intent.result.VIEW"
    private const val API_MX_RESULT_POSITION = "position"
    private const val API_MX_RESULT_DURATION = "duration"
    private const val API_MX_RESULT_END_BY = "end_by"
    private const val API_MX_RESULT_END_BY_PLAYBACK_COMPLETION = "playback_completion"
    private const val API_MX_TITLE = "title"
    private const val API_MX_FILENAME = "filename"
    private const val API_MX_SECURE_URI = "secure_uri"
    private const val API_VLC_RESULT_POSITION = "extra_position"
    private const val API_VLC_RESULT_DURATION = "extra_duration"

    private const val API_VIMU_TITLE = "forcename"
    private const val API_VIMU_SEEK_POSITION = "startfrom"
    private const val API_VIMU_RESUME = "forceresume"
    private const val API_VIMU_RESULT_ID = "net.gtvbox.videoplayer.result"
    private const val API_VIMU_RESULT_ERROR = 4
    private const val API_VIMU_RESULT_PLAYBACK_COMPLETED = 1

    private val positionExtras = arrayOf(API_MX_RESULT_POSITION, API_VLC_RESULT_POSITION)
    private val durationExtras = arrayOf(API_MX_RESULT_DURATION, API_VLC_RESULT_DURATION)
  }

  private var pendingResult: MethodChannel.Result? = null

  fun attach(messenger: BinaryMessenger) {
    MethodChannel(messenger, CHANNEL).setMethodCallHandler(::onMethodCall)
  }

  fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != REQUEST_CODE) return false
    val result = pendingResult
    pendingResult = null
    if (result == null) {
      android.util.Log.w("ExternalPlayerChannel", "Result received without a pending channel call")
    } else {
      result.success(buildResult(resultCode, data))
    }
    return true
  }

  fun dispose() {
    pendingResult?.error("ACTIVITY_DESTROYED", "Activity was destroyed while external player was active", null)
    pendingResult = null
  }

  internal fun buildResult(resultCode: Int, data: Intent?): Map<String, Any?> {
    val extras = data?.extras
    val endPosition = firstNumberExtra(extras, positionExtras)
    val duration = firstNumberExtra(extras, durationExtras)
    val action = data?.action
    val playbackCompleted = when (action) {
      API_MX_RESULT_ID -> extras?.getString(API_MX_RESULT_END_BY) == API_MX_RESULT_END_BY_PLAYBACK_COMPLETION
      API_VIMU_RESULT_ID -> resultCode == API_VIMU_RESULT_PLAYBACK_COMPLETED
      else -> false
    }
    val playbackError = action == API_VIMU_RESULT_ID && resultCode == API_VIMU_RESULT_ERROR

    return mapOf(
      "launched" to true,
      "resultCode" to resultCode,
      "resultOk" to (resultCode == Activity.RESULT_OK),
      "action" to action,
      "positionMs" to endPosition,
      "durationMs" to duration,
      "playbackCompleted" to playbackCompleted,
      "playbackError" to playbackError
    )
  }

  private fun firstNumberExtra(extras: Bundle?, keys: Array<String>): Long? {
    if (extras == null) return null
    for (key in keys) {
      @Suppress("DEPRECATION")
      val value = extras.get(key)
      when (value) {
        is Number -> return value.toLong()
        is String -> value.toLongOrNull()?.let { return it }
      }
    }
    return null
  }

  @Suppress("UNCHECKED_CAST")
  private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method != "openVideo") {
      result.notImplemented()
      return
    }

    val filePath = call.argument<String>("filePath")
    val packageNames = call.argument<List<Any?>>("packages")
      ?.mapNotNull { (it as? String)?.trim()?.takeIf(String::isNotEmpty) }
      ?: emptyList()
    val title = call.argument<String>("title")?.trim()?.takeIf(String::isNotEmpty)
    val startPositionMs = call.argument<Number>("startPositionMs")?.toLong() ?: 0L

    if (filePath == null) {
      result.error("INVALID_ARGUMENT", "filePath is required", null)
      return
    }
    if (pendingResult != null) {
      result.error("ALREADY_ACTIVE", "An external player is already active", null)
      return
    }

    try {
      val source = resolveSource(filePath)
      val targetPackages = if (packageNames.isEmpty()) listOf<String?>(null) else packageNames
      for (packageName in targetPackages) {
        try {
          pendingResult = result
          activity.startActivityForResult(
            buildIntent(source, packageName, startPositionMs, title),
            REQUEST_CODE
          )
          return
        } catch (_: ActivityNotFoundException) {
          pendingResult = null
        }
      }

      val message = if (packageNames.isEmpty()) {
        "No app found for video"
      } else {
        "No app found for packages: ${packageNames.joinToString(", ")}"
      }
      result.error("APP_NOT_FOUND", message, null)
    } catch (error: Exception) {
      pendingResult = null
      result.error("LAUNCH_FAILED", error.message ?: error.javaClass.simpleName, null)
    }
  }

  private data class Source(val uri: Uri, val grantRead: Boolean, val fileName: String?)

  private fun resolveSource(filePath: String): Source {
    if (filePath.startsWith("http://") || filePath.startsWith("https://")) {
      val uri = Uri.parse(filePath)
      return Source(uri, grantRead = false, fileName = uri.lastPathSegment)
    }
    if (filePath.startsWith("content://")) {
      val uri = Uri.parse(filePath)
      return Source(uri, grantRead = true, fileName = uri.lastPathSegment)
    }

    val path = if (filePath.startsWith("file://")) filePath.removePrefix("file://") else filePath
    val file = File(path)
    val uri = FileProvider.getUriForFile(activity, "com.edde746.plezy.fileprovider", file)
    return Source(uri, grantRead = true, fileName = file.name)
  }

  private fun buildIntent(
    source: Source,
    packageName: String?,
    startPositionMs: Long,
    title: String?
  ): Intent = Intent(Intent.ACTION_VIEW).apply {
    setDataAndType(source.uri, "video/*")
    if (source.grantRead) addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    packageName?.let(::setPackage)
    val startPosition = startPositionMs.coerceAtLeast(0).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    if (startPosition > 0) {
      putExtra(API_MX_RESULT_POSITION, startPosition)
      putExtra(API_VIMU_SEEK_POSITION, startPosition)
    }
    putExtra(API_MX_RETURN_RESULT, true)
    putExtra(API_MX_SECURE_URI, true)
    putExtra(API_VIMU_RESUME, false)
    title?.let {
      putExtra(API_MX_TITLE, it)
      putExtra(API_VIMU_TITLE, it)
    }
    source.fileName?.let { putExtra(API_MX_FILENAME, it) }
  }
}
