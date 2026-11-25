package plezy.buildlogic

import com.sun.net.httpserver.HttpServer
import org.gradle.api.GradleException
import org.gradle.testkit.runner.GradleRunner
import org.gradle.testkit.runner.TaskOutcome
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.InetSocketAddress
import java.nio.file.Files
import java.security.MessageDigest
import java.util.Collections
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** A variant's fetch task against the lock: what its own entry says reaches it, under the configuration cache too. */
class MpvArtifactsPluginTest {
    private val dir = Files.createTempDirectory("plezy-mpv-plugin").toFile()
    private val zips = mapOf("a.zip" to zip("lib-a.txt"), "b.zip" to zip("lib-b.txt"))
    private val requests = Collections.synchronizedList(mutableListOf<String>())

    // Serves every zip under any release path (`/<release>/<name>`, or `/<name>`) and records what was asked for.
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0).apply {
        createContext("/") { exchange ->
            requests += exchange.requestURI.path
            val body = zips.getValue(exchange.requestURI.path.substringAfterLast('/'))
            exchange.sendResponseHeaders(200, body.size.toLong())
            exchange.responseBody.use { it.write(body) }
        }
        start()
    }

    @AfterTest
    fun stop() {
        server.stop(0)
        dir.deleteRecursively()
    }

    private fun zip(entry: String): ByteArray {
        val bytes = ByteArrayOutputStream()
        ZipOutputStream(bytes).use { zip ->
            zip.putNextEntry(ZipEntry(entry))
            zip.write(entry.toByteArray())
            zip.closeEntry()
        }
        return bytes.toByteArray()
    }

    private fun sha256(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }

    private fun lock(x8664: String, aarch64: String) {
        fun asset(name: String) = """{"asset": "$name", "checksum": "${sha256(zips.getValue(name))}"}"""
        File(dir, "mpv-build.lock.json").writeText(
            """
            {
              "artifacts": {
                "apple": {"commit": "$APPLE_PIN"},
                "windows": {
                  "assetBase": "http://127.0.0.1:${server.address.port}",
                  "assets": {"x86_64": ${asset(x8664)}, "aarch64": ${asset(aarch64)}}
                }
              },
              "formatVersion": 2
            }
            """.trimIndent(),
        )
    }

    // The test writes the lock and builds at once, in one daemon. A watching daemon keeps what it hashed between builds
    // and learns of a change from the OS's file events, which may come after the next build has started: it would then
    // reuse the configuration cache entry of the lock before. Without watching each build hashes the files anew.
    private fun gradle(vararg args: String) =
        GradleRunner.create().withProjectDir(dir).withPluginClasspath().withArguments(*args, "--no-watch-fs").build()

    private fun fetch(): TaskOutcome? = gradle("fetchMpvX8664", "--configuration-cache").task(":fetchMpvX8664")?.outcome

    private fun projectYml(revision: String) =
        File(dir, "apple").apply { mkdirs() }.resolve("project.yml").writeText(
            "packages:\n  MPVKit:\n    url: https://github.com/edde746/mpv-build\n    revision: $revision # mpv-build pin\n",
        )

    private fun windowsProject() {
        projectYml(APPLE_PIN)
        File(dir, "settings.gradle").writeText("")
        File(dir, "build.gradle").writeText("plugins { id 'plezy.mpv-artifacts' }\nmpvArtifacts.group.set('windows')\n")
        // The download cache lives under the user's home: the test's own.
        File(dir, "gradle.properties").writeText("org.gradle.jvmargs=-Duser.home=${File(dir, "home").invariantSeparatorsPath}\n")
    }

    @Test
    fun aVariantFetchesAgainOnlyWhenItsOwnEntryChanges() {
        windowsProject()
        val out = File(dir, "build/mpv/x86_64")

        lock(x8664 = "a.zip", aarch64 = "a.zip")
        assertEquals(TaskOutcome.SUCCESS, fetch())
        assertEquals(listOf("lib-a.txt"), out.list()?.sorted())

        lock(x8664 = "a.zip", aarch64 = "b.zip")
        assertEquals(TaskOutcome.UP_TO_DATE, fetch(), "another variant's entry changed")

        lock(x8664 = "b.zip", aarch64 = "b.zip")
        assertEquals(TaskOutcome.SUCCESS, fetch())
        assertEquals(listOf("lib-b.txt"), out.list()?.sorted(), "the lock's new asset, not the cached configuration's")
    }

    @Test
    fun anApplePinThatDiffersFromTheLockFails() {
        MpvLock.checkApplePin(APPLE_PIN, MpvLock.applePins("    revision: $APPLE_PIN # mpv-build pin\n"))
        val error = assertFailsWith<GradleException> { MpvLock.checkApplePin(APPLE_PIN, MpvLock.applePins("    revision: ${"1".repeat(40)} # mpv-build pin\n")) }
        assertTrue("differs from mpv-build.lock.json's apple commit $APPLE_PIN" in error.message.orEmpty(), error.message)
        assertFailsWith<GradleException>("no pin line") { MpvLock.checkApplePin(APPLE_PIN, MpvLock.applePins("packages: {}\n")) }
    }

    /**
     * A build without `apple/` (the server's image, whose context leaves the apps out) configures the module and runs
     * what needs no libmpv; only a fetch reads `apple/project.yml`, and fails without it.
     */
    @Test
    fun aBuildWithoutTheAppleProjectConfiguresAndOnlyAFetchNeedsIt() {
        windowsProject()
        lock(x8664 = "a.zip", aarch64 = "a.zip")
        File(dir, "apple").deleteRecursively()

        assertEquals(TaskOutcome.SUCCESS, gradle("help", "--configuration-cache").task(":help")?.outcome)
        val failed = GradleRunner.create().withProjectDir(dir).withPluginClasspath()
            .withArguments("fetchMpvX8664", "--configuration-cache", "--no-watch-fs").buildAndFail()
        assertTrue("Missing " in failed.output && "apple/project.yml" in failed.output, failed.output)
        assertTrue(requests.isEmpty(), "nothing fetched: $requests")
    }

    /**
     * mpv-build uploads each publish run's assets to a release of its own, so one commit's variants can sit in
     * different releases: an asset with an `assetBase` of its own is fetched from there, one without from its group's.
     */
    @Test
    fun eachAssetIsFetchedFromItsOwnRelease() {
        windowsProject()
        val base = "http://127.0.0.1:${server.address.port}"
        File(dir, "mpv-build.lock.json").writeText(
            """
            {
              "artifacts": {
                "apple": {"commit": "$APPLE_PIN"},
                "windows": {
                  "assetBase": "$base/binaries-windows",
                  "assets": {
                    "x86_64": {"asset": "a.zip", "checksum": "${sha256(zips.getValue("a.zip"))}"},
                    "aarch64": {"asset": "b.zip", "checksum": "${sha256(zips.getValue("b.zip"))}", "assetBase": "$base/binaries-0123456789ab"}
                  }
                }
              },
              "formatVersion": 2
            }
            """.trimIndent(),
        )
        gradle("fetchMpv")

        assertEquals(
            listOf("/binaries-0123456789ab/b.zip", "/binaries-windows/a.zip"),
            requests.sorted(),
            "the older release's asset from the group base, the per-run release's from its own",
        )
        assertEquals(listOf("lib-a.txt"), File(dir, "build/mpv/x86_64").list()?.sorted())
        assertEquals(listOf("lib-b.txt"), File(dir, "build/mpv/aarch64").list()?.sorted())
    }

    private companion object {
        val APPLE_PIN = "0".repeat(40)
    }
}
