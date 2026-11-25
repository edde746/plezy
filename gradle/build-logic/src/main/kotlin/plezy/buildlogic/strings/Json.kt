package plezy.buildlogic.strings

/** A parsed JSON value and the 1-based line it starts on, for error messages. */
internal sealed class JsonValue(val line: Int)

internal class JsonString(val value: String, line: Int) : JsonValue(line)

/** Members in file order. */
internal class JsonObject(val members: Map<String, JsonValue>, line: Int) : JsonValue(line)

/** Arrays, numbers, booleans and null: valid JSON, but never a valid string source. [kind] names it for messages. */
internal class JsonOther(val kind: String, line: Int) : JsonValue(line)

internal class JsonSyntaxException(val line: Int, val column: Int, message: String) : Exception(message)

/**
 * Strict RFC 8259 parser. It exists instead of a library for what string sources need: member order, line numbers and
 * duplicate keys reported as errors (common parsers keep the last one silently).
 */
internal object Json {
    fun parse(text: String): JsonValue = JsonParser(text).document()
}

/** Far deeper than any string source: its groups nest a few levels. */
private const val MAX_DEPTH = 64

private class JsonParser(private val s: String) {
    private var i = 0
    private var line = 1
    private var lineStart = 0
    private var depth = 0

    fun document(): JsonValue {
        if (s.startsWith('\uFEFF')) i = 1
        whitespace()
        val value = value()
        whitespace()
        if (i < s.length) fail("unexpected ${describe(s[i])} after the top-level value")
        return value
    }

    private fun value(): JsonValue {
        val start = line
        return when (val c = peek()) {
            '{' -> nested { obj() }
            '"' -> JsonString(string(), start)
            '[' -> { nested { array() }; JsonOther("an array", start) }
            't' -> { word("true"); JsonOther("true", start) }
            'f' -> { word("false"); JsonOther("false", start) }
            'n' -> { word("null"); JsonOther("null", start) }
            else -> if (c == '-' || c in '0'..'9') { number(); JsonOther("a number", start) } else fail("expected a value, found ${describe(c)}")
        }
    }

    /** [parse] one level deeper, failing past [MAX_DEPTH] levels: the parser and the catalog recurse per level. */
    private inline fun <T> nested(parse: () -> T): T {
        if (depth == MAX_DEPTH) fail("nested deeper than $MAX_DEPTH levels")
        depth++
        return parse().also { depth-- }
    }

    private fun obj(): JsonObject {
        val start = line
        i++ // {
        val members = LinkedHashMap<String, JsonValue>()
        whitespace()
        if (peek() == '}') { i++; return JsonObject(members, start) }
        while (true) {
            if (peek() != '"') fail("expected a quoted key, found ${describe(peek())}")
            val keyLine = line
            val keyColumn = column()
            val key = string()
            whitespace()
            expect(':')
            whitespace()
            val value = value()
            if (members.put(key, value) != null) throw JsonSyntaxException(keyLine, keyColumn, "duplicate key \"$key\"")
            whitespace()
            when (peek()) {
                ',' -> { i++; whitespace() }
                '}' -> { i++; return JsonObject(members, start) }
                else -> fail("expected ',' or '}', found ${describe(peek())}")
            }
        }
    }

    private fun array() {
        i++ // [
        whitespace()
        if (peek() == ']') { i++; return }
        while (true) {
            value()
            whitespace()
            when (peek()) {
                ',' -> { i++; whitespace() }
                ']' -> { i++; return }
                else -> fail("expected ',' or ']', found ${describe(peek())}")
            }
        }
    }

    private fun string(): String {
        i++ // opening quote
        val out = StringBuilder()
        while (true) {
            if (i >= s.length) fail("unterminated string")
            val c = s[i]
            when {
                c == '"' -> { i++; return out.toString() }
                c == '\\' -> { i++; out.append(escape()) }
                c < ' ' -> fail("unescaped control character U+%04X in a string".format(c.code))
                else -> { out.append(c); i++ }
            }
        }
    }

    private fun escape(): Char {
        if (i >= s.length) fail("unterminated string")
        val c = s[i++]
        return when (c) {
            '"', '\\', '/' -> c
            'b' -> '\b'
            'f' -> '\u000C'
            'n' -> '\n'
            'r' -> '\r'
            't' -> '\t'
            'u' -> {
                val hex = s.substring(i, minOf(i + 4, s.length))
                if (hex.length < 4 || !hex.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) fail("invalid \\u escape")
                i += 4
                hex.toInt(16).toChar()
            }
            else -> { i--; fail("invalid escape \\$c") }
        }
    }

    private fun number() {
        if (peek() == '-') i++
        when (peek()) {
            '0' -> i++
            in '1'..'9' -> digits()
            else -> fail("invalid number")
        }
        if (peek() == '.') { i++; if (peek() !in '0'..'9') fail("invalid number"); digits() }
        if (peek() == 'e' || peek() == 'E') {
            i++
            if (peek() == '+' || peek() == '-') i++
            if (peek() !in '0'..'9') fail("invalid number")
            digits()
        }
    }

    private fun digits() {
        while (peek() in '0'..'9') i++
    }

    private fun word(word: String) {
        if (!s.startsWith(word, i)) fail("expected a value, found ${describe(peek())}")
        i += word.length
    }

    private fun whitespace() {
        while (i < s.length) {
            when (s[i]) {
                '\n' -> { line++; lineStart = i + 1 }
                ' ', '\t', '\r' -> {}
                else -> return
            }
            i++
        }
    }

    private fun expect(c: Char) {
        if (peek() != c) fail("expected '$c', found ${describe(peek())}")
        i++
    }

    /** The current character, or NUL at the end (never valid where it's checked). */
    private fun peek(): Char = if (i < s.length) s[i] else '\u0000'

    private fun column() = i - lineStart + 1

    private fun describe(c: Char) = if (i >= s.length) "the end of the file" else if (c < ' ') "U+%04X".format(c.code) else "'$c'"

    private fun fail(message: String): Nothing = throw JsonSyntaxException(line, column(), message)
}
