<#
.SYNOPSIS
  Standard, pinned Windows build for SC-300 exam prep Flutter app.

.DESCRIPTION
  Wraps the exact environment and command sequence confirmed working, so
  rebuilding this repo never again depends on tribal knowledge or whatever happens to be on PATH.
  Safe to re-run; does not modify the system/global PATH.
#>

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

# Flutter SDK path - this project requires SDK ^3.13.0, satisfied by Flutter 3.47.5 (Dart 3.13.4)
$flutterPinned = "C:\Users\chris\flutter\bin"

if (-not (Test-Path $flutterPinned)) {
    throw "Flutter SDK not found at $flutterPinned"
}

# Scoped to this process only -- never touches the user/system PATH.
$env:Path = "$flutterPinned;$env:Path"

Set-Location $repoRoot

Write-Output "Building Windows app..."
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows exited with code $LASTEXITCODE"
}

$artifactPath = "build\windows\x64\runner\Release\sc300_prep.exe"
if (-not (Test-Path $artifactPath)) {
    throw "Build reported success but $artifactPath was not found"
}

$artifact = Get-Item $artifactPath
Write-Output ""
Write-Output "Built: $($artifact.FullName) ($([math]::Round($artifact.Length / 1MB, 1)) MB, $($artifact.LastWriteTime))"
Write-Output ""
