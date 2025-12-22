plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.deliber.app"
    compileSdk = 36
    buildToolsVersion = "36.0.0"

    defaultConfig {
        applicationId = "com.deliber.app"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.firebase:firebase-messaging-ktx:24.0.3")
    implementation("com.google.firebase:firebase-analytics-ktx:22.1.2")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

val flutterApkOut = rootProject.projectDir.parentFile
    .resolve("build/app/outputs/flutter-apk")

tasks.register<Copy>("copyFlutterDebugApk") {
    from(layout.buildDirectory.dir("outputs/flutter-apk"))
    into(flutterApkOut)
    include("app-debug.apk")
}

tasks.matching { it.name == "assembleDebug" }.configureEach {
    finalizedBy("copyFlutterDebugApk")
}
