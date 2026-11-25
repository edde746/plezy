package com.edde746.plezy.app

import com.edde746.plezy.jellyfin.JellyfinAuthHeader
import com.edde746.plezy.plex.sanitizeHeaderValue

/**
 * What this install calls itself to media servers and companion devices ([AppPlatform.device]): Plex dashboards show
 * [deviceName] as the player, Jellyfin and Emby as the device.
 *
 * @param platform `Android`, `iOS`, `tvOS`, `macOS`, `Windows` or `Linux`: Plex's `X-Plex-Platform`.
 * @param platformVersion the OS's own description of its version, sent on Plex Home user switches: Android's build
 *   display id (`AP4A.250105.002`), Apple's `Version 18.2 (Build 22C150)`, Windows' `"Windows 11 Pro" 10.0 (Build
 *   22631)`, Linux's `uname` sysname, release and version (`Linux 6.8.0-45-generic #45-Ubuntu SMP …`).
 * @param deviceModel the hardware model (`AFTKM`, `iPhone`, `Apple TV`): Plex's `X-Plex-Device`; null when unknown.
 * @param deviceName the device's own, usually user-given, name (Android's Device name, a computer's name); null when
 *   unknown. It may hold characters no HTTP header takes: [plexDeviceName] is the header-safe form.
 * @param isTv an Android TV, Fire TV or Apple TV.
 */
data class DeviceIdentity(
    val platform: String,
    val platformVersion: String,
    val deviceModel: String?,
    val deviceName: String?,
    val isTv: Boolean,
) {
    /** [deviceModel] as Plex's `X-Plex-Device` header carries it; null when nothing usable remains. */
    val plexDevice: String? get() = sanitizeHeaderValue(deviceModel)

    /** [deviceName] as Plex's `X-Plex-Device-Name` header carries it; null when nothing usable remains. */
    val plexDeviceName: String? get() = sanitizeHeaderValue(deviceName)

    /** The MediaBrowser `Client` (`Plezy Android TV`, `Plezy iOS`). */
    val jellyfinClientName: String get() = JellyfinAuthHeader.clientName(platform, isTv)

    /** The MediaBrowser `Device`: [deviceName], else [deviceModel], else [platform]. */
    val jellyfinDeviceName: String get() = JellyfinAuthHeader.deviceName(platform, deviceModel, deviceName)
}
