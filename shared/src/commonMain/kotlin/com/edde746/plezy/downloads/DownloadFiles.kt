package com.edde746.plezy.downloads

/** The names of the downloader's temporary files: a task's bytes arrive in `<clean task id>.part` first. */
internal object DownloadNames {
    const val PART = ".part"

    /** What sits next to a part file while a platform transport works on it (Apple: a received body). */
    val PART_SIDECARS = listOf(".part.incoming")

    /** A name safe as one path component on every platform. */
    fun clean(name: String): String {
        val replaced = name.replace(":", " -").replace(INVALID, "").replace(SPACES, " ").trim().trimEnd('.', ' ')
        val short = if (replaced.length > MAX_COMPONENT) replaced.take(MAX_COMPONENT).trimEnd('.', ' ') else replaced
        return if (short.uppercase().substringBefore('.') in RESERVED) "_$short" else short
    }

    private const val MAX_COMPONENT = 80
    private val INVALID = Regex("""[\\/*?"<>|\u0000-\u001F]""")
    private val SPACES = Regex("""\s+""")
    private val RESERVED = setOf("CON", "PRN", "AUX", "NUL") + (1..9).flatMap { listOf("COM$it", "LPT$it") }
}
