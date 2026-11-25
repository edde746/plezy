import co.touchlab.skie.configuration.SuppressSkieWarning
import co.touchlab.skie.plugin.configuration.SkieExtension
import com.android.build.api.dsl.KotlinMultiplatformAndroidLibraryTarget
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.KotlinPlatformType
import org.jetbrains.kotlin.gradle.plugin.mpp.NativeBuildType

// Test-only code no release build links: the development session (DevSession.kt: `--dev` on desktop and Apple, the
// launch extras of Android's debug and harness builds), the test report's UiState→JSON model (jvmAndAndroidMain:
// Android's debug and harness builds and the desktop harness launcher write the same report). Android links it from
// its debug and harness build types, desktop from its harness source set, Apple from its Debug configuration.
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library) apply false
}

// SKIE, as :shared applies it for Release's PlezyKit (only on macOS, where Apple frameworks build), for Debug's
// below.
if (System.getProperty("os.name").startsWith("Mac")) {
    apply(plugin = libs.plugins.skie.get().pluginId)
    extensions.configure<SkieExtension> {
        // As in :shared: no bundled Swift, so the compile's cache key holds no absolute path.
        swiftBundling { enabled.set(false) }
        features {
            // As in :shared: Ktor's HttpStatusCode.description reaches Swift as description_, which Swift never reads.
            group("io.ktor.http.HttpStatusCode") { SuppressSkieWarning.NameCollision(true) }
        }
    }
}

// Hosts without an Android SDK build with -Pplezy.android=false (settings.gradle.kts), as :shared does.
val androidEnabled = extra["plezy.android"] as Boolean
if (androidEnabled) apply(plugin = libs.plugins.android.kmp.library.get().pluginId)

kotlin {
    jvmToolchain(27)

    applyDefaultHierarchyTemplate {
        common {
            group("jvmAndAndroid") {
                withJvm()
                withCompilations { it.target.platformType == KotlinPlatformType.androidJvm }
            }
        }
    }

    if (androidEnabled) {
        extensions.configure<KotlinMultiplatformAndroidLibraryTarget>("android") {
            namespace = "com.edde746.plezy.dev"
            compileSdk = 37
            minSdk = 25
            compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
        }
    }
    jvm {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    // The Apple Debug configuration's PlezyKit (the one umbrella framework, since each KMP framework would embed a
    // Kotlin runtime of its own): :shared exported with the development session, built by the Xcode script phase
    // (`:dev:embedAndSignAppleFrameworkForXcode`). Release links :shared's PlezyKit, which has no development
    // session.
    listOf(iosArm64(), iosSimulatorArm64(), macosArm64(), tvosArm64(), tvosSimulatorArm64()).forEach { target ->
        target.binaries.framework(listOf(NativeBuildType.DEBUG)) {
            baseName = "PlezyKit"
            isStatic = true
            // Explicit, or Kotlin/Native warns on every link that it cannot infer one.
            binaryOption("bundleId", "com.edde746.plezy.PlezyKit")
            export(project(":shared"))
        }
    }

    sourceSets {
        commonMain.dependencies {
            api(project(":shared"))
            implementation(libs.kotlinx.coroutines.core)
            implementation(libs.ktor.client.mock)
        }
        getByName("jvmAndAndroidMain").dependencies {
            api(libs.kotlinx.serialization.json)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
        // The dev session's sign-in against a Jellyfin the tests fake (DevServersTest), on the desktop's database driver.
        jvmTest.dependencies {
            implementation(libs.ktor.client.mock)
        }
    }
}

// The app's cast receiver listens on the cast port (48640), else on a free one, and the demo phone (DevServersTest)
// reaches it over loopback. A JVM's socket is dual stack, and on macOS it binds a port another process's IPv4 socket
// listens on, which then gets every IPv4 connection: a Plezy app running on the Mac took the demo phone's. An IPv4
// socket's bind fails there, so the receiver takes a free port, as it does on Linux and Windows.
tasks.named<Test>("jvmTest") { systemProperty("java.net.preferIPv4Stack", "true") }
