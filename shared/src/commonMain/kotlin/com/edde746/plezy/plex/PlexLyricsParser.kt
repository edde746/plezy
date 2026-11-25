package com.edde746.plezy.plex

import com.edde746.plezy.model.LyricLine
import com.edde746.plezy.model.Lyrics
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/*
 * Plex's lyrics endpoint (`/library/streams/{id}`) answers with a `MediaContainer > Lyrics > Line > Span` document:
 * JSON when asked for it, XML from older servers and proxies, and the raw LRC or text sidecar from implementations
 * that expose the file itself.
 */

/** A decoded response body: a JSON object, or a string body read as [parsePlexLyricsResponse] text. */
fun parsePlexLyricsResponse(raw: JsonElement?): Lyrics? = when {
    raw is JsonObject -> parseJsonLyrics(raw)
    raw is JsonPrimitive && raw.isString -> parsePlexLyricsResponse(raw.content)
    else -> null
}

/** A text body: XML (null when malformed), a JSON object, else LRC or plain text. */
fun parsePlexLyricsResponse(raw: String): Lyrics? {
    val trimmed = raw.trimStart()
    if (trimmed.isEmpty()) return null
    if (trimmed.startsWith("<")) {
        val document = try {
            parseXml(trimmed)
        } catch (_: XmlSyntaxException) {
            return null
        }
        return parseXmlLyrics(document)
    }
    if (trimmed.startsWith("{")) {
        val decoded = try {
            Json.parseToJsonElement(trimmed)
        } catch (_: SerializationException) {
            return null
        }
        if (decoded is JsonObject) return parseJsonLyrics(decoded)
    }
    return parseLrc(raw)
}

private class ParsedLine(val text: String, val startMs: Long?)

/** One value or a list of them, as Plex's XML-to-JSON path sends either. */
private fun JsonElement?.flexList(): List<JsonElement> = when (this) {
    null, JsonNull -> emptyList()
    is JsonArray -> this
    else -> listOf(this)
}

private fun JsonObject.text(): String? = get("text").scalarString() ?: get("Text").scalarString()

private fun parseJsonLyrics(response: JsonObject): Lyrics? {
    val container = response["MediaContainer"] as? JsonObject ?: return null
    for (rawLyrics in container["Lyrics"].flexList()) {
        if (rawLyrics !is JsonObject) continue
        val parsed = ArrayList<ParsedLine>()
        for (rawLine in rawLyrics["Line"].flexList()) {
            if (rawLine is JsonPrimitive && rawLine.isString) {
                val text = rawLine.content.trim()
                if (text.isNotEmpty()) parsed += ParsedLine(text, null)
                continue
            }
            if (rawLine !is JsonObject) continue
            val spans = rawLine["Span"].flexList()
            val text = if (spans.isEmpty()) {
                rawLine.text()?.trim() ?: ""
            } else {
                spans.joinToString("") { span -> if (span is JsonObject) span.text() ?: "" else span.scalarString() ?: "" }.trim()
            }
            if (text.isEmpty()) continue
            val firstSpan = spans.firstOrNull { it is JsonObject } as JsonObject?
            parsed += ParsedLine(text, rawLine["startOffset"].flexLong() ?: firstSpan?.get("startOffset").flexLong())
        }
        buildLyrics(parsed, timed = rawLyrics["timed"].flexBoolOrNull())?.let { return it }
    }
    return null
}

private fun parseXmlLyrics(document: XmlElement): Lyrics? {
    for (lyrics in document.descendants("Lyrics")) {
        val parsed = ArrayList<ParsedLine>()
        for (line in lyrics.children("Line")) {
            val spans = line.children("Span")
            val text = if (spans.isEmpty()) {
                (line.attributes["text"] ?: line.innerText).trim()
            } else {
                spans.joinToString("") { it.attributes["text"] ?: it.innerText }.trim()
            }
            if (text.isEmpty()) continue
            val startMs = line.attributes["startOffset"]?.toLongOrNull() ?: spans.firstOrNull()?.attributes?.get("startOffset")?.toLongOrNull()
            parsed += ParsedLine(text, startMs)
        }
        buildLyrics(parsed, timed = lyrics.attributes["timed"]?.let { it == "1" || it.equals("true", ignoreCase = true) })?.let { return it }
    }
    return null
}

/** Synced unless explicitly untimed or no line has an offset; offsets of unsynced lyrics are dropped. */
private fun buildLyrics(parsed: List<ParsedLine>, timed: Boolean?): Lyrics? {
    if (parsed.isEmpty()) return null
    val synced = timed != false && parsed.any { it.startMs != null }
    return Lyrics(synced = synced, lines = parsed.map { LyricLine(it.text, if (synced) it.startMs else null) })
}

/** `[mm:ss]`, `[mm:ss.x]` … `[mm:ss.xxx]`; a line may carry several. */
private val LRC_TIMESTAMP = Regex("""\[(\d{1,3}):(\d{1,2})(?:\.(\d{1,3}))?]""")

/** ID tags such as `[ar:Artist]` and `[offset:+120]`. */
private val LRC_ID_TAG = Regex("""^\[([a-zA-Z#]+):(.*)]$""")

private val LINE_BREAK = Regex("""\r?\n""")

/**
 * LRC: each timestamp of a line becomes a synced line (sorted by time, the `[offset:±ms]` tag applied, floored at 0).
 * Text without any timestamp is plain unsynced lines; blank input is null.
 */
private fun parseLrc(raw: String): Lyrics? {
    val lines = ArrayList<LyricLine>()
    val plain = ArrayList<String>()
    var offsetMs = 0L
    for (rawLine in raw.split(LINE_BREAK)) {
        val line = rawLine.trim()
        if (line.isEmpty()) continue
        val idTag = LRC_ID_TAG.find(line)
        if (idTag != null && !LRC_TIMESTAMP.containsMatchIn(line)) {
            if (idTag.groupValues[1].lowercase() == "offset") offsetMs = idTag.groupValues[2].trim().toLongOrNull() ?: 0
            continue
        }
        val stamps = LRC_TIMESTAMP.findAll(line).toList()
        if (stamps.isEmpty()) {
            plain += line
            continue
        }
        val text = line.substring(stamps.last().range.last + 1).trim()
        for (stamp in stamps) {
            val minutes = stamp.groupValues[1].toLong()
            val seconds = stamp.groupValues[2].toLong()
            // The fraction scales by its digit count: ".5" and ".50" are both 500 ms.
            val fraction = stamp.groups[3]?.value
            val fractionMs = if (fraction == null) 0L else (fraction.toLong() * 1000 / pow10(fraction.length)).coerceIn(0L, 999L)
            val startMs = (minutes * 60 + seconds) * 1000 + fractionMs - offsetMs
            lines += LyricLine(text, startMs.coerceAtLeast(0))
        }
    }
    if (lines.isNotEmpty()) return Lyrics(synced = true, lines = lines.sortedBy { it.startMs })
    if (plain.isNotEmpty()) return Lyrics(synced = false, lines = plain.map { LyricLine(it) })
    return null
}

private fun pow10(digits: Int): Long = when (digits) {
    1 -> 10
    2 -> 100
    else -> 1000
}

/* A minimal XML reader for the lyrics document: elements, attributes, text, CDATA; comments and declarations skipped. */

private class XmlSyntaxException(message: String) : Exception(message)

private class XmlElement(val name: String, val attributes: Map<String, String>) {
    /** [XmlElement] or [String] text, in document order. */
    val content = ArrayList<Any>()

    fun children(name: String): List<XmlElement> = content.filterIsInstance<XmlElement>().filter { it.name == name }

    fun descendants(name: String): Sequence<XmlElement> = sequence {
        for (child in content) {
            if (child !is XmlElement) continue
            if (child.name == name) yield(child)
            yieldAll(child.descendants(name))
        }
    }

    val innerText: String
        get() = content.joinToString("") { if (it is XmlElement) it.innerText else it as String }
}

/** The document as a synthetic root holding its top-level element; throws [XmlSyntaxException] when malformed. */
private fun parseXml(text: String): XmlElement {
    val document = XmlElement("", emptyMap())
    val stack = arrayListOf(document)
    var i = 0
    fun fail(what: String): Nothing = throw XmlSyntaxException("$what at $i")
    fun skipPast(terminator: String) {
        val end = text.indexOf(terminator, i)
        if (end < 0) fail("Unterminated markup")
        i = end + terminator.length
    }
    while (i < text.length) {
        if (text[i] != '<') {
            val end = text.indexOf('<', i).let { if (it < 0) text.length else it }
            val chunk = text.substring(i, end)
            if (stack.size > 1) stack.last().content += decodeEntities(chunk) else if (chunk.isNotBlank()) fail("Text outside the root")
            i = end
            continue
        }
        when {
            text.startsWith("<?", i) -> skipPast("?>")
            text.startsWith("<!--", i) -> skipPast("-->")
            text.startsWith("<![CDATA[", i) -> {
                val start = i + 9
                skipPast("]]>")
                if (stack.size == 1) fail("CDATA outside the root")
                stack.last().content += text.substring(start, i - 3)
            }
            text.startsWith("<!", i) -> skipPast(">")
            text.startsWith("</", i) -> {
                val end = text.indexOf('>', i)
                if (end < 0) fail("Unterminated end tag")
                val name = text.substring(i + 2, end).trim()
                if (stack.size == 1 || stack.last().name != name) fail("Mismatched end tag </$name>")
                stack.removeAt(stack.lastIndex)
                i = end + 1
            }
            else -> {
                i++
                val nameStart = i
                while (i < text.length && !text[i].isWhitespace() && text[i] != '>' && text[i] != '/') i++
                val name = text.substring(nameStart, i)
                if (name.isEmpty()) fail("Empty tag name")
                val attributes = LinkedHashMap<String, String>()
                while (true) {
                    while (i < text.length && text[i].isWhitespace()) i++
                    if (i >= text.length) fail("Unterminated tag <$name>")
                    if (text[i] == '>' || text.startsWith("/>", i)) break
                    val attrStart = i
                    while (i < text.length && text[i] != '=' && !text[i].isWhitespace() && text[i] != '>') i++
                    val attrName = text.substring(attrStart, i)
                    while (i < text.length && text[i].isWhitespace()) i++
                    if (i >= text.length || text[i] != '=') fail("Attribute without a value")
                    i++
                    while (i < text.length && text[i].isWhitespace()) i++
                    val quote = text.getOrNull(i)?.takeIf { it == '"' || it == '\'' } ?: fail("Unquoted attribute value")
                    val valueEnd = text.indexOf(quote, i + 1)
                    if (valueEnd < 0) fail("Unterminated attribute value")
                    attributes[attrName] = decodeEntities(text.substring(i + 1, valueEnd))
                    i = valueEnd + 1
                }
                val element = XmlElement(name, attributes)
                if (stack.size == 1 && document.content.isNotEmpty()) fail("Second root element")
                stack.last().content += element
                if (text[i] == '>') {
                    stack += element
                    i++
                } else {
                    i += 2
                }
            }
        }
    }
    if (stack.size > 1) throw XmlSyntaxException("Unclosed element <${stack.last().name}>")
    if (document.content.isEmpty()) throw XmlSyntaxException("No root element")
    return document
}

private val ENTITY = Regex("""&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);""")

private fun decodeEntities(text: String): String = ENTITY.replace(text) { match ->
    val entity = match.groupValues[1]
    when {
        entity.startsWith("#x") -> codePoint(entity.substring(2).toInt(16))
        entity.startsWith("#") -> codePoint(entity.substring(1).toInt())
        entity == "lt" -> "<"
        entity == "gt" -> ">"
        entity == "amp" -> "&"
        entity == "quot" -> "\""
        entity == "apos" -> "'"
        else -> throw XmlSyntaxException("Unknown entity &$entity;")
    }
}

private fun codePoint(value: Int): String {
    if (value < 0x10000) return value.toChar().toString()
    val offset = value - 0x10000
    return charArrayOf((0xD800 + (offset shr 10)).toChar(), (0xDC00 + (offset and 0x3FF)).toChar()).concatToString()
}
