package plezy.buildlogic.strings

import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * Generates the Kotlin string accessors (`T`) from the module's `i18n/<locale>.i18n.json` files (`shared/i18n/`);
 * error messages name them by their path from the repository's root. The semantics are in
 * [CatalogReader], the generated shape in [KotlinRenderer].
 *
 * It registers `generateStrings`; the module adds the output as a source directory, which makes every task that
 * compiles it depend on the generator:
 * ```
 * plugins { id("plezy.strings") }
 * kotlin { sourceSets { commonMain { kotlin.srcDir(tasks.named("generateStrings")) } } }
 * ```
 * It also registers `generateInfoPlistStrings` for the Apple apps ([GenerateInfoPlistStrings]).
 */
class StringsPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        val sourceDir = project.layout.projectDirectory.dir("i18n")
        val root = project.layout.settingsDirectory
        val generate = project.tasks.register("generateStrings", GenerateStrings::class.java) {
            group = "build"
            description = "Generates the Kotlin string accessors (T) from the module's i18n/*.i18n.json."
            sources.from(project.fileTree(sourceDir) { include("*$SOURCE_SUFFIX") })
            displayRoot.set(root)
            outputDir.set(project.layout.buildDirectory.dir("generated/plezy/strings/commonMain/kotlin"))
        }
        // IDE sync resolves sources without compiling; have it generate them too.
        project.tasks.named { it == "prepareKotlinIdeaImport" }.configureEach { dependsOn(generate) }
        project.tasks.register("generateInfoPlistStrings", GenerateInfoPlistStrings::class.java) {
            group = "build"
            description = "Generates the Apple apps' <locale>.lproj/InfoPlist.strings from the module's i18n/*.i18n.json."
            sources.from(project.fileTree(sourceDir) { include("*$SOURCE_SUFFIX") })
            displayRoot.set(root)
            outputDir.set(project.layout.buildDirectory.dir("generated/plezy/strings/apple"))
        }
    }
}

@CacheableTask
abstract class GenerateStrings : DefaultTask() {
    /** The `<tag>.i18n.json` files; the file name is the locale. */
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NAME_ONLY)
    abstract val sources: ConfigurableFileCollection

    /** Error messages show source paths relative to this directory. */
    @get:Internal
    abstract val displayRoot: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun generate() {
        val root = displayRoot.get().asFile
        val files = sources.files.map { StringsSource(it.relativeToOrSelf(root).path, it.name, it.readBytes()) }
        val output = try {
            KotlinRenderer.render(CatalogReader.read(files))
        } catch (e: StringsException) {
            throw GradleException("Invalid string sources:\n${e.message}")
        }
        val dir = outputDir.get().asFile
        dir.deleteRecursively()
        for ((path, text) in output) dir.resolve(path).apply { parentFile.mkdirs() }.writeText(text)
    }
}

/**
 * Writes `<locale>.lproj/InfoPlist.strings` for every locale: the Info.plist keys whose text people read (the local
 * network prompt's purpose), from the strings [INFO_PLIST_KEYS] names, English where a translation lacks one. The Apple
 * apps' Kotlin phase (apple/project.yml) runs it and copies the folders into the app, where the system reads them; the
 * Info.plist itself holds the English text too (project.yml's `INFOPLIST_KEY_*`), as the key's base value.
 */
@CacheableTask
abstract class GenerateInfoPlistStrings : DefaultTask() {
    /** The `<tag>.i18n.json` files; the file name is the locale. */
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NAME_ONLY)
    abstract val sources: ConfigurableFileCollection

    /** Error messages show source paths relative to this directory. */
    @get:Internal
    abstract val displayRoot: DirectoryProperty

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun generate() {
        val root = displayRoot.get().asFile
        val files = sources.files.map { StringsSource(it.relativeToOrSelf(root).path, it.name, it.readBytes()) }
        val catalog = try {
            CatalogReader.read(files)
        } catch (e: StringsException) {
            throw GradleException("Invalid string sources:\n${e.message}")
        }
        val dir = outputDir.get().asFile
        dir.deleteRecursively()
        for (locale in catalog.locales) {
            val entries = INFO_PLIST_KEYS.map { (plistKey, path) ->
                plistKey to (text(locale.root, path) ?: text(catalog.base.root, path)
                    ?: throw GradleException("$BASE_TAG$SOURCE_SUFFIX has no string $path for the Info.plist's $plistKey"))
            }
            dir.resolve("${locale.tag}.lproj/InfoPlist.strings").apply { parentFile.mkdirs() }.writeText(plist(entries))
        }
    }

    private fun text(group: Node.Group, path: String): String? {
        val node = path.split('.').fold<String, Node?>(group) { node, key -> (node as? Node.Group)?.children?.get(key) }
        val parts = (node as? Node.Text)?.template?.parts ?: return null
        if (parts.any { it is Template.Part.Param }) throw GradleException("$path: an Info.plist string takes no parameters")
        return parts.joinToString("") { (it as Template.Part.Literal).text }
    }

    /** An XML property list: a `.strings` table may be one, as Xcode's own compiled tables are (binary ones). */
    private fun plist(entries: List<Pair<String, String>>): String = buildString {
        appendLine("""<?xml version="1.0" encoding="UTF-8"?>""")
        appendLine("""<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">""")
        appendLine("""<plist version="1.0">""")
        appendLine("<dict>")
        for ((key, value) in entries) {
            appendLine("\t<key>$key</key>")
            appendLine("\t<string>${value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")}</string>")
        }
        appendLine("</dict>")
        appendLine("</plist>")
    }

    private companion object {
        /** Info.plist key → its string in the i18n files. */
        val INFO_PLIST_KEYS = mapOf("NSLocalNetworkUsageDescription" to "app.localNetworkUsage")
    }
}
