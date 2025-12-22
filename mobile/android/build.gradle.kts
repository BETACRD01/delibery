// Configuración global para todos los módulos
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
// Tarea de limpieza estándar para Gradle 8.x
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}