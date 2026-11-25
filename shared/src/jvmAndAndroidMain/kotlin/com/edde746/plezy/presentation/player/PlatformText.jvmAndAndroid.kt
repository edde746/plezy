package com.edde746.plezy.presentation.player

import java.math.RoundingMode
import java.text.Collator
import java.text.Normalizer
import java.text.NumberFormat
import java.util.Locale

internal actual fun localizedDecimal(value: Double, minFractionDigits: Int, maxFractionDigits: Int, locale: String): String =
    NumberFormat.getNumberInstance(Locale.forLanguageTag(locale)).apply {
        minimumFractionDigits = minFractionDigits
        maximumFractionDigits = maxFractionDigits
        roundingMode = RoundingMode.HALF_UP
    }.format(value)

internal actual fun localeOrder(locale: String): Comparator<String> {
    val collator = Collator.getInstance(Locale.forLanguageTag(locale))
    return Comparator { a, b -> collator.compare(a, b) }
}

internal actual fun localeContains(text: String, needle: String, locale: String): Boolean {
    val language = Locale.forLanguageTag(locale)
    // Lower case first, in the language's rules (Turkish İ is i), then the accents come off as combining marks.
    fun String.folded() = Normalizer.normalize(lowercase(language), Normalizer.Form.NFD).replace(COMBINING_MARKS, "")
    return needle.folded() in text.folded()
}

private val COMBINING_MARKS = Regex("""\p{M}+""")
