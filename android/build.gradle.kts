allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Force compileSdk 36 for plugins (e.g. vibration) compiled against old SDKs
subprojects {
    afterEvaluate {
        if (project.name != "app") {
            extensions.findByName("android")?.let { ext ->
                try {
                    ext.javaClass
                        .getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                        .invoke(ext, 36)
                } catch (e: Exception) {
                    println("Could not set compileSdk for ${project.name}: ${e.message}")
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}