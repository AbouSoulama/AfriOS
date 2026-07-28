# Lancer AfriOS mobile sur Chrome (test rapide UI)
Set-Location $PSScriptRoot
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/v1
