package com.edde746.plezy.strings

import kotlinx.coroutines.flow.StateFlow

/**
 * Which language the interface is in, and the observable behind `T.locale`. The platform reports the system's
 * languages as it starts ([com.edde746.plezy.app.SystemInputs.report]) and again when they change
 * ([setSystemLanguages]); the device's Language setting (`app_locale`), once one is picked, overrides them
 * ([setChosen]). The UI redraws itself when [tag] changes and lays out right to left when [isRightToLeft] says so.
 * Main thread only.
 */
object InterfaceLocale {
    private var system: List<String> = emptyList()
    private var chosen: String? = null

    /**
     * `T.locale` as the UI should see it: a new value means every string changed. It is `T.locale` whoever set it, so it
     * never shows a language the strings have left (a test that switches the strings' language and back).
     */
    val tag: StateFlow<String> = Locales.selected

    /**
     * The languages this build has strings for (`shared/i18n/<tag>.i18n.json`), English first: those the Language
     * setting offers.
     */
    val available: List<String> get() = Locales.available

    /**
     * The system's preferred languages as BCP 47 tags, most preferred first. With no chosen language, the interface
     * uses the first of them that has strings ([Locales.hasStrings]: English, any region, or a language of
     * [Locales.available]); if none does, English strings under the first tag's number formats.
     */
    fun setSystemLanguages(tags: List<String>) {
        if (tags == system) return
        system = tags
        apply()
    }

    /** The picked interface language, or null for the system's. */
    fun setChosen(tag: String?) {
        if (tag == chosen) return
        chosen = tag
        apply()
    }

    /** Whether the strings shown for [tag] (default: the current language) are in a right-to-left language. */
    fun isRightToLeft(tag: String = T.locale): Boolean {
        val shown = Locales.resolve(tag)
        return shown.substringBefore('-').lowercase() in RIGHT_TO_LEFT
    }

    /**
     * [tag] as the locale text is drawn in, for the glyphs: Chinese without a region gets its script's
     * (`zh-Hans-CN`, `zh-Hant-TW`), so the fonts the system falls back to draw the Chinese forms of Han characters
     * rather than the Japanese ones (Windows' DirectWrite picks a Japanese font for a bare `zh`).
     */
    fun glyphTag(tag: String = T.locale): String {
        val subtags = tag.trim().replace('_', '-').split('-')
        val region = subtags.drop(1).any { it.length == 2 || (it.length == 3 && it.all(Char::isDigit)) }
        if (!subtags[0].equals("zh", ignoreCase = true) || region) return tag
        return if (Locales.resolve(tag) == "zh-Hant") "zh-Hant-TW" else "zh-Hans-CN"
    }

    /**
     * [text] as an Apple menu entry's title: in title case where the strings shown are English ("Normalize loudness" →
     * "Normalize Loudness", short articles, conjunctions and prepositions lowercase inside), else unchanged, since title
     * case is an English rule and other languages keep their own casing. The shared strings are in sentence case.
     */
    fun menuTitle(text: String): String {
        if (Locales.resolve(T.locale).substringBefore('-') != Locales.available[0]) return text
        val words = text.split(' ')
        return words.mapIndexed { index, word ->
            val inner = index != 0 && index != words.lastIndex
            if (inner && word in MINOR_WORDS) word
            else word.split('-').joinToString("-") { part -> part.replaceFirstChar { it.titlecase() } }
        }.joinToString(" ")
    }

    private fun apply() {
        val next = chosen ?: system.firstOrNull { Locales.hasStrings(it) } ?: system.firstOrNull() ?: Locales.available[0]
        T.locale = next
    }

    // None of the languages this build shows is written right to left; these are for when one is added.
    private val RIGHT_TO_LEFT = setOf("ar", "fa", "he", "ur", "ps", "sd", "ug", "yi", "dv")

    // Words an English title keeps lowercase between its first and last words.
    private val MINOR_WORDS = setOf("a", "an", "and", "as", "at", "but", "by", "for", "from", "in", "into", "nor", "of", "on", "or", "the", "to", "via", "vs", "with")
}
