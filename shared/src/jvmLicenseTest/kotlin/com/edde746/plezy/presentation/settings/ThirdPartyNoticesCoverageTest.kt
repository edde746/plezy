package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.DevicePlatform
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Every module an app ships has its notice in that app's list: the Gradle modules of the Android release build, of the
 * desktop app (this host's: Linux, else Windows) and of Apple's framework, as Gradle resolves them, and the Swift
 * packages the Apple apps link. A module of a project without a notice fails here until the project's notice is in
 * [ThirdPartyNotices] and its modules' prefix in [notices].
 */
class ThirdPartyNoticesCoverageTest {
    /** Each project's notice by the prefix of its modules' `group:name`, which ends at a '.', ':' or '-'. */
    private val notices = mapOf(
        "androidx" to "AndroidX",
        "app.cash.sqldelight" to "SQLDelight",
        "co.touchlab.skie" to "SKIE",
        "co.touchlab:sqliter" to "SQLiter",
        "co.touchlab:stately" to "Stately",
        "com.abovevacant:epitaph" to "Epitaph",
        "com.android.billingclient" to "Google Play Billing Library",
        "com.github.hypfvieh:dbus-java" to "dbus-java",
        "com.google.accompanist" to "Accompanist",
        "com.google.android.datatransport" to "Firebase Android SDK",
        "com.google.android.gms" to "Google Play services",
        "com.google.firebase" to "Firebase Android SDK",
        "com.google.guava" to "Guava",
        "com.google.zxing" to "ZXing",
        "com.squareup.okhttp3" to "OkHttp",
        "com.squareup.okio" to "Okio",
        "dev.whyoleg.cryptography" to "cryptography-kotlin",
        "edde746:mpv-android" to "mpv-build",
        "io.coil-kt.coil3" to "Coil",
        "io.ktor" to "Ktor",
        "io.sentry:sentry" to "Sentry Java SDK",
        "io.sentry:sentry-android" to "Sentry Android SDK",
        "io.sentry:sentry-native-ndk" to "Sentry Native SDK",
        "javax.inject:javax.inject" to "javax.inject",
        "org.jetbrains:annotations" to "JetBrains Java Annotations",
        "org.jetbrains.androidx" to "Compose Multiplatform",
        "org.jetbrains.androidx.lifecycle" to "Lifecycle",
        "org.jetbrains.androidx.navigation3" to "Navigation 3",
        "org.jetbrains.compose" to "Compose Multiplatform",
        "org.jetbrains.compose.material3" to "Material 3 for Compose",
        "org.jetbrains.kotlin" to "Kotlin",
        "org.jetbrains.kotlinx:atomicfu" to "kotlinx-atomicfu",
        "org.jetbrains.kotlinx:kotlinx-coroutines" to "kotlinx.coroutines",
        "org.jetbrains.kotlinx:kotlinx-datetime" to "kotlinx-datetime",
        "org.jetbrains.kotlinx:kotlinx-io" to "kotlinx-io",
        "org.jetbrains.kotlinx:kotlinx-serialization" to "kotlinx.serialization",
        "org.jetbrains.runtime:jbr-api" to "JetBrains Runtime API",
        "org.jetbrains.skiko" to "Skiko",
        "org.jmdns:jmdns" to "JmDNS",
        "org.jspecify" to "JSpecify",
        "org.slf4j" to "SLF4J",
        "org.xerial:sqlite-jdbc" to "SQLite JDBC",
        "party.openwatch" to "Open Watch Party",
    )

    /** Each Swift package's notice by its name in apple/project.yml. */
    private val swiftNotices = mapOf(
        "MPVKit" to "mpv-build",
        "Nuke" to "Nuke",
        "Sentry" to "Sentry Cocoa SDK",
        "Sparkle" to "Sparkle",
    )

    private fun noticeOf(module: String): String? = notices.entries
        .filter { (prefix, _) -> module == prefix || module.startsWith(prefix) && module[prefix.length] in ".:-" }
        .maxByOrNull { it.key.length }?.value

    private fun property(name: String): String? = System.getProperty("plezy.$name")

    private fun required(name: String) = checkNotNull(property(name)) { "Run through Gradle's licenseTest" }

    @Test
    fun everyModuleAnAppShipsHasItsNotice() {
        val desktop = if (System.getProperty("os.name").startsWith("Linux")) DevicePlatform.LINUX else DevicePlatform.WINDOWS
        val shipped = buildMap {
            put(desktop, File(required("shippedModules.desktop")).readLines())
            // Absent from a build without Android (PLEZY_ANDROID=false).
            property("shippedModules.android")?.let { put(DevicePlatform.ANDROID, File(it).readLines()) }
            put(DevicePlatform.IOS, required("shippedModules.apple").split(','))
        }
        for ((platform, modules) in shipped) assertTrue(modules.any { it.isNotBlank() }, "$platform ships no modules")
        val unlisted = shipped.mapValues { (platform, modules) ->
            val listed = ThirdPartyNotices.forPlatform(platform).map { it.name }
            modules.filter { noticeOf(it) !in listed }
        }.filterValues { it.isNotEmpty() }
        assertEquals(emptyMap(), unlisted, "modules shipped without their notice")
    }

    @Test
    fun everySwiftPackageTheAppleAppsLinkHasItsNotice() {
        val project = File(required("appleProject")).readText()
        val linked = Regex("""^\s*- package: (\S+)""", RegexOption.MULTILINE).findAll(project).map { it.groupValues[1] }.toSet()
        val listed = listOf(DevicePlatform.IOS, DevicePlatform.IPADOS, DevicePlatform.MACOS, DevicePlatform.TVOS)
            .flatMap { ThirdPartyNotices.forPlatform(it) }.map { it.name }
        assertTrue(linked.isNotEmpty(), "apple/project.yml links no package")
        assertEquals(emptyList(), linked.filter { swiftNotices[it] !in listed }, "the Apple apps link these without their notice")
    }
}
