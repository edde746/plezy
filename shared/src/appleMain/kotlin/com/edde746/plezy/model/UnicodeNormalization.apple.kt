package com.edde746.plezy.model

import platform.Foundation.NSString
import platform.Foundation.precomposedStringWithCompatibilityMapping

@Suppress("CAST_NEVER_SUCCEEDS")
internal actual fun normalizeNfkc(value: String): String = (value as NSString).precomposedStringWithCompatibilityMapping
