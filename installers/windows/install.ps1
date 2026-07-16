#Requires -Version 5.1
<#
.SYNOPSIS
    Installs SystrayApp to the current user's local app directory.
.DESCRIPTION
    Copies systray-app.exe to %LOCALAPPDATA%\SystrayApp, creates a Desktop
    shortcut, and optionally adds the install directory to the user PATH.
.PARAMETER AddToPath
    When specified, adds %LOCALAPPDATA%\SystrayApp to the user PATH.
#>
param(
    [switch]$AddToPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppName   = "SystrayApp"
$Binary    = "systray-app.exe"
$InstallDir = Join-Path $env:LOCALAPPDATA $AppName
$BinPath    = Join-Path $InstallDir $Binary
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceBin  = Join-Path $ScriptDir $Binary

if (-not (Test-Path $SourceBin)) {
    Write-Error "Cannot find '$Binary' next to this script. Run install.ps1 from the extracted zip folder."
}

Write-Host "Installing $AppName to $InstallDir ..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Force $SourceBin $BinPath

# Desktop shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\$AppName.lnk")
$Shortcut.TargetPath      = $BinPath
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.Description     = "Go + Next.js Tray App"
$Shortcut.Save()
Write-Host "Desktop shortcut created."

# Start Menu shortcut
$StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$StartShortcut = $WshShell.CreateShortcut("$StartMenuDir\$AppName.lnk")
$StartShortcut.TargetPath      = $BinPath
$StartShortcut.WorkingDirectory = $InstallDir
$StartShortcut.Description     = "Go + Next.js Tray App"
$StartShortcut.Save()
Write-Host "Start Menu shortcut created."

if ($AddToPath) {
    $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($CurrentPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$InstallDir", "User")
        Write-Host "Added $InstallDir to user PATH."
    }
}

Write-Host ""
Write-Host "Done. Launch $AppName from your Desktop or Start Menu."
Write-Host "To uninstall: Remove-Item -Recurse '$InstallDir'"
