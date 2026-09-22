param(
    [Parameter(Mandatory = $true)]
    [string]$Tag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Repository = "wnbotoo/sailens-app"
$PackageName = "com.sailens"
$MainActivity = "com.sailens/.MainActivity"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $Root

function Fail([string]$Message) {
    throw $Message
}

function Find-Command([string[]]$Names) {
    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) { return $command.Source }
    }
    return $null
}

function Invoke-Checked([string]$File, [string[]]$Arguments) {
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        Fail "$File exited with code $LASTEXITCODE."
    }
}

function Invoke-Captured([string]$File, [string[]]$Arguments) {
    $output = @(& $File @Arguments 2>&1 | ForEach-Object { "$_" })
    if ($LASTEXITCODE -ne 0) {
        $output | ForEach-Object { Write-Host $_ }
        Fail "$File exited with code $LASTEXITCODE."
    }
    return $output
}

function Normalize-Sha256([string]$Value) {
    return (($Value -replace ":", "") -replace "\s", "").ToLowerInvariant()
}

function Resolve-AndroidSdk {
    foreach ($candidate in @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME)) {
        if ($candidate -and (Test-Path $candidate)) { return (Resolve-Path $candidate).Path }
    }
    $localProperties = Join-Path $Root "local.properties"
    if (Test-Path $localProperties) {
        $line = Get-Content $localProperties | Where-Object { $_ -match "^sdk\.dir=" } | Select-Object -First 1
        if ($line) {
            $value = $line.Substring("sdk.dir=".Length).Replace("\:", ":").Replace("\\", "\")
            if (Test-Path $value) { return (Resolve-Path $value).Path }
        }
    }
    return $null
}

function Resolve-Adb {
    if ($env:ADB -and (Test-Path $env:ADB)) { return $env:ADB }
    $command = Find-Command @("adb.exe", "adb")
    if ($command) { return $command }
    $sdk = Resolve-AndroidSdk
    if ($sdk) {
        foreach ($name in @("adb.exe", "adb")) {
            $path = Join-Path $sdk "platform-tools/$name"
            if (Test-Path $path) { return $path }
        }
    }
    Fail "adb was not found. Install Android SDK Platform-Tools or set ADB."
}

function Resolve-ApkSigner {
    if ($env:APKSIGNER -and (Test-Path $env:APKSIGNER)) { return $env:APKSIGNER }
    $command = Find-Command @("apksigner.bat", "apksigner")
    if ($command) { return $command }
    $sdk = Resolve-AndroidSdk
    if ($sdk) {
        $buildTools = Get-ChildItem (Join-Path $sdk "build-tools") -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending
        foreach ($dir in $buildTools) {
            foreach ($name in @("apksigner.bat", "apksigner")) {
                $path = Join-Path $dir.FullName $name
                if (Test-Path $path) { return $path }
            }
        }
    }
    Fail "apksigner was not found. Install Android SDK Build-Tools or set APKSIGNER."
}

function Get-AdbArgs([string[]]$Arguments) {
    if ($script:DeviceSerial) { return @("-s", $script:DeviceSerial) + $Arguments }
    return $Arguments
}

function Invoke-Adb([string[]]$Arguments) {
    Invoke-Checked $script:Adb (Get-AdbArgs $Arguments)
}

function Invoke-AdbCaptured([string[]]$Arguments) {
    return Invoke-Captured $script:Adb (Get-AdbArgs $Arguments)
}

function Add-ManualPass([string]$Description) {
    Write-Host ""
    Write-Host $Description
    $answer = Read-Host "Type PASS to accept this gate"
    if ($answer -cne "PASS") {
        Add-Content -Path $script:Report -Value "- FAIL: $Description"
        Fail "Manual release gate was not accepted."
    }
    Add-Content -Path $script:Report -Value "- PASS: $Description"
}

if ($Tag -notmatch "^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$") {
    Fail "Tag must use vMAJOR.MINOR.PATCH."
}
$major = [int64]$Matches[1]
$minor = [int64]$Matches[2]
$patch = [int64]$Matches[3]
if ($minor -gt 999 -or $patch -gt 999) { Fail "MINOR and PATCH must each be <= 999." }
$VersionName = "$major.$minor.$patch"
$VersionCode = $major * 1000000 + $minor * 1000 + $patch
if ($VersionCode -lt 1 -or $VersionCode -gt 2100000000) { Fail "Derived versionCode is invalid." }

$Git = Find-Command @("git.exe", "git")
$Gh = Find-Command @("gh.exe", "gh")
$script:Adb = Resolve-Adb
$ApkSigner = Resolve-ApkSigner
if (-not $Git) { Fail "git was not found." }
if (-not $Gh) { Fail "gh was not found." }

Invoke-Checked $Gh @("auth", "status", "--hostname", "github.com")
Invoke-Checked $Git @("fetch", "origin", "main", "--tags", "--force")

$TagCommit = (Invoke-Captured $Git @("rev-list", "-n", "1", $Tag) | Select-Object -First 1).Trim()
if ($TagCommit -notmatch "^[0-9a-f]{40}$") { Fail "Tag $Tag does not resolve to a commit." }
& $Git merge-base --is-ancestor $TagCommit "origin/main"
if ($LASTEXITCODE -ne 0) { Fail "Tag $Tag is not reachable from origin/main." }

$ExpectedCertText = (Invoke-Captured $Git @("show", "${Tag}:release/app-signing-certificate.sha256") | Select-Object -First 1)
$ExpectedCert = Normalize-Sha256 $ExpectedCertText
if ($ExpectedCert -notmatch "^[0-9a-f]{64}$") { Fail "Pinned signing fingerprint at $Tag is invalid." }

$ReleaseJson = (Invoke-Captured $Gh @("release", "view", $Tag, "--repo", $Repository, "--json", "isDraft,tagName") -join "`n")
$Release = $ReleaseJson | ConvertFrom-Json
if (-not $Release.isDraft) { Fail "Release $Tag is already public; the device gate must run against a draft." }

$ShortCommit = $TagCommit.Substring(0, 12)
$ReportDir = Join-Path $Root "dist/release-gate/$Tag-$ShortCommit"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
Invoke-Checked $Gh @(
    "release", "download", $Tag, "--repo", $Repository,
    "--pattern", "sailens-$VersionName.apk",
    "--pattern", "release-manifest.json",
    "--pattern", "sailens-$VersionName-source.tar.gz",
    "--dir", $ReportDir, "--clobber"
)

$Apk = Join-Path $ReportDir "sailens-$VersionName.apk"
$ManifestPath = Join-Path $ReportDir "release-manifest.json"
$SourceArchive = Join-Path $ReportDir "sailens-$VersionName-source.tar.gz"
foreach ($path in @($Apk, $ManifestPath, $SourceArchive)) {
    if (-not (Test-Path $path)) { Fail "Draft release asset is missing: $path" }
}

$Manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json
if ($Manifest.tag -ne $Tag) { Fail "Manifest tag does not match $Tag." }
if ($Manifest.versionName -ne $VersionName) { Fail "Manifest versionName is wrong." }
if ([int64]$Manifest.versionCode -ne $VersionCode) { Fail "Manifest versionCode is wrong." }
if ($Manifest.channel -ne "github") { Fail "Manifest channel is not github." }
if ($Manifest.source.commit -ne $TagCommit) { Fail "Manifest source commit does not match tag commit." }
if ((Normalize-Sha256 $Manifest.signing.certificateSha256) -ne $ExpectedCert) {
    Fail "Manifest signer does not match the pinned signing identity."
}

$ApkSha = (Get-FileHash -Algorithm SHA256 $Apk).Hash.ToLowerInvariant()
$SourceSha = (Get-FileHash -Algorithm SHA256 $SourceArchive).Hash.ToLowerInvariant()
if ($ApkSha -ne (Normalize-Sha256 $Manifest.artifacts.apk.sha256)) { Fail "APK SHA-256 does not match manifest." }
if ($SourceSha -ne (Normalize-Sha256 $Manifest.artifacts.correspondingSourceArchive.sha256)) {
    Fail "Corresponding-source archive SHA-256 does not match manifest."
}

$SignerOutput = @(Invoke-Captured $ApkSigner @("verify", "--verbose", "--print-certs", $Apk))
$SignerOutput | ForEach-Object { Write-Host $_ }
$SignerLine = $SignerOutput | Where-Object { $_ -match "certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)" } | Select-Object -First 1
if (-not $SignerLine) { Fail "Could not read APK signer SHA-256." }
[void]($SignerLine -match "certificate SHA-256 digest:\s*([0-9A-Fa-f:]+)")
$ApkCert = Normalize-Sha256 $Matches[1]
if ($ApkCert -ne $ExpectedCert) { Fail "APK signer does not match the pinned Sailens signing identity." }

$deviceLines = @(Invoke-Captured $script:Adb @("devices")) | Where-Object { $_ -match "^([^\s]+)\s+device$" }
if ($env:ANDROID_SERIAL) {
    $script:DeviceSerial = $env:ANDROID_SERIAL
    $state = (Invoke-AdbCaptured @("get-state") | Select-Object -First 1).Trim()
    if ($state -ne "device") { Fail "ANDROID_SERIAL=$($env:ANDROID_SERIAL) is not an authorized online device." }
} else {
    if ($deviceLines.Count -ne 1) { Fail "Exactly one authorized device is required; found $($deviceLines.Count)." }
    [void]($deviceLines[0] -match "^([^\s]+)")
    $script:DeviceSerial = $Matches[1]
}

function Get-Prop([string]$Name) {
    return ((Invoke-AdbCaptured @("shell", "getprop", $Name)) -join "").Trim()
}
$DeviceModel = Get-Prop "ro.product.model"
$DeviceManufacturer = Get-Prop "ro.product.manufacturer"
$DeviceSdk = [int](Get-Prop "ro.build.version.sdk")
$DeviceAndroid = Get-Prop "ro.build.version.release"
$DeviceAbi = Get-Prop "ro.product.cpu.abi"
$DeviceSocManufacturer = Get-Prop "ro.soc.manufacturer"
$DeviceSocModel = Get-Prop "ro.soc.model"
if ($DeviceSdk -lt 31) { Fail "Device SDK $DeviceSdk is below minSdk 31." }
if ($DeviceAbi -ne "arm64-v8a") { Fail "Device ABI is $DeviceAbi; Sailens release requires arm64-v8a." }

$script:Report = Join-Path $ReportDir "report.md"
$InstallLog = Join-Path $ReportDir "install.txt"
$StartLog = Join-Path $ReportDir "start.txt"
$Logcat = Join-Path $ReportDir "logcat.txt"
$CrashLog = Join-Path $ReportDir "crash.txt"

@"
# Sailens exact-artifact release gate — $Tag

## Candidate

- Result: IN PROGRESS
- Product commit: $TagCommit
- Platform commit: $($Manifest.source.platformCommit)
- Version name: $VersionName
- Version code: $VersionCode
- APK SHA-256: $ApkSha
- App-signing certificate SHA-256: $ApkCert

## Device

- Serial: $script:DeviceSerial
- Manufacturer: $DeviceManufacturer
- Model: $DeviceModel
- Android: $DeviceAndroid
- SDK: $DeviceSdk
- ABI: $DeviceAbi
- SoC manufacturer: $DeviceSocManufacturer
- SoC model: $DeviceSocModel

## Machine checks

- PASS: draft Release tag resolves to a commit reachable from origin/main.
- PASS: manifest source commit/version/channel match the draft tag.
- PASS: APK and corresponding-source hashes match the release manifest.
- PASS: manifest and exact APK signer match the pinned Sailens signing identity.
- PASS: target device satisfies API/ABI floor.

## Manual checks
"@ | Set-Content -Encoding UTF8 $script:Report

Write-Host ""
Write-Host "Installing exact draft APK on $DeviceModel ($script:DeviceSerial)..."
$installOutput = @(& $script:Adb @(Get-AdbArgs @("install", "-r", $Apk)) 2>&1 | ForEach-Object { "$_" })
$installOutput | Set-Content -Encoding UTF8 $InstallLog
$installOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "If this is INSTALL_FAILED_UPDATE_INCOMPATIBLE, another-signed com.sailens is installed."
    Write-Host "Uninstall it manually only if clearing that app data is acceptable, then rerun the gate."
    Fail "APK installation failed."
}

$PackageInfo = (Invoke-AdbCaptured @("shell", "dumpsys", "package", $PackageName)) -join "`n"
if ($PackageInfo -notmatch "versionCode=(\d+)") { Fail "Could not read installed versionCode." }
$InstalledVersionCode = [int64]$Matches[1]
if ($PackageInfo -notmatch "(?m)^\s*versionName=(.+)$") { Fail "Could not read installed versionName." }
$InstalledVersionName = $Matches[1].Trim()
if ($InstalledVersionCode -ne $VersionCode) { Fail "Installed versionCode $InstalledVersionCode != $VersionCode." }
if ($InstalledVersionName -ne $VersionName) { Fail "Installed versionName $InstalledVersionName != $VersionName." }
Add-Content $script:Report "- PASS: installed package reports versionName=$InstalledVersionName versionCode=$InstalledVersionCode."

Invoke-Adb @("logcat", "-c")
Invoke-Adb @("shell", "am", "force-stop", $PackageName)
$startOutput = Invoke-AdbCaptured @("shell", "am", "start", "-W", "-n", $MainActivity)
$startOutput | Set-Content -Encoding UTF8 $StartLog
$startOutput | ForEach-Object { Write-Host $_ }
Start-Sleep -Seconds 5
$pid = ((Invoke-AdbCaptured @("shell", "pidof", $PackageName)) -join "").Trim()
if (-not $pid) { Fail "$PackageName is not running five seconds after launch." }
Add-Content $script:Report "- PASS: launcher activity started and process remained alive after initial launch."

Add-ManualPass "The release UI opened without a fatal configuration state; first-run/camera permission handling worked; Guidance could be started."
Add-ManualPass "Retained known-scene evidence for these exact model hashes confirms Cityscapes channel order and detection class meaning."
Add-ManualPass "A real camera -> sem + det -> Guidance session ran continuously for at least two minutes without crash, stuck analysis, or loss of guidance."
Add-ManualPass "Speech output was actually heard through the intended TTS/TalkBack configuration and did not silently fail."
Add-ManualPass "Expected haptic output was physically felt for a guidance/failure cue."
Add-ManualPass "Current same-commit device evidence shows no material performance/backend regression from the accepted baseline."
Add-ManualPass "The intended public distribution has been checked against current model-provenance terms, including the Cityscapes non-commercial restriction."

$logcatOutput = @(& $script:Adb @(Get-AdbArgs @("logcat", "-d", "-v", "threadtime")) 2>&1 | ForEach-Object { "$_" })
$logcatOutput | Set-Content -Encoding UTF8 $Logcat
$crashOutput = @(& $script:Adb @(Get-AdbArgs @("logcat", "-d", "-b", "crash", "-v", "threadtime")) 2>&1 | ForEach-Object { "$_" })
$crashOutput | Set-Content -Encoding UTF8 $CrashLog

$pidAfter = ((Invoke-AdbCaptured @("shell", "pidof", $PackageName)) -join "").Trim()
if (-not $pidAfter) { Fail "$PackageName is no longer running after the manual session." }
if (($crashOutput -join "`n") -match [regex]::Escape($PackageName)) { Fail "Crash buffer contains $PackageName; inspect $CrashLog." }
$fatalPattern = "UnsatisfiedLinkError|No implementation found for|JNI DETECTED ERROR|dlopen failed|Fatal signal|SIG(SEGV|ABRT)"
if (($logcatOutput -join "`n") -match $fatalPattern) { Fail "Native/JNI fatal pattern found; inspect $Logcat." }

@"

## Final result

**PASS**

Machine checks and explicitly accepted manual checks passed for the exact draft APK.
This gate does not replace the broader target-user and Phase A guidance-validation work tracked in Sailens Android.
"@ | Add-Content -Encoding UTF8 $script:Report

Write-Host ""
Write-Host "Release gate PASS."
Write-Host "Report: $script:Report"
Write-Host "APK:    $Apk"
Write-Host "Signer: $ApkCert"
Write-Host ""
Write-Host "Review/retain the evidence, then publish with:"
Write-Host "gh release edit $Tag --repo $Repository --draft=false"
