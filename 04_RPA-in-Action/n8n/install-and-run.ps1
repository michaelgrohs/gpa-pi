# Installs n8n locally (no global install, no Docker, no account) and starts it.
# All state (n8n itself, its database, credentials) lives under .\.n8n-runtime next to
# this script, so nothing touches your global npm packages or your user profile, and you
# can wipe it completely by deleting that one folder (or running with -Reset).
#
# Usage (from PowerShell):
#   .\install-and-run.ps1          # install (first run) and start n8n
#   .\install-and-run.ps1 -Reset   # wipe local n8n data (workflows/credentials) and start fresh
#
# Override the pinned version if needed:
#   $env:N8N_VERSION = "2.33.2"; .\install-and-run.ps1
#
# If PowerShell refuses to run this script ("running scripts is disabled on this
# system"), see the "Windows: script execution policy" section in README-setup.md.

param(
    [switch]$Reset
)

$ErrorActionPreference = "Stop"

$N8nVersion = if ($env:N8N_VERSION) { $env:N8N_VERSION } else { "2.32.6" }
$MinNodeMajor = 22
$MinNodeMinorIfSameMajor = 22

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RuntimeDir = Join-Path $ScriptDir ".n8n-runtime"
$DataDir = Join-Path $RuntimeDir "data"

if ($Reset) {
    Write-Host "Removing local n8n data (workflows, credentials, execution history) at:"
    Write-Host "  $DataDir"
    if (Test-Path $DataDir) { Remove-Item -Recurse -Force $DataDir }
    Write-Host "Done. n8n itself (in .n8n-runtime\node_modules) was left in place."
}

Write-Host "== Checking prerequisites =="

$node = Get-Command node -ErrorAction SilentlyContinue
$npm = Get-Command npm -ErrorAction SilentlyContinue

if (-not $node -or -not $npm) {
    Write-Host ""
    Write-Host "Node.js (which includes npm) was not found on your PATH."
    Write-Host ""
    Write-Host "Install it from https://nodejs.org (the ""LTS"" build), then open a new"
    Write-Host "PowerShell window and re-run this script."
    exit 1
}

$nodeVersionRaw = (node -v).TrimStart("v")
$nodeVersionParts = $nodeVersionRaw.Split(".")
$nodeMajor = [int]$nodeVersionParts[0]
$nodeMinor = [int]$nodeVersionParts[1]

if (($nodeMajor -lt $MinNodeMajor) -or (($nodeMajor -eq $MinNodeMajor) -and ($nodeMinor -lt $MinNodeMinorIfSameMajor))) {
    Write-Host ""
    Write-Host "n8n $N8nVersion requires Node.js >= $MinNodeMajor.$MinNodeMinorIfSameMajor, but this machine has v$nodeVersionRaw."
    Write-Host ""
    Write-Host "Install a newer Node.js from https://nodejs.org (the ""LTS"" build), then re-run this script."
    exit 1
}

Write-Host "Node.js v$nodeVersionRaw OK, npm $(npm -v) OK."

New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
Push-Location $RuntimeDir

try {
    if (-not (Test-Path "package.json")) {
        # Not `npm init -y`: it derives the package name from the directory name, and
        # ".n8n-runtime" (leading dot) is rejected by npm as an invalid package name.
        '{"name":"n8n-course-runtime","private":true}' | Set-Content -Path "package.json" -NoNewline
    }

    $installedVersion = $null
    $installedPkgPath = Join-Path $RuntimeDir "node_modules\n8n\package.json"
    if (Test-Path $installedPkgPath) {
        $installedVersion = (Get-Content $installedPkgPath | ConvertFrom-Json).version
    }

    if ($installedVersion -ne $N8nVersion) {
        Write-Host "== Installing n8n $N8nVersion locally =="
        Write-Host "First install can take 10-15 minutes: a couple of dependencies (isolated-vm, ssh2)"
        Write-Host "compile native code from source and are slow even when everything works correctly."
        npm install --no-fund --no-audit "n8n@$N8nVersion"
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "npm install failed. The most common cause on Windows is missing native build"
            Write-Host "tools for a dependency (e.g. isolated-vm or ssh2) that needs to compile from source:"
            Write-Host ""
            Write-Host "  npm install --global windows-build-tools"
            Write-Host "  (or install ""Desktop development with C++"" via Visual Studio Build Tools)"
            Write-Host ""
            Write-Host "Once that's installed, just re-run .\install-and-run.ps1 — npm resumes from"
            Write-Host "where it left off."
            exit 1
        }
    } else {
        Write-Host "n8n $N8nVersion already installed, skipping."
    }

    Write-Host ""
    Write-Host "== Starting n8n $N8nVersion =="
    Write-Host "Data folder: $DataDir"
    Write-Host "Once you see 'Editor is now accessible via:', open:  http://localhost:5678"
    Write-Host "Press Ctrl+C to stop."
    Write-Host ""

    $env:N8N_USER_FOLDER = $DataDir
    $env:N8N_DIAGNOSTICS_ENABLED = "false"
    $env:N8N_VERSION_NOTIFICATIONS_ENABLED = "false"
    $env:N8N_TEMPLATES_ENABLED = "false"

    npx --no-install n8n start
}
finally {
    Pop-Location
}
