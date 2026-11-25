package com.edde746.plezy.strings

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.concurrent.Volatile

/**
 * Runtime behind the generated `T`: the locales that have a `shared/i18n/<tag>.i18n.json` file ([tags], English first)
 * and the one [T.locale] selected. The generated `Locales` object extends it with one index constant per tag. Reads
 * and [select] may happen on any thread.
 */
internal abstract class LocaleTable(private val tags: Array<String>) {
    private val rules = Array(tags.size) { PluralRule.forTag(tags[it]) }

    @Volatile private var selection = Selection(tags[0], IntArray(0))
    private val selectedTag = MutableStateFlow(tags[0])

    /** Every locale that has a strings file, English first: the interface languages on offer. */
    val available: List<String> = tags.toList()

    /** The tag last passed to [select], unchanged. */
    val tag: String get() = selection.tag

    /** [tag] as it changes ([InterfaceLocale.tag]). */
    val selected: StateFlow<String> = selectedTag.asStateFlow()

    /**
     * Indices of the locale files to try for each string, most specific first. English (index 0) isn't listed: every
     * accessor ends with it.
     */
    val chain: IntArray get() = selection.chain

    /** Whether this build shows [tag]'s language: it is English (the base), or a locale file serves it. */
    fun hasStrings(tag: String): Boolean =
        tag.trim().replace('_', '-').substringBefore('-').equals(tags[0], ignoreCase = true) || lookupChain(tag, tags).isNotEmpty()

    /** The tag of the locale file whose strings [tag] shows first: the most specific file there is, else English. */
    fun resolve(tag: String): String = lookupChain(tag, tags).firstOrNull()?.let { tags[it] } ?: tags[0]

    fun select(tag: String) {
        selection = Selection(tag, lookupChain(tag, tags))
        selectedTag.value = tag
    }

    /** The plural category of [n] in the language of locale [index]. */
    fun plural(index: Int, n: Int): PluralCategory = rules[index].select(n)

    private class Selection(val tag: String, val chain: IntArray)
}

/**
 * RFC 4647 lookup of the BCP 47 [tag] among [tags]: the tag itself, then with its last subtag removed, and so on (a
 * singleton such as `-x-` goes with the subtag after it). Returns the index of every candidate present, most specific
 * first, except index 0 (the base). Case-insensitive; `_` works as a separator.
 *
 * Chinese without a script: regions TW, HK and MO mean Traditional (`zh-Hant`). Traditional never falls back to the
 * Simplified `zh` file; like CLDR (whose parent of `zh_Hant` is root), a string missing from `zh-Hant` shows in
 * English.
 *
 * Portuguese: the regions that write European Portuguese (PT, AO, MZ, CV, GW, ST, TL, MO, GQ, LU, CH) mean `pt-PT`;
 * plain `pt`, `pt-BR` and every other region use the `pt` file.
 *
 * A language that has only regional files (say `fr-CA`, no `fr`) serves every region of the language: `fr-FR` and plain
 * `fr` use the first such file.
 */
internal fun lookupChain(tag: String, tags: Array<String>): IntArray {
    val subtags = tag.trim().replace('_', '-').lowercase().split('-').filter { it.isNotEmpty() }.toMutableList()
    val language = subtags.firstOrNull().orEmpty()
    val chinese = language == "zh"
    if (chinese && subtags.getOrNull(1) in setOf("tw", "hk", "mo")) subtags.add(1, "hant")
    if (language == "pt" && subtags.getOrNull(1) in EUROPEAN_PORTUGUESE_REGIONS) subtags.add(1, "pt")
    val traditional = chinese && subtags.getOrNull(1) == "hant"
    val chain = mutableListOf<Int>()
    while (subtags.isNotEmpty()) {
        if (traditional && subtags.size == 1) break
        val candidate = subtags.joinToString("-")
        val index = tags.indexOfFirst { it.equals(candidate, ignoreCase = true) }
        if (index > 0 && index !in chain) chain += index
        subtags.removeAt(subtags.lastIndex)
        if (subtags.lastOrNull()?.length == 1) subtags.removeAt(subtags.lastIndex)
    }
    if (chain.isEmpty() && !chinese && tags.none { it.equals(language, ignoreCase = true) }) {
        val regional = tags.indexOfFirst { it.startsWith("$language-", ignoreCase = true) }
        if (regional > 0) chain += regional
    }
    return chain.toIntArray()
}

/** The regions besides Portugal whose Portuguese is European (CLDR's `pt_PT` children). */
private val EUROPEAN_PORTUGUESE_REGIONS = setOf("ao", "mz", "cv", "gw", "st", "tl", "mo", "gq", "lu", "ch")
