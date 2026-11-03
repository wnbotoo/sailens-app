import java.security.MessageDigest
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
}

val enableLitertNpuRuntime = providers.gradleProperty("sailens.enableLitertNpuRuntime")
    .map { it.toBooleanStrict() }
    .getOrElse(false)

val appVersionCode = providers.gradleProperty("sailens.versionCode")
    .map { value ->
        value.toIntOrNull()
            ?.takeIf { it in 1..2_100_000_000 }
            ?: error("sailens.versionCode must be an integer in 1..2100000000 (was '$value').")
    }
    .getOrElse(1)
val appVersionName = providers.gradleProperty("sailens.versionName")
    .map { value -> value.takeIf { it.isNotBlank() } ?: error("sailens.versionName must not be blank.") }
    .getOrElse("1.0")

val appSigningKeystorePath = providers.environmentVariable("SAILENS_APP_SIGNING_KEYSTORE")
val appSigningStorePassword = providers.environmentVariable("SAILENS_APP_SIGNING_STORE_PASSWORD")
val appSigningKeyAlias = providers.environmentVariable("SAILENS_APP_SIGNING_KEY_ALIAS")
val appSigningKeyPassword = providers.environmentVariable("SAILENS_APP_SIGNING_KEY_PASSWORD")
val appSigningValues = listOf(
    appSigningKeystorePath,
    appSigningStorePassword,
    appSigningKeyAlias,
    appSigningKeyPassword,
)
val configuredAppSigningValues = appSigningValues.count { it.isPresent }
check(configuredAppSigningValues == 0 || configuredAppSigningValues == appSigningValues.size) {
    "App signing must configure all of SAILENS_APP_SIGNING_KEYSTORE, " +
        "SAILENS_APP_SIGNING_STORE_PASSWORD, SAILENS_APP_SIGNING_KEY_ALIAS and SAILENS_APP_SIGNING_KEY_PASSWORD."
}
val appSigningConfigured = configuredAppSigningValues == appSigningValues.size
val litertNpuRuntimeRoot = rootProject.layout.projectDirectory.dir("sailens/litert_npu_runtime_libraries_jit").asFile
val litertNpuRuntimeFeatureModules = listOf(
    "qualcomm_runtime_v81",
    "qualcomm_runtime_v79",
    "qualcomm_runtime_v75",
    "qualcomm_runtime_v73",
    "qualcomm_runtime_v69",
)
val missingLitertNpuRuntimeFeatures = litertNpuRuntimeFeatureModules.filterNot { moduleName ->
    litertNpuRuntimeRoot.resolve(moduleName).resolve("build.gradle.kts").isFile
}
val hasLitertNpuRuntimeStrings =
    litertNpuRuntimeRoot.resolve("runtime_strings").resolve("build.gradle.kts").isFile
if (enableLitertNpuRuntime) {
    check(hasLitertNpuRuntimeStrings && missingLitertNpuRuntimeFeatures.isEmpty()) {
        "sailens.enableLitertNpuRuntime=true requires runtime_strings and all Qualcomm LiteRT NPU " +
            "runtime feature modules under ${litertNpuRuntimeRoot.path}; " +
            "missingFeatures=${missingLitertNpuRuntimeFeatures.joinToString()}, " +
            "runtimeStringsPresent=$hasLitertNpuRuntimeStrings"
    }
}
val availableLitertNpuRuntimeFeatures = litertNpuRuntimeFeatureModules
    .takeIf { enableLitertNpuRuntime }
    .orEmpty()
    .map { moduleName -> ":litert_npu_runtime_libraries_jit:$moduleName" }
    .toSet()

// Build provenance for recorded data (field captures from debug builds): which code and which model
// weights produced the APK. Here the weights are tracked and the platform is pinned, so this
// repository's commit identifies all three; the hashes still record the weights actually packaged.
//
// Commit: HEAD, with "-dirty" when `git status --porcelain` lists anything -- modified or untracked
// files alike, a sailens/ checkout that is not the pinned commit included. Empty when git is
// unavailable (a source archive). Same command as Sailens Android's reference host, whose
// scripts/test_build_identity.py locks its semantics.
val buildGitSha: String = runCatching {
    val sha = providers.exec { commandLine("git", "rev-parse", "HEAD") }
        .standardOutput.asText.get().trim()
    val dirty = providers.exec { commandLine("git", "status", "--porcelain") }
        .standardOutput.asText.get().isNotBlank()
    if (Regex("[0-9a-f]{40}").matches(sha)) sha + (if (dirty) "-dirty" else "") else ""
}.getOrDefault("")

/**
 * Writes `build_provenance.json` into a generated assets directory: the commit and the SHA-256 of
 * every packaged `.tflite`. Hashing happens here, once per changed model, never at capture time.
 */
abstract class GenerateBuildProvenance : DefaultTask() {
    @get:Input
    abstract val gitSha: Property<String>

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.NAME_ONLY)
    abstract val models: ConfigurableFileCollection

    @get:OutputDirectory
    abstract val outputDir: DirectoryProperty

    @TaskAction
    fun generate() {
        val hashes = models.files.filter { it.isFile }.sortedBy { it.name }.map { file ->
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().use { input ->
                val buffer = ByteArray(1 shl 16)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    digest.update(buffer, 0, read)
                }
            }
            file.name to "sha256:" + digest.digest().joinToString("") { "%02x".format(it) }
        }
        val artifacts = hashes.joinToString(",") { (name, hash) -> "\"$name\":\"$hash\"" }
        val out = outputDir.get().asFile
        out.mkdirs()
        out.resolve("build_provenance.json")
            .writeText("{\"gitSha\":\"${gitSha.get()}\",\"modelArtifacts\":{$artifacts}}\n")
    }
}

val generateBuildProvenance = tasks.register<GenerateBuildProvenance>("generateBuildProvenance") {
    gitSha.set(buildGitSha)
    models.from(fileTree("src/main/assets") { include("*.tflite") })
}

android {
    namespace = "com.sailens"
    compileSdk = 37

    defaultConfig {
        // The official Sailens product owns the plain com.sailens Play identity. Namespace stays
        // com.sailens as well, but for a different reason: it is the source/resource namespace and
        // does not need to move. The Sailens Android reference host uses com.sailens.reference, so
        // both applications remain installable side by side. Manifest placeholders derived from
        // applicationId (FileProvider, WorkManager receiver permission, etc.) follow automatically.
        applicationId = "com.sailens"
        // Android 12 (API 31). 31 is the floor for Build.SOC_MANUFACTURER/SOC_MODEL used by
        // DeviceHardwareProfileProvider, and keeps device reach broad for the GPU-only release.
        minSdk = 31
        targetSdk = 37
        versionCode = appVersionCode
        versionName = appVersionName

        // Official distribution: this build bundles AGPL-3.0-covered model material, so users must
        // be pointed at THIS distribution's corresponding source, not the Apache-2.0 platform.
        // Model provenance and release obligations are recorded in DISTRIBUTION_NOTICE.md and
        // docs/model-provenance.md.
        buildConfigField("String", "APP_LICENSE", "\"AGPL-3.0\"")
        buildConfigField("String", "APP_SOURCE_URL", "\"https://github.com/wnbotoo/sailens-app\"")

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        // arm64-v8a covers every modern 64-bit Android SoC (Qualcomm, MediaTek Dimensity, Google
        // Tensor) — this is NOT a vendor restriction. It drops 32-bit-only and x86 (emulator/ChromeOS)
        // to shrink the APK and native build time for the packaged native libs (OpenCV plus Sailens
        // Android's libsailens_runtime / libsailens_vision / libsailens_guidance).
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    if (enableLitertNpuRuntime) {
        dynamicFeatures += availableLitertNpuRuntimeFeatures
    }

    signingConfigs {
        if (appSigningConfigured) {
            create("release") {
                storeFile = file(appSigningKeystorePath.get())
                storePassword = appSigningStorePassword.get()
                storeType = "PKCS12"
                keyAlias = appSigningKeyAlias.get()
                keyPassword = appSigningKeyPassword.get()
            }
        }
    }

    buildTypes {
        debug {
            buildConfigField("boolean", "SHOW_DIAGNOSTICS", "true")
            // DetFirstConfig.LAUNCH did not pass its acceptance (Sailens Android
            // docs/experiments/detfirst-acceptance-2026-11.md). The reference host lets a debug
            // build ask for it with -PdetFirst=launch; this distribution offers no such switch, in
            // any build type. scripts/verify-distribution.py and BuildContractTest hold it off.
            buildConfigField("boolean", "DET_FIRST_LAUNCH", "false")
        }
        release {
            if (appSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
            buildConfigField("boolean", "SHOW_DIAGNOSTICS", "false")
            buildConfigField("boolean", "DET_FIRST_LAUNCH", "false")
            // R8 relies on the default native-methods keep rule plus the JNI keeps in
            // sailens-runtime/vision/guidance consumer-rules.pro. Smoke-test a release build on
            // device before relying on it: name-based JNI / reflection break at runtime, not build.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging {
        jniLibs {
            // Only the Qualcomm NPU path needs extracted native libs: LiteRT's QNN dispatch dlopen()s
            // libLiteRtDispatch_Qualcomm.so from the app's lib dir (/data/app/.../lib/arm64), which is
            // empty under the modern uncompressed-in-APK default. GPU-only builds don't need it, so tie
            // legacy packaging to the NPU runtime flag to keep the default (GPU) release install smaller.
            // NOTE: native-lib load failures surface at runtime, not build — smoke-test a release build.
            useLegacyPackaging = enableLitertNpuRuntime
        }
    }
}

androidComponents {
    onVariants { variant ->
        variant.sources.assets?.addGeneratedSourceDirectory(generateBuildProvenance, GenerateBuildProvenance::outputDir)
    }
}

dependencies {

    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material3.window.size)
    implementation(libs.koin.android)
    implementation(libs.koin.androidx.compose)
    // Required for LiteRT's downloadLibrary() to install the on-demand Qualcomm NPU runtime module.
    implementation(libs.google.litert)
    implementation(libs.google.play.feature.delivery)
    implementation(libs.google.play.feature.delivery.ktx)
    if (enableLitertNpuRuntime) {
        implementation("com.sailens:runtime_strings")
    }
    implementation("com.sailens:sailens-core")
    implementation("com.sailens:sailens-runtime")
    implementation("com.sailens:sailens-vision")
    implementation("com.sailens:sailens-vlm")
    implementation("com.sailens:sailens-guidance")
    implementation("com.sailens:sailens-camera")
    implementation("com.sailens:sailens-output")
    implementation("com.sailens:sailens-describe")
    implementation("com.sailens:sailens-shell")
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
}
