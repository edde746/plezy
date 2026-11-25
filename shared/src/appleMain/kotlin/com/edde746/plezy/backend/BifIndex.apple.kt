package com.edde746.plezy.backend

import kotlin.experimental.ExperimentalNativeApi

@OptIn(ExperimentalNativeApi::class)
internal actual val bifMaxBytes: Long =
    if (Platform.osFamily == OsFamily.MACOSX) 200L * 1024 * 1024 else 50L * 1024 * 1024
