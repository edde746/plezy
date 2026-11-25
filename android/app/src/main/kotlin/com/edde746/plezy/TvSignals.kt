package com.edde746.plezy

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration

/** What the device reports about itself, read once from the framework ([read]). */
internal data class TvSignals(
    val isAutomotive: Boolean,
    val isTelevisionUiMode: Boolean,
    val hasTelevisionFeature: Boolean,
    val hasLeanback: Boolean,
    val hasFireTvFeature: Boolean,
    val hasTouchscreen: Boolean,
) {
    /** Each TV signal present, by name; any one makes a TV. */
    val reasons: List<String>
        get() = buildList {
            if (isTelevisionUiMode) add("ui_mode_television")
            if (hasTelevisionFeature) add("television_feature")
            if (hasLeanback) add("leanback")
            if (hasFireTvFeature) add("fire_tv")
            if (!hasTouchscreen) add("no_touchscreen")
        }

    /** A car is never a TV: rotary-only head units report no touchscreen, and an OEM image can carry a stray leanback flag. */
    val isTv: Boolean get() = !isAutomotive && reasons.isNotEmpty()

    companion object {
        @Suppress("DEPRECATION")
        fun read(context: Context): TvSignals {
            val pm = context.packageManager
            return TvSignals(
                isAutomotive = pm.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE),
                isTelevisionUiMode = context.getSystemService(UiModeManager::class.java)?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION,
                hasTelevisionFeature = pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION),
                hasLeanback = pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK),
                hasFireTvFeature = pm.hasSystemFeature("amazon.hardware.fire_tv"),
                hasTouchscreen = pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN),
            )
        }
    }
}
