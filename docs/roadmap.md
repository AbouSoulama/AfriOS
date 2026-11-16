# AfriOS — Architecture et feuille de route (document interne)

> Ce contenu figurait auparavant sur la page web publique (« Architecture technique »,
> « Vision sur 12 mois »). Il n'a rien à faire sur un site destiné aux commerçants : il
> est conservé ici, corrigé pour refléter l'état réel du projet.

## Architecture réelle

| Couche | Technologie |
|--------|-------------|
| Application mobile (Android) | Flutter, Riverpod, GoRouter, Dio |
| API | FastAPI, SQLAlchemy (async) |
| Base de données | SQLite en développement, PostgreSQL en production |
| Authentification | Code OTP par SMS (Africa's Talking), JWT |
| Paiements clients → commerçant | FedaPay, avec les clés du commerçant |
| Abonnement commerçant → AfriOS | FedaPay, avec les clés de la plateforme (variables d'environnement) |
| Notifications | Firebase Cloud Messaging |
| Assistant IA | Règles métier sur les données du commerçant, repli OpenAI optionnel |
| Site web | React, Vite, Tailwind (fichier unique) |

Corrections par rapport à l'ancien texte du site : le projet n'utilise **ni Node.js, ni
Redis, ni Flutterwave, ni Supabase** en production, et n'intègre pas directement Wave ou
Orange Money (le Mobile Money passe par FedaPay). Les indicateurs « uptime 99,5 % » et
« démarrage < 3 s » n'étaient pas mesurés.

## État actuel (bêta)

- Inscription OTP, profil entreprise
- Clients, produits et stock, factures, envoi WhatsApp
- Encaissement Mobile Money (compte FedaPay du commerçant) ou espèces
- Relances manuelles WhatsApp ; relances automatiques J+3 / J+7 / J+14 (plan Pro) qui créent
  une notification et un message WhatsApp prêt à envoyer (pas d'envoi automatique)
- Assistant IA (plan Pro)
- Mode hors ligne avec file d'opérations synchronisée au retour du réseau
- Plans Gratuit / Pro avec limites appliquées côté serveur ; Entreprise non disponible

## Pistes (non engagées, sans dates)

- Export PDF des factures depuis l'application (l'API sait déjà générer le PDF)
- Recherche dans la liste de clients
- Envoi automatique réel des relances WhatsApp / SMS
- Verrouillage par PIN ou empreinte, rafraîchissement du JWT
- Chiffrement au repos des clés FedaPay des commerçants
- Rapports exportables, multi-devise
- Multi-utilisateurs et rôles, comptabilité simplifiée, paie (plan Entreprise)
- Version iOS
