# Guide Beta — AfriOS MVP (Sénégal & Côte d'Ivoire)

## Objectif beta

Valider le produit avec **50 commerçants** avant publication Play Store.

## Critères d'inclusion

- Boutique, restaurant ou prestataire de services
- Android 8.0+
- Utilise déjà WhatsApp pour la facturation
- Sénégal (+221) ou Côte d'Ivoire (+225)

## Checklist QA avant beta

### Fonctionnel
- [x] Inscription OTP complète (dev mode + chemin SMS Africa's Talking)
- [x] Création client + facture + partage WhatsApp
- [x] Paiement CinetPay sandbox → statut Payée
- [x] Marquage manuel paiement espèces
- [x] Relance manuelle WhatsApp
- [x] Assistant IA : CA du mois, stock faible
- [x] Mode offline : création facture + sync

### Relances
- [x] Relances automatiques (job journalier + notif marchand)

### OTP SMS (prod)
1. Compte [Africa's Talking](https://account.africastalking.com/)
2. Render : `AFRICAS_TALKING_API_KEY` + `AFRICAS_TALKING_USERNAME` (+ sender optionnel)
3. `OTP_DEV_MODE=false`
4. Tester SMS réel SN (+221) / CI (+225)

### UI
- [x] Navigation 5 onglets fluide
- [x] États vides avec CTA
- [x] Bannière offline visible
- [x] Montants FCFA formatés correctement

### Sécurité
- [x] Isolation multi-tenant (pas d'accès cross-business) — test API
- [ ] JWT expiration + refresh
- [ ] PIN verrouillage (optionnel MVP)

### Performance
- [ ] Cold start < 3s (Android milieu de gamme)
- [ ] Liste 100 factures scroll fluide

## Publication Play Store

1. Créer compte Google Play Developer (25 USD)
2. Générer keystore release : `keytool -genkey -v -keystore afrios-release.jks`
3. Configurer `mobile/android/app/build.gradle` signing
4. Build AAB : `flutter build appbundle --release`
5. Fiche store : screenshots, description FR, politique confidentialité
6. Beta fermée → 50 testeurs → production

## Métriques beta (4 semaines)

| Métrique | Cible |
|----------|-------|
| Factures créées / user / semaine | ≥ 3 |
| Taux rétention J7 | ≥ 50% |
| Crashes | < 1% sessions |
| NPS | ≥ 40 |

## Support beta

- Groupe WhatsApp dédié
- Numéro support : +221 XX XXX XX XX
- Formulaire feedback in-app (Paramètres → Aide)
