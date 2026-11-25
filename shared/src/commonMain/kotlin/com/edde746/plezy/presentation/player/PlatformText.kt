package com.edde746.plezy.presentation.player

/**
 * [value] with [minFractionDigits] to [maxFractionDigits] decimals, rounded half up, in the digits and decimal
 * separator of [locale] (`1.25` in English, `1,25` in German).
 */
internal expect fun localizedDecimal(value: Double, minFractionDigits: Int, maxFractionDigits: Int, locale: String): String

/**
 * Text in the order readers of [locale] expect, by the platform's collation (JDK/ICU `Collator`, `NSString`):
 * "Čeština" among the C's, where code points put it after "Tiếng Việt".
 */
internal expect fun localeOrder(locale: String): Comparator<String>

/** Whether [text] holds [needle] as readers of [locale] search: case and accents aside, "francais" finds "Français". */
internal expect fun localeContains(text: String, needle: String, locale: String): Boolean
