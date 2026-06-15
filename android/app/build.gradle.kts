import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Đọc key.properties để build local (file này không được commit)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.nks.hoczita"
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
        applicationId = "com.nks.hoczita"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // CI: đọc từ env vars (GitHub Secrets)
            // Local: đọc từ android/key.properties
            val envStore = System.getenv("STORE_FILE")
            val envStorePass = System.getenv("STORE_PASSWORD")
            val envKeyAlias = System.getenv("KEY_ALIAS")
            val envKeyPass = System.getenv("KEY_PASSWORD")

            storeFile = if (envStore != null) file(envStore)
                        else keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = envStorePass ?: keystoreProperties["storePassword"] as String?
            keyAlias = envKeyAlias ?: keystoreProperties["keyAlias"] as String?
            keyPassword = envKeyPass ?: keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
