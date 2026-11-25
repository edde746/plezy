// The desktop app: Windows, and Linux as a native Wayland client (X11 sessions run it without video).
//
//   ./gradlew :app-desktop:run --args="--mpv-log mpv.log"
//   ./gradlew :app-desktop:writeHarnessArgs && "$(cat desktop/app/build/run/java.txt)" @desktop/app/build/run/harness.args \
//     com.edde746.plezy.desktop.harness.TestMainKt --dev
//
// `run` starts the product (the release jar's main class) on a JDK 25 toolchain; on Linux and on Windows arm64 that is
// JetBrains Runtime 25 (vendor JETBRAINS, provisioned by the foojay resolver): on another runtime AWT may miss the
// window manager's resizes on Linux, and Windows arm64 has no Temurin 25.
// The test-only options (a dev session, the test report) are the harness launcher's, in the harness source set below,
// started without Gradle through `writeHarnessArgs`' argfile (the desktop test harness does that).
import java.net.URI
import java.nio.file.FileSystems
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import org.jetbrains.compose.desktop.application.tasks.AbstractJPackageTask
import org.jetbrains.compose.desktop.application.tasks.AbstractProguardTask

plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.kotlin.compose)
}

kotlin { jvmToolchain(25) }

val isLinux = System.getProperty("os.name").startsWith("Linux")
val isWindowsArm64 = System.getProperty("os.name").startsWith("Windows") && System.getProperty("os.arch") == "aarch64"
val mainClassName = "com.edde746.plezy.desktop.MainKt"
val nativeAccess = "--enable-native-access=ALL-UNNAMED"
// The app's JVM flags: FFM, and the AWT internals that reach each window's native window (its HWND; its X window and
// AWT's X connection; or its wl_surface and AWT's Wayland connection) for its dark title bar and frame (mpv-jvm's
// DesktopWindow.useDarkChrome) and, under Wayland, the video plane below it (mpv-jvm's WaylandVideoHost). On Linux
// also the app id, the desktop entry's id (desktop/app/packaging/linux), so the desktop shows the window as that
// entry's app: JetBrains Runtime gives it a Wayland window (by default the main class's name), and AWT's X11 toolkit
// takes it as the windows' class through its internals (mpv-jvm's DesktopWindow.useAppId). On Windows also Windows's
// proxy settings, which the JDK's default proxy selector (and so the HTTP client) reads only with
// java.net.useSystemProxies.
val appJvmFlags = listOf(
    nativeAccess,
    "--add-exports=java.desktop/sun.awt=ALL-UNNAMED",
    // CVE-2026-114938, the AVX-512 Base64 decoder's overflow: drop once the bundled runtime is a fixed build.
    "-XX:-UseBASE64Intrinsics",
) + if (isLinux) {
    listOf(
        "--add-opens=java.desktop/sun.awt.X11=ALL-UNNAMED",
        "--add-exports=java.desktop/sun.awt.wl=ALL-UNNAMED",
        "-Dawt.app.id=com.edde746.plezy",
    )
} else {
    listOf("--add-exports=java.desktop/sun.awt.windows=ALL-UNNAMED", "-Djava.net.useSystemProxies=true")
}
// version.xcconfig, through settings.gradle.kts.
val appVersion = project.extra["plezy.version"] as String

// mpv-jvm's extracted libmpv artifact, passed to the app as -Dplezy.mpv.dir, and packaged with the app (below).
val mpvNatives = configurations.dependencyScope("mpvNatives")
val mpvNativesPath = configurations.resolvable("mpvNativesPath") {
    extendsFrom(mpvNatives.get())
    attributes { attribute(Usage.USAGE_ATTRIBUTE, objects.named("plezy-mpv-natives")) }
}

dependencies {
    implementation(project(":ui-compose"))
    implementation(project(":mpv-jvm"))
    implementation(compose.desktop.currentOs)
    implementation(libs.kotlinx.coroutines.swing)
    implementation(libs.kotlinx.serialization.json)
    // AppGraph's HttpClient.
    implementation(libs.ktor.client.core)
    // Crash reports (Main.kt starts Sentry's Java SDK through ui-compose's SentryReports).
    implementation(libs.sentry.java)
    // MPRIS (linux/LinuxMediaControls.kt): compiled everywhere, shipped only in Linux builds.
    compileOnly(libs.dbus.java.core)
    if (isLinux) {
        implementation(libs.dbus.java.core)
        runtimeOnly(libs.dbus.java.transport.unixsocket)
    }
    add(mpvNatives.name, project(":mpv-jvm"))
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.coroutines.test)
    // The portal's answers in FileChooserPortalTest are dbus-java types, on every build host.
    testImplementation(libs.dbus.java.core)
}

// sqlite-jdbc carries its native library for every OS and architecture it supports (13 MB of its 14 MB jar). The app
// loads the one of the machine it runs on, which is the machine it was built on (each image is built on its own OS and
// architecture, as its Skiko library is), so the jar the app, the harness launcher and the tests take keeps only that
// one: org/sqlite/native/<OS>/<arch>/, in sqlite-jdbc's names (its OSInfo).
val sqliteNativeFolder = run {
    val os = System.getProperty("os.name")
    val osFolder = when {
        os.startsWith("Windows") -> "Windows"
        os.startsWith("Linux") -> "Linux"
        os.startsWith("Mac") -> "Mac"
        else -> throw GradleException("sqlite-jdbc has no native library folder for $os")
    }
    val archFolder = when (val arch = System.getProperty("os.arch")) {
        "amd64", "x86_64" -> "x86_64"
        "aarch64" -> "aarch64"
        else -> throw GradleException("sqlite-jdbc has no native library folder for $arch")
    }
    "$osFolder/$archFolder"
}

abstract class KeepSqliteNative : TransformAction<KeepSqliteNative.Parameters> {
    interface Parameters : TransformParameters {
        @get:Input
        val folder: Property<String>
    }

    @get:InputArtifact
    @get:PathSensitive(PathSensitivity.NAME_ONLY)
    abstract val jar: Provider<FileSystemLocation>

    override fun transform(outputs: TransformOutputs) {
        val input = jar.get().asFile
        if (!input.name.startsWith("sqlite-jdbc-")) {
            outputs.file(input)
            return
        }
        val natives = "org/sqlite/native/"
        val keep = natives + parameters.folder.get() + "/"
        var kept = 0
        ZipFile(input).use { zip ->
            ZipOutputStream(outputs.file(input.name).outputStream()).use { out ->
                for (entry in zip.entries()) {
                    // The folders above the kept one stay.
                    if (entry.name.startsWith(natives) && !keep.startsWith(entry.name) && !entry.name.startsWith(keep)) continue
                    if (entry.name.startsWith(keep) && !entry.isDirectory) kept++
                    out.putNextEntry(ZipEntry(entry.name).apply { time = entry.time })
                    zip.getInputStream(entry).use { it.copyTo(out) }
                    out.closeEntry()
                }
            }
        }
        if (kept == 0) throw GradleException("$input has no native library in $keep")
    }
}

val sqliteNatives = Attribute.of("com.edde746.plezy.sqlite-natives", String::class.java)
dependencies {
    attributesSchema { attribute(sqliteNatives) }
    artifactTypes.getByName("jar").attributes.attribute(sqliteNatives, "all")
    registerTransform(KeepSqliteNative::class) {
        from.attribute(sqliteNatives, "all")
        to.attribute(sqliteNatives, sqliteNativeFolder)
        parameters.folder.set(sqliteNativeFolder)
    }
}
configurations.matching { it.name in setOf("runtimeClasspath", "harnessRuntimeClasspath", "testRuntimeClasspath") }
    .configureEach { attributes.attribute(sqliteNatives, sqliteNativeFolder) }

// The modules the app ships, a group:name per line, for which :shared's ThirdPartyNoticesCoverageTest finds a notice.
tasks.register("shippedModules") {
    val modules = configurations.runtimeClasspath.map { classpath ->
        classpath.incoming.resolutionResult.allComponents
            .mapNotNull { (it.id as? ModuleComponentIdentifier)?.moduleIdentifier?.toString() }.sorted()
    }
    val output = layout.buildDirectory.file("shipped-modules.txt")
    inputs.property("modules", modules)
    outputs.file(output)
    doLast { output.get().asFile.writeText(modules.get().joinToString("\n")) }
}

val runtimeJdk = javaToolchains.launcherFor {
    languageVersion.set(JavaLanguageVersion.of(25))
    if (isLinux || isWindowsArm64) vendor.set(JvmVendorSpec.JETBRAINS)
}

// The licence texts each desktop app ships: its groups of the repository's licenses/ (licenses/apps.json), each with
// one folder per component.
val licenseApps = groovy.json.JsonSlurper()
    .parseText(providers.fileContents(rootProject.layout.projectDirectory.file("licenses/apps.json")).asText.get()) as Map<*, *>
val licenseGroups = listOf("linux", "windows").associateWith { os -> (licenseApps[os] as List<*>).map { it as String } }

// The app image's resources (app/resources; Compose takes common/ on every OS and linux/ or windows/ on that one): the
// packaged app's libmpv, from mpv-jvm's artifact: the library alone (libmpv-2.dll, or libmpv.so.2 as one file rather
// than its symlink chain), in mpv/, where MpvNatives looks when no directory is configured, and beside it in
// mpv/licenses/ the artifact's licenses/ as it is: the licence texts of every component linked into libmpv, one folder
// per component, which mpv-build collects from the sources it built; and in licenses/ the licence texts of what else the
// app ships (licenses/README.md). About shows both: the groups both desktops take in common/, the others in their OS's.
// Two groups never hold the same folder: the copy fails on a duplicate. An artifact without licence texts fails it too.
// mpv-build's Linux libmpv carries its DWARF (about 33 MB); the copy here loses it (strip --strip-debug, which keeps the
// build ID that matches it to the symbols zip tools/upload_symbols.sh uploads), so the packages ship it stripped.
val packagedResources = tasks.register<Sync>("packagedResources") {
    from(mpvNativesPath) {
        include("**/libmpv-2.dll", "**/libmpv.so.2", "licenses/**")
        into("common/mpv")
    }
    for (group in licenseGroups.values.flatten().distinct()) {
        val os = licenseGroups.filterValues { group in it }.keys.singleOrNull() ?: "common"
        from(rootProject.file("licenses/$group")) { into("$os/licenses") }
    }
    // The player's bundled shaders (one copy in the repository, which the Android app ships as assets).
    from(rootProject.file("android/mpv/src/main/assets/shaders")) { into("common/shaders") }
    includeEmptyDirs = false
    val destination = layout.buildDirectory.dir("app-resources")
    into(destination)
    val natives = files(mpvNativesPath)
    doFirst {
        val licenses = natives.singleFile.resolve("licenses")
        if (licenses.walk().none { it.isFile && it.length() > 0 }) {
            throw GradleException("libmpv's artifact has no licence texts in $licenses (mpv-build.lock.json's pin)")
        }
    }
    doLast {
        destination.get().asFile.walk().filter { it.name == "libmpv.so.2" }.forEach { library ->
            val status = ProcessBuilder("strip", "--strip-debug", library.absolutePath).inheritIO().start().waitFor()
            if (status != 0) throw GradleException("strip --strip-debug $library exited $status")
        }
    }
}

// ProGuard checks the jars' references against the JDK's classes, and keeps their overrides of JDK methods, by the
// runtime JDK's jmods/, which Compose gives it as library jars. Temurin's JDK 25 (the Windows x64 runtime) has none
// (JEP 493): with such a JDK they come from its run-time image (jrt:/), written into one jar here.
val runtimeJdkHome = runtimeJdk.get().metadata.installationPath.asFile
val proguardJdkRules = layout.buildDirectory.file("proguard/jdk.pro")
val proguardJdkClasses = tasks.register("proguardJdkClasses") {
    val home = runtimeJdkHome.absolutePath
    val version = runtimeJdk.get().metadata.javaRuntimeVersion
    val jar = layout.buildDirectory.file("proguard/jdk.jar")
    val rules = proguardJdkRules
    inputs.property("jdk", "$home $version")
    outputs.files(jar, rules)
    doLast {
        val out = jar.get().asFile
        FileSystems.newFileSystem(URI.create("jrt:/"), mapOf("java.home" to home)).use { jrt ->
            ZipOutputStream(out.outputStream().buffered()).use { zip ->
                Files.walk(jrt.getPath("/modules")).use { paths ->
                    // /modules/<module>/<package path>/<class>.class
                    for (path in paths.iterator()) {
                        val name = path.fileName?.toString() ?: continue
                        if (path.nameCount < 3 || !name.endsWith(".class") || name == "module-info.class") continue
                        zip.putNextEntry(ZipEntry(path.subpath(2, path.nameCount).joinToString("/")))
                        Files.copy(path, zip)
                        zip.closeEntry()
                    }
                }
            }
        }
        // The JDK's version makes a new JDK a new configuration for proguardReleaseJars.
        rules.get().asFile.writeText("# $version\n-libraryjars '${out.absolutePath}'\n")
    }
}

// `createReleaseDistributable` builds the app image the release packages wrap (desktop/app/packaging: the Flatpak, the
// Windows installer, portables and MSIX): the launcher, the app's jars as ProGuard shrank them (proguard-rules.pro),
// the resources above and a runtime linked from the JDK above, for the machine Gradle runs on (an arm64 image on
// Windows arm64). `createDistributable` builds the same image with the jars as they are.
compose.desktop.application {
    mainClass = mainClassName
    javaHome = runtimeJdkHome.absolutePath
    jvmArgs += appJvmFlags
    nativeDistributions {
        packageName = "Plezy"
        packageVersion = appVersion
        // Plezy.exe's version resource (CompanyName, FileDescription, LegalCopyright): Task Manager and the file's
        // properties show them.
        vendor = "com.edde746"
        description = "Plezy"
        copyright = "Copyright (C) 2025 edde746. All rights reserved."
        // Beyond Compose's defaults: what `./gradlew :app-desktop:suggestRuntimeModules` lists (java.sql for the
        // SQLite driver, jdk.unsupported, java.management, java.instrument; on Linux also jdk.security.auth, whose
        // UnixSystem gives dbus-java's authentication the user's uid), plus jdk.accessibility for screen readers on
        // Windows, and on Windows jdk.crypto.mscapi for its certificate store (the HTTP client's trusted roots). Run it
        // again on each OS when dependencies change: a missing module fails only at run time.
        modules("java.instrument", "java.management", "java.sql", "jdk.unsupported", "jdk.accessibility")
        if (isLinux) modules("jdk.security.auth")
        if (System.getProperty("os.name").startsWith("Windows")) modules("jdk.crypto.mscapi")
        appResourcesRootDir.set(layout.buildDirectory.dir("app-resources"))
        // Icons are generated by tools/brand/generate.sh.
        windows { iconFile.set(project.file("icons/plezy.ico")) }
        linux { iconFile.set(project.file("icons/plezy.png")) }
    }
    buildTypes.release.proguard {
        configurationFiles.from(project.file("proguard-rules.pro"))
        if (!runtimeJdkHome.resolve("jmods").isDirectory) {
            configurationFiles.from(files(proguardJdkRules).builtBy(proguardJdkClasses))
        }
        // Shrinking only: ProGuard's optimizer specializes return types the JVM's verifier then refuses (okio's
        // Okio__OkioKt.buffer: VerifyError on the first HTTP request), which shows only when a class first loads.
        optimize.set(false)
    }
}

tasks.matching { it.name == "prepareAppResources" }.configureEach { dependsOn(packagedResources) }
// Compose's packaging tasks (createDistributable and the rest) copy prepareAppResources' folder into the image but mark
// it @Internal, so a changed resource (libmpv, its stripped copy, a licence text) left an image up to date with the old
// one. The folder's contents are their input here.
tasks.withType<AbstractJPackageTask>().configureEach {
    inputs.files(appResourcesDir).withPropertyName("appResources").withPathSensitivity(PathSensitivity.RELATIVE)
}

// About's version (Main.kt reads it from the jar's manifest), the build number the update feed is compared with
// (Bootstrap.kt reads it), and the BuildFlavor's name from -Pplezy.flavor (settings.gradle.kts; Bootstrap.kt reads it):
// the release workflow builds the MSIX as store, the Flatpaks as sideloaded.
tasks.jar {
    manifest {
        attributes(
            "Implementation-Version" to appVersion,
            "Plezy-Build" to project.extra["plezy.build"].toString(),
            "Plezy-Flavor" to project.extra["plezy.flavor"] as String,
        )
    }
}

// The window icon for unpackaged runs (Main.kt), read from the classpath.
tasks.processResources { from("icons/plezy.png") { into("icons") } }

abstract class MpvDirArgument : CommandLineArgumentProvider {
    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val natives: ConfigurableFileCollection

    override fun asArguments() = listOf("-Dplezy.mpv.dir=${natives.singleFile.absolutePath}")
}

tasks.withType<JavaExec>().configureEach {
    jvmArgumentProviders += objects.newInstance<MpvDirArgument>().apply { natives.from(mpvNativesPath) }
}

// -- harness: the harness launcher --
// The harness launcher (harness/TestMain.kt: the app with its test-only options, the test report and the dev session,
// through Main.kt's runApp). Its own source set, the only one with :dev, keeps it out of the app's jar and runtime
// classpath, which the app image packages. The tests compile against it too (the report journal, the test options).
val harnessSources = sourceSets.create("harness")
kotlin.target.compilations.named("harness") { associateWith(kotlin.target.compilations.getByName("main")) }
kotlin.target.compilations.named("test") { associateWith(kotlin.target.compilations.getByName("harness")) }
dependencies { "harnessImplementation"(project(":dev")) }

// -Pplezy.harnessRelease=true: the harness launcher runs on ProGuard's jars (writeHarnessArgs, below). ProGuard then
// also takes the harness launcher's classes (as a jar) and what only it adds to the app's classpath (:dev, its
// libraries), which proguard-rules.pro keeps whole as Plezy's own code, so the library code they call stays: as
// Android's harness build type compiles its test extras into the R8 build. A release image built with it holds them
// too (a test image, never a release's).
val harnessRelease = providers.gradleProperty("plezy.harnessRelease").orNull.toBoolean()
if (harnessRelease) {
    val harnessJar = tasks.register<Jar>("harnessJar") {
        archiveClassifier.set("harness")
        from(harnessSources.output)
    }
    val harnessLibraries = harnessSources.runtimeClasspath - harnessSources.output -
        files(sourceSets.main.get().output) - files(configurations.runtimeClasspath)
    tasks.withType<AbstractProguardTask>().configureEach { inputFiles.from(harnessJar, harnessLibraries) }
}

/**
 * Writes, in build/run/:
 * - harness.args, a java @argfile (`java [jvm flags] @harness.args <main class> [arguments]`): the app's JVM flags, its
 *   libmpv directory, its resources folder (prepareAppResources', as the run task's: the licence texts About shows)
 *   and a classpath of the app's jar (its manifest names the version and flavor), the harness and their dependencies;
 *   with -Pplezy.harnessRelease=true (above) ProGuard's jars instead: the release image's, the harness's and :dev's;
 * - java.txt: the path of the runtime JDK's java executable (JetBrains Runtime on Linux);
 * - harness.classpath: the harness's entries the app image lacks (its classes, :dev), one per line, which
 *   a test run adds to a copy of the image's Plezy.cfg to start the harness
 *   launcher with the image's launcher, runtime and jars; none with -Pplezy.harnessRelease=true, whose image has them.
 */
tasks.register("writeHarnessArgs") {
    val jar = tasks.jar.flatMap { it.archiveFile }
    val classpath = harnessSources.runtimeClasspath
    val mainOutput = files(sourceSets.main.get().output)
    val appRuntime = files(configurations.runtimeClasspath)
    val releaseJars = files().apply { if (harnessRelease) from(tasks.named("proguardReleaseJars")) }
    val natives = files(mpvNativesPath)
    // prepareAppResources' output folder, as a file collection: the action keeps no task object.
    val appResources = files(tasks.named("prepareAppResources"))
    val java = runtimeJdk.map { it.executablePath.asFile.absolutePath }
    val jvmFlags = appJvmFlags
    val argsOut = layout.buildDirectory.file("run/harness.args")
    val javaOut = layout.buildDirectory.file("run/java.txt")
    val imageOut = layout.buildDirectory.file("run/harness.classpath")
    inputs.file(jar)
    inputs.files(classpath, appRuntime, releaseJars, natives, appResources)
    inputs.property("java", java)
    inputs.property("jvmFlags", jvmFlags)
    outputs.files(argsOut, javaOut, imageOut)
    doLast {
        // Forward slashes: backslashes are escapes inside quoted @argfile tokens.
        fun path(f: File) = f.absolutePath.replace('\\', '/')
        val app = mainOutput.files
        // Without the output directories a source set doesn't make (classes/java/harness: no Java sources).
        val harness = classpath.files.filter { it !in app && it.exists() }
        val entries = if (releaseJars.isEmpty) {
            listOf(jar.get().asFile) + harness
        } else {
            releaseJars.asFileTree.matching { include("*.jar") }.files.sortedBy { it.name != jar.get().asFile.name }
        }
        val cp = entries.joinToString(File.pathSeparator, transform = ::path)
        val flags = jvmFlags + listOf(
            "-Dplezy.mpv.dir=\"${path(natives.singleFile)}\"",
            "-Dcompose.application.resources.dir=\"${path(appResources.singleFile)}\"",
            "-cp \"$cp\"",
        )
        argsOut.get().asFile.writeText(flags.joinToString("\n", postfix = "\n"))
        javaOut.get().asFile.writeText(java.get() + "\n")
        val image = appRuntime.files
        val imageLacks = if (releaseJars.isEmpty) harness.filter { it !in image } else emptyList()
        imageOut.get().asFile.writeText(imageLacks.joinToString("\n", postfix = "\n") { it.absolutePath })
    }
}

// -- secrets: tests --
// The SecretStore contract (shared commonTest, secrets/) against this OS's store: Windows Credential Manager, which
// needs an interactive logon session, or libsecret, which needs a Secret Service on the session bus. Neither is a
// given on CI or over SSH, so the tests have their own source set and task: `secretStoreTest`, run in a desktop session.
val secretStoreTestSources = sourceSets.create("secretStoreTest")
kotlin.target.compilations.named("secretStoreTest") { associateWith(kotlin.target.compilations.getByName("main")) }
// Compiled here too, so that directory holds only the contract suite and uses only public API.
kotlin.sourceSets.named("secretStoreTest") { kotlin.srcDir("../../shared/src/commonTest/kotlin/com/edde746/plezy/secrets") }
dependencies {
    "secretStoreTestImplementation"(kotlin("test-junit"))
    "secretStoreTestImplementation"(libs.kotlinx.coroutines.test)
}
tasks.register<Test>("secretStoreTest") {
    description = "Runs the SecretStore contract against Windows Credential Manager or libsecret."
    group = "verification"
    testClassesDirs = secretStoreTestSources.output.classesDirs
    classpath = secretStoreTestSources.runtimeClasspath
    jvmArgs(nativeAccess)
}

