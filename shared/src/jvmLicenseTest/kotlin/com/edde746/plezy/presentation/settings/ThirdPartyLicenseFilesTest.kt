package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.DevicePlatform
import java.io.File
import java.security.MessageDigest
import java.util.zip.ZipFile
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Each app ships the licence texts of every notice it lists, and no others: the folders of licenses/ in the groups
 * licenses/apps.json gives that app, which its build copies into its bundled resources as licenses/<folder>, and the
 * folders of mpv-build's artefact, which its build takes as they are (ThirdPartyNotices.mpvLicenses). The APK also ships
 * the licence files its libraries carry for the code built into them.
 */
class ThirdPartyLicenseFilesTest {
    private val licenses = File(checkNotNull(System.getProperty("plezy.licensesDir")) { "Run through Gradle's licenseTest" })

    /** Each app's groups of licenses/. */
    private val groups: Map<String, List<String>> = Json.parseToJsonElement(licenses.resolve("apps.json").readText()).jsonObject
        .mapValues { (_, groups) -> groups.jsonArray.map { it.jsonPrimitive.content } }

    /** The platforms each app of [groups] is built for. */
    private val platforms = mapOf(
        "android" to listOf(DevicePlatform.ANDROID, DevicePlatform.ANDROID_TV),
        "windows" to listOf(DevicePlatform.WINDOWS),
        "linux" to listOf(DevicePlatform.LINUX),
        "ios" to listOf(DevicePlatform.IOS, DevicePlatform.IPADOS),
        "macos" to listOf(DevicePlatform.MACOS),
        "tvos" to listOf(DevicePlatform.TVOS),
    )

    /**
     * The licence texts in the licenses/ folder of each app's pinned mpv-build artefact that Gradle hands this test
     * (`plezy.mpvArtefact.<app>`): mpv-android's AAR, whose assets/licenses/ the APK merges, and the libmpv artifact
     * of this host's desktop app (Windows' on Windows, Linux's elsewhere), each text's path → its size. MPVKit's and the
     * other desktop's aren't fetched here: their apps' builds and UI tests check those.
     */
    private val artefacts: Map<String, Map<String, Long>> = buildMap {
        val aar = File(checkNotNull(System.getProperty("plezy.mpvArtefact.android")) { "Run through Gradle's licenseTest" })
        put("android", ZipFile(aar).use { zip ->
            zip.entries().asSequence().filter { !it.isDirectory && it.name.startsWith("assets/licenses/") }
                .associate { it.name.removePrefix("assets/licenses/") to it.size }
        })
        for (app in listOf("windows", "linux")) {
            val root = File(System.getProperty("plezy.mpvArtefact.$app") ?: continue, "licenses")
            put(app, root.walk().filter { it.isFile }.associate { it.relativeTo(root).invariantSeparatorsPath to it.length() })
        }
    }

    @Test
    fun everyGroupBelongsToAnAppAndHoldsOnlyTexts() {
        assertEquals(platforms.keys, groups.keys, "licenses/apps.json's apps")
        val folders = licenses.listFiles().orEmpty().filter { it.isDirectory }.map { it.name }.toSet()
        assertEquals(groups.values.flatten().toSet(), folders, "the groups in licenses/ and in licenses/apps.json")
        for (group in folders) {
            val empty = licenses.resolve(group).walk().filter { it.isFile && it.length() == 0L }.toList()
            assertEquals(emptyList(), empty, "empty licence texts in licenses/$group")
        }
    }

    /** mpv-build's artefact has a folder per component, each with a text, and among them mpv's, FFmpeg's and libass's. */
    @Test
    fun eachMpvBuildArtefactHoldsATextInEveryComponentsFolder() {
        for ((app, texts) in artefacts) {
            val folders = texts.keys.map { it.substringBefore('/') }.toSet()
            assertTrue(folders.containsAll(listOf("mpv", "ffmpeg", "libass")), "$app's mpv-build artefact has only $folders")
            val empty = folders.filter { folder -> texts.none { (path, size) -> path.startsWith("$folder/") && size > 0 } }
            assertEquals(emptyList(), empty, "$app's mpv-build artefact: folders without a licence text")
        }
    }

    @Test
    fun eachAppShipsTheTextsOfEveryNoticeItListsAndNoOthers() {
        for ((app, appGroups) in groups) {
            val shipped = appGroups.flatMap { group ->
                licenses.resolve(group).listFiles().orEmpty().filter { it.isDirectory }.map { "licenses/${it.name}" to group }
            }
            // mpv-build's artefact's folders, in the app's folder of them; unknown where this host lacks the artefact,
            // whose notices' texts go unchecked then. That folder as a whole, too, where the app's own aren't in it.
            val root = ThirdPartyNotices.mpvLicenses(platforms.getValue(app).first())
            val carried = artefacts[app]?.keys?.map { "$root/${it.substringBefore('/')}" }?.distinct()
            val whole = root.takeIf { carried != null && shipped.none { (folder, _) -> folder.startsWith("$root/") } }
            val twice = (shipped + carried.orEmpty().map { it to "mpv-build's artefact" })
                .groupBy({ it.first }, { it.second }).filterValues { it.size > 1 }
            assertEquals(emptyMap(), twice, "$app: folders in more than one of its groups and its mpv-build artefact")
            val folders = shipped.map { it.first } + carried.orEmpty() + listOfNotNull(whole)
            for (platform in platforms.getValue(app)) {
                val notices = ThirdPartyNotices.forPlatform(platform)
                assertEquals(emptyList(), notices.filter { it.texts.isEmpty() }.map { it.name }, "$platform: notices without licence texts")
                val missing = notices.flatMap { notice ->
                    notice.texts.filter { it !in folders && (carried != null || (it != root && !it.startsWith("$root/"))) }
                        .map { "${notice.name}: $it" }
                }
                assertEquals(emptyList(), missing, "$platform: licence texts its app doesn't ship")
                val listed = notices.flatMap { it.texts }.toSet()
                val unlisted = folders.filter { it !in listed && !(whole != null && whole in listed && it.startsWith("$whole/")) }
                assertEquals(emptyList(), unlisted, "$platform: shipped texts of no notice")
            }
            for ((folder, group) in shipped) {
                assertTrue(
                    licenses.resolve(group).resolve(folder.removePrefix("licenses/")).walk().any { it.isFile },
                    "licenses/$group/${folder.removePrefix("licenses/")} holds no licence text",
                )
            }
        }
    }

    /**
     * Every third_party_licenses.txt an AAR of the Android release build carries (Google's: the licences of the
     * open-source code built into it; the app's shippedLicenseFiles, "group:name:version sha256" per line) is among the
     * Android app's texts as `<folder>/<name>/third_party_licenses.txt`, byte for byte, and no other such file is: a
     * version that moves fails here until licenses/ has its file.
     */
    @Test
    fun theApkShipsTheLicenceFilesItsLibrariesCarry() {
        // Absent from a build without Android (PLEZY_ANDROID=false).
        val carried = System.getProperty("plezy.shippedLicenseFiles.android")?.let { File(it).readLines().filter(String::isNotBlank) } ?: return
        fun sha256(file: File) = MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }
        val shipped = groups.getValue("android").flatMap { group ->
            licenses.resolve(group).walk().filter { it.isFile && it.name == "third_party_licenses.txt" }.toList()
        }.associateBy { "${it.parentFile.name} ${sha256(it)}" }
        val wanted = carried.associateBy { line -> line.substringBefore(' ').split(':')[1] + " " + line.substringAfter(' ') }
        assertEquals(emptyList(), (wanted.keys - shipped.keys).map { wanted.getValue(it) }, "licence files of shipped AARs the APK lacks")
        assertEquals(emptyList(), (shipped.keys - wanted.keys).map { shipped.getValue(it).path }, "third_party_licenses.txt of no shipped AAR")
    }
}
