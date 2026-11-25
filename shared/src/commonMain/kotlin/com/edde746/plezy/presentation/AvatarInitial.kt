package com.edde746.plezy.presentation

/**
 * The initial a profile's avatar shows: the trimmed name's first character as a
 * reader sees it, upper case; "?" for a blank name.
 *
 * One character as a reader sees it, by the rules of Unicode's extended grapheme clusters (UAX #29) that a name's
 * first character meets: a letter with its combining accents and spacing vowel signs, an emoji with its variation
 * selector, skin tone and the emoji it joins with a zero-width joiner, a flag's two regional indicators, a
 * subdivision flag's tags, a keycap.
 */
fun initialOf(name: String): String {
    val trimmed = name.trim()
    if (trimmed.isEmpty()) return "?"
    return trimmed.substring(0, firstCharacterEnd(trimmed)).uppercase()
}

/** Where [text]'s (not empty) first user-perceived character ends: [initialOf]'s rules. */
private fun firstCharacterEnd(text: String): Int {
    val first = text.codePointAt(0)
    var end = charCount(first)
    // A flag: two regional indicators, and no more (a second flag starts after them).
    if (first.isRegionalIndicator() && end < text.length && text.codePointAt(end).isRegionalIndicator()) end += 2
    var joined = false
    while (end < text.length) {
        val next = text.codePointAt(end)
        if (!joined && !next.isExtend() && next != ZERO_WIDTH_JOINER) break
        // After a joiner the next character is part of this one (an emoji sequence: 👩‍💻, 🏳️‍🌈).
        joined = next == ZERO_WIDTH_JOINER
        end += charCount(next)
    }
    return end
}

/**
 * The colour (ARGB) behind [name]'s initial, the same for the same name, from a palette dark enough for white text;
 * null for an empty name, which takes the theme's primary colour.
 */
fun avatarColorOf(name: String): Long? {
    if (name.isEmpty()) return null
    var hash = 0
    for (c in name) hash = (hash * 31 + c.code) and 0x7fffffff
    return AVATAR_PALETTE[hash % AVATAR_PALETTE.size]
}

private val AVATAR_PALETTE = longArrayOf(
    0xFF1565C0, // blue
    0xFF2E7D32, // green
    0xFFAD1457, // pink
    0xFF6A1B9A, // purple
    0xFF00838F, // teal
    0xFFE65100, // orange
    0xFF4527A0, // deep purple
    0xFFC62828, // red
)

private const val ZERO_WIDTH_JOINER = 0x200D

/** Joins the character before it: combining and spacing marks, variation selectors, skin tones, tags. */
private fun Int.isExtend(): Boolean = when {
    this < 0x10000 -> when (toChar().category) {
        CharCategory.NON_SPACING_MARK, CharCategory.ENCLOSING_MARK, CharCategory.COMBINING_SPACING_MARK -> true
        // The zero-width non-joiner, Thai and Lao sara am, halfwidth katakana's sound marks.
        else -> this == 0x200C || this == 0x0E33 || this == 0x0EB3 || this in 0xFF9E..0xFF9F
    }
    // Emoji skin tones, tags (subdivision flags), the supplementary variation selectors.
    else -> this in 0x1F3FB..0x1F3FF || this in 0xE0020..0xE007F || this in 0xE0100..0xE01EF
}

private fun Int.isRegionalIndicator() = this in 0x1F1E6..0x1F1FF

private fun charCount(codePoint: Int) = if (codePoint >= 0x10000) 2 else 1

/** The code point at [index]; a lone surrogate as itself. */
private fun String.codePointAt(index: Int): Int {
    val high = this[index]
    if (high.isHighSurrogate() && index + 1 < length) {
        val low = this[index + 1]
        if (low.isLowSurrogate()) return 0x10000 + ((high.code - 0xD800) shl 10) + (low.code - 0xDC00)
    }
    return high.code
}
