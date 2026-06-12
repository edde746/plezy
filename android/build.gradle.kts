allprojects {
    repositories {
        google()
        mavenCentral()
        if (providers.gradleProperty("localAssCore").isPresent) {
            // Opt-in A/B of a locally built libass native core: build it in the
            // libass-android fork with `./gradlew :lib_ass:publishToMavenLocal
            // -PVERSION_NAME=0.4.0-local`, then build this app with -PlocalAssCore.
            mavenLocal()
        } else {
            // Production libass native core: the -O3/NEON/asm AAR published on
            // the edde746/libass-android fork's releases (the upstream Maven
            // artifact io.github.peerless2012:ass ships un-optimized natives —
            // see the fork's pinned libass-cmake fix). Resolved as
            // <tag>/ass-<tag>.aar with no metadata probing.
            exclusiveContent {
                forRepository {
                    ivy {
                        url = uri("https://github.com/edde746/libass-android/releases/download")
                        patternLayout { artifact("[revision]/[artifact]-[revision].[ext]") }
                        metadataSources { artifact() }
                    }
                }
                filter { includeModule("io.github.peerless2012", "ass") }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
