import com.android.build.api.dsl.KotlinMultiplatformAndroidLibraryTarget
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

// Compose UI shared by app-android and app-desktop (Material 3 Expressive, monochromatic).
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library) apply false
    alias(libs.plugins.compose.multiplatform)
    alias(libs.plugins.kotlin.compose)
}

// Hosts without an Android SDK build with -Pplezy.android=false (settings.gradle.kts). The Android plugin then
// isn't applied at all: applied without its target, it fails configuration ("compileSdk version is not set").
// Android Lint analyses a KMP library's Android target only with its own plugin (shared/build.gradle.kts).
val androidEnabled = extra["plezy.android"] as Boolean
if (androidEnabled) {
    apply(plugin = libs.plugins.android.kmp.library.get().pluginId)
    apply(plugin = libs.plugins.android.lint.get().pluginId)
}

kotlin {
    jvmToolchain(27)

    if (androidEnabled) {
        extensions.configure<KotlinMultiplatformAndroidLibraryTarget>("android") {
            namespace = "com.edde746.plezy.ui"
            compileSdk = 37
            minSdk = 25
            compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
        }
    }
    jvm {
        compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
    }

    sourceSets {
        commonMain.dependencies {
            api(project(":shared"))
            api(libs.compose.runtime)
            api(libs.compose.foundation)
            api(libs.compose.ui)
            api(libs.compose.material3)
            // Navigation 3: it draws the shared PlezyNavigator's back stack (a StateFlow the app owns), so screens
            // navigate through their stores' host interfaces and routes stay plain Kotlin values.
            api(libs.navigation3.ui)
            // Posters and backgrounds through the app's HttpClient (AppGraph.http).
            implementation(libs.coil.compose)
            implementation(libs.coil.network.ktor3)
            implementation(libs.ktor.client.core)
            // QR codes (Watch together's invite). A Java library: commonMain compiles only for the JVM and Android.
            implementation(libs.zxing.core)
            // Crash reports (crash/SentryReports): Sentry's Java SDK, which both apps' Sentry setups build on.
            implementation(libs.sentry.java)
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
        jvmTest.dependencies {
            // The UI tests compose screens through Compose's UI test API, on this host's Skia build.
            implementation(libs.compose.ui.test)
            implementation(compose.desktop.currentOs)
            // The artwork loader's tests answer its requests.
            implementation(libs.ktor.client.mock)
        }
    }
}

// The desktop UI tests need AWT's toolkit (the player's hidden pointer is a custom cursor). On Windows, JDK 25 and 27 take
// a session without an interactive desktop (OpenSSH's, where remote builds run) as headless, which JDK 21 didn't; the
// toolkit works there all the same.
tasks.named<Test>("jvmTest") { systemProperty("java.awt.headless", "false") }
