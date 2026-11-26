import co.touchlab.skie.configuration.SuppressSkieWarning
import co.touchlab.skie.plugin.configuration.SkieExtension
import com.android.build.api.dsl.KotlinMultiplatformAndroidLibraryTarget
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.KotlinPlatformType
import org.jetbrains.kotlin.gradle.plugin.mpp.NativeBuildType
import plezy.buildlogic.GenerateChapterMarkerModel
import plezy.buildlogic.GenerateRegistrations

plugins {
    id("plezy.strings")
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library) apply false
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.sqldelight)
}

// SKIE only does work for Apple frameworks, which only build on macOS. :dev applies it the same way for Debug's
// PlezyKit.
if (System.getProperty("os.name").startsWith("Mac")) {
    apply(plugin = libs.plugins.skie.get().pluginId)
    extensions.configure<SkieExtension> {
        // No Swift goes into the framework from Kotlin's source sets. SKIE adds the bundled Swift's directory to the
        // Kotlin/Native compile task as an absolute path, which keeps the compile out of Gradle's build cache between
        // checkouts; with bundling off that directory is never made, so the compile's cache key is the same in any
        // checkout of this tree.
        swiftBundling { enabled.set(false) }
        features {
            // Ktor's HttpStatusCode.description meets NSObject's description() and reaches Swift as description_.
            // Swift never reads it and it isn't ours to rename; the project's own names are Swift-safe at the source
            // (@ObjCName("descriptionText"), and i18n keys the strings plugin checks).
            group("io.ktor.http.HttpStatusCode") { SuppressSkieWarning.NameCollision(true) }
        }
    }
}

// Hosts without an Android SDK build with -Pplezy.android=false (settings.gradle.kts). The Android plugin then
// isn't applied at all: applied without its target, it fails configuration ("compileSdk version is not set").
// Android Lint analyses a KMP library's Android target (androidMain, jvmAndAndroidMain, commonMain) only with its own
// plugin; :app-android's lint then checks it against the app's minSdk (checkDependencies).
val androidEnabled = extra["plezy.android"] as Boolean
if (androidEnabled) {
    apply(plugin = libs.plugins.android.kmp.library.get().pluginId)
    apply(plugin = libs.plugins.android.lint.get().pluginId)
}

kotlin {
    jvmToolchain(27)

    // jvmAndAndroidMain: plain JDK code both JVM targets run (the loopback OAuth redirect receiver of desktop and
    // Android sign-in, the OkHttp engine, language names and decimals); an actual the two would copy goes there. It
    // runs on Android's API 25 too, which has no java.time (API 26): lintDebug fails on such a call.
    applyDefaultHierarchyTemplate {
        common {
            group("jvmAndAndroid") {
                withJvm()
                // The Android KMP library plugin's target isn't a KotlinAndroidTarget, which withAndroidTarget() matches.
                withCompilations { it.target.platformType == KotlinPlatformType.androidJvm }
            }
        }
    }

    if (androidEnabled) {
        extensions.configure<KotlinMultiplatformAndroidLibraryTarget>("android") {
            namespace = "com.edde746.plezy.shared"
            compileSdk = 37
            // -Pplezy.deviceTests=true builds this module for its device tests alone, at minSdk 30: DEX takes the
            // spaces in commonTest's backticked test names from version 040 (Android 11) on, and d8 refuses them
            // below it. The app can't consume that build (its minSdk is 25), so nothing else builds with the flag.
            minSdk = if (providers.gradleProperty("plezy.deviceTests").map(String::toBoolean).getOrElse(false)) 30 else 25
            compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
            // Device tests run commonTest and src/androidDeviceTest on a real Android runtime (its JCA stack and regex
            // engine differ from the desktop JVM's), from the APK `:shared:assembleAndroidDeviceTest` builds with the
            // flag above. Their names are DEX names: letters, digits, spaces, `$-_` and most of Unicode, no other ASCII.
            withDeviceTestBuilder { sourceSetTreeName = "test" }.configure {
                instrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
            }
        }
    }

    // Desktop app (Windows/Linux).
    jvm {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    // One umbrella framework for every Apple target: several would each embed a Kotlin runtime. This is
    // the Release configuration's PlezyKit, without the development session (the Xcode script phase's
    // `:shared:embedAndSignAppleFrameworkForXcode`); Debug's is :dev's, with it. The Mac app is universal, so macOS has
    // an Intel target too (macosX64, deprecated by Kotlin but still built); iOS and tvOS are arm64 only.
    listOf(iosArm64(), iosSimulatorArm64(), macosArm64(), macosX64(), tvosArm64(), tvosSimulatorArm64()).forEach { target ->
        target.binaries.framework(listOf(NativeBuildType.RELEASE)) {
            baseName = "PlezyKit"
            isStatic = true
            // Explicit, or Kotlin/Native warns on every link that it cannot infer one.
            binaryOption("bundleId", "com.edde746.plezy.PlezyKit")
        }
    }

    sourceSets {
        // `T` and the other string accessors, generated from shared/i18n/*.i18n.json (build-logic's plezy.strings).
        // As a task-backed source directory it makes every compilation of commonMain depend on the generator.
        commonMain { kotlin.srcDir(tasks.named("generateStrings")) }
        commonMain.dependencies {
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.atomicfu)
            implementation(libs.kotlinx.serialization.json)
            // JCA on JVM/Android, CryptoKit (CommonCrypto fallback) on Apple.
            implementation(libs.cryptography.core)
            implementation(libs.cryptography.provider.optimal)
            // HTTP (OkHttp on Android/JVM, Darwin on Apple).
            implementation(libs.ktor.client.core)
            // The anime mapping datasets (trackers/ids): cached files, parsed as streams.
            implementation(libs.kotlinx.io.core)
            implementation(libs.kotlinx.serialization.json.io)
            // Watch together: rooms, sync and matching on Open Watch Party (its relays' WebSockets go through the app's
            // HttpClient, which installs WebSockets).
            implementation(libs.openwatchparty)
            // Casting: its receiver's WebSocket server and its sender's WebSocket, on raw sockets, with Ktor's WebSocket
            // framing.
            implementation(libs.ktor.network)
            implementation(libs.ktor.websockets)
        }
        // One OkHttp engine for desktop and Android (net/PlatformHttpEngine.jvmAndAndroid.kt).
        getByName("jvmAndAndroidMain").dependencies {
            implementation(libs.ktor.client.okhttp)
        }
        // The desktop's DNS-SD for casting (cast/JmdnsCastDiscovery.kt).
        jvmMain.dependencies {
            implementation(libs.jmdns)
        }
        appleMain.dependencies {
            implementation(libs.ktor.client.darwin)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.kotlinx.coroutines.test)
            implementation(libs.ktor.client.mock)
        }
        if (androidEnabled) {
            // Android pins the JCA provider (crypto/CryptoProvider.android.kt), which needs the JDK provider API.
            getByName("androidMain").dependencies {
                implementation(libs.cryptography.provider.jdk)
            }
            getByName("androidDeviceTest").dependencies {
                implementation(libs.androidx.test.runner)
            }
        }
    }
}

// -- this build's registrations --
// Client registrations with outside services become generated objects in commonMain, so every app (Android, desktop,
// the Apple framework) ships the same ones. Each value comes from a Gradle property or, for CI, an environment
// variable; a build without them leaves that service or flow out. The values ship in the binary, as for every native
// client of these services. Secrets that must stay private live on the server instead: MyAnimeList's and AniList's
// on the tracker relay, the Sign in with Apple key on the hosted instance.
/**
 * Registers a [GenerateRegistrations] task: each config field from Gradle property `<prefix>.<field>`, else the
 * environment variable [fields] names, else its entry in [defaults], else blank.
 */
fun registrations(
    task: String,
    objectName: String,
    visibility: String,
    configType: String,
    doc: String,
    prefix: String,
    fields: Map<String, String>,
    defaults: Map<String, String> = emptyMap(),
) = tasks.register<GenerateRegistrations>(task) {
    this.objectName.set(objectName)
    this.visibility.set(visibility)
    this.configType.set(configType)
    this.doc.set(doc)
    propertyPrefix.set(prefix)
    for ((field, env) in fields) {
        values.put(
            field,
            providers.gradleProperty("$prefix.$field").orElse(providers.environmentVariable(env)).orElse(defaults[field] ?: ""),
        )
    }
    output.set(layout.buildDirectory.dir("generated/plezy/$task/commonMain/kotlin"))
}

// The tracker services. The client IDs (and Trakt's secret, which its device flow sends) are public (every app sends
// them to the service) and default to Plezy's registrations, the relay to Plezy's server; a fork can point at its own.
val generateTrackerConfig = registrations(
    task = "generateTrackerConfig",
    objectName = "com.edde746.plezy.trackers.BuildTrackerConfig",
    visibility = "public",
    configType = "TrackerConfig",
    doc = "This build's tracker registrations; blank values leave their services out.",
    prefix = "plezy.trackers",
    fields = mapOf(
        "traktClientId" to "PLEZY_TRAKT_CLIENT_ID",
        "traktClientSecret" to "PLEZY_TRAKT_CLIENT_SECRET",
        "simklClientId" to "PLEZY_SIMKL_CLIENT_ID",
        "simklLegacyClientId" to "PLEZY_SIMKL_LEGACY_CLIENT_ID",
        "mdblistClientId" to "PLEZY_MDBLIST_CLIENT_ID",
        "malClientId" to "PLEZY_MAL_CLIENT_ID",
        "relayBaseUrl" to "PLEZY_TRACKER_RELAY_URL",
    ),
    defaults = mapOf(
        "traktClientId" to "9861e686e95c13409dd321736f903973cb9b8e5c6abd0634bec8962f52ea30f4",
        "traktClientSecret" to "acfa17b9d77fabd7e51175b7da6631aea69423530a6d49b3b3c38cd107cbd207",
        "simklClientId" to "ec68bc6a9d04b3c50af8cc495f9c9bf478c2371b979aed7e3385bdb771b9b18d",
        "simklLegacyClientId" to "ac97718a469c33eab948b63f92226106157e58fdcdd70c1b5857f1779b1d3a6a",
        "mdblistClientId" to "xOUwKUPdGEbHif6aKwW2gCxCAvFx7m0Q3jX0ZxXZ",
        "malClientId" to "463b1c92992505e4bdfcef6aab3aedbe",
        "relayBaseUrl" to "https://ice.plezy.app",
    ),
)

// Plezy's application on Discord, which Rich Presence's handshake names and Discord shows the activity as ("Watching
// Plezy"). The ID is public (every client sends it) and defaults to Plezy's; a fork can point at its own, and a
// blank one leaves Rich Presence out: no Discord switch, nothing connects (DiscordConfig).
val generateDiscordConfig = registrations(
    task = "generateDiscordConfig",
    objectName = "com.edde746.plezy.presentation.player.BuildDiscordConfig",
    visibility = "public",
    configType = "DiscordConfig",
    doc = "This build's Discord application; a blank one leaves Rich Presence out.",
    prefix = "plezy.discord",
    fields = mapOf("applicationId" to "PLEZY_DISCORD_APPLICATION_ID"),
    defaults = mapOf("applicationId" to "1453773470306402439"),
)

// Crash reports' Sentry DSN: blank by default, so only a build given one sends reports. The release workflow passes
// its secret as PLEZY_SENTRY_DSN; development, CI and harness builds have none. The commit names Sentry's release
// (`plezy@<commit7>`): -Pplezy.crashReports.commit, else GitHub Actions' GITHUB_SHA, else the checkout's HEAD, else
// blank (`plezy@unknown`) where the sources aren't a git checkout.
val generateCrashReportConfig = registrations(
    task = "generateCrashReportConfig",
    objectName = "com.edde746.plezy.crash.BuildCrashReportConfig",
    visibility = "public",
    configType = "CrashReportConfig",
    doc = "This build's crash-report endpoint; blank sends none.",
    prefix = "plezy.crashReports",
    fields = mapOf("dsn" to "PLEZY_SENTRY_DSN"),
)
generateCrashReportConfig.configure {
    val head = providers.exec {
        commandLine("git", "rev-parse", "HEAD")
        workingDir = rootDir
        isIgnoreExitValue = true
    }.standardOutput.asText.map { it.trim() }
    values.put(
        "commit",
        providers.gradleProperty("plezy.crashReports.commit").orElse(providers.environmentVariable("GITHUB_SHA")).orElse(head),
    )
}
kotlin.sourceSets.commonMain {
    kotlin.srcDir(generateTrackerConfig)
    kotlin.srcDir(generateDiscordConfig)
    kotlin.srcDir(generateCrashReportConfig)
}

// Persistence (SQLDelight). databases/<N>.db is the schema version N as a release shipped it; `check` runs
// verifyCommonMainPlezyDatabaseMigration, which fails unless each, migrated by migrations/<N>.sqm onwards, equals the
// schema the .sq files declare. Until the first release there's none: version 1 is edited in place (preview installs
// are wiped). The release step, snapshotReleasedDatabaseSchema, writes the version it ships; from then on every
// schema change is the next migrations/<N>.sqm (the schema version is the last one's N + 1), and the next release
// snapshots that version.
sqldelight {
    databases {
        create("PlezyDatabase") {
            packageName.set("com.edde746.plezy.data.db")
            // SQLDelight's oldest dialect, SQLite 3.18 (Android API 26). The app's minSdk 25 ships SQLite 3.9, so the
            // .sq files keep to what 3.9 has; the Apple and JDBC builds are newer.
            dialect(libs.sqldelight.sqlite.dialect)
            schemaOutputDirectory.set(layout.projectDirectory.dir("src/commonMain/sqldelight/databases"))
            verifyMigrations.set(true)
        }
    }
}

// The release step: snapshots the schema version the release ships as databases/<version>.db. A version already
// snapshotted shipped in an earlier release, so the task refuses it: the schema changed without a migration.
val databaseSnapshots = layout.projectDirectory.dir("src/commonMain/sqldelight/databases")
val databaseMigrations = fileTree("src/commonMain/sqldelight") { include("**/*.sqm") }
val checkDatabaseSnapshotIsNew = tasks.register("checkDatabaseSnapshotIsNew") {
    val snapshots = databaseSnapshots.asFile
    val migrations = databaseMigrations
    doLast {
        val version = (migrations.files.maxOfOrNull { it.nameWithoutExtension.toInt() } ?: 0) + 1
        val snapshot = snapshots.resolve("$version.db")
        check(!snapshot.exists()) {
            "Schema version $version shipped already (${snapshot.name}): add the migration to ${version + 1} first"
        }
    }
}
tasks.matching { it.name == "generateCommonMainPlezyDatabaseSchema" }.configureEach { mustRunAfter(checkDatabaseSnapshotIsNew) }
tasks.register("snapshotReleasedDatabaseSchema") {
    group = "release"
    description = "Writes the schema version this release ships as src/commonMain/sqldelight/databases/<version>.db."
    dependsOn(checkDatabaseSnapshotIsNew, "generateCommonMainPlezyDatabaseSchema")
}

// SQLDelight's verifier fails without a snapshot to migrate ("requires a database file"), so until the first release
// snapshots one it is skipped and version 1 is edited in place. Its task doesn't count the snapshots among its inputs
// (a new or changed databases/<N>.db reused an earlier result from the build cache), so they're added here.
tasks.matching { it.name == "verifyCommonMainPlezyDatabaseMigration" }.configureEach {
    val snapshots = databaseSnapshots.asFile
    inputs.files(fileTree(snapshots) { include("*.db") }).withPropertyName("releaseSnapshots").withPathSensitivity(PathSensitivity.RELATIVE)
    onlyIf("a release snapshot (databases/<N>.db) exists") { snapshots.listFiles { file -> file.extension == "db" }?.isNotEmpty() == true }
}

// -- playback: the chapter marker model --
// src/commonMain/models/chapter_marker_model.bin (playback/ChapterMarkerClassifier) becomes one generated Kotlin source
// in commonMain as base64 string constants of at most 60 000 characters (under the JVM's 64 KiB constant limit), so
// every app ships the same bytes with no platform resource API.
val generateChapterMarkerModel = tasks.register<GenerateChapterMarkerModel>("generateChapterMarkerModel") {
    model.set(layout.projectDirectory.file("src/commonMain/models/chapter_marker_model.bin"))
    output.set(layout.buildDirectory.dir("generated/plezy/chapterMarkerModel/commonMain/kotlin"))
}
kotlin.sourceSets.commonMain { kotlin.srcDir(generateChapterMarkerModel) }

// The generated database code is data's implementation detail, so it is made internal: the Apple framework then
// exports the repositories only, not every query class and row type (the generated `Profile` row would otherwise
// take data.profile.Profile's Swift name). SQLDelight has no visibility option; this runs as part of its task, so
// cached outputs are already rewritten.
tasks.withType<app.cash.sqldelight.gradle.SqlDelightTask>().configureEach {
    doLast {
        val topLevelPublic = Regex("^public (?=(data class|class|interface|object|fun|val) )", RegexOption.MULTILINE)
        outputDirectory.get().asFile.walk().filter { it.extension == "kt" }.forEach { file ->
            val text = file.readText()
            val rewritten = text.replace(topLevelPublic, "internal ")
            if (rewritten != text) file.writeText(rewritten)
        }
    }
}

kotlin {
    // data/DatabaseFactory is an expect class: each platform opens its database its own way.
    compilerOptions { freeCompilerArgs.add("-Xexpect-actual-classes") }
    sourceSets {
        commonMain.dependencies {
            implementation(libs.sqldelight.coroutines.extensions)
        }
        jvmMain.dependencies {
            implementation(libs.sqldelight.sqlite.driver)
        }
        appleMain.dependencies {
            implementation(libs.sqldelight.native.driver)
        }
        if (androidEnabled) {
            getByName("androidMain").dependencies {
                implementation(libs.sqldelight.android.driver)
            }
        }
    }
}

// The licence checks run on their own (`licenseTest`, part of `check`) from src/jvmLicenseTest, as they need other
// projects' and mpv-build's outputs that jvmTest doesn't: ThirdPartyLicenseFilesTest
// finds every in-app notice's licence texts in the groups of licenses/ each app ships (licenses/apps.json) and in the
// licenses/ of mpv-build's artefacts (mpv-android's AAR; mpv-jvm's libmpv artifact, this host's desktop's: Windows'
// on Windows, Linux's elsewhere), and the licence files the Android build's libraries carry (its shippedLicenseFiles)
// among the APK's; ThirdPartyNoticesCoverageTest finds a notice for every module each app ships (the apps'
// shippedModules, Apple's framework's libraries) and every package the Apple apps link (apple/project.yml).
val licenseTestCompilation = kotlin.jvm().compilations.create("licenseTest") {
    associateWith(kotlin.jvm().compilations.getByName("main"))
    defaultSourceSet.dependencies {
        implementation(kotlin("test-junit"))
        implementation(libs.kotlinx.serialization.json)
    }
}
val mpvArtefacts = configurations.dependencyScope("mpvArtefacts")
val mpvAar = configurations.resolvable("mpvAar") { extendsFrom(mpvArtefacts.get()) }
val mpvNatives = configurations.dependencyScope("mpvNatives")
val mpvNativesPath = configurations.resolvable("mpvNativesPath") {
    extendsFrom(mpvNatives.get())
    attributes { attribute(Usage.USAGE_ATTRIBUTE, objects.named("plezy-mpv-natives")) }
}
dependencies {
    add(mpvArtefacts.name, project.extra["mpv.aar"] as String)
    add(mpvNatives.name, project(":mpv-jvm"))
}
val licenseTest = tasks.register<Test>("licenseTest") {
    description = "Checks the apps' third-party notices against the licence texts and modules they ship."
    group = LifecycleBasePlugin.VERIFICATION_GROUP
    testClassesDirs = licenseTestCompilation.output.classesDirs
    classpath = licenseTestCompilation.output.allOutputs + licenseTestCompilation.runtimeDependencyFiles
    dependsOn("checkTestNames")
    val aar = files(mpvAar)
    inputs.files(aar).withPropertyName("mpvAar").withPathSensitivity(PathSensitivity.NONE)
    val natives = files(mpvNativesPath)
    inputs.files(natives.asFileTree.matching { include("licenses/**") }).withPropertyName("mpvLicenses")
        .withPathSensitivity(PathSensitivity.RELATIVE)
    val desktop = if (System.getProperty("os.name").startsWith("Windows")) "windows" else "linux"
    doFirst {
        systemProperty("plezy.mpvArtefact.android", aar.singleFile.absolutePath)
        systemProperty("plezy.mpvArtefact.$desktop", natives.singleFile.absolutePath)
    }
    val licensesDir = rootProject.file("licenses")
    inputs.dir(licensesDir).withPropertyName("licenses").withPathSensitivity(PathSensitivity.RELATIVE)
    systemProperty("plezy.licensesDir", licensesDir.absolutePath)
    for ((app, path) in listOfNotNull("desktop" to ":app-desktop", ("android" to ":app-android").takeIf { androidEnabled })) {
        val modules = project(path).layout.buildDirectory.file("shipped-modules.txt").get().asFile
        dependsOn("$path:shippedModules")
        inputs.file(modules).withPropertyName("${app}Modules").withPathSensitivity(PathSensitivity.NONE)
        systemProperty("plezy.shippedModules.$app", modules.absolutePath)
    }
    if (androidEnabled) {
        val licenseFiles = project(":app-android").layout.buildDirectory.file("shipped-license-files.txt").get().asFile
        dependsOn(":app-android:shippedLicenseFiles")
        inputs.file(licenseFiles).withPropertyName("androidLicenseFiles").withPathSensitivity(PathSensitivity.NONE)
        systemProperty("plezy.shippedLicenseFiles.android", licenseFiles.absolutePath)
    }
    val appleModules = configurations.named("iosArm64CompileKlibraries").map { klibraries ->
        klibraries.incoming.resolutionResult.allComponents
            .mapNotNull { (it.id as? ModuleComponentIdentifier)?.moduleIdentifier?.toString() }.sorted()
    }
    inputs.property("appleModules", appleModules)
    doFirst { systemProperty("plezy.shippedModules.apple", appleModules.get().joinToString(",")) }
    val appleProject = rootProject.file("apple/project.yml")
    inputs.file(appleProject).withPropertyName("appleProject").withPathSensitivity(PathSensitivity.NONE)
    systemProperty("plezy.appleProject", appleProject.absolutePath)
}
tasks.named("check") { dependsOn(licenseTest) }

// Backticked test names in every module keep to letters, digits and spaces: Kotlin/Native rejects `,` `(` `)` `#`,
// Windows paths reject `"`, and d8 rejects `'`, `+`, `=` and other punctuation in a method name.
val checkTestNames = tasks.register("checkTestNames") {
    val sources = rootProject.fileTree(rootProject.projectDir) {
        include("**/src/test/**/*.kt", "**/src/*Test/**/*.kt")
        exclude("**/build/**", "**/node_modules/**", ".gradle/**")
    }
    val root = rootProject.projectDir
    inputs.files(sources).withPropertyName("testSources").withPathSensitivity(PathSensitivity.RELATIVE)
    doLast {
        val name = Regex("""fun\s+`([^`]*)`""")
        val bad = sources.files.sorted().flatMap { file ->
            file.readLines().withIndex().flatMap { (index, line) ->
                name.findAll(line).map { it.groupValues[1] }
                    .filter { test -> test.any { !(it in 'a'..'z' || it in 'A'..'Z' || it in '0'..'9' || it == ' ') } }
                    .map { "${file.relativeTo(root)}:${index + 1}: `$it`" }
            }
        }
        check(bad.isEmpty()) { "Test names with characters other than letters, digits and spaces:\n${bad.joinToString("\n")}" }
    }
}
tasks.named("jvmTest") { dependsOn(checkTestNames) }

// -- secrets: Keychain tests --
// The Keychain tests (appleTest secrets/KeychainSecretStoreTest) need a booted simulator (a standalone spawn has no
// securityd) and an application identifier, which simulator binaries carry as simulated entitlements in a
// __TEXT,__entitlements section, as Xcode writes them. The simulator's securityd reads that section from the binary's
// file, which macOS's folder protection keeps it from in ~/Documents (and the other protected folders): the process
// then has no entitlements (OSStatus -34018). So the test runs a copy of the binary in the temporary folder. The
// macOS test binary is unsigned and the data protection keychain accepts only team-signed apps, so they don't run on
// macOS.
if (System.getProperty("os.name").startsWith("Mac")) {
    val entitlements = layout.projectDirectory.file("src/appleTest/keychain-tests.entitlements")
    // One folder per checkout, so two checkouts' runs never share a copy.
    val staging = File(System.getProperty("java.io.tmpdir"), "plezy-simulator-tests/${projectDir.absolutePath.hashCode().toUInt()}")
    listOf(kotlin.iosSimulatorArm64(), kotlin.tvosSimulatorArm64()).forEach { target ->
        val binary = target.binaries.getTest("DEBUG")
        binary.linkerOpts("-sectcreate", "__TEXT", "__entitlements", entitlements.asFile.absolutePath)
        binary.linkTaskProvider.configure { inputs.file(entitlements).withPropertyName("simulatedEntitlements") }
        val stage = tasks.register<Sync>("stage${target.name.replaceFirstChar { it.uppercase() }}TestBinary") {
            from(binary.linkTaskProvider.map { it.outputFile })
            into(File(staging, target.name))
        }
        tasks.named<org.jetbrains.kotlin.gradle.targets.native.tasks.KotlinNativeSimulatorTest>("${target.name}Test") {
            val staged = File(File(staging, target.name), binary.outputFile.name)
            executable(stage.get()) { staged }
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.targets.native.tasks.KotlinNativeSimulatorTest>().configureEach {
        standalone.set(false)
        val device = device
        // Boots the simulator unless it is running and waits for it. It stays booted, as after an Xcode test run.
        doFirst {
            val boot = ProcessBuilder("xcrun", "simctl", "bootstatus", device.get(), "-b").redirectErrorStream(true).start()
            val output = boot.inputStream.bufferedReader().readText()
            check(boot.waitFor() == 0) { "Couldn't boot simulator ${device.get()}:\n$output" }
        }
    }
    tasks.named<org.jetbrains.kotlin.gradle.targets.native.tasks.KotlinNativeHostTest>("macosArm64Test") {
        filter.excludeTestsMatching("com.edde746.plezy.secrets.KeychainSecretStoreTest")
    }
}
