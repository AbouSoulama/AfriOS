import { useState } from "react";
import Icon from "./Icon";

const faqs = [
  {
    q: "Mes clients paient en Mobile Money : qu'est-ce que je paie, moi ?",
    a: "Seulement votre abonnement AfriOS, et le plan Gratuit ne coûte rien. L'argent de vos clients arrive directement sur votre compte Chariot, pas chez AfriOS.",
  },
  {
    q: "Dois-je avoir un compte Chariot ?",
    a: "Seulement si vous voulez que vos clients paient en ligne par Mobile Money. Vous le connectez dans Paramètres → Encaissement clients. Sans compte, vous pouvez toujours confirmer un paiement en espèces.",
  },
  {
    q: "Sur quels téléphones et dans quels pays ?",
    a: "L'application est en bêta sur Android (Android 8 et plus), pour toute l'Afrique de l'Ouest (Burkina Faso, Sénégal, Côte d'Ivoire, Mali, etc.). Les montants sont en FCFA.",
  },
  {
    q: "Et sans connexion Internet ?",
    a: "Vous pouvez continuer à créer vos factures. Elles sont gardées sur le téléphone et synchronisées dès que le réseau revient.",
  },
  {
    q: "L'assistant IA, qu'est-ce que c'est ?",
    a: "Un assistant qui répond à des questions simples sur vos propres données : ce que vous avez facturé et encaissé, les impayés, le stock faible. Il est réservé au plan Pro.",
  },
  {
    q: "Les relances sont-elles envoyées toutes seules ?",
    a: "Avec le plan Pro, AfriOS vous prévient quand une facture est en retard (J+3, J+7, J+14) avec un message WhatsApp prêt à envoyer. Vous gardez la main : c'est vous qui appuyez sur envoyer.",
  },
];

export default function FAQ() {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="bg-white py-24">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="mb-12 text-center">
          <span className="mb-3 inline-block rounded-full bg-afri-teal-soft px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-dark">
            Questions fréquentes
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">On vous répond franchement.</h2>
        </div>

        <div className="space-y-3">
          {faqs.map((f, i) => {
            const isOpen = open === i;
            return (
              <div key={f.q} className="rounded-2xl border border-afri-line bg-afri-mist/60">
                <button
                  type="button"
                  onClick={() => setOpen(isOpen ? null : i)}
                  className="flex w-full items-center justify-between gap-4 px-6 py-4 text-left"
                  aria-expanded={isOpen}
                >
                  <span className="font-display text-base font-bold">{f.q}</span>
                  <Icon
                    name="chevronDown"
                    size={20}
                    className={`shrink-0 text-afri-teal transition-transform ${isOpen ? "rotate-180" : ""}`}
                  />
                </button>
                {isOpen && <p className="px-6 pb-5 text-sm leading-relaxed text-afri-slate">{f.a}</p>}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
