pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
    // This distribution consumes Sailens Android's version catalog on purpose: AGP, Kotlin and the
    // AndroidX stack stay aligned with the modules it builds against. The submodule commit is the
    // version boundary -- nothing is published to Maven and there is no artifact version to bump
    // (architecture.md §7).
    versionCatalogs {
        create("libs") {
            from(files("sailens/gradle/libs.versions.toml"))
        }
    }
}

// Sailens Android as a composite build. At settings top level, not inside pluginManagement: this is
// what makes Gradle substitute the local sailens-* projects for the "com.sailens:..." coordinates
// the app asks for (architecture.md §7).
includeBuild("sailens")

rootProject.name = "SailensApp"
include(":app")
