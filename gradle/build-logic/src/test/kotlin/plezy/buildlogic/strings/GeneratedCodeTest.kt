package plezy.buildlogic.strings

import org.jetbrains.kotlin.cli.common.ExitCode
import org.jetbrains.kotlin.cli.common.messages.CompilerMessageSeverity
import org.jetbrains.kotlin.cli.common.messages.CompilerMessageSourceLocation
import org.jetbrains.kotlin.cli.common.messages.MessageCollector
import org.jetbrains.kotlin.cli.common.messages.MessageRenderer
import org.jetbrains.kotlin.cli.common.messages.PrintingMessageCollector
import org.jetbrains.kotlin.cli.jvm.K2JVMCompiler
import org.jetbrains.kotlin.config.Services
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.PrintStream
import java.net.URLClassLoader
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Generates code from a fixture catalog, compiles it with the real runtime (`-Werror`, so the output is also
 * warning-free) on the classpath shared gives them (build-logic's `stringsLibraries`) and calls it, so escaping,
 * signatures and fallback are checked as behavior rather than as text.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class GeneratedCodeTest {
    private val d = '$'
    private val sources = mapOf(
        "en" to """
            {
              "title": "Top level",
              "escaping": {
                "dollar": "Costs ${d} 5, \\${d}amount and ${d}amount${d}",
                "quotes": "Say \"hi\" for \\${d}{price}",
                "controls": "tab\there\nnew\r\u0001\u00ad\u2028end",
                "comment": "a /* b */ c */ /*",
                "unicode": "Łódź … 😀 \ud800",
                "adjacent": "${d}{a}${d}{b}text${d}a"
              },
              "order": "${d}{second} then ${d}first then ${d}{second}",
              "count": { "one": "${d}{label}: ${d}{n} item", "other": "${d}{label}: ${d}{n} items for ${d}{who}" },
              "only": { "other": "${d}{n} things" },
              "files": { "one": "${d}n file", "few": "${d}n files (few)", "many": "${d}n files (many)", "other": "${d}n files" },
              "format": { "movie": "Movie", "other": "Other" },
              "nested": { "deep": { "leaf": "Leaf" } },
              "keep": "Kept in English",
              "account": { "copy": "Copy", "description": { "repeat": "Repeat" } }
            }
        """,
        "de" to """
            {
              "order": "${d}{first} vor ${d}{second}",
              "count": { "one": "${d}{label}: ${d}{n} Element", "other": "${d}{label}: ${d}{n} Elemente für ${d}{who}" },
              "keep": "",
              "escaping": { "dollar": "Kostet ${d}{amount} ${d}" },
              "account": { "copy": "Kopieren" }
            }
        """,
        "pl" to """
            {
              "count": {
                "one": "${d}{label}: ${d}{n} element",
                "few": "${d}{label}: ${d}{n} elementy",
                "many": "${d}{label}: ${d}{n} elementów dla ${d}{who}",
                "other": "${d}{label}: ${d}{n} elementu"
              }
            }
        """,
        "ru" to """{ "files": { "one": "${d}{n} файл", "few": "${d}{n} файла", "many": "${d}{n} файлов", "other": "${d}{n} файла" } }""",
        "fr" to """{ "files": { "one": "${d}{n} fichier", "many": "${d}{n} de fichiers", "other": "${d}{n} fichiers" } }""",
        "ja" to """{ "only": { "other": "${d}{n}件" }, "files": { "other": "${d}{n}個のファイル" } }""",
        "pt" to """{ "title": "Topo (pt)", "keep": "Mantido (pt)" }""",
        "pt_BR" to """{ "title": "Topo (pt-BR)" }""",
        "zh" to """{ "title": "顶层" }""",
        "zh-Hant" to """{ "title": "頂層" }""",
    )

    private lateinit var dir: File
    private lateinit var loader: ClassLoader

    @BeforeAll
    fun compile() {
        dir = Files.createTempDirectory("strings-codegen").toFile()
        val generated = KotlinRenderer.render(CatalogReader.read(sources.map { (tag, json) ->
            StringsSource(tag, "$tag.i18n.json", json.trimIndent().encodeToByteArray())
        }))
        val src = dir.resolve("src")
        for ((path, text) in generated) src.resolve(path).apply { parentFile.mkdirs() }.writeText(text)
        val runtime = System.getProperty("plezy.stringsRuntime").split(File.pathSeparator).map(::File)
        val classpath = System.getProperty("plezy.stringsClasspath").split(File.pathSeparator).map(::File)
        val out = dir.resolve("classes")
        val log = ByteArrayOutputStream()
        val printer = PrintingMessageCollector(PrintStream(log), MessageRenderer.PLAIN_FULL_PATHS, false)
        // An error on an import line: the library that import names is missing from the classpath.
        val unresolved = mutableListOf<String>()
        val messages = object : MessageCollector by printer {
            override fun report(severity: CompilerMessageSeverity, message: String, location: CompilerMessageSourceLocation?) {
                val line = location?.lineContent?.trim().orEmpty()
                if (severity.isError && line.startsWith("import ")) {
                    unresolved += "${line.removePrefix("import ")} (${File(location!!.path).name}:${location.line})"
                }
                printer.report(severity, message, location)
            }
        }
        val compiler = K2JVMCompiler()
        val arguments = compiler.createArguments()
        // Common code, as in shared's commonMain: the generated code may use common-only annotations (@ObjCName).
        val files = (src.walk().filter { it.isFile } + runtime).map { it.path }.toList()
        compiler.parseArguments(
            arrayOf(
                "-no-stdlib", "-no-reflect", "-Werror", "-jvm-target", "17", "-Xmulti-platform",
                "-Xcommon-sources=${files.joinToString(",")}",
                "-classpath", classpath.joinToString(File.pathSeparator), "-d", out.path,
                *files.toTypedArray(),
            ),
            arguments,
        )
        val exit = compiler.exec(messages, Services.EMPTY, arguments)
        val hint = unresolved.takeIf { it.isNotEmpty() }
            ?.joinToString(prefix = "Unresolved imports, whose libraries go in build-logic's stringsLibraries: ", postfix = "\n")
            .orEmpty()
        assertEquals(ExitCode.OK, exit, hint + log)
        // Runs on the classpath it compiled against, without the test's own libraries (the compiler's among them).
        val urls = (listOf(out) + classpath).map { it.toURI().toURL() }.toTypedArray()
        loader = URLClassLoader(urls, ClassLoader.getPlatformClassLoader())
    }

    @AfterAll
    fun cleanup() {
        dir.deleteRecursively()
    }

    private fun obj(name: String): Any = loader.loadClass("${KotlinRenderer.PACKAGE}.$name").getField("INSTANCE").get(null)

    private fun get(obj: String, property: String): Any =
        obj(obj).let { it.javaClass.getMethod("get" + property.replaceFirstChar(Char::uppercaseChar)).invoke(it) }

    private fun call(obj: String, method: String, vararg args: Any): String = obj(obj).let { instance ->
        val types = args.map { if (it is Int) Int::class.javaPrimitiveType!! else it.javaClass }.toTypedArray()
        instance.javaClass.getMethod(method, *types).invoke(instance, *args) as String
    }

    private fun locale(tag: String) {
        obj("T").let { it.javaClass.getMethod("setLocale", String::class.java).invoke(it, tag) }
    }

    @Test
    fun literalTextSurvivesEscaping() {
        locale("en")
        assertEquals("Costs \$ 5, \$amount and 7\$", call("EscapingStrings", "dollar", "7"))
        assertEquals("Say \"hi\" for \${price}", get("EscapingStrings", "quotes"))
        assertEquals("tab\there\nnew\r\u0001\u00ad\u2028end", get("EscapingStrings", "controls"))
        assertEquals("a /* b */ c */ /*", get("EscapingStrings", "comment"))
        assertEquals("Łódź … 😀 \ud800", get("EscapingStrings", "unicode"))
        locale("de")
        assertEquals("Kostet 7 \$", call("EscapingStrings", "dollar", "7"))
    }

    @Test
    fun bothParameterSyntaxesAreParameters() {
        locale("en")
        assertEquals("ABtextA", call("EscapingStrings", "adjacent", "A", "B"))
    }

    @Test
    fun parametersFollowEnglishOrderAndTranslationsMayReorderThem() {
        locale("en")
        assertEquals("S then F then S", call("T", "order", "S", "F"))
        locale("de")
        assertEquals("F vor S", call("T", "order", "S", "F"))
    }

    @Test
    fun pluralTakesCountFirstThenParametersAndUsesEachLanguagesRules() {
        locale("en")
        assertEquals("L: 1 item", call("T", "count", 1, "L", "W"))
        assertEquals("L: 0 items for W", call("T", "count", 0, "L", "W"))
        locale("de")
        assertEquals("L: 1 Element", call("T", "count", 1, "L", "W"))
        assertEquals("L: 2 Elemente für W", call("T", "count", 2, "L", "W"))
        locale("pl")
        assertEquals("L: 1 element", call("T", "count", 1, "L", "W"))
        assertEquals("L: 22 elementy", call("T", "count", 22, "L", "W"))
        assertEquals("L: 5 elementów dla W", call("T", "count", 5, "L", "W"))
        assertEquals("L: 12 elementów dla W", call("T", "count", 12, "L", "W"))
        // Missing in pl: English text with English rules.
        assertEquals("3 things", call("T", "only", 3))
        locale("ja")
        assertEquals("1件", call("T", "only", 1))
    }

    @Test
    fun eachRuleFamilyPicksItsForms() {
        fun files(tag: String, vararg counts: Int) = counts.map { locale(tag); call("T", "files", it) }
        // English: one for 1, the rest other; the English "few" and "many" are never chosen.
        assertEquals(listOf("0 files", "1 file", "3 files", "1000000 files"), files("en", 0, 1, 3, 1_000_000))
        // Russian: one for …1 but …11, few for …2-…4 but …12-…14, many for the rest.
        assertEquals(listOf("1 файл", "2 файла", "5 файлов", "11 файлов", "21 файл", "22 файла"), files("ru", 1, 2, 5, 11, 21, 22))
        // French: one for 0 and 1, many for millions.
        assertEquals(listOf("0 fichier", "1 fichier", "2 fichiers", "1000000 de fichiers"), files("fr", 0, 1, 2, 1_000_000))
        // Japanese: one form.
        assertEquals(listOf("1個のファイル", "2個のファイル"), files("ja", 1, 2))
        // Portuguese has no "files": English text, English rules.
        assertEquals(listOf("0 files", "1 file"), files("pt", 0, 1))
    }

    @Test
    fun fallsBackPerKeyThroughTheLocaleChain() {
        locale("pt-BR")
        assertEquals("Topo (pt-BR)", get("T", "title"))
        assertEquals("Mantido (pt)", get("T", "keep"))
        assertEquals("S then F then S", call("T", "order", "S", "F"))
        // An empty translation is untranslated.
        locale("de")
        assertEquals("Kept in English", get("T", "keep"))
        locale("es")
        assertEquals("Top level", get("T", "title"))
        assertEquals("es", get("T", "locale"))
    }

    @Test
    fun traditionalChineseRegionsUseTheTraditionalFile() {
        locale("zh-TW")
        assertEquals("頂層", get("T", "title"))
        locale("zh-Hant-HK")
        assertEquals("頂層", get("T", "title"))
        locale("zh-CN")
        assertEquals("顶层", get("T", "title"))
    }

    @Test
    fun groupsNestAndAnOtherKeyBesideOthersIsAString() {
        locale("en")
        assertEquals("Leaf", get(get("T", "nested").javaClass.simpleName, "deep").let { get(it.javaClass.simpleName, "leaf") })
        assertEquals("Other", get("FormatStrings", "other"))
        assertEquals("Movie", get("FormatStrings", "movie"))
    }

    @Test
    fun keysThatArePoorSwiftNamesKeepTheirKotlinNames() {
        locale("de")
        assertEquals("Kopieren", get("AccountStrings", "copy"))
        assertEquals("Repeat", get("AccountDescriptionStrings", "repeat"))
        assertEquals("AccountDescriptionStrings", get("AccountStrings", "description").javaClass.simpleName)
    }
}
