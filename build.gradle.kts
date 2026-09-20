// Top-level build file for the YOLO Edition application.
//
// This repository is a thin application over Core Edition's sailens-* libraries, consumed through
// a Gradle composite build (see settings.gradle.kts). It is no longer a fork: there is no merge
// base to preserve and no zero-code-difference invariant to keep.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
