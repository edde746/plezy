// Phone, tablet and Android TV in one APK.
//
// src/debug holds the test-only launch extras (dev sessions, the test report) that the device test harness drives, and
// the test builds' manifest (profileable, without the link filters, which stay the release build's); src/release has
// the same entry point without them, so release builds contain none of that code. The `harness` build type is the
// release build (R8, the same rules) with src/debug's extras and manifest: what the harness runs on to check
// minified code.
//
// The test builds (debug, harness) install as com.edde746.plezy.dev, "Plezy Dev" in the launcher, beside the
// release build's com.edde746.plezy: a device keeps its owner's release app and its data through every harness run.
// The device test harness installs, stops, clears and uninstalls only that package.
//
// The Baseline Profile (src/main/generated/baselineProfiles: baseline-prof.txt, which ART compiles ahead of time, and
// startup-prof.txt, which R8 lays the primary DEX file out by) comes from android/baselineprofile/'s journeys on the
// harness build, whose dev session signs into a media server: Home, a library's grid, an item's detail, on a TV and on
// a phone. It is merged into main, so release and harness both ship it as assets/dexopt/baseline.prof, and
// profileinstaller compiles it where the store doesn't (sideloads, Amazon's store).
// Regenerate it with :app-android:generateBaselineProfile on an Android TV and a phone, both connected
// (android/baselineprofile/ says how).
import com.android.build.api.artifact.SingleArtifact
import com.android.build.api.variant.FilterConfiguration
import java.security.MessageDigest
import java.util.Properties
import java.util.zip.CRC32
import java.util.zip.ZipFile
import javax.inject.Inject

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.androidx.baselineprofile)
    alias(libs.plugins.sentry.android)
}

// Release signing: key.properties in this directory (storeFile, relative to this directory, storePassword, keyAlias,
// keyPassword) names the upload keystore. The release workflow writes both files from its
// ANDROID_* secrets (.github/workflows/build.yml); git ignores them. Without key.properties, release builds are
// debug-signed, so the minified build still installs for device tests.
val uploadKeystore = providers.fileContents(layout.projectDirectory.file("key.properties")).asText.orNull
    ?.let { text -> Properties().apply { load(text.reader()) } }

// Version codes, one scheme per channel, from CURRENT_PROJECT_VERSION (N, version.xcconfig, through
// settings.gradle.kts), so the channels' codes never collide and a newer build always outranks an older one, the
// earlier releases' included (the same scheme since build 159):
// - the Play bundle (-Pplezy.flavor=store): N;
// - the sideloaded per-ABI APKs (-Pplezy.abiSplits=true): ABI * 1000 + N, armeabi-v7a 1, arm64-v8a 2, x86_64 4
//   (N = 160: 1160, 2160, 4160), so a device's best ABI outranks its fallback;
// - the Amazon Appstore's APK (-Pplezy.flavor=amazon): one APK with the ARM ABIs alone (Fire devices are ARM),
//   N + 3000.
val build = project.extra["plezy.build"] as Int
val amazon = project.extra["plezy.flavor"] == "AMAZON"
val abiSplits = providers.gradleProperty("plezy.abiSplits").map(String::toBoolean).getOrElse(false)
require(!(amazon && abiSplits)) { "The Amazon build is one APK: no -Pplezy.abiSplits" }
// The build type the device tests (src/androidTest) instrument: -Pplezy.testBuildType=<name>, debug by default.
val instrumentedBuildType = providers.gradleProperty("plezy.testBuildType").getOrElse("debug")

android {
    namespace = "com.edde746.plezy"
    compileSdk = 37
    // Android Automotive's car service (car/CarRestrictionsMonitor): the platform's optional library, compiled
    // against its stub; at runtime only Automotive images have it (the manifest's uses-library is optional).
    useLibrary("android.car")
    defaultConfig {
        applicationId = "com.edde746.plezy"
        // Fire OS 6 (Android 7.1).
        minSdk = 25
        targetSdk = 36
        versionCode = if (amazon) build + 3000 else build
        versionName = project.extra["plezy.version"] as String
        // BuildFlavor's name (settings.gradle.kts): the release workflow builds the Play bundle with
        // -Pplezy.flavor=store, Amazon's APK with -Pplezy.flavor=amazon and the GitHub release's APKs as sideloaded,
        // the default.
        buildConfigField("String", "BUILD_FLAVOR", "\"${project.extra["plezy.flavor"]}\"")
        // The launcher's label (the manifest's android:label); the test builds' own below.
        manifestPlaceholders["appLabel"] = "Plezy"
        if (amazon) ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a") }
        // Device tests (src/androidTest).
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    buildFeatures {
        buildConfig = true
    }
    signingConfigs {
        if (uploadKeystore != null) {
            create("upload") {
                storeFile = file(uploadKeystore.getProperty("storeFile"))
                storePassword = uploadKeystore.getProperty("storePassword")
                keyAlias = uploadKeystore.getProperty("keyAlias")
                keyPassword = uploadKeystore.getProperty("keyPassword")
            }
        }
    }
    // Per-ABI APKs for the GitHub release (arm64-v8a, armeabi-v7a, x86_64): the release workflow builds them with
    // -Pplezy.abiSplits=true, each with a versionCode of its own (androidComponents, below). Off by default, so the
    // harness installs one APK with every ABI, and so the Play bundle (bundleRelease, every ABI) builds: AGP refuses to
    // build a bundle while splits are on.
    splits {
        abi {
            isEnable = abiSplits
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = false
        }
    }
    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appLabel"] = "Plezy Dev"
        }
        release {
            // R8 with mpv-android's consumer rules (JNI names, the callbacks native code resolves by name).
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            signingConfig = signingConfigs.getByName(if (uploadKeystore != null) "upload" else "debug")
            // Full native symbols in the bundle, so Play symbolicates native crashes, of the libraries that carry them:
            // the prebuilt ones (mpv-android's libmpv, FFmpeg and JNI glue, Sentry's, AndroidX's) come stripped and add
            // none.
            ndk { debugSymbolLevel = "FULL" }
        }
        create("harness") {
            initWith(getByName("release"))
            // A test build: debug-signed even where the upload keystore is configured, with debug's package and label.
            signingConfig = signingConfigs.getByName("debug")
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appLabel"] = "Plezy Dev"
            ndk { debugSymbolLevel = "NONE" }
            matchingFallbacks += "release"
            // The test APK that instruments it is neither shrunk nor renamed (it takes the app's R8 mapping).
            testProguardFiles("proguard-test-rules.pro")
            // The test APK leaves out the libraries the app has, so while the device tests instrument it, the app keeps
            // those the instrumentation runner uses; the baseline profile's and the scenarios' harness builds stay
            // release's R8 output.
            if (instrumentedBuildType == "harness") proguardFile("proguard-instrumentation-rules.pro")
        }
    }
    // The device tests (src/androidTest) instrument debug by default; -Pplezy.testBuildType=harness runs them against
    // the harness build, R8-minified like release: what R8 may strip (code reached by name, from native code, or
    // through a library's reflection) fails there.
    testBuildType = instrumentedBuildType
    sourceSets.getByName("harness") {
        kotlin.directories += "src/debug/kotlin"
        manifest.srcFile("src/debug/AndroidManifest.xml")
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    // The unit tests see the merged manifest and resources (the file provider's paths, PlayerFilesTest); their
    // application stays a plain one (src/test/resources/robolectric.properties).
    testOptions {
        unitTests.isIncludeAndroidResources = true
    }
    // kotlinx-coroutines' debug agent class (for a JVM debugger's coroutine view), which nothing on Android loads.
    packaging {
        resources.excludes += "DebugProbesKt.bin"
    }
    // Lint reads the project modules' Android code too (shared, ui-compose, mpv-android), so an API call newer than
    // minSdk there, or a Compose check's error in ui-compose, fails lintDebug and lintRelease as it does in the app's
    // own code.
    lint {
        checkDependencies = true
    }
}

baselineProfile {
    mergeIntoMain = true
    dexLayoutOptimization = true
    variants {
        create("harness") { from(project(":baselineprofile")) }
    }
}

// Sentry's Gradle plugin does one job here: it puts a UUID made from the release build's R8 mapping file (its
// pg_map_hash) into the APK (assets/sentry-debug-meta.properties), and the SDK names that UUID in every report
// (debug_meta), so a report from an obfuscated build says which mapping retraces it. It uploads nothing: the
// crash-report server (edde746/bugs) takes no ProGuard mapping, so the release workflow keeps each one as a run
// artifact named by its UUID and uploads the native libraries' symbols itself (tools/upload_symbols.sh). Debug and
// harness builds skip it. The SDK comes from the dependencies below, so the plugin's own installation, bytecode
// instrumentation, runtime optimizations, dependency report and telemetry are off.
sentry {
    ignoredBuildTypes.set(setOf("debug", "harness"))
    includeProguardMapping.set(true)
    autoUploadProguardMapping.set(false)
    uploadNativeSymbols.set(false)
    includeDependenciesReport.set(false)
    telemetry.set(false)
    autoInstallation { enabled.set(false) }
    tracingInstrumentation { enabled.set(false) }
    runtimeOptimizations { enabled.set(false) }
}

dependencies {
    implementation(project(":ui-compose"))
    implementation(project(":mpv-android"))
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.browser)
    // The media session's artwork through the UI's image loader (AndroidMediaControls).
    implementation(libs.coil.compose)
    implementation(libs.jetbrains.lifecycle.runtime.compose)
    // AppGraph's HttpClient.
    implementation(libs.ktor.client.core)
    // Offline downloads: the shared engine's transfers run in a foreground dataSync worker (downloads/DownloadWorker).
    implementation(libs.androidx.work.runtime.ktx)
    // Compiles the Baseline Profile at install or on first launch where no store does it.
    implementation(libs.androidx.profileinstaller)
    // Crash reports (AndroidCrashReports): Sentry's Android SDK and its NDK part, which catches native crashes (libmpv's).
    implementation(libs.sentry.android.core)
    implementation(libs.sentry.android.ndk)
    // The development session and the test report's model (:dev), for the test builds' launch extras (src/debug).
    debugImplementation(project(":dev"))
    "harnessImplementation"(project(":dev"))
    // The Supporter purchase on Google Play (supporter/AndroidPlayBilling).
    implementation(libs.billing.ktx)
    // Unit tests (src/test): Android TV's Watch Next rules (watchnext/WatchNextRows), on JUnit 4 as AGP runs them, and
    // the launcher icon switch over Robolectric's package manager (appicon/AppIconSwitcher).
    testImplementation(kotlin("test-junit"))
    // Real Intent, Uri and Bundle classes for the external player hand-off's intent and result (players/).
    testImplementation(libs.robolectric)
    // Device tests (src/androidTest): the app's mpv engine on a device, against the harness build's R8 output.
    androidTestImplementation(libs.androidx.test.runner)
}

// Robolectric instruments classes with an ASM that reads class files up to Java 25's, the JDK's own included.
tasks.withType<Test>().configureEach {
    javaLauncher.set(javaToolchains.launcherFor { languageVersion.set(JavaLanguageVersion.of(25)) })
}

// The modules the release build ships, a group:name per line, for which :shared's ThirdPartyNoticesCoverageTest finds a
// notice.
tasks.register("shippedModules") {
    val modules = configurations.named("releaseRuntimeClasspath").map { classpath ->
        classpath.incoming.resolutionResult.allComponents
            .mapNotNull { (it.id as? ModuleComponentIdentifier)?.moduleIdentifier?.toString() }.sorted()
    }
    val output = layout.buildDirectory.file("shipped-modules.txt")
    inputs.property("modules", modules)
    outputs.file(output)
    doLast { output.get().asFile.writeText(modules.get().joinToString("\n")) }
}

// The licence files the release build's libraries carry for the code bundled inside them (Google's AARs:
// third_party_licenses.txt; some carry an empty one, which has nothing to ship), a "group:name:version sha256" per line,
// which :shared's ThirdPartyLicenseFilesTest finds among the APK's licence texts.
tasks.register("shippedLicenseFiles") {
    val classpath = configurations.getByName("releaseRuntimeClasspath")
    val archives = listOf("aar", "jar").map { type ->
        classpath.incoming.artifactView {
            lenient(true)
            attributes { attribute(Attribute.of("artifactType", String::class.java), type) }
        }.artifacts
    }
    val output = layout.buildDirectory.file("shipped-license-files.txt")
    for (artifacts in archives) inputs.files(artifacts.artifactFiles).withPropertyName("archives${archives.indexOf(artifacts)}")
    outputs.file(output)
    doLast {
        val lines = archives.flatMap { it.artifacts }.mapNotNull { artifact ->
            val module = artifact.id.componentIdentifier as? ModuleComponentIdentifier ?: return@mapNotNull null
            ZipFile(artifact.file).use { zip ->
                zip.getEntry("third_party_licenses.txt")?.takeIf { it.size != 0L }?.let { entry ->
                    val digest = MessageDigest.getInstance("SHA-256").digest(zip.getInputStream(entry).use { it.readBytes() })
                    "${module.displayName} ${digest.joinToString("") { "%02x".format(it) }}"
                }
            }
        }.distinct().sorted()
        output.get().asFile.writeText(lines.joinToString("\n"))
    }
}

// The licence texts of what the app ships, which About shows: the android groups of the repository's licenses/
// (licenses/apps.json), each folder of them in the APK's assets/licenses/, and beside them the folders mpv-android's
// AAR brings there in its own assets/licenses/ (one per component of mpv-build's build, which mpv-build collects from
// the sources it built, and mpv-android/ for the JNI glue). Two groups never hold the same folder: the copy fails on a
// duplicate. Every APK and bundle is checked to hold each text, the AAR's too, before assemble and bundle finish: AAPT
// leaves out assets it ignores (a name starting with a dot, a folder's starting with an underscore) without a word, an
// app asset at an AAR asset's path replaces it, and an AAR without licence texts fails the check.
val licenseGroups = (groovy.json.JsonSlurper()
    .parseText(providers.fileContents(rootProject.layout.projectDirectory.file("licenses/apps.json")).asText.get()) as Map<*, *>)
    .let { apps -> (apps["android"] as List<*>).map { rootProject.layout.projectDirectory.dir("licenses/$it") } }

/** Copies the folders of [groups] into [output]'s licenses/. */
abstract class LicenseTexts : DefaultTask() {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val groups: ConfigurableFileCollection

    @get:OutputDirectory
    abstract val output: DirectoryProperty

    @get:Inject
    abstract val files: FileSystemOperations

    @TaskAction
    fun copy() {
        files.sync {
            from(groups)
            into(output.dir("licenses"))
        }
    }
}

/**
 * Fails unless each APK or bundle of [packages] holds in its assets/licenses/ every file of [groups] and every file
 * under the [aar]'s assets/licenses/, byte for byte, or when the AAR has no such file.
 */
abstract class CheckLicenseTexts : DefaultTask() {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val groups: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val aar: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NAME_ONLY)
    abstract val packages: ConfigurableFileCollection

    @TaskAction
    fun check() {
        val library = aar.singleFile
        // Each text's path under licenses/ → its CRC-32.
        val carried = ZipFile(library).use { zip ->
            zip.entries().asSequence().filter { !it.isDirectory && it.name.startsWith("assets/licenses/") }
                .map { it.name.removePrefix("assets/licenses/") to it.crc }.toList()
        }
        if (carried.isEmpty()) throw GradleException("${library.name} has no licence texts in assets/licenses/ (mpv-build.lock.json's pin)")
        val texts = carried + groups.files.flatMap { group ->
            group.walk().filter { it.isFile }.map { it.relativeTo(group).invariantSeparatorsPath to CRC32().apply { update(it.readBytes()) }.value }.toList()
        }
        val archives = packages.asFileTree.files.filter { it.extension == "apk" || it.extension == "aab" }
        if (archives.isEmpty()) throw GradleException("Nothing to check: packages $archives")
        for (archive in archives) {
            val prefix = if (archive.extension == "aab") "base/assets/licenses/" else "assets/licenses/"
            val wrong = ZipFile(archive).use { zip ->
                texts.filter { (path, crc) -> zip.getEntry(prefix + path)?.crc != crc }.map { prefix + it.first }
            }
            if (wrong.isNotEmpty()) throw GradleException("${archive.name} lacks these licence texts (or holds other bytes): ${wrong.joinToString()}")
            logger.lifecycle("${archive.name} holds all ${texts.size} licence texts, ${carried.size} of them ${library.name}'s")
        }
    }
}

val mpvAar = configurations.dependencyScope("mpvAar")
val mpvAarFile = configurations.resolvable("mpvAarFile") { extendsFrom(mpvAar.get()) }
dependencies { add(mpvAar.name, project.extra["mpv.aar"] as String) }

// A per-ABI APK's versionCode thousands (onVariants, below; the scheme at the top).
val abiThousands = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 4)

androidComponents {
    onVariants { variant ->
        // A per-ABI APK's versionCode is its ABI's thousands + N; the bundle and the one-APK builds have no ABI
        // outputs and keep defaultConfig's.
        for (output in variant.outputs) {
            val abi = output.filters.find { it.filterType == FilterConfiguration.FilterType.ABI }?.identifier ?: continue
            output.versionCode.set(abiThousands.getValue(abi) * 1000 + build)
        }
        val name = variant.name.replaceFirstChar(Char::uppercase)
        val texts = tasks.register<LicenseTexts>("copy${name}LicenseTexts") { groups.from(licenseGroups) }
        variant.sources.assets?.addGeneratedSourceDirectory(texts, LicenseTexts::output)
        val packages = mapOf("Apk" to variant.artifacts.get(SingleArtifact.APK), "Bundle" to variant.artifacts.get(SingleArtifact.BUNDLE))
        for ((kind, artifact) in packages) {
            val check = tasks.register<CheckLicenseTexts>("check$name${kind}LicenseTexts") {
                groups.from(licenseGroups)
                aar.from(mpvAarFile)
                this.packages.from(artifact)
            }
            val packaging = if (kind == "Apk") "assemble$name" else "bundle$name"
            tasks.matching { it.name == packaging }.configureEach { dependsOn(check) }
        }
    }
}
