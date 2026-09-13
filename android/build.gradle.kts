allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // TODO: Remove these pins once https://github.com/ABausG/home_widget/issues/417
    //       is closed and the fix is available in a stable home_widget release.
    configurations.configureEach {
        resolutionStrategy.force(
            "androidx.glance:glance-appwidget:1.1.1",
            "androidx.work:work-runtime:2.9.1",
            "androidx.work:work-runtime-ktx:2.9.1",
        )
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
