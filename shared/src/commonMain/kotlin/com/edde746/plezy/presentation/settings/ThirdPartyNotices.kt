package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.DevicePlatform

/**
 * A component this app ships or embeds, its licence (SPDX), where its source and licence text are ([url]), and the
 * folders of its licence texts in the app's bundled resources ([texts]: Android's assets, the desktop app's resources
 * folder, the Apple app's bundle), by default `licenses/<its name in lower case, spaces as dashes>`. The repository's
 * licenses/ folder holds them (licenses/README.md), but mpv-build's components': its artefact carries those
 * ([ThirdPartyNotices.mpvLicenses]).
 */
internal class ThirdPartyNotice(
    val name: String,
    val license: String,
    val url: String,
    val texts: List<String> = listOf("licenses/" + name.lowercase().replace(' ', '-')),
)

internal object ThirdPartyNotices {
    /**
     * What the app on [platform] (one of [DevicePlatform]: the device the graph runs on) ships, for every platform the
     * mpv player stack ([mpvStack]: mpv-build's GPL build, whose `versions.json` lists every native library per
     * platform), the player's video shaders (NVIDIA Image Scaling, ArtCNN, Anime4K) and the shared core's libraries,
     * then per platform:
     * - Android and desktop: Compose Multiplatform with the AndroidX libraries it builds on, Coil, ZXing (QR codes),
     *   Sentry's Java SDK (crash reports), and OkHttp (Ktor's engine there) with the libraries the JVM builds pull in;
     * - Android: AndroidX Core, Activity and Browser, Guava's ListenableFuture (AndroidX Core's), Accompanist (Coil's),
     *   Sentry's Android SDK with its native SDK (libsentry.so), and Play Billing with the Play services libraries it
     *   brings;
     * - desktop: Skiko's native library ([skikoNatives]) with the AOSP code Skiko's NOTICE names, the SQLite JDBC driver
     *   with its SQLite, JmDNS (finding cast receivers), and the Java runtime a distribution bundles (JetBrains Runtime
     *   on Linux; the build's OpenJDK on Windows), and on Linux dbus-java (MPRIS) and what the Flatpak adds
     *   (build-flatpak.py): Noto Sans, the UI font, and the Ubuntu libraries libmpv links there (Lua, MuJS,
     *   libdisplay-info, bzip2);
     * - Apple: SKIE's runtime in the framework, SQLDelight's native driver SQLiter, Sentry's Cocoa SDK and Nuke (image
     *   loading); on the Mac, Sparkle (updates);
     * - Android and Apple: Go Noto Current, the subtitle font libass falls back to (on Android with its Hangul
     *   companion, the same family).
     */
    fun forPlatform(platform: String): List<ThirdPartyNotice> = mpvStack(platform) + common + when (platform) {
        DevicePlatform.IOS, DevicePlatform.IPADOS -> apple + subtitleFont
        DevicePlatform.MACOS -> apple + subtitleFont + listOf(
            ThirdPartyNotice("Sparkle", "MIT AND BSD-2-Clause AND Zlib", "https://github.com/sparkle-project/Sparkle"),
        )
        DevicePlatform.TVOS -> apple + subtitleFont
        DevicePlatform.ANDROID, DevicePlatform.ANDROID_TV -> compose + android + subtitleFont
        DevicePlatform.WINDOWS -> skikoNatives(platform) + compose + desktop + listOf(
            ThirdPartyNotice("OpenJDK", JAVA_RUNTIME, "https://openjdk.org/legal/gplv2+ce.html"),
        )
        DevicePlatform.LINUX -> skikoNatives(platform) + compose + desktop + listOf(
            ThirdPartyNotice("JetBrains Runtime", JAVA_RUNTIME, "https://github.com/JetBrains/JetBrainsRuntime"),
            ThirdPartyNotice("dbus-java", "MIT", "https://github.com/hypfvieh/dbus-java"),
            // The Flatpak's own: its Noto Sans font and the Ubuntu libraries it adds (build-flatpak.py).
            ThirdPartyNotice("Noto Sans", "OFL-1.1", "https://github.com/notofonts/latin-greek-cyrillic"),
            ThirdPartyNotice("Lua", "MIT", "https://www.lua.org/license.html"),
            ThirdPartyNotice("MuJS", "ISC", "https://github.com/ccxvii/mujs"),
            ThirdPartyNotice("libdisplay-info", "MIT", "https://gitlab.freedesktop.org/emersion/libdisplay-info"),
            ThirdPartyNotice("bzip2", "bzip2-1.0.6", "https://sourceware.org/bzip2/"),
        )
        else -> throw IllegalArgumentException("no app is built for platform '$platform'")
    }

    /**
     * Where the app on [platform] has mpv-build's licence texts in its bundled resources: the licenses/ folder of
     * mpv-build's artefact, one folder per component linked, which mpv-build collects from the sources it built. The
     * APK's assets take mpv-android's AAR's beside the app's own licenses/ folders, the desktop app image the libmpv
     * artifact's beside libmpv in mpv/, and the Apple apps have MPVKit's resource bundle, which keeps its resources in
     * Contents/Resources on the Mac.
     */
    fun mpvLicenses(platform: String): String = when (platform) {
        DevicePlatform.ANDROID, DevicePlatform.ANDROID_TV -> "licenses"
        DevicePlatform.WINDOWS, DevicePlatform.LINUX -> "mpv/licenses"
        DevicePlatform.IOS, DevicePlatform.IPADOS, DevicePlatform.TVOS -> "MPVKit__MPVKit.bundle/licenses"
        DevicePlatform.MACOS -> "MPVKit__MPVKit.bundle/Contents/Resources/licenses"
        else -> throw IllegalArgumentException("no app is built for platform '$platform'")
    }

    /**
     * The mpv player stack on [platform], with its texts in mpv-build's artefact ([mpvLicenses]): the components About
     * names, each with its folder there, and mpv-build, whose page shows every component's texts: the whole folder, or
     * on Android, whose assets/licenses/ the app's own texts share, each of the AAR's folders ([mpvAndroidFolders]).
     * The Apple package takes the libraries outside mpv, FFmpeg, libass and libplacebo prebuilt, as XCFrameworks named
     * lib<name>, and names their folders so; Windows' build names FreeType's freetype2. On the desktop Skiko's HarfBuzz
     * notice, and on Linux its FreeType notice ([skikoNatives]), with Skiko's texts, stand for libmpv's too, whose texts
     * are on mpv-build's page; Linux's libmpv links the Flatpak runtime's FreeType, FriBidi and HarfBuzz. On Android
     * the AAR also holds libmpv-android's JNI glue under Plezy's (mpv-android/) and the NDK's libc++_shared.so, and the
     * texts of libdovi and the Rust standard library it is built with.
     */
    private fun mpvStack(platform: String): List<ThirdPartyNotice> {
        val root = mpvLicenses(platform)
        val apple = root.startsWith("MPVKit")
        val android = platform == DevicePlatform.ANDROID || platform == DevicePlatform.ANDROID_TV
        fun component(notice: ThirdPartyNotice, folder: String = notice.name.lowercase()) =
            ThirdPartyNotice(notice.name, notice.license, notice.url, listOf("$root/$folder"))
        fun prebuilt(notice: ThirdPartyNotice) = component(notice, (if (apple) "lib" else "") + notice.name.lowercase())
        val named = listOf(
            component(ThirdPartyNotice("mpv", "GPL-2.0-or-later", "https://github.com/mpv-player/mpv")),
            // Every platform's FFmpeg is configured with --enable-gpl --enable-version3.
            component(ThirdPartyNotice("FFmpeg", "GPL-3.0-or-later", "https://ffmpeg.org/legal.html")),
            component(ThirdPartyNotice("libass", "ISC", "https://github.com/libass/libass")),
            component(ThirdPartyNotice("libplacebo", "LGPL-2.1-or-later", "https://code.videolan.org/videolan/libplacebo")),
            prebuilt(ThirdPartyNotice("dav1d", "BSD-2-Clause", "https://code.videolan.org/videolan/dav1d")),
        ) + when (platform) {
            DevicePlatform.LINUX -> emptyList()
            DevicePlatform.WINDOWS -> listOf(component(freeType, "freetype2"), component(friBidi))
            else -> listOf(prebuilt(freeType), prebuilt(friBidi), prebuilt(harfBuzz))
        } + if (android) {
            listOf(
                component(ThirdPartyNotice("libmpv-android", "MIT", "https://github.com/jarnedemeulemeester/libmpv-android"), "mpv-android"),
                component(ThirdPartyNotice("LLVM libc++", "Apache-2.0 WITH LLVM-exception", "https://github.com/llvm/llvm-project/tree/main/libcxx"), "libc++"),
                component(ThirdPartyNotice("libdovi", "MIT", "https://github.com/quietvoid/dovi_tool/tree/main/dolby_vision")),
                component(ThirdPartyNotice("Rust standard library", "MIT OR Apache-2.0", "https://github.com/rust-lang/rust"), "rust-std"),
            )
        } else {
            emptyList()
        }
        val texts = if (android) mpvAndroidFolders.map { "$root/$it" } else listOf(root)
        return named + ThirdPartyNotice("mpv-build", "GPL-3.0-only", "https://github.com/edde746/mpv-build/blob/main/versions.json", texts)
    }

    /** The folders of mpv-android's AAR's assets/licenses/, which ThirdPartyLicenseFilesTest checks against the pinned AAR. */
    private val mpvAndroidFolders = listOf(
        "mpv", "ffmpeg", "libass", "libplacebo", "dav1d", "openssl", "freetype", "fribidi", "harfbuzz", "libunibreak", "lua",
        "libdovi", "rust-std", "libc++", "mpv-android",
    )

    /**
     * Skiko's native library on the desktop [platform]: Skiko, the Skia inside it and the libraries Skia builds in, at
     * the revisions Skia's DEPS pins at the tag Skiko builds, found in each platform's library by their strings
     * (licenses/README.md).
     */
    private fun skikoNatives(platform: String): List<ThirdPartyNotice> = skiko + when (platform) {
        DevicePlatform.WINDOWS -> skikoWindows
        DevicePlatform.LINUX -> skikoLinux
        else -> throw IllegalArgumentException("Skiko's native library ships on Windows and Linux, not '$platform'")
    }

    private const val JAVA_RUNTIME = "GPL-2.0-only WITH Classpath-exception-2.0"

    private val subtitleFont = ThirdPartyNotice("Go Noto Current", "OFL-1.1", "https://github.com/satbyy/go-noto-universal")

    private val freeType = ThirdPartyNotice("FreeType", "FTL OR GPL-2.0-or-later", "https://freetype.org/license.html")
    private val friBidi = ThirdPartyNotice("FriBidi", "LGPL-2.1-or-later", "https://github.com/fribidi/fribidi")
    private val harfBuzz = ThirdPartyNotice("HarfBuzz", "MIT-Modern-Variant", "https://github.com/harfbuzz/harfbuzz")

    private val common = listOf(
        // The standard library's own third-party parts (BSD-3-Clause, BSL-1.0) are listed there.
        ThirdPartyNotice("Kotlin", "Apache-2.0", "https://github.com/JetBrains/kotlin/tree/master/license"),
        ThirdPartyNotice("kotlinx.coroutines", "Apache-2.0", "https://github.com/Kotlin/kotlinx.coroutines"),
        ThirdPartyNotice("kotlinx.serialization", "Apache-2.0", "https://github.com/Kotlin/kotlinx.serialization"),
        ThirdPartyNotice("kotlinx-io", "Apache-2.0", "https://github.com/Kotlin/kotlinx-io"),
        ThirdPartyNotice("kotlinx-atomicfu", "Apache-2.0", "https://github.com/Kotlin/kotlinx-atomicfu"),
        ThirdPartyNotice("Ktor", "Apache-2.0", "https://github.com/ktorio/ktor"),
        ThirdPartyNotice("SQLDelight", "Apache-2.0", "https://github.com/sqldelight/sqldelight"),
        ThirdPartyNotice("cryptography-kotlin", "Apache-2.0", "https://github.com/whyoleg/cryptography-kotlin"),
        // Watch together.
        ThirdPartyNotice("Open Watch Party", "Apache-2.0", "https://github.com/edde746/openwatchparty"),
        // The player's video shaders, as their GLSL files ship. Anime4K's downscale step is under the Unlicense.
        ThirdPartyNotice("NVIDIA Image Scaling", "MIT", "https://gist.github.com/agyild/7e8951915b2bf24526a9343d951db214"),
        ThirdPartyNotice("ArtCNN", "MIT", "https://github.com/Artoriuz/ArtCNN"),
        ThirdPartyNotice("Anime4K", "MIT AND Unlicense", "https://github.com/bloc97/Anime4K"),
    )

    /** The texts of compose-multiplatform-core (Material 3, Navigation 3, Lifecycle: one repository). */
    private val composeCore = listOf("licenses/compose-multiplatform-core")

    /** Android and desktop: the Compose UI and the JVM libraries. */
    private val compose = listOf(
        ThirdPartyNotice("Compose Multiplatform", "Apache-2.0", "https://github.com/JetBrains/compose-multiplatform"),
        ThirdPartyNotice("Material 3 for Compose", "Apache-2.0", "https://github.com/JetBrains/compose-multiplatform-core", composeCore),
        ThirdPartyNotice("Navigation 3", "Apache-2.0", "https://github.com/JetBrains/compose-multiplatform-core", composeCore),
        ThirdPartyNotice("Lifecycle", "Apache-2.0", "https://github.com/JetBrains/compose-multiplatform-core", composeCore),
        ThirdPartyNotice("AndroidX", "Apache-2.0", "https://github.com/androidx/androidx"),
        ThirdPartyNotice("Coil", "Apache-2.0", "https://github.com/coil-kt/coil"),
        ThirdPartyNotice("ZXing", "Apache-2.0", "https://github.com/zxing/zxing"),
        ThirdPartyNotice("OkHttp", "Apache-2.0", "https://github.com/lysine-dev/okhttp"),
        ThirdPartyNotice("Okio", "Apache-2.0", "https://github.com/lysine-dev/okio"),
        // OkHttp embeds the list.
        ThirdPartyNotice("Public Suffix List", "MPL-2.0", "https://publicsuffix.org"),
        ThirdPartyNotice("SLF4J", "MIT", "https://github.com/qos-ch/slf4j"),
        ThirdPartyNotice("JSpecify", "Apache-2.0", "https://github.com/jspecify/jspecify"),
        ThirdPartyNotice("JetBrains Java Annotations", "Apache-2.0", "https://github.com/JetBrains/java-annotations"),
        // With code from other projects, whose texts its jar's META-INF/SENTRY_THIRD_PARTY_NOTICES.md carries.
        ThirdPartyNotice("Sentry Java SDK", "MIT AND Apache-2.0", "https://github.com/getsentry/sentry-java"),
    )

    /** AndroidX's texts, which its Android-only libraries share with [compose]'s. */
    private val androidX = listOf("licenses/androidx")

    private val android = listOf(
        ThirdPartyNotice("AndroidX Core", "Apache-2.0", "https://github.com/androidx/androidx", androidX),
        ThirdPartyNotice("AndroidX Activity", "Apache-2.0", "https://github.com/androidx/androidx", androidX),
        ThirdPartyNotice("AndroidX Browser", "Apache-2.0", "https://github.com/androidx/androidx", androidX),
        // AndroidX Core's ListenableFuture.
        ThirdPartyNotice("Guava", "Apache-2.0", "https://github.com/google/guava"),
        ThirdPartyNotice("Accompanist", "Apache-2.0", "https://github.com/google/accompanist"),
        // The same repository and texts as the Java SDK's.
        ThirdPartyNotice("Sentry Android SDK", "MIT", "https://github.com/getsentry/sentry-java", listOf("licenses/sentry-java-sdk")),
        ThirdPartyNotice("Epitaph", "MIT", "https://github.com/abovevacant/epitaph"),
        // libsentry.so, with AOSP's libunwindstack built in.
        ThirdPartyNotice("Sentry Native SDK", "MIT", "https://github.com/getsentry/sentry-native"),
        ThirdPartyNotice("libunwindstack", "Apache-2.0", "https://github.com/getsentry/libunwindstack-ndk"),
        // The Supporter purchase on Google Play: Play Billing, which brings Play services' base and location libraries
        // and Google's Android transport with Firebase's encoders (whose javax.inject annotations come along). The Play
        // services libraries' texts are the third_party_licenses.txt each carries.
        ThirdPartyNotice("Google Play Billing Library", "Android-SDK", "https://developer.android.com/google/play/billing"),
        ThirdPartyNotice("Google Play services", "Android-SDK", "https://developer.android.com/studio/terms"),
        ThirdPartyNotice("Firebase Android SDK", "Apache-2.0", "https://github.com/firebase/firebase-android-sdk"),
        ThirdPartyNotice("javax.inject", "Apache-2.0", "https://github.com/javax-inject/javax-inject"),
    )

    /** Both desktops' [skikoNatives]. */
    private val skiko = listOf(
        ThirdPartyNotice("Skiko", "Apache-2.0", "https://github.com/JetBrains/skiko"),
        ThirdPartyNotice("Skia", "BSD-3-Clause", "https://skia.org"),
        ThirdPartyNotice("ICU", "Unicode-3.0", "https://github.com/unicode-org/icu"),
        harfBuzz,
        ThirdPartyNotice("libpng", "libpng-2.0", "https://github.com/pnggroup/libpng"),
        ThirdPartyNotice("libjpeg-turbo", "IJG AND BSD-3-Clause AND Zlib", "https://github.com/libjpeg-turbo/libjpeg-turbo"),
        ThirdPartyNotice("libwebp", "BSD-3-Clause", "https://chromium.googlesource.com/webm/libwebp"),
        // Chromium's zlib, whose SIMD code is under Chromium's licence.
        ThirdPartyNotice("zlib", "Zlib AND BSD-3-Clause", "https://chromium.googlesource.com/chromium/src/third_party/zlib"),
        ThirdPartyNotice("Expat", "MIT", "https://github.com/libexpat/libexpat"),
        ThirdPartyNotice("Wuffs", "Apache-2.0", "https://github.com/google/wuffs"),
    )

    /** Skia's Direct3D backend. */
    private val skikoWindows = listOf(
        ThirdPartyNotice("SPIRV-Cross", "Apache-2.0", "https://github.com/KhronosGroup/SPIRV-Cross"),
        ThirdPartyNotice("D3D12 Memory Allocator", "MIT", "https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator"),
    )

    /** Skia's fonts through FreeType, and its RAW image decoding. */
    private val skikoLinux = listOf(
        freeType,
        ThirdPartyNotice("piex", "Apache-2.0", "https://github.com/google/piex"),
        ThirdPartyNotice("DNG SDK", "DNG SDK License Agreement", "https://android.googlesource.com/platform/external/dng_sdk"),
    )

    private val desktop = listOf(
        // Skiko's NOTICE: it contains code adapted from AOSP's frameworks/base.
        ThirdPartyNotice("Android Open Source Project", "Apache-2.0", "https://android.googlesource.com/platform/frameworks/base"),
        ThirdPartyNotice("SQLite JDBC", "Apache-2.0 AND BSD-2-Clause", "https://github.com/xerial/sqlite-jdbc"),
        ThirdPartyNotice("SQLite", "Public domain", "https://sqlite.org/copyright.html"),
        ThirdPartyNotice("kotlinx-datetime", "Apache-2.0", "https://github.com/Kotlin/kotlinx-datetime"),
        ThirdPartyNotice("JetBrains Runtime API", "Apache-2.0", "https://github.com/JetBrains/JetBrainsRuntimeApi"),
        ThirdPartyNotice("JmDNS", "Apache-2.0", "https://github.com/jmdns/jmdns"),
    )

    private val apple = listOf(
        ThirdPartyNotice("SKIE", "Apache-2.0", "https://github.com/touchlab/SKIE"),
        ThirdPartyNotice("SQLiter", "Apache-2.0", "https://github.com/touchlab/SQLiter"),
        ThirdPartyNotice("Stately", "Apache-2.0", "https://github.com/touchlab/Stately"),
        ThirdPartyNotice("Nuke", "MIT", "https://github.com/kean/Nuke"),
        // Its SentryCrash is KSCrash's, with code from fishhook and from Apple's objc4 and CoreFoundation (APSL-2.0),
        // whose source is at the link, and its CPU and compiler headers are WebKit's (BSD-2-Clause).
        ThirdPartyNotice("Sentry Cocoa SDK", "MIT AND BSD-3-Clause AND BSD-2-Clause AND APSL-2.0", "https://github.com/getsentry/sentry-cocoa"),
    )

}
