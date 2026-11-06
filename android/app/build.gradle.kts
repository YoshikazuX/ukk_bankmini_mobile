import java.util.Properties
import java.io.FileInputStream

// Load keystore properties if they exist
val keystorePropertiesFile = rootProject.file("android/keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hanbank.bankmini"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hanbank.bankmini"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Create release signing config only if keystore properties are present.
        if (keystorePropertiesFile.exists()) {
            create("releaseSigning") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Debug builds use the default debug signing config (no keystore required).
        }
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("releaseSigning")
            } else {
                // Only abort when a release build is requested.
                if (gradle.startParameter.taskNames.any { it.contains("Release") }) {
                    throw GradleException("Keystore properties file not found at android/keystore.properties. Release build cannot proceed.")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
