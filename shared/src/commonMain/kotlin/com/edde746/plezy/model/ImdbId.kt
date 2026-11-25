package com.edde746.plezy.model

import kotlin.jvm.JvmInline

/** An IMDb title id, `tt0944947`: `tt` and 1 to 10 digits. */
@JvmInline
internal value class ImdbId private constructor(val value: String) {
    companion object {
        /** [text] when it is an IMDb title id; `null` for anything else (`ttabc`, `tt0944947:1:2`, `nm0000136`). */
        fun parse(text: String): ImdbId? =
            if (text.length in 3..12 && text.startsWith("tt") && (2 until text.length).all { text[it] in '0'..'9' }) ImdbId(text) else null
    }
}
