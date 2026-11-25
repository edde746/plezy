package plezy.buildlogic

import groovy.json.JsonSlurper
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.FileSystemOperations
import org.gradle.api.logging.Logger
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Internal
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.TaskAction
import org.gradle.process.ExecOperations
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.security.MessageDigest
import java.time.Duration
import javax.inject.Inject

/**
 * Fetches the prebuilt libmpv tarballs of the desktop groups pinned in the root `mpv-build.lock.json` (schema:
 * tools/set_native_revision.sh). The android group is an AAR, which Gradle resolves itself (settings.gradle.kts).
 *
 * Apply it and name the group:
 * ```
 * plugins { id("plezy.mpv-artifacts") }
 * mpvArtifacts { group.set("linux") }
 * ```
 * It registers `fetchMpv<Variant>` per variant in the lock (e.g. `fetchMpvX8664`) plus `fetchMpv` for all of
 * them. Each extracts into `build/mpv/<variant>/`. Downloads are verified against the lock's sha256 and cached in
 * `~/.gradle/caches/plezy-mpv/`, so every checkout and CI reuse them; concurrent builds may fetch the same asset there
 * ([fetchVerified]). A group or variant missing from the lock fails the build; there is no unpinned fallback.
 *
 * Each fetch also fails when `apple/project.yml`'s MPVKit revision (its `# mpv-build pin` line) differs from the
 * lock's apple commit: the two are written together by tools/set_native_revision.sh, and Xcode reads only the first.
 * The file is read only when a fetch runs, never while the build is configured: a build that fetches no libmpv (the
 * server's image, whose context has no `apple/`) configures this module without it.
 */
class MpvArtifactsPlugin : Plugin<Project> {
    override fun apply(project: Project) {
        val ext = project.extensions.create("mpvArtifacts", MpvArtifactsExtension::class.java)
        val lockFile = project.rootProject.layout.projectDirectory.file("mpv-build.lock.json")
        val aggregate = project.tasks.register("fetchMpv") {
            group = "mpv"
            description = "Fetches every pinned libmpv variant of this module's group."
        }
        project.afterEvaluate {
            val groupName = ext.group.orNull ?: throw GradleException("mpvArtifacts.group is not set in ${project.path}")
            // Read through Gradle's providers: a lock change then invalidates the configuration cache entry.
            val text = project.providers.fileContents(lockFile).asText.orNull
                ?: throw GradleException("Missing ${lockFile.asFile.path}; run tools/set_native_revision.sh")
            val lock = MpvLock.read(text)
            val projectYml = project.rootProject.layout.projectDirectory.file("apple/project.yml")
            val applePins = project.providers.fileContents(projectYml).asText.map(MpvLock::applePins)
            val group = lock.groups[groupName]
                ?: throw GradleException("mpv-build.lock.json has no '$groupName' group of tarballs")
            for ((variant, asset) in group.assets) {
                val task = project.tasks.register("fetchMpv${variant.taskSuffix()}", FetchMpvArtifact::class.java) {
                    this.group = "mpv"
                    description = "Fetches libmpv $groupName/$variant (${asset.name})."
                    url.set(asset.url)
                    sha256.set(asset.checksum)
                    assetName.set(asset.name)
                    outputDir.set(project.layout.buildDirectory.dir("mpv/$variant"))
                    appleCommit.set(lock.appleCommit)
                    this.applePins.set(applePins)
                    projectYmlPath.set(projectYml.asFile.path)
                }
                aggregate.configure { dependsOn(task) }
            }
        }
    }

    private fun String.taskSuffix(): String =
        split('-', '_', '.').joinToString("") { part -> part.replaceFirstChar { it.uppercase() } }
}

abstract class MpvArtifactsExtension {
    /** Lock group: `linux` or `windows`. */
    abstract val group: Property<String>
}

abstract class FetchMpvArtifact @Inject constructor(
    private val archives: ArchiveOperations,
    private val files: FileSystemOperations,
    private val exec: ExecOperations,
) : DefaultTask() {
    @get:Input abstract val url: Property<String>
    @get:Input abstract val sha256: Property<String>
    @get:Input abstract val assetName: Property<String>

    @get:OutputDirectory abstract val outputDir: DirectoryProperty

    /** The lock's apple commit, and the pins `apple/project.yml` holds (missing when the file is). */
    @get:Input abstract val appleCommit: Property<String>

    @get:Input @get:Optional abstract val applePins: ListProperty<String>

    @get:Internal abstract val projectYmlPath: Property<String>

    @get:Internal
    val cacheDir: File = File(System.getProperty("user.home"), ".gradle/caches/plezy-mpv")

    @TaskAction
    fun fetch() {
        MpvLock.checkApplePin(appleCommit.get(), applePins.orNull ?: throw GradleException("Missing ${projectYmlPath.get()}"))
        val archive = fetchVerified(url.get(), sha256.get(), File(cacheDir, assetName.get()), logger)
        val out = outputDir.get().asFile
        files.delete { delete(out) }
        out.mkdirs()
        val name = archive.name
        when {
            name.endsWith(".zip") -> files.copy { from(archives.zipTree(archive)); into(out) }
            name.endsWith(".tar.gz") || name.endsWith(".tgz") -> files.copy { from(archives.tarTree(archives.gzip(archive))); into(out) }
            // zstd is not in the JDK; system tar (bsdtar, or GNU tar with zstd) detects it on extraction.
            name.contains(".tar") -> exec.exec { commandLine("tar", "-xf", archive.absolutePath, "-C", out.absolutePath) }
            else -> throw GradleException("Unknown archive type: $name")
        }
    }
}

/**
 * Returns [target] holding [url]'s bytes, whose SHA-256 is [sha256], downloading them unless [target] already does.
 * [target]'s directory is shared by concurrent builds: each download writes a temp file of its own there, verifies it
 * and moves it into place atomically. A [target] another build moved in meanwhile is kept when valid (the temp is
 * deleted) and replaced when not. Temp files of killed builds are deleted a day on. A download that sends nothing for
 * [idleTimeout] fails.
 */
internal fun fetchVerified(url: String, sha256: String, target: File, logger: Logger, idleTimeout: Duration = Duration.ofMinutes(1)): File {
    if (target.isFile && sha256(target) == sha256) return target
    val dir = Files.createDirectories(target.toPath().parent)
    val stale = System.currentTimeMillis() - Duration.ofDays(1).toMillis()
    dir.toFile().listFiles { f -> f.name.endsWith(".part") && f.lastModified() < stale }?.forEach { it.delete() }
    val tmp = Files.createTempFile(dir, "${target.name}.", ".part")
    try {
        logger.lifecycle("Downloading $url")
        // HttpClient has no timeout between the bytes of a body; this connection's read timeout is one.
        val connection = URI(url).toURL().openConnection() as HttpURLConnection
        connection.connectTimeout = Duration.ofSeconds(30).toMillis().toInt()
        connection.readTimeout = idleTimeout.toMillis().toInt()
        try {
            if (connection.responseCode != 200) throw GradleException("GET $url -> HTTP ${connection.responseCode}")
            connection.inputStream.use { input -> Files.newOutputStream(tmp).use { input.copyTo(it) } }
        } finally {
            connection.disconnect()
        }
        val actual = sha256(tmp.toFile())
        if (actual != sha256) throw GradleException("Checksum mismatch for ${target.name}: expected $sha256, got $actual")
        // Another build may have moved the same bytes in while this one downloaded.
        if (target.isFile && sha256(target) == sha256) return target
        try {
            Files.move(tmp, target.toPath(), StandardCopyOption.ATOMIC_MOVE)
        } catch (e: IOException) {
            // Windows refuses to replace a file another build has open, which only a build extracting it does: valid.
            if (!(target.isFile && sha256(target) == sha256)) throw e
        }
        return target
    } finally {
        Files.deleteIfExists(tmp)
    }
}

private fun sha256(file: File): String {
    val md = MessageDigest.getInstance("SHA-256")
    // NIO opens it shareable for deletion on Windows, so another build can still replace it while this one reads.
    Files.newInputStream(file.toPath()).use { input ->
        val buf = ByteArray(1 shl 16)
        while (true) {
            val n = input.read(buf)
            if (n < 0) break
            md.update(buf, 0, n)
        }
    }
    return md.digest().joinToString("") { "%02x".format(it) }
}

internal data class MpvLock(val appleCommit: String, val groups: Map<String, Group>) {
    data class Group(val assets: Map<String, Asset>)

    /** [url]: the asset's own `assetBase` (its publish run's release), else its group's, then `/` and [name]. */
    data class Asset(val name: String, val checksum: String, val url: String)

    companion object {
        private val PIN = Regex("""(?m)^\s*revision:\s*([0-9a-f]{40})\s*# mpv-build pin""")

        /** The revisions of [projectYml]'s `revision: <sha> # mpv-build pin` lines. */
        fun applePins(projectYml: String): List<String> = PIN.findAll(projectYml).map { it.groupValues[1] }.toList()

        /** Fails unless [pins] is one pin, [appleCommit]. */
        fun checkApplePin(appleCommit: String, pins: List<String>) {
            if (pins != listOf(appleCommit)) {
                throw GradleException(
                    "apple/project.yml's MPVKit pin ${pins.ifEmpty { listOf("(none)") }.joinToString()} differs from " +
                        "mpv-build.lock.json's apple commit $appleCommit; run tools/set_native_revision.sh --only apple <rev>",
                )
            }
        }

        @Suppress("UNCHECKED_CAST")
        fun read(text: String): MpvLock {
            val root = JsonSlurper().parseText(text) as Map<String, Any?>
            if (root["formatVersion"] != 2) throw GradleException("Unsupported mpv-build.lock.json formatVersion ${root["formatVersion"]}")
            val artifacts = root["artifacts"] as Map<String, Map<String, Any?>>
            // The groups of tarballs; android's entry is the AAR.
            val groups = artifacts.filterValues { "assets" in it }.mapValues { (_, g) ->
                val assets = (g["assets"] as Map<String, Map<String, String>>).mapValues { (_, a) ->
                    val name = a.getValue("asset")
                    Asset(name, a.getValue("checksum"), "${a["assetBase"] ?: g["assetBase"] as String}/$name")
                }
                Group(assets)
            }
            val apple = artifacts["apple"] ?: throw GradleException("mpv-build.lock.json has no apple entry; run tools/set_native_revision.sh")
            return MpvLock(apple["commit"] as String, groups)
        }
    }
}
