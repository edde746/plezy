package com.edde746.plezy

import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration

/**
 * Native mirror of MainActivity.getAndroidTvDetection(): any TV signal counts,
 * except that FEATURE_AUTOMOTIVE vetoes the verdict outright. Kept in sync with
 * the Dart-facing detection so native gating matches PlatformDetector.isTV().
 */
object TvDetection {
  fun isTv(context: Context): Boolean {
    val pm = context.packageManager
    val uiModeType = context.resources.configuration.uiMode and Configuration.UI_MODE_TYPE_MASK

    // A car is never a TV: rotary-only head units report no touchscreen, and an
    // OEM image can carry a stray leanback flag.
    if (pm.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)) return false

    @Suppress("DEPRECATION")
    return uiModeType == Configuration.UI_MODE_TYPE_TELEVISION ||
      pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION) ||
      pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
      pm.hasSystemFeature("amazon.hardware.fire_tv") ||
      !pm.hasSystemFeature(PackageManager.FEATURE_TOUCHSCREEN)
  }
}
