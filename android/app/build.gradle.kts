import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (Pixel-only for now). The keystore and its passwords
// live only on the developer's machine: android/key.properties is
// gitignored and points at a keystore stored outside the repo. See
// docs/RELEASING.md. Without it, release builds fall back to the debug
// key so `flutter run --release` still works (e.g. in CI).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKey = keystorePropertiesFile.exists()

// Fail early with a clear message instead of "getProperty(...) must not
// be null" when key.properties is incomplete, misspelled or not plain text.
// Only the expected names are reported, never anything else in the file,
// so a stray password can't end up in the build log.
val signingNames = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

fun signingProperty(name: String): String {
    val value = keystoreProperties.getProperty(name)
    if (value.isNullOrBlank()) {
        val present = signingNames.filter {
            !keystoreProperties.getProperty(it).isNullOrBlank()
        }
        throw GradleException(
            "android/key.properties has no '$name'. It must be a plain-text " +
                "file with these lines: ${signingNames.joinToString { "$it=..." }} " +
                "(see docs/RELEASING.md). Found: " +
                present.joinToString().ifEmpty { "none of them" } + "."
        )
    }
    return value
}

android {
    namespace = "com.caljess.nudge"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications for scheduled
        // notifications on older Android versions.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.caljess.nudge"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
                storePassword = signingProperty("storePassword")
                storeFile = file(signingProperty("storeFile")).also {
                    if (!it.exists()) {
                        throw GradleException(
                            "Keystore not found at '$it' (storeFile in " +
                                "android/key.properties). Use the full path, " +
                                "e.g. /Users/you/nudge-upload.jks."
                        )
                    }
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Nudge: android/key.properties not found, signing the " +
                        "release build with the debug key."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
