// libmpv over the JDK 25 FFM API plus the per-OS video hosts:
// jextract bindings for client.h/render.h/render_gl.h in src/main/java (regenerate with jextract/generate.sh),
// handwritten Win32 (mpv in a child window under Compose) and Wayland/EGL (mpv's render API into a subsurface below
// the window) glue in src/main/kotlin.
plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.kotlin.compose)
    id("plezy.mpv-artifacts")
}

kotlin { jvmToolchain(25) }

// Natives for the machine this build runs on: Windows hosts fetch the windows group, everything else linux (the Mac
// only compiles, and uses the headers when regenerating the bindings).
val mpvGroup = if (System.getProperty("os.name").startsWith("Windows")) "windows" else "linux"
val mpvVariant = when (val arch = System.getProperty("os.arch")) {
    "amd64", "x86_64" -> "x86_64"
    "aarch64", "arm64" -> "aarch64"
    else -> throw GradleException("No libmpv artifact for os.arch=$arch")
}
mpvArtifacts { group.set(mpvGroup) }
val fetchNatives = "fetchMpv" + mpvVariant.split('_').joinToString("") { it.replaceFirstChar(Char::uppercase) }
val mpvDir = layout.buildDirectory.dir("mpv/$mpvVariant")

// The extracted artifact (build/mpv/<variant>/) as an outgoing artifact, so app-desktop can hand its path to the JVM
// as -Dplezy.mpv.dir without reaching into this project.
val mpvNatives = configurations.consumable("mpvNatives") {
    attributes { attribute(Usage.USAGE_ATTRIBUTE, objects.named("plezy-mpv-natives")) }
}
artifacts.add(mpvNatives.name, mpvDir) { builtBy(fetchNatives) }

dependencies {
    api(project(":shared"))
    api(libs.compose.foundation)
    implementation(libs.kotlinx.coroutines.swing)
    implementation(libs.kotlinx.serialization.json)
    testImplementation(kotlin("test-junit"))
}

// The subtitle fonts Android's engine ships (Go Noto Current and its Hangul companion, SIL OFL 1.1) as resources under
// subtitle-fonts/: the engine writes them out for mpv's sub-fonts-dir (SubtitleFonts).
val subtitleFonts = tasks.register<Sync>("subtitleFonts") {
    from(rootProject.file("android/mpv/src/main/assets/subtitle-fonts"))
    into(layout.buildDirectory.dir("generated/subtitle-fonts/subtitle-fonts"))
}
sourceSets.main { resources.srcDir(subtitleFonts.map { it.destinationDir.parentFile }) }

// -- libmpv: tests --
// The engine (windowless, `vo=null`) and its mpv handle on this machine's libmpv, the extracted artifact above:
// `:mpv-jvm:libmpvTest`, on Windows and on Linux desktops. Not in `test`, which CI runs: libmpv links system libraries
// CI doesn't install (vulkan-1.dll on Windows; VA-API, PipeWire and more on Linux), and the Mac's artifact is Linux's.
// On Linux libmpv also needs the three Ubuntu libraries MpvNatives preloads, from the directory PLEZY_MPV_PRELOAD
// names (the test harnesses set it on Linux hosts). The music player's gapless test plays the two tracks
// `-Pplezy.audioUrls=<url>,<url>` names, else two it writes itself. Each test's result and output show in the build's
// log: what a machine's mpv did there (its audio output, for one) is read from it.
val libmpvTestSources = sourceSets.create("libmpvTest")
kotlin.target.compilations.named("libmpvTest") { associateWith(kotlin.target.compilations.getByName("main")) }
dependencies { "libmpvTestImplementation"(kotlin("test-junit")) }
tasks.register<Test>("libmpvTest") {
    description = "Runs MpvCore and the engine against this machine's libmpv."
    group = "verification"
    testClassesDirs = libmpvTestSources.output.classesDirs
    classpath = libmpvTestSources.runtimeClasspath
    dependsOn(fetchNatives)
    systemProperty("plezy.mpv.dir", mpvDir.get().asFile.absolutePath)
    providers.environmentVariable("PLEZY_MPV_PRELOAD").orNull?.let { systemProperty("plezy.mpv.preload", it) }
    providers.gradleProperty("plezy.audioUrls").orNull?.let { systemProperty("plezy.audio.urls", it) }
    jvmArgs("--enable-native-access=ALL-UNNAMED")
    testLogging {
        showStandardStreams = true
        events("passed", "failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
    }
}
