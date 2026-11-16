import Icon, { type IconName } from "./Icon";

const steps: { icon: IconName; title: string; text: string }[] = [
  {
    icon: "userPlus",
    title: "1. Ajoutez un client",
    text: "Nom et téléphone suffisent. Vous connectez votre numéro par code SMS, sans mot de passe à retenir.",
  },
  {
    icon: "receipt",
    title: "2. Créez la facture",
    text: "Produits du stock, quantités, total en FCFA. Elle part en un geste sur WhatsApp, avec un message prêt à envoyer.",
  },
  {
    icon: "send",
    title: "3. Votre client paie",
    text: "Il règle par Mobile Money via le lien que vous lui envoyez, ou en espèces. L'argent va chez vous.",
  },
  {
    icon: "checkCircle",
    title: "4. Vous suivez",
    text: "La facture passe en « Payée ». Les retards remontent seuls, vous relancez en un geste par WhatsApp.",
  },
];

export default function HowItWorks() {
  return (
    <section id="how" className="bg-white py-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto mb-14 max-w-2xl text-center">
          <span className="mb-3 inline-block rounded-full bg-afri-teal-soft px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-dark">
            Comment ça marche
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
            De la vente à l'argent encaissé, en 4 gestes.
          </h2>
        </div>

        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s) => (
            <div key={s.title} className="rounded-3xl border border-afri-line bg-afri-mist/60 p-6">
              <span className="mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-afri-teal text-white">
                <Icon name={s.icon} size={22} />
              </span>
              <h3 className="font-display text-lg font-bold">{s.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-afri-slate">{s.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
