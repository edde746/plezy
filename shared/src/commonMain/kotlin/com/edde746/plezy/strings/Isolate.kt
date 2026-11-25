package com.edde746.plezy.strings

/**
 * [text] the app didn't write (an addon's title, a cast member, a person's or a device's name), ready to sit inside an
 * app string: first-strong isolates (U+2068 … U+2069) give it the direction of its own first letter and keep it from
 * reordering the app's words and punctuation around it, so "4. What If...?" and "With Robert Downey Jr." read in order
 * in a right-to-left language, and an Arabic title in order in a left-to-right one. Empty text stays empty.
 *
 * Text shown alone needs none: each UI gives it its own direction there.
 */
fun isolate(text: String): String = if (text.isEmpty()) text else "$FIRST_STRONG_ISOLATE$text$POP_DIRECTIONAL_ISOLATE"

private const val FIRST_STRONG_ISOLATE = '\u2068'
private const val POP_DIRECTIONAL_ISOLATE = '\u2069'
