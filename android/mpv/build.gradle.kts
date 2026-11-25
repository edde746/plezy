// Plezy's Android engine (MpvPlayerEngine, its Surfaces and views).
//
// It plays through mpv-build's mpv-android library (com.edde746.mpv): one AAR with the JNI glue and its Kotlin API,
// the playback helpers (GpuVoPolicy, MediaCodecQuery, GlCapabilities, MpvPlaceholderSurface,
// VideoRectPolicy), libmpv, FFmpeg and libc++_shared.so for every ABI, and the R8 rules for the names the native code
// resolves. The AAR is pinned in mpv-build.lock.json; settings.gradle.kts declares where Gradle fetches it and names
// it `mpv.aar`.
plugins {
    alias(libs.plugins.android.library)
}

android {
    namespace = "com.edde746.plezy.mpv"
    compileSdk = 37

    defaultConfig {
        minSdk = 25
        // Device tests against real libmpv (src/androidTest), on a connected device.
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    api(project(":shared"))
    implementation(project.extra["mpv.aar"] as String)
    // The decoder hold's answer and release (DecoderHoldGate).
    implementation(libs.kotlinx.coroutines.core)
    // Unit tests (src/test): the frame-rate vote's and the passthrough probe's rules, on JUnit 4 as AGP runs them.
    testImplementation(kotlin("test-junit"))
    androidTestImplementation(kotlin("test-junit"))
    androidTestImplementation(libs.androidx.test.runner)
}
