package com.edde746.plezy

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Parcelable
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

    // Honored by VLC and the native Zidoo player (com.android.gallery3d /
    // com.zidoo.player). Without it, a launch with no resume point lets the
    // player consult its own bookmark store, which on Zidoo collides across
    // Plex items because every part URL ends in the same `file.<ext>` (#2223).
    private const val API_VLC_FROM_START = "from_start"

    private const val API_VIMU_TITLE = "forcename"
    private const val API_VIMU_SEEK_POSITION = "startfrom"
    private const val API_VIMU_RESUME = "forceresume"
    private const val API_VIMU_RESULT_ID = "net.gtvbox.videoplayer.result"
    private const val API_VIMU_RESULT_ERROR = 4
    private const val API_VIMU_RESULT_PLAYBACK_COMPLETED = 1

    // MX Player's subtitle API; mpv-android reads `subs` and `subs.enable`,
    // Just Player `subs`, `subs.name` and `subs.enable`. VLC only takes
    // `subtitles_location`, which it opens as a local file path, so remote
    // sidecars cannot reach it that way.
    private const val API_SUBS = "subs"
    private const val API_SUBS_NAME = "subs.name"
    private const val API_SUBS_FILENAME = "subs.filename"
    private const val API_SUBS_ENABLE = "subs.enable"

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
    val subtitleArguments = call.argument<List<Any?>>("subtitles") ?: emptyList()

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
      val subtitles = subtitleArguments.mapNotNull(::resolveSubtitle)
      val targetPackages = if (packageNames.isEmpty()) listOf<String?>(null) else packageNames
      for (packageName in targetPackages) {
        try {
          pendingResult = result
          activity.startActivityForResult(
            buildIntent(source, packageName, startPositionMs, title, subtitles),
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

  internal data class Source(val uri: Uri, val grantRead: Boolean, val fileName: String?)

  internal data class Subtitle(val source: Source, val name: String?, val enabled: Boolean)

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

  private fun resolveSubtitle(argument: Any?): Subtitle? {
    val map = argument as? Map<*, *> ?: return null
    val location = (map["uri"] as? String)?.takeIf(String::isNotEmpty) ?: return null
    val source = try {
      resolveSource(location)
    } catch (error: IllegalArgumentException) {
      // FileProvider refuses a path outside its roots. Losing one subtitle
      // must not cost the whole launch.
      android.util.Log.w("ExternalPlayerChannel", "Skipping a subtitle FileProvider cannot share", error)
      return null
    }
    val name = (map["name"] as? String)?.trim()?.takeIf(String::isNotEmpty)
    return Subtitle(source, name, enabled = map["enabled"] == true)
  }

  internal fun buildIntent(
    source: Source,
    packageName: String?,
    startPositionMs: Long,
    title: String?,
    subtitles: List<Subtitle> = emptyList()
  ): Intent = Intent(Intent.ACTION_VIEW).apply {
    setDataAndType(source.uri, "video/*")
    if (source.grantRead) addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    packageName?.let(::setPackage)
    val startPosition = startPositionMs.coerceAtLeast(0).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    if (startPosition > 0) {
      putExtra(API_MX_RESULT_POSITION, startPosition)
      putExtra(API_VIMU_SEEK_POSITION, startPosition)
      putExtra(API_VLC_FROM_START, false)
    } else {
      putExtra(API_VLC_FROM_START, true)
    }
    putExtra(API_MX_RETURN_RESULT, true)
    putExtra(API_MX_SECURE_URI, true)
    putExtra(API_VIMU_RESUME, false)
    title?.let {
      putExtra(API_MX_TITLE, it)
      putExtra(API_VIMU_TITLE, it)
    }
    source.fileName?.let { putExtra(API_MX_FILENAME, it) }
    if (subtitles.isNotEmpty()) {
      putExtra(API_SUBS, Array<Parcelable>(subtitles.size) { subtitles[it].source.uri })
      putExtra(API_SUBS_NAME, Array(subtitles.size) { subtitles[it].name ?: subtitles[it].source.fileName.orEmpty() })
      putExtra(API_SUBS_FILENAME, Array(subtitles.size) { subtitles[it].source.fileName.orEmpty() })
      putExtra(API_SUBS_ENABLE, subtitles.filter { it.enabled }.map<Subtitle, Parcelable> { it.source.uri }.toTypedArray())
      // FLAG_GRANT_READ_URI_PERMISSION reaches the data URI and ClipData,
      // never extras: a downloaded sidecar's content:// URI has to ride in
      // ClipData too, or the player is refused when it opens the file.
      val shared = subtitles.filter { it.source.grantRead }.map { it.source.uri }
      if (shared.isNotEmpty()) {
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        clipData = ClipData.newRawUri(null, shared.first()).apply {
          shared.drop(1).forEach { addItem(ClipData.Item(it)) }
        }
      }
    }
  }
}
