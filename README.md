# AfriOS

**L'OS des PME africaines** — application mobile-first pour facturer, gérer clients & stock, encaisser via Mobile Money et s'appuyer sur un assistant IA.

Conçu pour les marchés ouest-africains (Sénégal, Côte d'Ivoire, etc.) : OTP téléphone, FCFA, Mobile Money (via Chariot), WhatsApp, mode hors ligne partiel.

### Qui paie quoi ?

Deux flux d'argent distincts, à ne pas confondre :

| Flux | Qui paie | Qui reçoit | Clés Chariot utilisées |
|------|----------|------------|------------------------|
| **Encaissement** d'une facture | Le **client** du commerçant | Le **commerçant** | Celles du commerçant (Paramètres → Encaissement clients) |
| **Abonnement** AfriOS (plan Pro) | Le **commerçant** | **AfriOS** | Celles de la plateforme (variables d'environnement de l'API) |

Le commerçant ne paie donc à AfriOS que son abonnement ; le plan Gratuit est à 0 FCFA.

---

## Structure du monorepo

```
AfriOS/
├── mobile/     # App Flutter (Android-first)
├── api/        # Backend FastAPI
├── website/    # Landing marketing (React + Vite)
├── docs/       # Schéma SQL, prompts IA, guides beta / Play Store
└── docker-compose.yml
```

## Stack

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter 3.x, Riverpod, GoRouter, Dio, flutter_animate |
| Backend | FastAPI, SQLAlchemy (async), JWT / OTP |
| Base de données | SQLite (dev local) · PostgreSQL (prod) |
| Paiements | Chariot (Mobile Money) |
| IA | Assistant conversationnel + intents métier |
| Push | Firebase Cloud Messaging (optionnel en dev) |

## Prérequis

- **Flutter** 3.22+ (`flutter doctor`)
- **Python** 3.11+
- **Node.js** 18+ (website uniquement)
- Android SDK / appareil physique ou émulateur
- Optionnel : Docker (Postgres + Redis)

---

## Démarrage rapide

### 1. API (backend)

Par défaut en local : **SQLite** — pas besoin de Docker.

```powershell
cd api
.\start-api.ps1
```

Ou manuellement :

```powershell
cd api
python -m venv .venv
.\.venv\Scripts\pip.exe install -r requirements.txt
copy .env.example .env   # si besoin
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

| URL | Description |
|-----|-------------|
| http://localhost:8000/health | Health check |
| http://localhost:8000/docs | Swagger UI |
| http://localhost:8000/v1 | Préfixe API |

> **Mode développement** : le code OTP est renvoyé dans la réponse API et affiché dans l'app.

#### Postgres (optionnel)

```bash
docker compose up -d postgres redis
```

Puis dans `api/.env` :

```env
DATABASE_URL=postgresql+asyncpg://afrios:afrios_dev@localhost:5432/afrios
```

### 2. Mobile (Flutter)

```powershell
cd mobile
flutter pub get
.\start-android.ps1
```

Ou :

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:8000/v1
```

#### Connexion téléphone ↔ API

| Appareil | URL (`⚙️` sur l'écran téléphone / login) |
|----------|------------------------------------------|
| Émulateur Android | `http://10.0.2.2:8000/v1` |
| Téléphone Wi‑Fi (même réseau) | `http://IP_DU_PC:8000/v1` |
| Téléphone USB | `adb reverse tcp:8000 tcp:8000` puis `http://127.0.0.1:8000/v1` |

Utilise le bouton **Tester** dans le dialogue URL serveur avant d'enregistrer.

### 3. Website (marketing)

```bash
cd website
npm install
npm run dev
```

---

## Fonctionnalités

- **Auth OTP** par numéro de téléphone + onboarding entreprise
- **Tableau de bord** CA, encaissements du jour, impayés, stock faible
- **Clients** — CRUD, notes, encours, facturation depuis la fiche
- **Factures** — lignes, remises, échéance, envoi, paiement Mobile Money, relances
- **Stock** — produits, seuils d'alerte, mouvements entrée / sortie
- **Assistant IA** — questions métier (CA, impayés, stock…)
- **Paramètres** — entreprise, encaissement clients (compte Chariot du commerçant), abonnement AfriOS, règles de relance, URL API, aide
- **Hors ligne** — cache local partiel + file d'attente de sync
- **Plans** — Gratuit (50 factures/mois, 25 clients), Pro (6 000 FCFA/mois : illimité, IA, relances automatiques), Entreprise (15 000 FCFA/mois, bientôt). Limites côté serveur contrôlées par `PLANS_ENFORCED` (false en bêta).

## Documentation

- [Schéma base de données](docs/supabase/001_initial_schema.sql)
- [Prompts assistant IA](docs/ai/system_prompts.md)
- [Guide beta SN / CI](docs/beta_launch.md)
- [Architecture et feuille de route](docs/roadmap.md)
- [Publication Play Store](docs/play_store.md)

## Variables d'environnement

Copier `api/.env.example` → `api/.env`. Ne jamais committer `.env`, `google-services.json` ni les keystores (déjà dans `.gitignore`).

### Checklist production

- `OTP_DEV_MODE=false` (sinon le code OTP est renvoyé dans la réponse API)
- `JWT_SECRET` long et aléatoire ; `JOBS_CRON_SECRET` changé
- `CORS_ORIGINS` limité aux origines réelles (pas `["*"]`)
- `CHARIOT_SANDBOX=false` + `CHARIOT_SECRET_KEY` / `CHARIOT_PUBLIC_KEY` de la plateforme (abonnements) + `CHARIOT_CALLBACK_URL` publique
- Chaque commerçant renseigne **ses propres** clés Chariot pour encaisser ses clients
- `PLANS_ENFORCED=false` pour ouvrir toutes les fonctions pendant la bêta, `true` pour appliquer les limites des plans
- Les routes de simulation de paiement (sandbox) répondent 404 hors mode sandbox

## Licence

Propriétaire — tous droits réservés. Usage interne / beta uniquement sauf accord contraire.
