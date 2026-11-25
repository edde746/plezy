package com.edde746.plezy.lang

/**
 * Display names for track languages. Codes are reduced to their canonical BCP 47 form first ([LanguageTags]:
 * `ger` → `de`), so every platform's CLDR data names them the same way.
 */
internal object LanguageNames {
    /**
     * The name of [language] in the language of [displayLocale], capitalized as a list entry ("English", "Deutsch",
     * "Portuguese (Brazil)"); the code in capitals when the platform has no name for it; null when it names no
     * language.
     */
    fun displayName(language: String?, displayLocale: String): String? {
        val tag = LanguageTags.canonical(language) ?: return null
        val name = localizedLanguageName(tag, displayLocale) ?: return tag.uppercase()
        return name.replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
    }
}

/**
 * The platform's name for BCP 47 [tag] (a language with optional script and region, `pt-BR`) in the language of
 * [displayLocale], from its CLDR data (JDK/ICU, `NSLocale`); null when the platform has no name for it.
 */
internal expect fun localizedLanguageName(tag: String, displayLocale: String): String?
