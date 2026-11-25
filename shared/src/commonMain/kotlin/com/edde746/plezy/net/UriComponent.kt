package com.edde746.plezy.net

/**
 * Percent-encoding as JavaScript's `encodeURIComponent` does it: every UTF-8 byte except ASCII letters, digits and
 * `- _ . ! ~ * ' ( )` becomes `%XX` with uppercase hex. The app's own links (`plezy://`) use it.
 */
object UriComponent {
    private const val HEX = "0123456789ABCDEF"

    fun encode(value: String): String {
        var plainPrefix = 0
        while (plainPrefix < value.length && isUnreserved(value[plainPrefix])) plainPrefix++
        if (plainPrefix == value.length) return value
        val out = StringBuilder(value.length + 16).append(value, 0, plainPrefix)
        for (byte in value.substring(plainPrefix).encodeToByteArray()) {
            val b = byte.toInt() and 0xFF
            if (b < 0x80 && isUnreserved(b.toChar())) {
                out.append(b.toChar())
            } else {
                out.append('%').append(HEX[b shr 4]).append(HEX[b and 0x0F])
            }
        }
        return out.toString()
    }

    /**
     * `name=value` pairs, both sides [encode]d, joined with `&`, in the given order.
     */
    fun encodeQuery(params: List<Pair<String, String>>): String =
        params.joinToString("&") { (name, value) -> encode(name) + "=" + encode(value) }

    /**
     * Percent-decodes [value] as the `url`/`percent-encoding` crates do: `%XX` with two hex digits becomes that byte,
     * anything else stays literal, and the bytes are read as UTF-8 with malformed sequences replaced by U+FFFD.
     */
    fun decode(value: String): String {
        if ('%' !in value) return value
        val bytes = value.encodeToByteArray()
        val out = ByteArray(bytes.size)
        var i = 0
        var n = 0
        while (i < bytes.size) {
            val b = bytes[i]
            if (b == '%'.code.toByte() && i + 2 < bytes.size) {
                val hi = hexValue(bytes[i + 1])
                val lo = hexValue(bytes[i + 2])
                if (hi >= 0 && lo >= 0) {
                    out[n++] = ((hi shl 4) or lo).toByte()
                    i += 3
                    continue
                }
            }
            out[n++] = b
            i++
        }
        return out.decodeToString(0, n)
    }

    private fun isUnreserved(c: Char): Boolean =
        c in 'a'..'z' || c in 'A'..'Z' || c in '0'..'9' ||
            c == '-' || c == '_' || c == '.' || c == '!' || c == '~' || c == '*' || c == '\'' || c == '(' || c == ')'

    private fun hexValue(b: Byte): Int = when (val c = b.toInt().toChar()) {
        in '0'..'9' -> c - '0'
        in 'a'..'f' -> c - 'a' + 10
        in 'A'..'F' -> c - 'A' + 10
        else -> -1
    }
}
