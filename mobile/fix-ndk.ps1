# Reparer le NDK Android corrompu
$ndk = "$env:LOCALAPPDATA\Android\sdk\ndk\28.2.13676358"
if (Test-Path $ndk) {
    Write-Host "Suppression NDK corrompu: $ndk" -ForegroundColor Yellow
    Remove-Item $ndk -Recurse -Force
    Write-Host "NDK supprime. Gradle le re-telechargera au prochain build." -ForegroundColor Green
} else {
    Write-Host "NDK deja absent — OK." -ForegroundColor Green
}
