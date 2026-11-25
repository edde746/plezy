package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.lang.LanguageNames
import com.edde746.plezy.lang.LanguageTags

/** The subtitle search's languages: ISO 639-1 codes, as the servers' subtitle providers take them. */
internal object SubtitleSearch {
    /**
     * The language a search starts in: the one kept ([PlayerChoices.subtitleSearchLanguage]), else the viewer's
     * language ([locale]), else English; each read as ISO 639-1 (`pt_BR` → `pt`, `eng` → `en`), skipped when it names
     * none.
     */
    fun language(stored: String?, locale: String): String = iso6391(stored) ?: iso6391(locale) ?: ENGLISH

    /** [value]'s ISO 639-1 code (`pt_BR` → `pt`, `eng` → `en`), or null when it names no language that has one. */
    fun iso6391(value: String?): String? {
        val primary = LanguageTags.canonical(value)?.let(LanguageTags::primary) ?: return null
        return primary.takeIf { it.length == 2 && LanguageTags.terminologic(it) != null }
    }

    /** [code]'s name in [locale] ("French", "Français"). */
    fun name(code: String, locale: String): String = LanguageNames.displayName(code, locale) ?: code.uppercase()

    /** The language picker: every language with an ISO 639-1 code by name, [selected] ticked, each searching in it. */
    fun languages(selected: String, locale: String, command: (String) -> PlayerCommand): List<OptionChoice> {
        val order = localeOrder(locale)
        return codes
            .map { it to name(it, locale) }
            .sortedWith { a, b -> order.compare(a.second, b.second) }
            .map { (code, name) -> OptionChoice(name, detail = null, selected = code == selected, command(code)) }
    }

    /** Every ISO 639-1 code, from the ISO 639-2 codes the language preferences store. */
    private val codes: List<String> by lazy {
        LanguageTags.preferenceCodes.mapNotNull(::iso6391).distinct()
    }

    private const val ENGLISH = "en"
}
