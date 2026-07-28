# AfriOS Mobile

Application Flutter Android-first du monorepo AfriOS.

Voir le [README racine](../README.md) pour l'architecture complète, le démarrage de l'API et la configuration réseau téléphone ↔ backend.

## Lancer

```powershell
flutter pub get
.\start-android.ps1
```

## Structure

```
lib/
├── app/           # Router, shell (nav glass)
├── core/          # Thème, réseau, widgets premium, offline
└── features/      # Auth, clients, factures, stock, IA, settings
```

## Assets

Les images d'onboarding / hero / logo sont dans `assets/images/`.
