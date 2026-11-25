package plezy.buildlogic.strings

import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.CodingErrorAction

/** One `<tag>.i18n.json` file. [name] is the path shown in messages. */
internal class StringsSource(val name: String, val fileName: String, val bytes: ByteArray)

/** Every problem found in the sources, one per line, each naming the file (with line) and the key. */
internal class StringsException(message: String) : Exception(message)

/** CLDR plural categories, in the order generated `when` branches list them. */
internal enum class PluralCategory {
    ZERO, ONE, TWO, FEW, MANY, OTHER;

    val key = name.lowercase()
}

internal sealed class Node(val line: Int) {
    class Group(val children: Map<String, Node>, line: Int) : Node(line)
    class Text(val template: Template, line: Int) : Node(line)
    class Plural(val forms: Map<PluralCategory, Template>, line: Int) : Node(line) {
        /** Every parameter but the count `n`, in order of first appearance across the forms as written. */
        val params: List<String> = forms.values.flatMap { it.params }.distinct() - COUNT
    }
}

internal class Template(val parts: List<Part>) {
    val params: List<String> = parts.filterIsInstance<Part.Param>().map { it.name }.distinct()

    sealed class Part {
        data class Literal(val text: String) : Part()
        data class Param(val name: String) : Part()
    }
}

internal class Locale(val tag: String, val source: String, val root: Node.Group)

/** English first, then the translations sorted by tag. */
internal class Catalog(val locales: List<Locale>) {
    val base: Locale get() = locales.first()
}

/** A plural's count parameter: always `n: Int`, first. */
internal const val COUNT = "n"
internal const val BASE_TAG = "en"
internal const val SOURCE_SUFFIX = ".i18n.json"

/**
 * Swift's name for the accessor of [key] when the key itself would make a poor one: Swift keywords (backticks) and
 * `NSObject` member names, which the Objective-C export renames (`description_`) or Swift resolves to `NSObject`'s own
 * member (`copy()`). The generated accessor keeps [key] as its Kotlin name and carries `@ObjCName("<key>Text")`.
 */
internal fun swiftName(key: String): String? = if (key in SWIFT_RESERVED) "${key}Text" else null

private val SWIFT_RESERVED = setOf(
    // Swift keywords that a lower-case key could be.
    "associatedtype", "await", "case", "catch", "class", "default", "defer", "deinit", "do", "else", "enum", "extension",
    "fallthrough", "false", "fileprivate", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is",
    "let", "nil", "open", "operator", "precedencegroup", "private", "protocol", "public", "repeat", "rethrows", "return",
    "self", "static", "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "var",
    "where", "while",
    // NSObject's members.
    "alloc", "autorelease", "copy", "dealloc", "debugDescription", "description", "hash", "isProxy", "mutableCopy", "new",
    "release", "retain", "retainCount", "superclass", "zone",
)

/**
 * Parses and validates string sources in slang's layout, with slang's default (`dart`) string interpolation:
 * - nested objects are groups; `${name}` and `$name` are parameters (`$name` ends at the first character that isn't a
 *   letter, digit or `_`); `\$` is a literal `$`, as is a `$` that no name follows (`$ 5`, `5$`). Other backslashes,
 *   typed or formatted parameters (`${n: int}`) and slang's linked translations (`@:key`) aren't supported and fail;
 * - an object is a plural when it has any of the keys `zero`, `one`, `two`, `few`, `many`, or only `other`. An object
 *   holding `other` beside non-category keys is a group;
 * - keys and parameter names match [IDENTIFIER] and aren't Kotlin keywords, so they are Kotlin names as they stand and
 *   can't shadow the generated code's own references (`T`, `Locales`, `PluralCategory`). Slang's key modifiers
 *   (`key(param=count)`, `key(rich)`) and comments (`@key`) fail with them;
 * - a key that would be a poor Swift name ([swiftName]) is read as `<key>Text` in Swift, so its group may not also
 *   hold a `<key>Text`;
 * - English is the base: it defines every key and the shape. Other locales may omit keys and may leave strings empty
 *   (slang's `fallback_strategy: base_locale_empty_string`); both fall back to English. They may not add keys,
 *   or change a key's shape or its parameters.
 */
internal object CatalogReader {
    private val CATEGORIES = PluralCategory.entries.associateBy { it.key }
    private val IDENTIFIER = Regex("[a-z][A-Za-z0-9_]*")
    private val TAG = Regex("[A-Za-z]{2,3}([-_][A-Za-z0-9]{1,8})*")

    // Kotlin's hard keywords: not usable as property, function or parameter names without backticks.
    private val KEYWORDS = setOf(
        "as", "break", "class", "continue", "do", "else", "false", "for", "fun", "if", "in", "interface", "is", "null",
        "object", "package", "return", "super", "this", "throw", "true", "try", "typealias", "typeof", "val", "var",
        "when", "while",
    )

    /** Top-level keys that would clash with members of the generated `T`. */
    private val RESERVED_TOP_LEVEL = setOf("locale")

    private val LINK = Regex("@:(\\w|\\{\\w)")

    fun read(sources: List<StringsSource>): Catalog = Reading().read(sources)

    /** Canonical BCP 47 case (`zh-Hant`, `pt-BR`, `es-419`), or null if [raw] isn't a language tag. */
    private fun canonicalTag(raw: String): String? {
        if (!TAG.matches(raw)) return null
        return raw.split('-', '_').mapIndexed { index, part ->
            when {
                index == 0 -> part.lowercase()
                part.length == 4 && part.all { it.isLetter() } -> part.lowercase().replaceFirstChar { it.uppercase() }
                part.length == 2 && part.all { it.isLetter() } || part.length == 3 && part.all { it.isDigit() } -> part.uppercase()
                else -> part.lowercase()
            }
        }.joinToString("-")
    }

    private class Reading {
        private val errors = mutableListOf<String>()

        fun read(sources: List<StringsSource>): Catalog {
            val parsed = LinkedHashMap<String, Pair<StringsSource, JsonObject>>()
            for (source in sources.sortedBy { it.fileName }) {
                val tag = canonicalTag(source.fileName.removeSuffix(SOURCE_SUFFIX))
                if (tag == null) {
                    errors += "${source.name}: file name must be <BCP 47 language tag>$SOURCE_SUFFIX (en, de, pt-BR, zh-Hant)"
                    continue
                }
                parsed[tag]?.let {
                    errors += "${source.name}: locale $tag is already defined by ${it.first.name}"
                    continue
                }
                val json = try {
                    Json.parse(decodeUtf8(source.bytes))
                } catch (e: CharacterCodingException) {
                    errors += "${source.name}: invalid JSON: not UTF-8"
                    continue
                } catch (e: JsonSyntaxException) {
                    errors += "${source.name}:${e.line}:${e.column}: invalid JSON: ${e.message}"
                    continue
                }
                if (json !is JsonObject) {
                    errors += "${source.name}:${json.line}: the top level must be an object, found ${kind(json)}"
                    continue
                }
                parsed[tag] = source to json
            }

            val (baseSource, baseJson) = parsed[BASE_TAG] ?: run {
                if (sources.none { it.fileName == "$BASE_TAG$SOURCE_SUFFIX" }) {
                    errors += "no $BASE_TAG$SOURCE_SUFFIX among ${sources.map { it.name }}: English is the base locale and defines every string"
                }
                throw StringsException(errors.joinToString("\n"))
            }
            val fileErrors = errors.size
            val base = Locale(BASE_TAG, baseSource.name, baseGroup(baseSource.name, baseJson, path = ""))
            // Translations are checked against a valid English shape only; otherwise every English error would echo.
            if (errors.size > fileErrors) throw StringsException(errors.joinToString("\n"))
            val translations = parsed.filterKeys { it != BASE_TAG }.toSortedMap().map { (tag, value) ->
                val (source, json) = value
                Locale(tag, source.name, translatedGroup(source.name, json, base.root, path = ""))
            }
            if (errors.isNotEmpty()) throw StringsException(errors.joinToString("\n"))
            return Catalog(listOf(base) + translations)
        }

        private fun baseGroup(file: String, json: JsonObject, path: String): Node.Group {
            val children = LinkedHashMap<String, Node>()
            for ((key, value) in json.members) {
                val keyPath = join(path, key)
                when {
                    !IDENTIFIER.matches(key) || key in KEYWORDS ->
                        errors += "$file:${value.line}: $keyPath: key must match ${IDENTIFIER.pattern} and not be a Kotlin keyword"
                    swiftName(key)?.let { it in json.members } == true ->
                        errors += "$file:${value.line}: $keyPath: Swift reads it as ${swiftName(key)}, a key of the same group; rename one of them"
                    path.isEmpty() && key in RESERVED_TOP_LEVEL ->
                        errors += "$file:${value.line}: $keyPath: reserved at the top level (T.$key)"
                }
                children[key] = when (value) {
                    is JsonString -> Node.Text(template(file, keyPath, value), value.line)
                    is JsonObject -> if (isPlural(value)) plural(file, keyPath, value, dropEmpty = false) else baseGroup(file, value, keyPath)
                    is JsonOther -> {
                        errors += "$file:${value.line}: $keyPath: expected a string or an object, found ${value.kind}"
                        null
                    }
                } ?: continue
            }
            return Node.Group(children, json.line)
        }

        /** Reads a translation in the shape of [base]; returns only the keys it translates (non-empty). */
        private fun translatedGroup(file: String, json: JsonObject, base: Node.Group, path: String): Node.Group {
            val children = LinkedHashMap<String, Node>()
            for ((key, value) in json.members) {
                val keyPath = join(path, key)
                val where = "$file:${value.line}: $keyPath"
                val node = when (val english = base.children[key]) {
                    null -> {
                        errors += "$where: not in $BASE_TAG$SOURCE_SUFFIX (every key must exist in English)"
                        null
                    }
                    is Node.Group ->
                        if (value is JsonObject) translatedGroup(file, value, english, keyPath).takeIf { it.children.isNotEmpty() }
                        else mismatch(where, "a group", value)
                    is Node.Text -> when {
                        value !is JsonString -> mismatch(where, "a string", value)
                        value.value.isEmpty() -> null
                        else -> Node.Text(template(file, keyPath, value), value.line).also {
                            checkParams(where, it.template.params, english.template.params)
                        }
                    }
                    is Node.Plural ->
                        if (value !is JsonObject) mismatch(where, "a plural object", value)
                        else plural(file, keyPath, value, dropEmpty = true)?.also { checkParams(where, it.params, english.params) }
                }
                if (node != null) children[key] = node
            }
            return Node.Group(children, json.line)
        }

        /** Null when the plural is invalid (reported) or, with [dropEmpty], has no non-empty form. */
        private fun plural(file: String, path: String, json: JsonObject, dropEmpty: Boolean): Node.Plural? {
            val forms = LinkedHashMap<PluralCategory, Template>()
            var valid = true
            for ((key, value) in json.members) {
                val category = CATEGORIES[key]
                when {
                    category == null -> {
                        errors += "$file:${value.line}: $path: unknown plural category \"$key\" (allowed: ${CATEGORIES.keys.joinToString()})"
                        valid = false
                    }
                    value !is JsonString -> {
                        errors += "$file:${value.line}: $path.$key: a plural form must be a string, found ${kind(value)}"
                        valid = false
                    }
                    dropEmpty && value.value.isEmpty() -> {}
                    else -> forms[category] = template(file, "$path.$key", value)
                }
            }
            if (!valid) return null
            if (dropEmpty && forms.isEmpty()) return null
            if (PluralCategory.OTHER !in forms) {
                errors += "$file:${json.line}: $path: plural has no \"other\" form"
                return null
            }
            return Node.Plural(forms, json.line)
        }

        private fun template(file: String, path: String, json: JsonString): Template {
            val text = json.value
            val where = "$file:${json.line}: $path"
            LINK.find(text)?.let {
                errors += "$where: linked translation \"${it.value}…\" isn't supported: write the text out"
                return Template(emptyList())
            }
            val parts = mutableListOf<Template.Part>()
            val literal = StringBuilder()
            fun param(name: String?, shown: String): Boolean {
                if (name == null || !IDENTIFIER.matches(name) || name in KEYWORDS) {
                    errors += "$where: malformed parameter \"$shown\": use \${name} or \$name with a name matching ${IDENTIFIER.pattern}, not a Kotlin keyword"
                    return false
                }
                if (literal.isNotEmpty()) parts += Template.Part.Literal(literal.toString()).also { literal.clear() }
                parts += Template.Part.Param(name)
                return true
            }
            var i = 0
            while (i < text.length) {
                val next = text.getOrNull(i + 1)
                when {
                    text[i] == '\\' -> {
                        if (next != '$') {
                            errors += "$where: a backslash may only escape \$ (\\\$ is a literal \$); slang reads any other as a Dart string escape"
                            return Template(emptyList())
                        }
                        literal.append('$')
                        i += 2
                    }
                    text[i] == '$' && next == '{' -> {
                        val end = text.indexOf('}', i + 2)
                        val shown = if (end < 0) text.substring(i) else text.substring(i, end + 1)
                        if (!param(if (end < 0) null else text.substring(i + 2, end), shown)) return Template(emptyList())
                        i = end + 1
                    }
                    text[i] == '$' && next != null && next.isWordChar() -> {
                        var end = i + 1
                        while (end < text.length && text[end].isWordChar()) end++
                        val name = text.substring(i + 1, end)
                        if (!param(name, "\$$name")) return Template(emptyList())
                        i = end
                    }
                    else -> literal.append(text[i++])
                }
            }
            if (literal.isNotEmpty()) parts += Template.Part.Literal(literal.toString())
            return Template(parts)
        }

        /** A character of a `$name` parameter: what Dart's `\w` matches. */
        private fun Char.isWordChar() = this in 'a'..'z' || this in 'A'..'Z' || this in '0'..'9' || this == '_'

        private fun checkParams(where: String, translated: List<String>, english: List<String>) {
            if (translated.toSet() != english.toSet()) {
                errors += "$where: parameters ${translated.sorted().braced()} differ from $BASE_TAG$SOURCE_SUFFIX ${english.sorted().braced()}"
            }
        }

        private fun mismatch(where: String, expected: String, found: JsonValue): Node? {
            errors += "$where: expected $expected as in $BASE_TAG$SOURCE_SUFFIX, found ${kind(found)}"
            return null
        }
    }

    private fun isPlural(json: JsonObject): Boolean {
        val keys = json.members.keys
        return keys.any { it != PluralCategory.OTHER.key && it in CATEGORIES } || keys == setOf(PluralCategory.OTHER.key)
    }

    private fun kind(json: JsonValue) = when (json) {
        is JsonString -> "a string"
        is JsonObject -> "an object"
        is JsonOther -> json.kind
    }

    private fun join(path: String, key: String) = if (path.isEmpty()) key else "$path.$key"

    private fun List<String>.braced() = joinToString(", ", "{", "}")

    private fun decodeUtf8(bytes: ByteArray): String = Charsets.UTF_8.newDecoder()
        .onMalformedInput(CodingErrorAction.REPORT)
        .onUnmappableCharacter(CodingErrorAction.REPORT)
        .decode(ByteBuffer.wrap(bytes))
        .toString()
}
