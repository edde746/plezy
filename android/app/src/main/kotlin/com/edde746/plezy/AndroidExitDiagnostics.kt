package com.edde746.plezy

import android.content.Context
import java.security.MessageDigest
import java.util.concurrent.Executors

internal data class HistoricalExitRecord(
  val reason: Int,
  val status: Int,
  val importance: Int,
  val timestamp: Long,
  val description: String? = null,
  val pssKb: Long = 0,
  val rssKb: Long = 0
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
  val uiState: String? = null
)

internal object AndroidRuntimeDiagnostics {
  const val UI_STARTUP = "startup"
  const val UI_AUTHENTICATION = "authentication"
  const val UI_MAIN_SCREEN = "main_screen"
  const val UI_PLAYER = "player"
  const val UI_PLAYER_DISPOSED = "player_disposed"

  private const val PREFERENCES_NAME = "plezy_runtime_diagnostics"
  private const val KEY_UI_STATE = "ui_state"
  private val allowedUiStates = setOf(
    UI_STARTUP,
    UI_AUTHENTICATION,
    UI_MAIN_SCREEN,
    UI_PLAYER,
    UI_PLAYER_DISPOSED
  )
  private val executor by lazy {
    Executors.newSingleThreadExecutor { task ->
      Thread(task, "plezy-runtime-diagnostics").apply { isDaemon = true }
    }
  }

  fun sanitizeUiState(raw: String?): String? = raw?.takeIf(allowedUiStates::contains)

  fun sanitize(snapshot: RuntimeDiagnosticSnapshot): RuntimeDiagnosticSnapshot = RuntimeDiagnosticSnapshot(
    uiState = sanitizeUiState(snapshot.uiState)
  )

  fun update(context: Context, uiState: String) {
    val sanitized = sanitizeUiState(uiState) ?: return
    val applicationContext = context.applicationContext
    executor.execute {
      runCatching {
        applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE).edit()
          .putString(KEY_UI_STATE, sanitized)
          .commit()
      }
    }
  }

  fun read(context: Context): RuntimeDiagnosticSnapshot {
    val preferences = context.applicationContext.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    return sanitize(
      RuntimeDiagnosticSnapshot(
        uiState = runCatching { preferences.getString(KEY_UI_STATE, null) }.getOrNull()
      )
    )
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
  val description: String?,
  val pssKb: Long?,
  val rssKb: Long?,
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
    description?.let { put("description", it) }
    pssKb?.let { put("pssKb", it) }
    rssKb?.let { put("rssKb", it) }
    runtime.uiState?.let { put("uiState", it) }
  }
}

internal object AndroidExitReportMapper {
  private const val REASON_EXIT_SELF = 1
  private const val REASON_SIGNALED = 2
  private const val REASON_LOW_MEMORY = 3
  private const val REASON_CRASH = 4
  private const val REASON_CRASH_NATIVE = 5
  private const val REASON_ANR = 6
  private const val REASON_INITIALIZATION_FAILURE = 7
  private const val REASON_PERMISSION_CHANGE = 8
  private const val REASON_EXCESSIVE_RESOURCE_USAGE = 9
  private const val REASON_USER_REQUESTED = 10
  private const val REASON_USER_STOPPED = 11
  private const val REASON_DEPENDENCY_DIED = 12
  private const val REASON_FREEZER = 14
  private const val REASON_PACKAGE_STATE_CHANGE = 15
  private const val REASON_PACKAGE_UPDATED = 16
  private const val MAX_DEVICE_MODEL_LENGTH = 80
  private const val MAX_DESCRIPTION_LENGTH = 120
  private const val MAX_MEMORY_KB = 64L * 1024 * 1024
  private val supportedAbis = setOf("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
  private val dottedNamePattern = Regex("[A-Za-z][A-Za-z0-9_]*(?:\\.[A-Za-z0-9_]+)+")
  private val numberPattern = Regex("[0-9]+")
  private val disallowedDescriptionCharacters = Regex("[^A-Za-z0-9 _.:,()\\[\\]#<>/=-]+")
  private val whitespacePattern = Regex("\\s+")

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
      description = sanitizeDescription(record.description),
      pssKb = record.pssKb.takeIf { it in 1..MAX_MEMORY_KB },
      rssKb = record.rssKb.takeIf { it in 1..MAX_MEMORY_KB },
      dedupeKey = dedupeKey
    )
  }

  fun mapReason(reason: Int): String = when (reason) {
    REASON_EXIT_SELF -> "exit_self"
    REASON_SIGNALED -> "signaled"
    REASON_LOW_MEMORY -> "low_memory"
    REASON_CRASH -> "crash"
    REASON_CRASH_NATIVE -> "native_crash"
    REASON_ANR -> "anr"
    REASON_INITIALIZATION_FAILURE -> "initialization_failure"
    REASON_PERMISSION_CHANGE -> "permission_change"
    REASON_EXCESSIVE_RESOURCE_USAGE -> "excessive_resource_usage"
    REASON_USER_REQUESTED, REASON_USER_STOPPED -> "user_requested"
    REASON_DEPENDENCY_DIED -> "dependency_died"
    REASON_FREEZER -> "freezer"
    REASON_PACKAGE_STATE_CHANGE -> "package_state_change"
    REASON_PACKAGE_UPDATED -> "package_updated"
    else -> "other"
  }

  /**
   * The system's free-text exit description (`"[FORCE STOP] stop <pkg> due to
   * from pid #"`, `"excessive cpu # during # dur=# limit=#"`) names the kill path that
   * [mapReason]'s codes collapse. Dotted names - other apps' packages, a
   * server's host name - and every number are masked, and only a fixed ASCII
   * set survives, so the text can identify neither the device nor its owner.
   */
  fun sanitizeDescription(raw: String?): String? {
    if (raw == null) return null
    return raw
      .replace(dottedNamePattern, "<pkg>")
      .replace(numberPattern, "#")
      .replace(disallowedDescriptionCharacters, " ")
      .replace(whitespacePattern, " ")
      .trim()
      .take(MAX_DESCRIPTION_LENGTH)
      .trim()
      .ifEmpty { null }
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
