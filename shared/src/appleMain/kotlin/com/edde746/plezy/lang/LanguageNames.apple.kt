package com.edde746.plezy.lang

import platform.Foundation.NSLocale
import platform.Foundation.localizedStringForLocaleIdentifier

internal actual fun localizedLanguageName(tag: String, displayLocale: String): String? {
    val name = NSLocale(localeIdentifier = displayLocale).localizedStringForLocaleIdentifier(tag)
    return name.takeUnless { it.isEmpty() || it.equals(tag, ignoreCase = true) }
}
