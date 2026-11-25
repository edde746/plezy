package com.edde746.plezy.presentation.settings

/**
 * [text], a licence file hard-wrapped at about 80 columns, as paragraphs that wrap to any width:
 * - paragraphs end at blank lines (and at a line of a lone `.`, the blank line of Debian's copyright files);
 * - inside one, a line goes on the line before it, after one space, when that line is long (at least [LONG_LINE] of the
 *   file's wrap width: its longest line, at most [MAX_WRAP] columns) and neither of the two stands alone;
 * - a line stands alone when it has no letter or digit (a rule, a code fence), holds a tab or four spaces in a row (a
 *   table's columns) or is centred (indented a quarter of the wrap width or more);
 * - the line before also keeps its break when it ends in a Markdown line break (`\`, `<br>`), and the line after when it
 *   starts a list item (`-`, `*`, `•`, `+`, `#`, `//`, `(a)`, `[1]`, `1.`, `1.1`, `a)`, `iv.`) or a copyright notice
 *   (`Copyright 2020`, `Copyright (c)`, `Copyright:`, `©`), so a list of copyright holders stays one per line.
 *
 * Every other break stays (headings, short lines, lists), and every line loses its indentation and trailing spaces.
 */
internal fun reflowLicense(text: String): List<String> {
    val lines = text.replace("\r\n", "\n").replace('\r', '\n').split('\n').map { it.trimEnd() }
    val width = minOf(lines.maxOfOrNull { it.length } ?: 0, MAX_WRAP)
    val paragraphs = mutableListOf<String>()
    val paragraph = StringBuilder()
    var previous: String? = null
    for (line in lines) {
        val words = line.trimStart()
        if (words.isEmpty() || words == ".") {
            if (paragraph.isNotEmpty()) paragraphs += paragraph.toString()
            paragraph.clear()
            previous = null
            continue
        }
        val joins = previous != null && previous.length >= width * LONG_LINE && !standsAlone(previous, width) &&
            !previous.endsWith('\\') && !previous.endsWith("<br>", ignoreCase = true) &&
            !standsAlone(line, width) && !ListItem.containsMatchIn(words) && !CopyrightNotice.containsMatchIn(words)
        if (joins) paragraph.append(' ') else if (paragraph.isNotEmpty()) paragraph.append('\n')
        paragraph.append(words)
        previous = line
    }
    if (paragraph.isNotEmpty()) paragraphs += paragraph.toString()
    return paragraphs
}

/** The widest wrap a licence file is taken to have: a file of longer lines (one unwrapped line) counts as 80 wide. */
private const val MAX_WRAP = 80

/** A line at least this share of the wrap width long ends where the file wrapped it. */
private const val LONG_LINE = 0.7

private val ListItem = Regex("""^(?:#+|//+|[-*•+]|\(\w{1,4}\)|\[\w{1,4}\]|\d+(?:\.\d+)+\.?|\d+[.)]|[a-zA-Z][.)]|[ivxIVX]{1,4}[.)])(?:\s|$)""")

private val CopyrightNotice = Regex("""^(?:Copyright\s*(?::|\([cC]\)|©|\d|\[)|©|\([cC]\)\s)""")

/** [line] has no letter or digit, holds a table's columns, or is centred in [width] columns. */
private fun standsAlone(line: String, width: Int): Boolean {
    val words = line.trim()
    val indent = line.length - line.trimStart().length
    return words.none { it.isLetterOrDigit() } || "    " in words || '\t' in words || (indent > 0 && indent * 4 >= width)
}
