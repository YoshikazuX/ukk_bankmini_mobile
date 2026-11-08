import java.util.Properties
import java.io.FileInputStream

// Load keystore properties if they exist
val keystorePropertiesFile = listOf(
    rootProject.file("keystore.properties"),
    rootProject.file("key.properties"),
    rootProject.file("android/keystore.properties"),
    project.file("keystore.properties"),
    project.file("key.properties")
).firstOrNull { it.exists() }
val keystoreProperties = Properties()
if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
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
        if (keystorePropertiesFile != null && keystorePropertiesFile.exists()) {
            create("releaseSigning") {
                val storePath = keystoreProperties["storeFile"] as String
                val resolvedFile = File(storePath).let { f ->
                    if (f.isAbsolute) f
                    else if (file(storePath).exists()) file(storePath)
                    else rootProject.file(storePath)
                }
                storeFile = resolvedFile
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
            if (keystorePropertiesFile != null && keystorePropertiesFile.exists() && signingConfigs.findByName("releaseSigning") != null) {
                signingConfig = signingConfigs.getByName("releaseSigning")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
