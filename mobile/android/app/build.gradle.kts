plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.deliber.app"
    // Ajustado a 36 para compatibilidad con plugins y dependencias AndroidX
    compileSdk = 36

    defaultConfig {
        applicationId = "com.deliber.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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
        debug {
            isDebuggable = true
            isMinifyEnabled = false
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // AndroidX Core
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")

    // Java 8+ Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")

    // Firebase (Gestionado por BoM)
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")

    // Multidex para evitar errores de límite de 64k métodos
    implementation("androidx.multidex:multidex:2.0.1")

    // NOTA: Se eliminó 'com.google.android.play:core' para resolver conflictos de duplicidad de clases.
    // Los plugins de Flutter gestionan sus dependencias de Play Services internamente.
}

/* Tarea para sincronizar el APK generado con la ruta esperada por Flutter */
afterEvaluate {
    val assembleDebugTask = tasks.findByName("assembleDebug")
    val assembleReleaseTask = tasks.findByName("assembleRelease")

    listOfNotNull(assembleDebugTask, assembleReleaseTask).forEach { assembleTask ->
        tasks.register<Copy>("forceCopyApkToFlutterDefault_${assembleTask.name}") {
            dependsOn(assembleTask)

            val flutterProjectRoot = file("${rootProject.projectDir.parent}")
            val sourceApkDir = file("$buildDir/outputs/flutter-apk")
            val flutterDefaultDir = file("${flutterProjectRoot}/build/app/outputs/flutter-apk")

            from(sourceApkDir)
            include("*.apk")
            into(flutterDefaultDir)

            doFirst {
                println("Iniciando copia técnica del APK...")
                flutterDefaultDir.mkdirs()
            }

            doLast {
                val apkFiles = flutterDefaultDir.listFiles { file -> file.extension == "apk" }
                if (!apkFiles.isNullOrEmpty()) {
                    println("Build exitoso. APK disponible en: ${flutterDefaultDir.absolutePath}")
                }
            }
        }.also { copyTask ->
            assembleTask.finalizedBy(copyTask)
        }
    }
}
