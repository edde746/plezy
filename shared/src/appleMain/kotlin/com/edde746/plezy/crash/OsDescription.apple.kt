package com.edde746.plezy.crash

import platform.Foundation.NSProcessInfo
import kotlin.experimental.ExperimentalNativeApi

/** The system's name, then its version as it reads it: `ios Version 27.2 (Build 24C51)`, `macos Version 27.2 (…)`. */
@OptIn(ExperimentalNativeApi::class)
internal actual fun osDescription(): String {
    val os = when (Platform.osFamily) {
        OsFamily.MACOSX -> "macos"
        OsFamily.TVOS -> "tvos"
        else -> "ios"
    }
    return "$os ${NSProcessInfo.processInfo.operatingSystemVersionString}"
}
