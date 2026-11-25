package com.edde746.plezy.crash

import android.os.Build

internal actual fun osDescription(): String = "android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"
