package com.edde746.plezy.downloads

import kotlinx.io.files.SystemPathSeparator

/**
 * Path strings of this platform's file system, handled as Dart's `path` package does: `/` separates on every platform,
 * `\` too on Windows, where roots are drive letters (`C:\`) or shares (`\\server\share\`). Joins use
 * [SystemPathSeparator].
 */
internal object LocalPath {
    private val windows = SystemPathSeparator == '\\'

    fun isSeparator(c: Char) = c == '/' || (windows && c == '\\')

    /** How many leading characters of [path] are its root (0 for a relative path). */
    fun rootLength(path: String): Int {
        if (path.isEmpty()) return 0
        if (!windows) return if (path[0] == '/') 1 else 0
        if (isSeparator(path[0])) {
            if (path.length < 2 || !isSeparator(path[1])) return 1
            // \\server\share\
            var index = path.indexOfFirst(2) { isSeparator(it) }
            if (index < 0) return path.length
            index = path.indexOfFirst(index + 1) { isSeparator(it) }
            return if (index < 0) path.length else index + 1
        }
        if (path.length >= 2 && path[0].isLetter() && path[1] == ':') return if (path.length >= 3 && isSeparator(path[2])) 3 else 2
        return 0
    }

    fun isAbsolute(path: String) = rootLength(path) > 0

    /** [children] appended to [base] in turn; an absolute child replaces what came before it. */
    fun join(base: String, vararg children: String): String = children.fold(base) { joined, child ->
        when {
            isAbsolute(child) -> child
            joined.isEmpty() -> child
            child.isEmpty() -> joined
            isSeparator(joined.last()) -> joined + child
            else -> joined + SystemPathSeparator + child
        }
    }

    /** Collapses separators, `.` and `..` (above an absolute root it stays at the root). */
    fun normalize(path: String): String {
        val rootLength = rootLength(path)
        val root = path.substring(0, rootLength).let { if (windows) it.replace('/', '\\') else it }
        val parts = ArrayList<String>()
        for (part in segments(path.substring(rootLength))) {
            when {
                part.isEmpty() || part == "." -> Unit
                part == ".." && parts.isNotEmpty() && parts.last() != ".." -> parts.removeAt(parts.lastIndex)
                part == ".." && rootLength > 0 -> Unit
                else -> parts += part
            }
        }
        val joined = parts.joinToString(SystemPathSeparator.toString())
        return if (root.isEmpty() && joined.isEmpty()) "." else root + joined
    }

    /** Everything before the last component: `.` for a bare name, the root for a root's child. */
    fun dirname(path: String): String {
        val rootLength = rootLength(path)
        var end = path.length
        while (end > rootLength && isSeparator(path[end - 1])) end--
        if (end <= rootLength) return if (rootLength > 0) path.substring(0, rootLength) else "."
        var start = end
        while (start > rootLength && !isSeparator(path[start - 1])) start--
        if (start <= rootLength) return if (rootLength > 0) path.substring(0, rootLength) else "."
        var dirEnd = start
        while (dirEnd > rootLength && isSeparator(path[dirEnd - 1])) dirEnd--
        return path.substring(0, maxOf(dirEnd, rootLength))
    }

    /** The last component, without trailing separators. */
    fun basename(path: String): String {
        var end = path.length
        while (end > 0 && isSeparator(path[end - 1])) end--
        var start = end
        while (start > 0 && !isSeparator(path[start - 1])) start--
        return path.substring(start, end)
    }

    /** [path] without the extension of its last component (a leading dot doesn't start one). */
    fun withoutExtension(path: String): String {
        val name = basename(path)
        val dot = name.lastIndexOf('.')
        if (dot <= 0) return path
        val nameEnd = path.lastIndexOf(name)
        return path.substring(0, nameEnd + dot) + path.substring(nameEnd + name.length)
    }

    /** Whether [child] is strictly inside [parent] (by components, so `<parent>-other` is not). */
    fun isWithin(parent: String, child: String): Boolean {
        if (isAbsolute(parent) != isAbsolute(child)) return false
        val parentParts = components(normalize(parent))
        val childParts = components(normalize(child))
        if (childParts.size <= parentParts.size) return false
        return parentParts.indices.all { childParts[it].equals(parentParts[it], ignoreCase = windows) }
    }

    /** [path] relative to [from], for a [path] [isWithin] [from]. */
    fun relative(path: String, from: String): String {
        require(isWithin(from, path)) { "$path is not inside $from" }
        return components(normalize(path)).drop(components(normalize(from)).size).joinToString(SystemPathSeparator.toString())
    }

    private fun components(normalized: String): List<String> {
        val rootLength = rootLength(normalized)
        val root = normalized.substring(0, rootLength)
        val rest = segments(normalized.substring(rootLength)).filter { it.isNotEmpty() && it != "." }
        return if (root.isEmpty()) rest else listOf(root) + rest
    }

    private fun segments(path: String): List<String> = path.split(*if (windows) charArrayOf('/', '\\') else charArrayOf('/'))

    private inline fun String.indexOfFirst(from: Int, predicate: (Char) -> Boolean): Int {
        for (index in from until length) if (predicate(this[index])) return index
        return -1
    }
}
