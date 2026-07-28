# Publication Play Store — AfriOS

## Prérequis

1. Compte [Google Play Console](https://play.google.com/console) (25 USD unique)
2. Flutter SDK installé
3. Keystore de signature release

## Étapes

### 1. Générer le keystore

```bash
keytool -genkey -v -keystore afrios-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias afrios
```

Stocker le keystore hors du repo. Configurer `mobile/android/key.properties` :

```properties
storePassword=***
keyPassword=***
keyAlias=afrios
storeFile=../afrios-release.jks
```

### 2. Build release

```bash
cd mobile
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.afrios.app/v1
```

Le fichier AAB sera dans `build/app/outputs/bundle/release/`.

### 3. Fiche Play Store

- **Titre** : AfriOS — Gestion PME
- **Description courte** : Facturation, stock, clients et Mobile Money pour les PME africaines.
- **Catégorie** : Business
- **Pays** : Sénégal, Côte d'Ivoire
- **Politique de confidentialité** : URL requise (héberger sur le site marketing)

### 4. Beta fermée

1. Créer une piste "Beta fermée" dans Play Console
2. Ajouter 50 testeurs (emails Google)
3. Distribuer le lien d'inscription beta
4. Collecter retours 2-4 semaines avant production

### 5. Critères de validation Google

- Icône 512x512
- Screenshots téléphone (min 4)
- Pas de permissions inutiles
- Cible API récente (Android 14+ recommandé)
