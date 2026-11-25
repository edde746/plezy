package plezy.buildlogic.strings

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class ValidationTest {
    private fun source(fileName: String, json: String) = StringsSource("shared/i18n/$fileName", fileName, json.encodeToByteArray())

    private fun errors(vararg sources: StringsSource): List<String> =
        assertFailsWith<StringsException> { KotlinRenderer.render(CatalogReader.read(sources.toList())) }.message!!.lines()

    private fun enErrors(json: String) = errors(source("en.i18n.json", json))

    private val en = source(
        "en.i18n.json",
        """
        {
          "player": {
            "paused": "Paused",
            "position": "${'$'}{position} / ${'$'}{duration}",
            "tracks": { "one": "${'$'}{n} track", "other": "${'$'}{n} tracks in ${'$'}{title}" }
          }
        }
        """.trimIndent(),
    )

    private fun deErrors(json: String) = errors(en, source("de.i18n.json", json))

    @Test
    fun invalidJsonNamesFileLineAndColumn() {
        assertEquals(
            listOf("shared/i18n/en.i18n.json:3:1: invalid JSON: expected a quoted key, found '}'"),
            enErrors("{\n  \"a\": \"x\",\n}"),
        )
        assertEquals(listOf("shared/i18n/en.i18n.json:1:12: invalid JSON: duplicate key \"a\""), enErrors("""{"a": "x", "a": "y"}"""))
        assertEquals(listOf("shared/i18n/en.i18n.json:1:9: invalid JSON: unterminated string"), enErrors("""{"a": "x"""))
        assertEquals(listOf("shared/i18n/en.i18n.json: invalid JSON: not UTF-8"), errors(StringsSource("shared/i18n/en.i18n.json", "en.i18n.json", byteArrayOf('"'.code.toByte(), 0xC3.toByte(), '"'.code.toByte()))))
        assertEquals(listOf("shared/i18n/en.i18n.json:1: the top level must be an object, found an array"), enErrors("[]"))
        assertEquals(listOf("shared/i18n/en.i18n.json:1:65: invalid JSON: nested deeper than 64 levels"), enErrors("[".repeat(100_000)))
    }

    @Test
    fun valuesMustBeStringsOrObjects() {
        assertEquals(listOf("shared/i18n/en.i18n.json:2: a.b: expected a string or an object, found a number"), enErrors("{\"a\": {\n\"b\": 5}}"))
    }

    @Test
    fun pluralWithoutOther() {
        assertEquals(listOf("shared/i18n/en.i18n.json:1: tracks: plural has no \"other\" form"), enErrors("""{"tracks": {"one": "x", "few": "y"}}"""))
        // A translation needs "other" too, once its empty forms (untranslated, so falling back) are dropped.
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.tracks: plural has no \"other\" form"),
            deErrors("""{"player": {"tracks": {"one": "${'$'}{n} Spur", "other": ""}}}"""),
        )
    }

    @Test
    fun unknownPluralCategory() {
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: tracks: unknown plural category \"several\" (allowed: zero, one, two, few, many, other)",
            ),
            enErrors("""{"tracks": {"one": "x", "several": "y", "other": "z"}}"""),
        )
        // English decides the shape: a translated plural is checked even when it only has "other" and a typo.
        assertEquals(
            listOf("shared/i18n/de.i18n.json:3: player.tracks: unknown plural category \"othr\" (allowed: zero, one, two, few, many, other)"),
            deErrors("{\"player\": {\"tracks\": {\n\"other\": \"${'$'}{n} Spuren in ${'$'}{title}\",\n\"othr\": \"x\"}}}"),
        )
    }

    @Test
    fun translationKeyMissingFromEnglish() {
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.stopped: not in en.i18n.json (every key must exist in English)"),
            deErrors("""{"player": {"stopped": "Gestoppt"}}"""),
        )
    }

    @Test
    fun translationParametersMustMatchEnglish() {
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.position: parameters {position} differ from en.i18n.json {duration, position}"),
            deErrors("""{"player": {"position": "${'$'}{position}"}}"""),
        )
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.position: parameters {dauer, position} differ from en.i18n.json {duration, position}"),
            deErrors("""{"player": {"position": "${'$'}{position} / ${'$'}{dauer}"}}"""),
        )
        // In plurals the count n is always available; the other parameters are compared across all forms.
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.tracks: parameters {} differ from en.i18n.json {title}"),
            deErrors("""{"player": {"tracks": {"one": "Eine Spur", "other": "${'$'}{n} Spuren"}}}"""),
        )
    }

    @Test
    fun translationMustKeepEnglishShape() {
        assertEquals(
            listOf("shared/i18n/de.i18n.json:1: player.tracks: expected a plural object as in en.i18n.json, found a string"),
            deErrors("""{"player": {"tracks": "${'$'}{n} Spuren"}}"""),
        )
        assertEquals(listOf("shared/i18n/de.i18n.json:1: player: expected a group as in en.i18n.json, found a string"), deErrors("""{"player": "x"}"""))
    }

    @Test
    fun keysMustBeKotlinIdentifiers() {
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: foo-bar: key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
                "shared/i18n/en.i18n.json:1: g.class: key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
                "shared/i18n/en.i18n.json:1: Upper: key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
                "shared/i18n/en.i18n.json:1: 2fa: key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
                "shared/i18n/en.i18n.json:1: locale: reserved at the top level (T.locale)",
            ),
            enErrors("""{"foo-bar": "a", "g": {"class": "b"}, "Upper": "c", "2fa": "d", "locale": "e", "ok_key2": "f"}"""),
        )
        // Slang's key modifiers and comments aren't supported.
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: count(param=n): key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
                "shared/i18n/en.i18n.json:1: @count: key must match [a-z][A-Za-z0-9_]* and not be a Kotlin keyword",
            ),
            enErrors("""{"count(param=n)": {"one": "x", "other": "y"}, "@count": "a comment"}"""),
        )
    }

    @Test
    fun aKeySwiftReadsUnderAnotherNameMayNotMeetThatName() {
        // `copy` is read as `copyText` in Swift (an NSObject member name); `switch` as `switchText` (a Swift keyword).
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: account.copy: Swift reads it as copyText, a key of the same group; rename one of them",
                "shared/i18n/en.i18n.json:1: switch: Swift reads it as switchText, a key of the same group; rename one of them",
            ),
            enErrors("""{"account": {"copy": "a", "copyText": "b", "description": "c"}, "switch": {"x": "d"}, "switchText": "e"}"""),
        )
    }

    @Test
    fun parametersMustBeWellFormed() {
        val rule = "use ${'$'}{name} or ${'$'}name with a name matching [a-z][A-Za-z0-9_]*, not a Kotlin keyword"
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: a: malformed parameter \"${'$'}{first name}\": $rule",
                "shared/i18n/en.i18n.json:1: b: malformed parameter \"${'$'}{in}\": $rule",
                "shared/i18n/en.i18n.json:1: c: malformed parameter \"${'$'}{open\": $rule",
                "shared/i18n/en.i18n.json:1: d: malformed parameter \"${'$'}5\": $rule",
                "shared/i18n/en.i18n.json:1: e: malformed parameter \"${'$'}Name\": $rule",
                "shared/i18n/en.i18n.json:1: f: malformed parameter \"${'$'}{n: int}\": $rule",
                "shared/i18n/en.i18n.json:1: g: malformed parameter \"${'$'}when\": $rule",
            ),
            enErrors(
                """{"a": "Hi ${'$'}{first name}", "b": "${'$'}{in}", "c": "x ${'$'}{open", "d": "Costs ${'$'}5", "e": "${'$'}Name",""" +
                    """ "f": "${'$'}{n: int}", "g": "${'$'}when", "h": "${'$'} and \\${'$'}name stay literal, as does 5${'$'}"}""",
            ),
        )
    }

    @Test
    fun backslashesOtherThanBeforeADollarFail() {
        val rule = "a backslash may only escape ${'$'} (\\${'$'} is a literal ${'$'}); slang reads any other as a Dart string escape"
        assertEquals(
            listOf("shared/i18n/en.i18n.json:1: a: $rule", "shared/i18n/en.i18n.json:1: b: $rule"),
            enErrors("""{"a": "C:\\Users", "b": "line\\n", "c": "\\${'$'}{x} costs \\${'$'}5"}"""),
        )
    }

    @Test
    fun linkedTranslationsFail() {
        assertEquals(
            listOf(
                "shared/i18n/en.i18n.json:1: b: linked translation \"@:a…\" isn't supported: write the text out",
                "shared/i18n/en.i18n.json:1: c: linked translation \"@:{a…\" isn't supported: write the text out",
            ),
            enErrors("""{"a": "A", "b": "See @:a", "c": "See @:{a}", "d": "Time 10@: 5"}"""),
        )
    }

    @Test
    fun localeFiles() {
        assertEquals(
            listOf("no en.i18n.json among [shared/i18n/de.i18n.json]: English is the base locale and defines every string"),
            errors(source("de.i18n.json", "{}")),
        )
        assertEquals(
            listOf(
                "shared/i18n/english.i18n.json: file name must be <BCP 47 language tag>.i18n.json (en, de, pt-BR, zh-Hant)",
                "shared/i18n/pt_br.i18n.json: locale pt-BR is already defined by shared/i18n/pt-BR.i18n.json",
            ),
            errors(en, source("english.i18n.json", "{}"), source("pt-BR.i18n.json", "{}"), source("pt_br.i18n.json", "{}")),
        )
    }

    @Test
    fun groupsThatWouldShareAClassName() {
        assertEquals(
            listOf("shared/i18n/en.i18n.json:1: aB.c: generates class ABCStrings, as does a.bC; rename one of them"),
            enErrors("""{"a": {"bC": {"x": "1"}}, "aB": {"c": {"x": "2"}}}"""),
        )
    }

    @Test
    fun everyProblemIsReportedAtOnce() {
        assertEquals(
            listOf(
                "shared/i18n/fr.i18n.json:1:1: invalid JSON: expected a value, found the end of the file",
                "shared/i18n/de.i18n.json:3: player.stopped: not in en.i18n.json (every key must exist in English)",
                "shared/i18n/de.i18n.json:4: player.position: parameters {} differ from en.i18n.json {duration, position}",
            ),
            errors(
                en,
                source("de.i18n.json", "{\"player\": {\n\"paused\": \"Pausiert\",\n\"stopped\": \"Gestoppt\",\n\"position\": \"–\"}}"),
                source("fr.i18n.json", ""),
            ),
        )
    }
}
