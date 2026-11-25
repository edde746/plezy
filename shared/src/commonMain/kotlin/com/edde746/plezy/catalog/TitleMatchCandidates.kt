package com.edde746.plezy.catalog

/**
 * Season markers that begin a sequel suffix. Everything from the first match to the end is dropped, which collapses
 * stacked suffixes (`… Season 2 Part 2`, `… Season 3: The Culling Game Part 1`) in one pass.
 */
private val seasonSuffixes = listOf(
    Regex("""\s+season\s+\d+\b.*$""", RegexOption.IGNORE_CASE),
    Regex("""\s+\d+(?:st|nd|rd|th)\s+season\b.*$""", RegexOption.IGNORE_CASE),
    Regex("""\s+final\s+season\b.*$""", RegexOption.IGNORE_CASE),
    Regex("""\s+(?:part|cour|act)\.?\s*(?:\d+|i{1,3}v?|vi{0,3}|ix|x)\b.*$""", RegexOption.IGNORE_CASE),
    Regex("""\s+(?:ii|iii|iv|v|vi|vii|viii|ix|x)$""", RegexOption.IGNORE_CASE),
)

/**
 * A bare trailing number usually marks a sequel (`Isekai Quartet 3`), so it is stripped last, but not after a token
 * that expects a number: `Kaiju No. 8` and `Vol. 3` are titles.
 */
private val bareTrailingNumber = Regex("""\s+\d+$""")
private val numberedNoun = Regex("""\b(?:no|vol|pt|ep|episode|chapter)\.?\s+\d+$""", RegexOption.IGNORE_CASE)

/** Typographic variants media servers index differently from what catalog providers send. */
private val punctuation = mapOf(
    "\u2019" to "'",
    "\u2018" to "'",
    "\u201C" to "\"",
    "\u201D" to "\"",
    "\u2013" to "-",
    "\u2014" to "-",
    "\u30FB" to " ",
    "\uFF1A" to ":",
    "\uFF01" to "!",
    "\uFF1F" to "?",
)

/** [title] without its sequel suffix; null when it has none or stripping would leave nothing. */
fun stripSeasonSuffix(title: String): String? {
    var out = title
    for (marker in seasonSuffixes) out = marker.replaceFirst(out, "")
    if (!numberedNoun.containsMatchIn(out)) out = bareTrailingNumber.replaceFirst(out, "")
    out = out.trim()
    return if (out.isEmpty() || out == title.trim()) null else out
}

private fun normalizeTitle(title: String): String {
    var out = title
    for ((from, to) in punctuation) out = out.replace(from, to)
    return out.trim()
}

/**
 * Ordered, deduplicated title candidates for a media-server reverse lookup, at most [limit]. Neither backend filters
 * by external id, so the title is the only candidate filter, and a sequel entry's own title never matches the parent
 * show. Each title (punctuation normalized) is immediately followed by its season-stripped form, so the cap can never
 * spend every slot on unstripped titles. Duplicates are dropped case-insensitively; callers verify external ids.
 */
fun titleMatchCandidates(titles: Iterable<String?>, limit: Int = 4): List<String> {
    val out = ArrayList<String>()
    val seen = HashSet<String>()

    fun add(raw: String?) {
        if (raw == null || out.size >= limit) return
        val title = normalizeTitle(raw)
        if (title.isEmpty() || !seen.add(title.lowercase())) return
        out += title
    }

    for (title in titles) {
        if (out.size >= limit) break
        val normalized = title?.let(::normalizeTitle) ?: continue
        add(normalized)
        add(stripSeasonSuffix(normalized))
    }
    return out
}
