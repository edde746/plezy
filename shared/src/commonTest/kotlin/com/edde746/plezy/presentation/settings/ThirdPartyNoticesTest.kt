package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.DevicePlatform
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class ThirdPartyNoticesTest {
    private val apple = setOf("SKIE", "SQLiter", "Stately", "Sentry Cocoa SDK")

    private val mac = setOf("Sparkle")
    private val android = setOf(
        "AndroidX Core", "AndroidX Activity", "AndroidX Browser", "Guava", "Accompanist", "libmpv-android", "LLVM libc++",
        "Sentry Android SDK", "Epitaph", "Sentry Native SDK", "libunwindstack",
    )
    private val desktop = setOf(
        "Skiko", "Android Open Source Project", "Skia", "ICU", "libpng", "libjpeg-turbo", "libwebp", "zlib", "Expat", "Wuffs",
        "SQLite JDBC", "SQLite", "kotlinx-datetime", "JetBrains Runtime API",
    )
    private val windows = setOf("OpenJDK", "SPIRV-Cross", "D3D12 Memory Allocator")
    private val linux = setOf(
        "JetBrains Runtime", "dbus-java", "Noto Sans", "Lua", "MuJS", "libdisplay-info", "bzip2", "piex", "DNG SDK",
    )

    /** Android's and the desktop's, never Apple's: Compose and the JVM libraries. */
    private val compose = setOf(
        "Compose Multiplatform", "Material 3 for Compose", "Navigation 3", "Lifecycle", "AndroidX", "Coil", "ZXing", "OkHttp", "Okio",
        "Public Suffix List", "SLF4J", "JSpecify", "JetBrains Java Annotations", "Sentry Java SDK",
    )

    /** Android's and Apple's, never the desktop's: the subtitle font libass falls back to. */
    private val subtitleFont = setOf("Go Noto Current")

    /** Every platform's: the player stack, the shared core. */
    private val common = setOf("mpv", "FFmpeg", "libass", "mpv-build", "Kotlin", "Ktor", "SQLDelight")

    private fun names(platform: String) = ThirdPartyNotices.forPlatform(platform).map { it.name }

    @Test
    fun eachPlatformListsItsOwnLibrariesAndNoneOfAnothers() {
        val own = listOf(DevicePlatform.IOS, DevicePlatform.IPADOS).associateWith { apple + subtitleFont } +
            mapOf(DevicePlatform.MACOS to apple + mac + subtitleFont, DevicePlatform.TVOS to apple + subtitleFont) +
            listOf(DevicePlatform.ANDROID, DevicePlatform.ANDROID_TV).associateWith { compose + android + subtitleFont } +
            mapOf(DevicePlatform.WINDOWS to compose + desktop + windows, DevicePlatform.LINUX to compose + desktop + linux)
        val platformOnly = apple + mac + android + desktop + windows + linux + compose + subtitleFont
        for ((platform, expected) in own) {
            val names = names(platform)
            assertEquals(names.distinct(), names, "$platform lists each notice once")
            assertTrue(names.containsAll(common + expected), "$platform misses ${(common + expected) - names.toSet()}")
            assertEquals(emptySet(), names.toSet().intersect(platformOnly - expected), "$platform lists another platform's")
        }
    }

    @Test
    fun anUnknownPlatformHasNoList() {
        assertFailsWith<IllegalArgumentException> { ThirdPartyNotices.forPlatform("webos") }
    }
}
