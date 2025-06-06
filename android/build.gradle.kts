buildscript {
    val kotlin_version = "1.9.23" // Latest stable as of June 2025

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0") // Latest stable
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.4.2") // Latest stable
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "2.9.9" apply false // Added for Firebase stability
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Build directory customization
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Force consistent Kotlin version across all subprojects
    afterEvaluate {
        if (project.plugins.hasPlugin("kotlin-android")) {
            project.extensions.getByType<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>()
                .jvmToolchain(17) // Java 17 compatibility
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}