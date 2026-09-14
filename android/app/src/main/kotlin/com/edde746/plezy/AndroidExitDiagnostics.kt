package com.edde746.plezy

import android.content.Context
import android.content.SharedPreferences
import java.security.MessageDigest
import java.util.concurrent.Executors

internal data class HistoricalExitRecord(
  val reason: Int,
  val status: Int,
  val importance: Int,
  val timestamp: Long
)

internal object AndroidStartupPhases {
  const val NATIVE_ON_CREATE = "native_on_create"
  private val allowed = setOf(
    NATIVE_ON_CREATE,
    "dart_main",
    "runApp",
    "first_frame",
    "database_open_started",
    "database_ready",
    "credentials_loaded",
    "binding_started",
    "binding_settled",
    "main_screen"
  )

  fun sanitize(raw: String?): String? = raw?.takeIf(allowed::contains)
}

internal class StartupPhaseStore(
  readPhase: () -> String?,
  private val persistPhase: (String) -> Boolean
) {
  val previousPhase: String? = AndroidStartupPhases.sanitize(readPhase())

  @Synchronized
  fun mark(raw: String?): Boolean {
    val phase = AndroidStartupPhases.sanitize(raw) ?: return false
    return persistPhase(phase)
  }
}

internal data class RuntimeDiagnosticSnapshot(
  val codecContext: String? = null,
  val channelCount: Int? = null,
  val sampleRate: Int? = null,
  val selectedDecoder: String? = null,
  val passthroughEnabled: Boolean? = null,
  val downmixEnabled: Boolean? = null,
  val normalizationEnabled: Boolean? = null,
  val uiState: String? = null
)

internal object AndroidRuntimeDiagnostics {
  const val UI_STARTUP = "startup"
  const val UI_AUTHENTICATION = "authentication"
  const val UI_MAIN_SCREEN = "main_screen"
  const val UI_PLAYER = "player"
  const val UI_PLAYER_DISPOSED = "player_disposed"

  private const val PREFERENCES_NAME = "plezy_runtime_diagnostics"
  private const val KEY_CODEC_CONTEXT = "codec_context"
  private const val KEY_CHANNEL_COUNT = "channel_count"
  private const val KEY_SAMPLE_RATE = "sample_rate"
  private const val KEY_SELECTED_DECODER = "selected_decoder"
  private const val KEY_PASSTHROUGH_ENABLED = "passthrough_enabled"
  private const val KEY_DOWNMIX_ENABLED = "downmix_enabled"
  private const val KEY_NORMALIZATION_ENABLED = "normalization_enabled"
  private const val KEY_UI_STATE = "ui_state"
  private val allowedCodecContexts = setOf(
    "audio:aac",
    "audio:ac3",
    "audio:eac3",
    "audio:dts",
    "audio:truehd",
    "audio:flac",
    "audio:pcm",
    "audio:other",
    "video:dolby_vision",
    "video:hevc",
    "video:avc",
    "video:other"
  )
  private val allowedUiStates = setOf(
    UI_STARTUP,
    UI_AUTHENTICATION,
    UI_MAIN_SCREEN,
    UI_PLAYER,
    UI_PLAYER_DISPOSED
  )
  private val decoderNamePattern = Regex("[A-Za-z0-9_.:-]{1,96}")
  private val executor by lazy {
    Executors.newSingleThreadExecutor { task ->
      Thread(task, "plezy-runtime-diagnostics").apply { isDaemon = true }
    }
  }

  fun codecContextForMime(mimeType: String?): String? {
    val normalized = mimeType?.lowercase() ?: return null
    return when (normalized) {
      "audio/mp4a-latm" -> "audio:aac"
      "audio/ac3" -> "audio:ac3"
      "audio/eac3", "audio/eac3-joc" -> "audio:eac3"
      "audio/vnd.dts", "audio/vnd.dts.hd" -> "audio:dts"
      "audio/true-hd" -> "audio:truehd"
      "audio/flac" -> "audio:flac"
      "audio/raw" -> "audio:pcm"
      "video/dolby-vision" -> "video:dolby_vision"
      "video/hevc" -> "video:hevc"
      "video/avc" -> "video:avc"
      else -> when {
        normalized.startsWith("audio/") -> "audio:other"
        normalized.startsWith("video/") -> "video:other"
        else -> null
      }
    }
  }

  fun sanitizeDecoderName(raw: String?): String? {
    if (raw == null) return null
    return raw.takeIf(decoderNamePattern::matches) ?: "unknown"
  }

  fun sanitizeUiState(raw: String?): String? = raw?.takeIf(allowedUiStates::contains)
  fun sanitize(snapshot: RuntimeDiagnosticSnapshot): RuntimeDiagnosticSnapshot = RuntimeDiagnosticSnapshot(
    codecContext = snapshot.codecContext?.takeIf(allowedCodecContexts::contains),
    channelCount = snapshot.channelCount?.takeIf { it in 1..32 },
    sampleRate = snapshot.sampleRate?.takeIf { it in 1..768_000 },
    selectedDecoder = sanitizeDecoderName(snapshot.selectedDecoder),
    passthroughEnabled = snapshot.passthroughEnabled,
    downmixEnabled = snapshot.downmixEnabled,
    normalizationEnabled = snapshot.normalizationEnabled,
    uiState = sanitizeUiState(snapshot.uiState)
  )

  fun update(
    context: Context,
    codecContext: String? = null,
    channelCount: Int? = null,
    sampleRate: Int? = null,
    selectedDecoder: String? = null,
    passthroughEnabled: Boolean? = null,
    downmixEnabled: Boolean? = null,
    normalizationEnabled: Boolean? = null,
    uiState: String? = null
  ) {
    val safeCodecContext = codecContext?.takeIf(allowedCodecContexts::contains)
    val safeChannelCount = channelCount?.takeIf { it in 1..32 }
    val safeSampleRate = sampleRate?.takeIf { it in 1..768_000 }
    val safeDecoder = sanitizeDecoderName(selectedDecoder)
    val safeUiState = sanitizeUiState(uiState)
    val applicationContext = context.applicationContext
    executor.execute {
      runCatching {
        applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE).edit().apply {
          safeCodecContext?.let { putString(KEY_CODEC_CONTEXT, it) }
          safeChannelCount?.let { putInt(KEY_CHANNEL_COUNT, it) }
          safeSampleRate?.let { putInt(KEY_SAMPLE_RATE, it) }
          safeDecoder?.let { putString(KEY_SELECTED_DECODER, it) }
          passthroughEnabled?.let { putBoolean(KEY_PASSTHROUGH_ENABLED, it) }
          downmixEnabled?.let { putBoolean(KEY_DOWNMIX_ENABLED, it) }
          normalizationEnabled?.let { putBoolean(KEY_NORMALIZATION_ENABLED, it) }
          safeUiState?.let { putString(KEY_UI_STATE, it) }
        }.commit()
      }
    }
  }

  fun clearPlayback(context: Context) {
    val applicationContext = context.applicationContext
    executor.execute {
      runCatching {
        applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE).edit()
          .remove(KEY_CODEC_CONTEXT)
          .remove(KEY_CHANNEL_COUNT)
          .remove(KEY_SAMPLE_RATE)
          .remove(KEY_SELECTED_DECODER)
          .remove(KEY_PASSTHROUGH_ENABLED)
          .remove(KEY_DOWNMIX_ENABLED)
          .remove(KEY_NORMALIZATION_ENABLED)
          .putString(KEY_UI_STATE, UI_PLAYER_DISPOSED)
          .commit()
      }
    }
  }

  fun read(context: Context): RuntimeDiagnosticSnapshot {
    val preferences = context.applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    return RuntimeDiagnosticSnapshot(
      codecContext = runCatching { preferences.getString(KEY_CODEC_CONTEXT, null) }
        .getOrNull()
        ?.takeIf(allowedCodecContexts::contains),
      channelCount = runCatching { preferences.getInt(KEY_CHANNEL_COUNT, -1) }.getOrNull()?.takeIf { it in 1..32 },
      sampleRate = runCatching { preferences.getInt(KEY_SAMPLE_RATE, -1) }.getOrNull()?.takeIf { it in 1..768_000 },
      selectedDecoder = sanitizeDecoderName(runCatching { preferences.getString(KEY_SELECTED_DECODER, null) }.getOrNull()),
      passthroughEnabled = readBoolean(preferences, KEY_PASSTHROUGH_ENABLED),
      downmixEnabled = readBoolean(preferences, KEY_DOWNMIX_ENABLED),
      normalizationEnabled = readBoolean(preferences, KEY_NORMALIZATION_ENABLED),
      uiState = sanitizeUiState(runCatching { preferences.getString(KEY_UI_STATE, null) }.getOrNull())
    )
  }

  private fun readBoolean(preferences: SharedPreferences, key: String): Boolean? {
    if (!preferences.contains(key)) return null
    return runCatching { preferences.getBoolean(key, false) }.getOrNull()
  }
}

internal data class PreviousExitReport(
  val reason: String,
  val status: Int,
  val importance: Int,
  val timestamp: Long,
  val deviceModel: String,
  val apiLevel: Int,
  val abi: String,
  val lowRam: Boolean,
  val startupPhase: String?,
  val runtime: RuntimeDiagnosticSnapshot,
  val dedupeKey: String
) {
  fun toMap(): Map<String, Any> = buildMap {
    put("reason", reason)
    put("status", status)
    put("importance", importance)
    put("timestamp", timestamp)
    put("deviceModel", deviceModel)
    put("apiLevel", apiLevel)
    put("abi", abi)
    put("lowRam", lowRam)
    startupPhase?.let { put("startupPhase", it) }
    runtime.codecContext?.let { put("codecContext", it) }
    runtime.channelCount?.let { put("channelCount", it) }
    runtime.sampleRate?.let { put("sampleRate", it) }
    runtime.selectedDecoder?.let { put("selectedDecoder", it) }
    runtime.passthroughEnabled?.let { put("passthroughEnabled", it) }
    runtime.downmixEnabled?.let { put("downmixEnabled", it) }
    runtime.normalizationEnabled?.let { put("normalizationEnabled", it) }
    runtime.uiState?.let { put("uiState", it) }
  }
}

internal object AndroidExitReportMapper {
  private const val REASON_LOW_MEMORY = 3
  private const val REASON_CRASH = 4
  private const val REASON_CRASH_NATIVE = 5
  private const val REASON_ANR = 6
  private const val REASON_USER_REQUESTED = 10
  private const val REASON_USER_STOPPED = 11
  private const val MAX_DEVICE_MODEL_LENGTH = 80
  private val supportedAbis = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")

  fun map(
    record: HistoricalExitRecord,
    deviceModel: String,
    apiLevel: Int,
    abi: String,
    lowRam: Boolean,
    startupPhase: String? = null,
    runtime: RuntimeDiagnosticSnapshot = RuntimeDiagnosticSnapshot()
  ): PreviousExitReport {
    val dedupeKey = sha256(
      listOf(
        record.timestamp.toString(),
        record.reason.toString(),
        record.status.toString(),
        record.importance.toString()
      )
    )
    return PreviousExitReport(
      reason = mapReason(record.reason),
      status = record.status,
      importance = record.importance,
      timestamp = record.timestamp,
      deviceModel = sanitizeDeviceModel(deviceModel),
      apiLevel = apiLevel,
      abi = abi.takeIf(supportedAbis::contains) ?: "unknown",
      lowRam = lowRam,
      startupPhase = AndroidStartupPhases.sanitize(startupPhase),
      runtime = AndroidRuntimeDiagnostics.sanitize(runtime),
      dedupeKey = dedupeKey
    )
  }

  fun mapReason(reason: Int): String = when (reason) {
    REASON_CRASH -> "crash"
    REASON_CRASH_NATIVE -> "native_crash"
    REASON_ANR -> "anr"
    REASON_LOW_MEMORY -> "low_memory"
    REASON_USER_REQUESTED, REASON_USER_STOPPED -> "user_requested"
    else -> "other"
  }

  fun sanitizeDeviceModel(raw: String): String {
    val sanitized = buildString(raw.length.coerceAtMost(MAX_DEVICE_MODEL_LENGTH)) {
      var pendingSpace = false
      raw.forEach { character ->
        if (length >= MAX_DEVICE_MODEL_LENGTH) return@forEach
        if (character.isWhitespace() || Character.isISOControl(character)) {
          pendingSpace = isNotEmpty()
        } else {
          if (pendingSpace && length < MAX_DEVICE_MODEL_LENGTH) append(' ')
          if (length < MAX_DEVICE_MODEL_LENGTH) append(character)
          pendingSpace = false
        }
      }
    }.trim()
    return sanitized.ifEmpty { "unknown" }
  }

  private fun sha256(fields: List<String>): String {
    val digest = MessageDigest.getInstance("SHA-256")
    fields.forEach { field ->
      digest.update(field.length.toString().toByteArray(Charsets.UTF_8))
      digest.update(':'.code.toByte())
      digest.update(field.toByteArray(Charsets.UTF_8))
      digest.update(';'.code.toByte())
    }
    return digest.digest().joinToString("") { byte ->
      (byte.toInt() and 0xff).toString(16).padStart(2, '0')
    }
  }
}

internal class PreviousExitReportStore(
  private val readDedupeKey: () -> String?,
  private val persistDedupeKey: (String) -> Boolean
) {
  @Synchronized
  fun takeIfNew(report: PreviousExitReport): Map<String, Any>? {
    if (readDedupeKey() == report.dedupeKey) return null
    if (!persistDedupeKey(report.dedupeKey)) return null
    return report.toMap()
  }
}
