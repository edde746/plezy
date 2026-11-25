package com.edde746.plezy.plex

/** An IP literal's bytes: 4 for IPv4, 16 for IPv6; null when [text] is not one (brackets and zone ids not accepted). */
internal fun parseIpLiteral(text: String): ByteArray? = parseIpv4(text) ?: parseIpv6(text)

private fun parseIpv4(text: String): ByteArray? {
    val parts = text.split('.')
    if (parts.size != 4) return null
    val out = ByteArray(4)
    for ((i, part) in parts.withIndex()) {
        if (part.isEmpty() || part.length > 3 || part.any { it !in '0'..'9' }) return null
        val v = part.toInt()
        if (v > 255) return null
        out[i] = v.toByte()
    }
    return out
}

private fun parseIpv6(text: String): ByteArray? {
    if (':' !in text) return null
    val doubleColon = text.indexOf("::")
    if (doubleColon >= 0 && text.indexOf("::", doubleColon + 1) >= 0) return null
    val head = if (doubleColon >= 0) text.substring(0, doubleColon) else text
    val tail = if (doubleColon >= 0) text.substring(doubleColon + 2) else ""
    val headGroups = groups(head) ?: return null
    val tailGroups = groups(tail) ?: return null
    val total = headGroups.size + tailGroups.size
    if (doubleColon < 0 && total != 8) return null
    if (doubleColon >= 0 && total > 7) return null
    val words = IntArray(8)
    headGroups.forEachIndexed { i, w -> words[i] = w }
    tailGroups.forEachIndexed { i, w -> words[8 - tailGroups.size + i] = w }
    return ByteArray(16) { i -> (if (i % 2 == 0) words[i / 2] shr 8 else words[i / 2]).toByte() }
}

/** 16-bit groups of [part]; a trailing dotted IPv4 counts as two. */
private fun groups(part: String): List<Int>? {
    if (part.isEmpty()) return emptyList()
    val pieces = part.split(':')
    val out = ArrayList<Int>(pieces.size + 1)
    for ((i, piece) in pieces.withIndex()) {
        if (i == pieces.lastIndex && '.' in piece) {
            val v4 = parseIpv4(piece) ?: return null
            out += ((v4[0].toInt() and 0xFF) shl 8) or (v4[1].toInt() and 0xFF)
            out += ((v4[2].toInt() and 0xFF) shl 8) or (v4[3].toInt() and 0xFF)
            continue
        }
        if (piece.isEmpty() || piece.length > 4) return null
        out += piece.toIntOrNull(16) ?: return null
    }
    return out
}
