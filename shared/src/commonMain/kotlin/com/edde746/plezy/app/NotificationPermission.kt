package com.edde746.plezy.app

/**
 * Android 13+'s notification permission, asked before a download is queued: its notification anchors the transfer's
 * foreground service ([AppPlatform.notificationPermission]). Media notifications are exempt, so playback never asks.
 * Asked once per run; a no-op elsewhere.
 */
fun interface NotificationPermission {
    suspend fun ensure()
}

/** The platforms with nothing to ask. */
internal val NoNotificationPermission = NotificationPermission {}
