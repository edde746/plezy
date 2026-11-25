package com.edde746.plezy.playback.resolve

/**
 * A `Content-Range` value (RFC 9110 §14.4): `bytes 0-65535/1234567`, `bytes 0-65535/*` (length unknown) or, on a
 * 416, `bytes */1234567`.
 *
 * @param first first byte position, or null for the unsatisfied form.
 * @param last last byte position (inclusive), or null for the unsatisfied form.
 * @param total complete length, or null when the server sent `*`.
 */
internal data class ContentRange(val first: Long?, val last: Long?, val total: Long?) {
    companion object {
        private val pattern = Regex("""^\s*bytes\s+(?:(\d+)-(\d+)|\*)\s*/\s*(\d+|\*)\s*$""", RegexOption.IGNORE_CASE)

        /** Null when [value] isn't a well-formed byte range. */
        fun parse(value: String?): ContentRange? {
            val match = pattern.matchEntire(value ?: return null) ?: return null
            val (firstText, lastText, totalText) = match.destructured
            val total = if (totalText == "*") null else totalText.toLongOrNull() ?: return null
            if (firstText.isEmpty()) return if (total == null) null else ContentRange(null, null, total)
            val first = firstText.toLongOrNull() ?: return null
            val last = lastText.toLongOrNull() ?: return null
            if (last < first || total != null && last >= total) return null
            return ContentRange(first, last, total)
        }
    }
}
