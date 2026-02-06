plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.habitiurs"
    compileSdk = flutter.compileSdkVersion
    // MODIFICA ESTA LÍNEA:
    ndkVersion = "27.0.12077973" // <-- Cambia de flutter.ndkVersion a la versión directa
    // Opcional: Si tienes problemas para que Android Studio te muestre la versión actual,
    // puedes intentar esto si la línea de arriba no funciona:
    // ndkVersion = "27.0.12077973" as String // Esto fuerza que sea un String si hay algún problema de tipo
    // Mantenemos esta línea, pero ahora el valor será el que pusimos directamente arriba.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ... (el resto de tu defaultConfig)
        applicationId = "com.example.habitiurs"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}