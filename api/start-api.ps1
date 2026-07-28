# Demarrer l'API AfriOS (Windows PowerShell)
Set-Location $PSScriptRoot

$python = $null
$candidates = @(
    "C:\Python313\python.exe",
    "C:\Python312\python.exe",
    "C:\Python311\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
)
foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
        $python = $candidate
        break
    }
}
if (-not $python) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { $python = $cmd.Source }
}
if (-not $python) {
    Write-Host "Python introuvable. Installe Python 3.11+ depuis python.org" -ForegroundColor Red
    exit 1
}

$venvPy = ".\.venv\Scripts\python.exe"
$venvOk = $false
if (Test-Path $venvPy) {
    & $venvPy -c "import sys" 2>$null
    if ($LASTEXITCODE -eq 0) { $venvOk = $true }
}

if (-not $venvOk) {
    Write-Host "Creation / recreation de l'environnement virtuel..." -ForegroundColor Yellow
    if (Test-Path ".venv") { Remove-Item -Recurse -Force ".venv" }
    & $python -m venv .venv
    & .\.venv\Scripts\pip.exe install -r requirements.txt
}

Write-Host "Demarrage de l'API sur http://0.0.0.0:8000" -ForegroundColor Green
Write-Host "Health: http://localhost:8000/health" -ForegroundColor Cyan
Write-Host "Docs:   http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "Android Wi-Fi: http://IP_DU_PC:8000/v1 (ipconfig)" -ForegroundColor Cyan
& .\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
