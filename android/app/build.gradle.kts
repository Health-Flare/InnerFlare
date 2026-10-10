import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config, loaded from android/key.properties (see
// docs/deployment/android-release.md). That file is gitignored and never
// committed. Without it a release build fails rather than silently signing
// with the debug key; pass -PallowDebugSigning=true (or set
// ORG_GRADLE_PROJECT_allowDebugSigning=true) to opt in to that for a quick
// local `flutter run --release`.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val allowDebugSigning =
    providers.gradleProperty("allowDebugSigning").orNull?.toBoolean() ?: false

// Checked once the task graph is known, not at configuration time: the
// release buildType is configured for debug builds too, and those must keep
// working with no key.properties.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (buildsRelease && !hasKeystoreProperties && !allowDebugSigning) {
        throw GradleException(
            "Release build without android/key.properties. Refusing to sign " +
                "with the debug key. Create key.properties (see " +
                "docs/deployment/android-release.md), or pass " +
                "-PallowDebugSigning=true for a local, never-distributed build.",
        )
    }
}

android {
    namespace = "org.healthflare.app.innerflare"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time APIs that need desugaring
        // on API levels below 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "org.healthflare.app.innerflare"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signs with the key in android/key.properties (see
            // docs/deployment/android-release.md). The debug-key branch is only
            // reachable with -PallowDebugSigning=true: see the taskGraph check
            // above.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // proguard-rules.pro keeps the SQLCipher native bindings alive if
            // minification is ever turned on here.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
