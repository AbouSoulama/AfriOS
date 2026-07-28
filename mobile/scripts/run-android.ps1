# Lance AfriOS mobile sur Windows (contourne les espaces dans les chemins utilisateur/projet).
# Usage: .\scripts\run-android.ps1
# Wi-Fi : .\scripts\run-android.ps1 -WifiHost 192.168.1.10

param([string]$WifiHost)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path $PSScriptRoot -Parent
$junctionProject = "D:\AfriOS"
$junctionFlutter = "C:\flutter_sdk"

if (-not (Test-Path $junctionProject)) {
    cmd /c mklink /J $junctionProject $projectRoot | Out-Null
}

$flutterSource = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if ($flutterSource) {
    $flutterHome = Split-Path (Split-Path $flutterSource -Parent) -Parent
    if ($flutterHome -match " ") {
        if (-not (Test-Path $junctionFlutter)) {
            cmd /c mklink /J $junctionFlutter $flutterHome | Out-Null
        }
        $env:PATH = "C:\flutter_sdk\bin;" + $env:PATH
    }
}

$workDir = if (Test-Path $junctionProject) { Join-Path $junctionProject "mobile" } else { $projectRoot }
Set-Location $workDir

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (Test-Path $adb) {
    & $adb reverse tcp:8000 tcp:8000 2>$null
    Write-Host ">> adb reverse tcp:8000 tcp:8000 (USB)" -ForegroundColor Green
}

$lanIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.' } |
    Select-Object -First 1).IPAddress

$dartDefines = @()
if ($WifiHost) {
    $dartDefines += "--dart-define=API_HOST=$WifiHost"
    Write-Host ">> API Wi-Fi : http://${WifiHost}:8000/v1" -ForegroundColor Yellow
} elseif ($lanIp) {
    Write-Host ">> API USB   : http://127.0.0.1:8000/v1" -ForegroundColor Yellow
    Write-Host ">> API Wi-Fi : http://${lanIp}:8000/v1  (.\scripts\run-android.ps1 -WifiHost $lanIp)" -ForegroundColor DarkYellow
}

Write-Host ">> Lance l'API : cd api; uvicorn app.main:app --reload --host 0.0.0.0 --port 8000" -ForegroundColor Cyan
Write-Host ">> Dossier de travail: $workDir" -ForegroundColor Cyan

flutter pub get
flutter run @dartDefines @args
