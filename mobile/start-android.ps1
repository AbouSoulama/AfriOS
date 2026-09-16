# Lancer AfriOS sur telephone Android
# Corrige: JAVA_HOME, Espaces dans les chemins (Format 8.3), URL API avec port :8000
Set-Location $PSScriptRoot

# --- Gestion de l'espace dans le nom d'utilisateur (Format 8.3) ---
# Transforme "C:\Users\Dev SOULAMA" en chemin court sans espace (ex: C:\Users\DEV_SO~1)
$fso = New-Object -ComObject Scripting.FileSystemObject
$shortUserFolder = $fso.GetFolder($env:USERPROFILE).ShortPath

# --- Flutter SDK ---
# On utilise le chemin court pour le SDK Flutter
$env:FLUTTER_ROOT = "$shortUserFolder\flutter"
$env:PATH = "$env:FLUTTER_ROOT\bin;$env:PATH"

# --- Java (Gradle) ---
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"

# --- Variables de configuration ---
# API publique (fonctionne en 4G, sans IP locale)
$apiUrl = "https://afrios-api.onrender.com/v1"

Write-Host "Flutter path (Court): $env:FLUTTER_ROOT" -ForegroundColor Gray
Write-Host "Projet:               $PSScriptRoot" -ForegroundColor Gray
Write-Host "API:          $apiUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Premier build: 5-15 min. Patientez..." -ForegroundColor Yellow

# On nettoie le cache corrompu par l'espace
flutter clean

# On récupère les dépendances avec le nouvel environnement
flutter pub get

# Lancement
flutter run --dart-define=API_BASE_URL=$apiUrl