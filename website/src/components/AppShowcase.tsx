import { useState } from "react";
import AppPhone, { type ScreenId } from "./AppPhone";
import Icon from "./Icon";

const screens: { id: ScreenId; label: string; title: string; text: string; points: string[] }[] = [
  {
    id: "home",
    label: "Accueil",
    title: "Votre journée en un coup d'œil.",
    text: "Ce que vous avez encaissé aujourd'hui et ce mois, les factures en attente ou en retard, le stock à renouveler.",
    points: ["Encaissé aujourd'hui / ce mois", "Factures en attente et en retard", "Alerte de stock faible", "Actions rapides"],
  },
  {
    id: "invoices",
    label: "Factures",
    title: "Toutes vos factures, filtrées.",
    text: "Retrouvez d'un coup ce qui est en attente, en retard ou déjà payé, et créez une nouvelle facture en quelques touches.",
    points: ["Filtres : Toutes, En attente, En retard, Payées", "Statuts clairs : brouillon, envoyée, payée", "Création rapide depuis vos produits", "Envoi par WhatsApp"],
  },
  {
    id: "invoice",
    label: "Encaissement",
    title: "Votre client paie, vous suivez.",
    text: "Depuis une facture, envoyez le lien de paiement à votre client, vérifiez l'encaissement, ou confirmez un paiement en espèces.",
    points: ["Lien de paiement Mobile Money à envoyer", "Vérification de l'encaissement", "Paiement en espèces à confirmer", "Relance WhatsApp en un geste"],
  },
  {
    id: "clients",
    label: "Clients",
    title: "Votre carnet de clients.",
    text: "Chaque client avec son téléphone et ce qu'il vous doit encore. Vous savez à qui parler en premier.",
    points: ["Fiche client avec téléphone et notes", "« À encaisser » et « Facturé » par client", "Contact WhatsApp en un geste", "Liste de ses factures"],
  },
  {
    id: "stock",
    label: "Stock",
    title: "Ne tombez plus en rupture.",
    text: "Vos produits, leurs quantités et leurs prix. Un seuil par produit et une alerte « Faible » quand il faut renouveler.",
    points: ["Entrées et sorties de stock", "Seuil d'alerte par produit", "Produits réutilisés dans les factures"],
  },
  {
    id: "ai",
    label: "IA",
    title: "Posez la question, obtenez le chiffre.",
    text: "L'assistant répond à partir de vos propres données : facturé, encaissé, impayés, stock faible. Réservé au plan Pro.",
    points: ["« Combien j'ai facturé ce mois ? »", "« Factures impayées ? »", "« Stock faible ? »", "Inclus dans le plan Pro"],
  },
];

export default function AppShowcase() {
  const [current, setCurrent] = useState<ScreenId>("home");
  const info = screens.find((s) => s.id === current) ?? screens[0];

  return (
    <section id="app" className="bg-afri-mist py-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto mb-10 max-w-2xl text-center">
          <span className="mb-3 inline-block rounded-full bg-afri-teal-soft px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-dark">
            L'application
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
            Voici l'application, telle qu'elle est.
          </h2>
          <p className="mt-4 text-lg text-afri-slate">
            Cinq onglets : Accueil, Factures, Clients, Stock et IA. Touchez les écrans ci-dessous pour les parcourir.
          </p>
        </div>

        <div className="mb-10 flex flex-wrap justify-center gap-2">
          {screens.map((s) => (
            <button
              key={s.id}
              type="button"
              onClick={() => setCurrent(s.id)}
              className={`rounded-full px-5 py-2.5 text-sm font-bold transition-colors ${
                current === s.id
                  ? "bg-afri-ink text-white"
                  : "border border-afri-line bg-white text-afri-navy hover:border-afri-teal"
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>

        <div className="grid items-center gap-10 lg:grid-cols-2">
          <div className="order-2 mx-auto max-w-lg lg:order-1">
            <h3 className="font-display text-2xl font-extrabold tracking-tight sm:text-3xl">{info.title}</h3>
            <p className="mt-3 text-afri-slate">{info.text}</p>
            <ul className="mt-5 space-y-2.5">
              {info.points.map((p) => (
                <li key={p} className="flex items-center gap-2.5 text-sm text-afri-navy">
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-afri-teal-soft text-afri-teal-dark">
                    <Icon name="check" size={12} strokeWidth={3} />
                  </span>
                  {p}
                </li>
              ))}
            </ul>
          </div>

          <div className="order-1 flex justify-center lg:order-2">
            <AppPhone screen={current} onNavigate={setCurrent} />
          </div>
        </div>
        <p className="mt-10 text-center text-xs text-afri-slate-light">Noms et chiffres d'exemple.</p>
      </div>
    </section>
  );
}
