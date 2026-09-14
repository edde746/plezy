import com.android.build.api.variant.LibraryAndroidComponentsExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        // This project still runs Flutter's legacy KGP mode. AGP 9-aware
        // plugins such as file_picker may otherwise assume built-in Kotlin
        // and leave their src/main/kotlin entry points uncompiled.
        if (name == "file_picker" && !pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { extension ->
                // Plugin modules can lag the app's Android tools even when
                // their dependencies already require current APIs.
                extension.compileSdk = 36
                extension.buildToolsVersion = "36.1.0"
                // The Flutter plugin copies the app's build types into every plugin
                // module, so `minified` arrives here carrying the app's shrinker flags.
                // Library-level shrinking then deletes the plugin entry points that only
                // GeneratedPluginRegistrant references, and the app's R8 fails on the
                // missing classes. Only the app should shrink.
                extension.buildTypes.findByName("minified")?.isMinifyEnabled = false
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
