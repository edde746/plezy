package com.edde746.plezy

import android.app.ActivityManager
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/**
 * Raw per-signal snapshot of everything the OS is willing to tell us about
 * whether our own background work will be allowed to run.
 *
 * Every field is nullable: a null means "this API level cannot answer", not
 * "unrestricted". [BackgroundWorkClassifier] treats unknown as OK, because a
 * warning we cannot substantiate is worse than no warning at all.
 */
internal data class BackgroundWorkSignals(
  val sdkInt: Int? = null,
  val backgroundRestricted: Boolean? = null,
  val standbyBucket: Int? = null,
  val notificationsEnabled: Boolean? = null,
  val downloadChannelBlocked: Boolean? = null,
  val dataSaverRestricted: Boolean? = null,
  val ignoringBatteryOptimizations: Boolean? = null
)

/**
 * Turns [BackgroundWorkSignals] into a verdict plus ordered reasons.
 *
 * Deliberately pure and free of `Build.VERSION` reads so the whole decision
 * table is exercisable from plain JVM unit tests.
 */
internal object BackgroundWorkClassifier {
  const val VERDICT_OK = "ok"
  const val VERDICT_DEGRADED = "degraded"
  const val VERDICT_BLOCKED = "blocked"

  const val REASON_BACKGROUND_RESTRICTED = "background_restricted"
  const val REASON_STANDBY_RESTRICTED = "standby_restricted"
  const val REASON_DOWNLOAD_CHANNEL_BLOCKED = "download_channel_blocked"
  const val REASON_NOTIFICATIONS_DISABLED = "notifications_disabled"
  const val REASON_DATA_SAVER = "data_saver"

  /**
   * `STANDBY_BUCKET_RESTRICTED` (API 30) and `STANDBY_BUCKET_NEVER`. Declared
   * literally so the classifier stays compilable and testable below those API
   * levels. `RARE` (40) is intentionally absent — it is reached by ordinary
   * disuse and says nothing about a user-imposed restriction, so warning on it
   * would fire on healthy devices.
   */
  const val BUCKET_RESTRICTED = 45
  const val BUCKET_NEVER = 50

  private val blockingReasons = setOf(
    REASON_BACKGROUND_RESTRICTED,
    REASON_STANDBY_RESTRICTED
  )

  /** Ordered most- to least-actionable; the UI leads with the first entry. */
  fun reasons(signals: BackgroundWorkSignals): List<String> = buildList {
    if (signals.backgroundRestricted == true) add(REASON_BACKGROUND_RESTRICTED)
    if (signals.standbyBucket != null && isRestrictedBucket(signals.standbyBucket)) add(REASON_STANDBY_RESTRICTED)
    // App-wide denial is more fundamental than a muted channel and routes to
    // a screen that also exists before the channel has been created.
    if (signals.notificationsEnabled == false) {
      add(REASON_NOTIFICATIONS_DISABLED)
    } else if (signals.downloadChannelBlocked == true) {
      add(REASON_DOWNLOAD_CHANNEL_BLOCKED)
    }
    if (signals.dataSaverRestricted == true) add(REASON_DATA_SAVER)
  }

  fun verdict(signals: BackgroundWorkSignals, reasons: List<String> = reasons(signals)): String = when {
    reasons.any(blockingReasons::contains) -> VERDICT_BLOCKED
    signals.sdkInt != null &&
      signals.sdkInt >= Build.VERSION_CODES.TIRAMISU &&
      signals.notificationsEnabled == false -> VERDICT_BLOCKED
    reasons.isNotEmpty() -> VERDICT_DEGRADED
    else -> VERDICT_OK
  }

  fun isRestrictedBucket(bucket: Int): Boolean = bucket == BUCKET_RESTRICTED || bucket == BUCKET_NEVER

  fun toMap(signals: BackgroundWorkSignals): Map<String, Any?> {
    val reasons = reasons(signals)
    return mapOf(
      "verdict" to verdict(signals, reasons),
      "reasons" to reasons,
      "sdkInt" to signals.sdkInt,
      "backgroundRestricted" to signals.backgroundRestricted,
      "standbyBucket" to signals.standbyBucket,
      "notificationsEnabled" to signals.notificationsEnabled,
      "downloadChannelBlocked" to signals.downloadChannelBlocked,
      "dataSaverRestricted" to signals.dataSaverRestricted,
      "ignoringBatteryOptimizations" to signals.ignoringBatteryOptimizations
    )
  }
}

/** Settings screen a remedy button can send the user to. */
internal enum class BackgroundSettingsTarget(val id: String) {
  APP_DETAILS("app_details"),
  APP_NOTIFICATIONS("app_notifications"),
  NOTIFICATION_CHANNEL("notification_channel");

  companion object {
    fun fromId(raw: String?): BackgroundSettingsTarget? = entries.firstOrNull { it.id == raw }
  }
}

/** Declarative intent description, kept Intent-free so it unit-tests on the JVM. */
internal data class SettingsIntentSpec(
  val action: String,
  val data: String? = null,
  val stringExtras: Map<String, String> = emptyMap()
)

/**
 * Ordered candidate intents per target, each falling back to the app details
 * page — the one Settings screen that exists on every Android build and that
 * reaches Battery → Unrestricted on One UI, Pixel, and AOSP alike.
 *
 * Samsung's own "Background usage limits" screen lives in an unexported
 * `com.samsung.android.lool` activity that moves between One UI releases, so
 * it is deliberately not targeted; the user gets written directions instead.
 */
internal object BackgroundSettingsIntents {
  fun specsFor(
    target: BackgroundSettingsTarget,
    packageName: String,
    sdkInt: Int
  ): List<SettingsIntentSpec> {
    val appDetails = SettingsIntentSpec(
      action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
      data = "package:$packageName"
    )
    if (sdkInt < Build.VERSION_CODES.O) return listOf(appDetails)
    return when (target) {
      BackgroundSettingsTarget.APP_DETAILS -> listOf(appDetails)
      BackgroundSettingsTarget.APP_NOTIFICATIONS -> listOf(
        SettingsIntentSpec(
          action = Settings.ACTION_APP_NOTIFICATION_SETTINGS,
          stringExtras = mapOf(Settings.EXTRA_APP_PACKAGE to packageName)
        ),
        appDetails
      )
      BackgroundSettingsTarget.NOTIFICATION_CHANNEL -> listOf(
        SettingsIntentSpec(
          action = Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS,
          stringExtras = mapOf(
            Settings.EXTRA_APP_PACKAGE to packageName,
            Settings.EXTRA_CHANNEL_ID to BackgroundWorkDiagnostics.DOWNLOAD_NOTIFICATION_CHANNEL_ID
          )
        ),
        SettingsIntentSpec(
          action = Settings.ACTION_APP_NOTIFICATION_SETTINGS,
          stringExtras = mapOf(Settings.EXTRA_APP_PACKAGE to packageName)
        ),
        appDetails
      )
    }
  }
}

/**
 * Reads the OS-visible reasons background downloads may be blocked.
 *
 * Every read is for our own package and needs no permission. Notably absent is
 * `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: it is a Play-policy-restricted
 * permission whose qualifying use cases do not include media downloading.
 * Whitelist state is reported for support diagnostics only.
 */
internal object BackgroundWorkDiagnostics {
  /** `background_downloader`'s channel id (`Notifications.kt`, `nId`). */
  const val DOWNLOAD_NOTIFICATION_CHANNEL_ID = "background_downloader"

  fun read(context: Context): BackgroundWorkSignals = BackgroundWorkSignals(
    sdkInt = Build.VERSION.SDK_INT,
    backgroundRestricted = readBackgroundRestricted(context),
    standbyBucket = readStandbyBucket(context),
    notificationsEnabled = readNotificationsEnabled(context),
    downloadChannelBlocked = readDownloadChannelBlocked(context),
    dataSaverRestricted = readDataSaverRestricted(context),
    ignoringBatteryOptimizations = readIgnoringBatteryOptimizations(context)
  )

  private fun readBackgroundRestricted(context: Context): Boolean? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
    return runCatching {
      (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).isBackgroundRestricted
    }.getOrNull()
  }

  private fun readStandbyBucket(context: Context): Int? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
    return runCatching {
      (context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager).appStandbyBucket
    }.getOrNull()
  }

  private fun readNotificationsEnabled(context: Context): Boolean? = runCatching {
    (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()
  }.getOrNull()

  /**
   * Null until the plugin has created its channel (first download), which is
   * correct — there is nothing to warn about before then.
   */
  private fun readDownloadChannelBlocked(context: Context): Boolean? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
    return runCatching {
      val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      val channel = manager.getNotificationChannel(DOWNLOAD_NOTIFICATION_CHANNEL_ID) ?: return null
      channel.importance == NotificationManager.IMPORTANCE_NONE
    }.getOrNull()
  }

  private fun readDataSaverRestricted(context: Context): Boolean? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return null
    return runCatching {
      val connectivity = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
      connectivity.restrictBackgroundStatus == ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED
    }.getOrNull()
  }

  private fun readIgnoringBatteryOptimizations(context: Context): Boolean? = runCatching {
    (context.getSystemService(Context.POWER_SERVICE) as PowerManager)
      .isIgnoringBatteryOptimizations(context.packageName)
  }.getOrNull()

  /**
   * Launches the first candidate Settings screen that resolves. Returns false
   * when the device has none of them — some TV and Fire OS builds ship without
   * a battery settings activity entirely.
   */
  fun openSettings(context: Context, target: BackgroundSettingsTarget): Boolean {
    for (spec in BackgroundSettingsIntents.specsFor(target, context.packageName, Build.VERSION.SDK_INT)) {
      val launched = runCatching {
        val intent = Intent(spec.action).apply {
          spec.data?.let { data = Uri.parse(it) }
          spec.stringExtras.forEach { (key, value) -> putExtra(key, value) }
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        true
      }.getOrDefault(false)
      if (launched) return true
    }
    return false
  }
}
