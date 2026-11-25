package com.edde746.plezy.plex

import platform.Foundation.NSString
import platform.Foundation.decomposedStringWithCanonicalMapping

@Suppress("CAST_NEVER_SUCCEEDS")
internal actual fun canonicalDecomposition(value: String): String =
    (value as NSString).decomposedStringWithCanonicalMapping
