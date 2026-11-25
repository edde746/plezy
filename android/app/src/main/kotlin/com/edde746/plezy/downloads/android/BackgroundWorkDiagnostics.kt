package com.edde746.plezy.downloads.android

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
import com.edde746.plezy.downloads.BackgroundSettingsTarget
import com.edde746.plezy.downloads.BackgroundWorkProbe
import com.edde746.plezy.log.Log

/**
 * What the OS tells about whether this app's background work may run. Null means "this API level can't answer", not
 * "unrestricted": [BackgroundWorkClassifier] treats unknown as fine, as a warning that can't be substantiated is
 * worse than none.
 */
internal data class BackgroundWorkSignals(
    val sdkInt: Int? = null,
    val backgroundRestricted: Boolean? = null,
    val standbyBucket: Int? = null,
    val notificationsEnabled: Boolean? = null,
    val downloadChannelBlocked: Boolean? = null,
    val dataSaverRestricted: Boolean? = null,
    val ignoringBatteryOptimizations: Boolean? = null,
)

/** [BackgroundWorkSignals] as a verdict and ordered reasons; free of `Build.VERSION` reads so it tests on the JVM. */
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
     * `STANDBY_BUCKET_RESTRICTED` (API 30) and `STANDBY_BUCKET_NEVER`, as literals so the classifier compiles below
     * those levels. `RARE` (40) isn't one: ordinary disuse reaches it, so it says nothing about a user's restriction.
     */
    const val BUCKET_RESTRICTED = 45
    const val BUCKET_NEVER = 50

    private val blockingReasons = setOf(REASON_BACKGROUND_RESTRICTED, REASON_STANDBY_RESTRICTED)

    /** Most to least actionable; the UI leads with the first. */
    fun reasons(signals: BackgroundWorkSignals): List<String> = buildList {
        if (signals.backgroundRestricted == true) add(REASON_BACKGROUND_RESTRICTED)
        if (signals.standbyBucket != null && isRestrictedBucket(signals.standbyBucket)) add(REASON_STANDBY_RESTRICTED)
        // App-wide denial is more fundamental than a muted channel, and its screen exists before the channel does.
        if (signals.notificationsEnabled == false) {
            add(REASON_NOTIFICATIONS_DISABLED)
        } else if (signals.downloadChannelBlocked == true) {
            add(REASON_DOWNLOAD_CHANNEL_BLOCKED)
        }
        if (signals.dataSaverRestricted == true) add(REASON_DATA_SAVER)
    }

    fun verdict(signals: BackgroundWorkSignals, reasons: List<String> = reasons(signals)): String = when {
        reasons.any(blockingReasons::contains) -> VERDICT_BLOCKED
        signals.sdkInt != null && signals.sdkInt >= Build.VERSION_CODES.TIRAMISU && signals.notificationsEnabled == false -> VERDICT_BLOCKED
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
            "ignoringBatteryOptimizations" to signals.ignoringBatteryOptimizations,
        )
    }
}

/** A settings screen as an intent description, Intent-free so it tests on the JVM. */
internal data class SettingsIntentSpec(val action: String, val data: String? = null, val stringExtras: Map<String, String> = emptyMap())

/**
 * The settings screens to try for each target, in order, each ending with the app details page: the one screen every
 * Android build has, and the way to Battery → Unrestricted on One UI, Pixel and AOSP alike. Samsung's own background
 * usage limits screen is an unexported activity that moves between releases, so it isn't targeted.
 */
internal object BackgroundSettingsIntents {
    fun specsFor(target: BackgroundSettingsTarget, packageName: String, sdkInt: Int): List<SettingsIntentSpec> {
        val appDetails = SettingsIntentSpec(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, data = "package:$packageName")
        if (sdkInt < Build.VERSION_CODES.O) return listOf(appDetails)
        val appNotifications = SettingsIntentSpec(
            Settings.ACTION_APP_NOTIFICATION_SETTINGS,
            stringExtras = mapOf(Settings.EXTRA_APP_PACKAGE to packageName),
        )
        return when (target) {
            BackgroundSettingsTarget.APP_DETAILS -> listOf(appDetails)
            BackgroundSettingsTarget.APP_NOTIFICATIONS -> listOf(appNotifications, appDetails)
            BackgroundSettingsTarget.NOTIFICATION_CHANNEL -> listOf(
                SettingsIntentSpec(
                    Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS,
                    stringExtras = mapOf(
                        Settings.EXTRA_APP_PACKAGE to packageName,
                        Settings.EXTRA_CHANNEL_ID to DownloadNotifications.CHANNEL,
                    ),
                ),
                appNotifications,
                appDetails,
            )
        }
    }
}

/**
 * Reads why background downloads may be blocked, for this app's own package and with no permission. Absent on
 * purpose: `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, a Play-restricted permission whose qualifying uses don't include
 * media downloads; the whitelist state is reported for support logs only.
 */
internal class BackgroundWorkDiagnostics(private val context: Context) : BackgroundWorkProbe {
    override suspend fun backgroundWorkSignals(): Map<String, Any?> = BackgroundWorkClassifier.toMap(read())

    /** Launches the first candidate screen that resolves; false when the device has none (some TV and Fire OS builds). */
    override suspend fun openBackgroundSettings(target: BackgroundSettingsTarget): Boolean {
        for (spec in BackgroundSettingsIntents.specsFor(target, context.packageName, Build.VERSION.SDK_INT)) {
            val intent = Intent(spec.action).apply {
                spec.data?.let { data = Uri.parse(it) }
                spec.stringExtras.forEach { (key, value) -> putExtra(key, value) }
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val launched = runCatching { context.startActivity(intent) }
                .onFailure { Log.d(TAG, it) { "No settings screen for ${spec.action}" } }
                .isSuccess
            if (launched) return true
        }
        return false
    }

    fun read(): BackgroundWorkSignals = BackgroundWorkSignals(
        sdkInt = Build.VERSION.SDK_INT,
        backgroundRestricted = signal { if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) activityManager.isBackgroundRestricted else null },
        standbyBucket = signal {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                (context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager).appStandbyBucket
            } else {
                null
            }
        },
        notificationsEnabled = signal { notificationManager.areNotificationsEnabled() },
        downloadChannelBlocked = signal {
            // Null until the downloads create their channel, which is right: nothing to warn about before then.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                notificationManager.getNotificationChannel(DownloadNotifications.CHANNEL)?.let {
                    it.importance == NotificationManager.IMPORTANCE_NONE
                }
            } else {
                null
            }
        },
        dataSaverRestricted = signal {
            val connectivity = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            connectivity.restrictBackgroundStatus == ConnectivityManager.RESTRICT_BACKGROUND_STATUS_ENABLED
        },
        ignoringBatteryOptimizations = signal {
            (context.getSystemService(Context.POWER_SERVICE) as PowerManager).isIgnoringBatteryOptimizations(context.packageName)
        },
    )

    private val activityManager get() = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    private val notificationManager get() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** One signal, null when the OS refuses to answer. */
    private fun <T> signal(read: () -> T?): T? = runCatching(read)
        .onFailure { Log.d(TAG, it) { "Background work signal unreadable" } }
        .getOrNull()

    private companion object {
        const val TAG = "BackgroundWork"
    }
}
