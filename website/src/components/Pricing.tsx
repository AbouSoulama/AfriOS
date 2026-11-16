import Icon from "./Icon";

const plans = [
  {
    name: "Gratuit",
    price: "0",
    tagline: "Pour commencer et tester.",
    features: [
      "Jusqu'à 50 factures par mois",
      "Jusqu'à 25 clients",
      "Gestion de stock",
      "Encaissement Mobile Money (votre compte FedaPay)",
      "Relances manuelles par WhatsApp",
      "Mode hors ligne",
    ],
    cta: "Commencer gratuitement",
    highlight: false,
    available: true,
  },
  {
    name: "Pro",
    price: "6 000",
    tagline: "Pour les PME en croissance.",
    features: [
      "Factures et clients illimités",
      "Assistant IA business",
      "Relances automatiques (J+3, J+7, J+14)",
      "Notifications",
      "Tout le plan Gratuit",
    ],
    cta: "Passer en Pro depuis l'app",
    highlight: true,
    available: true,
  },
  {
    name: "Entreprise",
    price: "15 000",
    tagline: "Pour les organisations.",
    features: ["Tout le plan Pro", "Multi-utilisateurs et rôles", "Comptabilité et rapports", "Paie des employés"],
    cta: "Bientôt disponible",
    highlight: false,
    available: false,
  },
];

export default function Pricing() {
  return (
    <section id="pricing" className="bg-afri-mist py-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto mb-14 max-w-2xl text-center">
          <span className="mb-3 inline-block rounded-full bg-afri-teal-soft px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-dark">
            Tarifs
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
            Gratuit pour démarrer. Pro quand vous grandissez.
          </h2>
          <p className="mt-4 text-lg text-afri-slate">
            Ces prix sont ceux de l'abonnement AfriOS. Ils ne concernent pas l'argent que vos clients vous versent.
          </p>
        </div>

        <div className="mx-auto grid max-w-5xl gap-6 lg:grid-cols-3">
          {plans.map((p) => (
            <div
              key={p.name}
              className={`relative flex flex-col rounded-3xl p-8 ${
                p.highlight ? "hero-gradient text-white shadow-2xl" : "border border-afri-line bg-white"
              } ${p.available ? "" : "opacity-75"}`}
            >
              {p.highlight && (
                <span className="absolute -top-3 left-8 rounded-full bg-afri-teal-bright px-3 py-1 text-[11px] font-extrabold uppercase tracking-wide text-afri-ink">
                  Recommandé
                </span>
              )}
              <h3 className="font-display text-xl font-extrabold">{p.name}</h3>
              <p className={`mt-1 text-sm ${p.highlight ? "text-white/70" : "text-afri-slate"}`}>{p.tagline}</p>
              <p className="mt-6 flex items-baseline gap-1.5">
                <span className="font-display text-4xl font-extrabold tracking-tight">{p.price}</span>
                <span className={`text-sm ${p.highlight ? "text-white/70" : "text-afri-slate"}`}>FCFA / mois</span>
              </p>
              <ul className="mt-6 flex-1 space-y-3 text-sm">
                {p.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5">
                    <Icon
                      name="check"
                      size={16}
                      strokeWidth={3}
                      className={`mt-0.5 shrink-0 ${p.highlight ? "text-afri-teal-bright" : "text-afri-teal"}`}
                    />
                    <span className={p.highlight ? "text-white/90" : "text-afri-navy"}>{f}</span>
                  </li>
                ))}
              </ul>
              {p.available ? (
                <a
                  href="#get-app"
                  className={`mt-8 inline-flex items-center justify-center rounded-2xl px-6 py-3.5 text-sm font-bold transition-colors ${
                    p.highlight
                      ? "bg-white text-afri-ink hover:bg-afri-teal-soft"
                      : "bg-afri-teal text-white hover:bg-afri-teal-dark"
                  }`}
                >
                  {p.cta}
                </a>
              ) : (
                <span className="mt-8 inline-flex items-center justify-center rounded-2xl bg-afri-mist px-6 py-3.5 text-sm font-bold text-afri-slate-light">
                  {p.cta}
                </span>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
