package com.edde746.plezy.lang

import java.util.Locale

internal actual fun localizedLanguageName(tag: String, displayLocale: String): String? {
    val name = Locale.forLanguageTag(tag).getDisplayName(Locale.forLanguageTag(displayLocale))
    return name.takeUnless { it.isEmpty() || it.equals(tag, ignoreCase = true) }
}
