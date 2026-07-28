import { useState } from "react";

const plans = [
  {
    name: "Gratuit",
    price: "0",
    tagline: "Pour commencer et tester.",
    cta: "Commencer gratuitement",
    highlight: false,
    features: [
      "Jusqu'à 50 factures / mois",
      "Gestion stock basique",
      "CRM limité (25 clients)",
      "1 compte Mobile Money",
      "Mode offline",
      "Support communautaire",
    ],
  },
  {
    name: "Pro",
    price: "15 000",
    tagline: "Pour les PME en croissance.",
    cta: "Essayer Pro 14 jours",
    highlight: true,
    badge: "Le plus populaire",
    features: [
      "Factures illimitées",
      "Stock & mouvements complets",
      "CRM illimité",
      "Tous les Mobile Money",
      "Relances automatiques",
      "Assistant IA business",
      "Notifications push",
      "Support prioritaire",
      "Rapports hebdomadaires",
    ],
  },
  {
    name: "Entreprise",
    price: "50 000",
    tagline: "Pour les organisations.",
    cta: "Contacter les ventes",
    highlight: false,
    features: [
      "Tout Pro +",
      "Multi-utilisateurs & rôles",
      "Paie des employés",
      "Comptabilité avancée",
      "Rapports fiscaux",
      "API & intégrations",
      "Account manager dédié",
      "SLA 99,9%",
    ],
  },
];

export default function Pricing() {
  const [yearly, setYearly] = useState(false);

  return (
    <section id="pricing" className="relative py-24 bg-gradient-to-b from-white to-slate-50 overflow-hidden">
      <div className="absolute inset-0 bg-dots opacity-20" />
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-12">
          <span className="inline-block px-4 py-1.5 rounded-full bg-teal-50 text-teal-700 text-xs font-bold uppercase tracking-wider mb-4">
            Tarifs simples
          </span>
          <h2 className="font-display text-4xl sm:text-5xl font-extrabold tracking-tight mb-4">
            Commencez <span className="gradient-text-teal-navy">gratuitement</span>.
          </h2>
          <p className="text-lg text-slate-600 mb-8">
            Aucun frais caché. Commission transparente de 0,8% à 1,5% sur les paiements Mobile Money.
          </p>

          {/* Toggle */}
          <div className="inline-flex items-center gap-3 p-1.5 rounded-full bg-slate-100 border border-slate-200">
            <button
              onClick={() => setYearly(false)}
              className={`px-5 py-2 rounded-full text-sm font-bold transition-all ${!yearly ? "bg-white shadow-md text-slate-900" : "text-slate-500"}`}
            >
              Mensuel
            </button>
            <button
              onClick={() => setYearly(true)}
              className={`px-5 py-2 rounded-full text-sm font-bold transition-all ${yearly ? "bg-white shadow-md text-slate-900" : "text-slate-500"}`}
            >
              Annuel <span className="ml-1 text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">-20%</span>
            </button>
          </div>
        </div>

        <div className="grid md:grid-cols-3 gap-5 max-w-6xl mx-auto">
          {plans.map((p) => (
            <div
              key={p.name}
              className={`relative rounded-3xl p-6 sm:p-8 ${
                p.highlight
                  ? "bg-gradient-to-br from-slate-900 via-blue-900 to-teal-900 text-white shadow-2xl shadow-blue-500/30 scale-[1.02]"
                  : "bg-white border border-slate-200 shadow-sm"
              }`}
            >
              {p.badge && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 rounded-full bg-gradient-to-r from-orange-400 to-orange-600 text-white text-xs font-black shadow-lg">
                  🔥 {p.badge}
                </div>
              )}

              <div className="mb-6">
                <h3 className={`font-display text-xl font-extrabold mb-1 ${p.highlight ? "text-white" : "text-slate-900"}`}>{p.name}</h3>
                <p className={`text-sm ${p.highlight ? "text-blue-200" : "text-slate-500"}`}>{p.tagline}</p>
              </div>

              <div className="mb-6 pb-6 border-b border-dashed border-slate-200">
                <div className="flex items-baseline gap-1">
                  <span className={`text-4xl sm:text-5xl font-black ${p.highlight ? "text-white" : "text-slate-900"}`}>
                    {p.price === "0" ? "0" : (parseInt(p.price.replace(/\s/g, "")) * (yearly ? 0.8 : 1)).toLocaleString("fr-FR")}
                  </span>
                  <span className={`text-sm font-bold ${p.highlight ? "text-blue-200" : "text-slate-500"}`}>FCFA{yearly ? "/an" : "/mois"}</span>
                </div>
                {p.price !== "0" && yearly && (
                  <p className="text-xs text-emerald-400 font-semibold mt-1">Économisez ~{Math.round(parseInt(p.price.replace(/\s/g, "")) * 0.2 * 12).toLocaleString("fr-FR")} FCFA / an</p>
                )}
              </div>

              <button className={`w-full py-3.5 rounded-2xl text-sm font-bold mb-6 transition-all ${
                p.highlight
                  ? "bg-white text-slate-900 hover:shadow-xl hover:shadow-white/20"
                  : "bg-slate-900 text-white hover:bg-slate-800"
              }`}>
                {p.cta}
              </button>

              <ul className="space-y-3">
                {p.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm">
                    <div className={`flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center mt-0.5 ${p.highlight ? "bg-teal-500/30 text-teal-300" : "bg-teal-100 text-teal-700"}`}>
                      <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7"/></svg>
                    </div>
                    <span className={p.highlight ? "text-blue-100" : "text-slate-700"}>{f}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <p className="text-center text-sm text-slate-500 mt-10 max-w-2xl mx-auto">
          Commission de 0,8% à 1,5% sur les paiements Mobile Money. Facturation et gestion de stock : aucune commission. Essai Pro 14 jours sans carte bancaire.
        </p>
      </div>
    </section>
  );
}
