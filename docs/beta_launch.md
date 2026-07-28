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
- [ ] Inscription OTP complète
- [ ] Création client + facture + partage WhatsApp
- [ ] Paiement CinetPay sandbox → statut Payée
- [ ] Marquage manuel paiement espèces
- [ ] Relance manuelle WhatsApp
- [ ] Assistant IA : CA du mois, stock faible
- [ ] Mode offline : création facture + sync

### UI
- [ ] Navigation 5 onglets fluide
- [ ] États vides avec CTA
- [ ] Bannière offline visible
- [ ] Montants FCFA formatés correctement

### Sécurité
- [ ] Isolation multi-tenant (pas d'accès cross-business)
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
