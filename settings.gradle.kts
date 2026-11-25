pluginManagement {
    includeBuild("gradle/build-logic")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Provisions the JDK toolchains a host lacks: 27 (shared, dev, ui-compose) and 25 (the
    // desktop modules; JetBrains Runtime on Linux).
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

// mpv-build's mpv-android library (libmpv, FFmpeg and the JNI glue with its Kotlin API, one AAR), pinned in
// mpv-build.lock.json: its key is the version :mpv-android depends on, and its sha256 the one Gradle's dependency
// verification checks (gradle/verification-metadata.xml, which tools/set_native_revision.sh writes with the lock).
// Gradle fetches it from the GitHub release through an Ivy repository: no metadata, no authentication. The repository
// is the AAR's own release (the publish run's that built it) when the lock names one, else the android group's.
@Suppress("UNCHECKED_CAST")
val mpvLock = groovy.json.JsonSlurper().parseText(providers.fileContents(layout.rootDirectory.file("mpv-build.lock.json")).asText.get())
    as Map<String, Map<String, Map<String, Any>>>
val mpvAndroid = mpvLock.getValue("artifacts")["android"]
    ?: throw GradleException("mpv-build.lock.json has no android group; run tools/set_native_revision.sh")
@Suppress("UNCHECKED_CAST")
val mpvAar = mpvAndroid.getValue("aar") as Map<String, String>
val mpvAarKey = Regex.escape(mpvAar.getValue("key"))
val mpvAarVerified = Regex(
    """<component group="edde746" name="mpv-android" version="$mpvAarKey">\s*<artifact name="mpv-android-$mpvAarKey\.aar">""" +
        """\s*<sha256 value="${Regex.escape(mpvAar.getValue("checksum"))}"""",
)
check(mpvAarVerified.containsMatchIn(providers.fileContents(layout.rootDirectory.file("gradle/verification-metadata.xml")).asText.get())) {
    "gradle/verification-metadata.xml doesn't check mpv-android against mpv-build.lock.json's key and sha256; run tools/set_native_revision.sh"
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        exclusiveContent {
            forRepository {
                ivy {
                    name = "mpv-build"
                    url = uri(mpvAar["assetBase"] ?: mpvAndroid.getValue("assetBase") as String)
                    patternLayout { artifact("[artifact]-[revision].[ext]") }
                    metadataSources { artifact() }
                }
            }
            filter { includeModule("edde746", "mpv-android") }
        }
    }
}

rootProject.name = "plezy"

// Android modules need an Android SDK. Hosts without one (the Windows/Linux desktop test machines) build with
// -Pplezy.android=false or PLEZY_ANDROID=false; shared and ui-compose then drop their Android target too.
val androidEnabled = providers.gradleProperty("plezy.android").orElse(providers.environmentVariable("PLEZY_ANDROID"))
    .map { it.toBoolean() }.getOrElse(true)

// The app's version, shared with the Apple project (version.xcconfig): `plezy.version` is MARKETING_VERSION
// (major.minor.patch), `plezy.build` CURRENT_PROJECT_VERSION (the build number that grows with every release).
val appVersion = providers.fileContents(layout.rootDirectory.file("version.xcconfig")).asText.get().lineSequence()
    .mapNotNull { Regex("""^(\w+)\s*=\s*(\S+)$""").matchEntire(it.trim())?.destructured?.let { (key, value) -> key to value } }
    .toMap()
val marketingVersion = checkNotNull(appVersion["MARKETING_VERSION"]) { "version.xcconfig: no MARKETING_VERSION" }
val buildNumber = checkNotNull(appVersion["CURRENT_PROJECT_VERSION"]) { "version.xcconfig: no CURRENT_PROJECT_VERSION" }

// Where the Android and desktop builds are distributed (the shared BuildFlavor): store for Google Play and the
// Microsoft Store, amazon for the Amazon Appstore (Android only), sideloaded (the default) for the GitHub release's
// APKs and desktop packages. Set with -Pplezy.flavor=<name> or PLEZY_FLAVOR=<name>; `plezy.flavor` is the BuildFlavor
// constant's name. The Apple apps take theirs from apple/project.yml's PLEZY_APPLE_FLAVOR
// (another name: Xcode passes its build settings to the Gradle phase's environment).
val flavor = providers.gradleProperty("plezy.flavor").orElse(providers.environmentVariable("PLEZY_FLAVOR"))
    .getOrElse("sideloaded")
check(flavor in setOf("store", "amazon", "sideloaded")) { "plezy.flavor must be store, amazon or sideloaded, not '$flavor'" }

gradle.beforeProject {
    extensions.extraProperties["plezy.android"] = androidEnabled
    extensions.extraProperties["plezy.version"] = marketingVersion
    extensions.extraProperties["plezy.build"] = buildNumber.toInt()
    extensions.extraProperties["plezy.flavor"] = flavor.uppercase()
    extensions.extraProperties["mpv.aar"] = "edde746:mpv-android:${mpvAar.getValue("key")}@aar"
}

// The Android and desktop modules live in android/ and desktop/ under project names of their own, which name their
// outputs (app-android-debug.apk, ...).
include(":shared", ":dev", ":ui-compose", ":mpv-jvm", ":app-desktop")
project(":mpv-jvm").projectDir = file("desktop/mpv")
project(":app-desktop").projectDir = file("desktop/app")
if (androidEnabled) {
    include(":mpv-android", ":app-android", ":baselineprofile")
    project(":mpv-android").projectDir = file("android/mpv")
    project(":app-android").projectDir = file("android/app")
    project(":baselineprofile").projectDir = file("android/baselineprofile")
}
