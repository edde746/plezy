group = "com.fluttercavalry.saf_util"
version = "1.0-SNAPSHOT"

buildscript {
  val kotlinVersion = "2.3.20"
  repositories {
    google()
    mavenCentral()
  }

  dependencies {
    classpath("com.android.tools.build:gradle:9.0.1")
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
  }
}

allprojects {
  repositories {
    google()
    mavenCentral()
  }
}

plugins {
  id("com.android.library")
}

android {
  namespace = "com.fluttercavalry.saf_util"

  compileSdk = 36

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }

  sourceSets {
    getByName("main") {
      java.srcDirs("src/main/kotlin")
    }
    getByName("test") {
      java.srcDirs("src/test/kotlin")
    }
  }

  defaultConfig {
    minSdk = 24
  }

  testOptions {
    unitTests {
      isIncludeAndroidResources = true
      isReturnDefaultValues = true
      all {
        it.useJUnitPlatform()

        it.outputs.upToDateWhen { false }

        it.testLogging {
          events("passed", "skipped", "failed", "standardOut", "standardError")
          showStandardStreams = true
        }
      }
    }
  }
}

kotlin {
  compilerOptions {
    jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
  }
}

dependencies {
  implementation("androidx.documentfile:documentfile:1.1.0")
  testImplementation("org.jetbrains.kotlin:kotlin-test")
  testImplementation("org.mockito:mockito-core:5.14.2")
  testImplementation("junit:junit:4.13.2")
  testImplementation("org.robolectric:robolectric:4.15.1")
  testRuntimeOnly("org.junit.vintage:junit-vintage-engine:5.11.4")
}
