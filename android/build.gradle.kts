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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val configureAndroid = Action<Project> {
        if (hasProperty("android")) {
            val android = extensions.getByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                if (android.namespace == null) {
                    val group = project.group.toString()
                    android.namespace = if (group.isNotEmpty()) group else "dev.isar.${project.name.replace("-", "_")}"
                }
                // Try to set versions. If it's already too late for some, we might need a different strategy,
                // but usually compileSdkVersion can be set in afterEvaluate if not already finalized.
                try {
                    android.compileSdkVersion(34)
                    android.defaultConfig.targetSdkVersion(34)
                } catch (e: Exception) {
                    // Log or handle if needed
                }
            }
        }
    }

    if (state.executed) {
        configureAndroid.execute(this)
    } else {
        afterEvaluate { configureAndroid.execute(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
