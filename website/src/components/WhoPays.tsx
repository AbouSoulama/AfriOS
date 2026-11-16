import Icon from "./Icon";

export default function WhoPays() {
  return (
    <section id="who-pays" className="bg-white py-24">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="mx-auto mb-14 max-w-2xl text-center">
          <span className="mb-3 inline-block rounded-full bg-afri-teal-soft px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-dark">
            Qui paie quoi ?
          </span>
          <h2 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl">
            Deux paiements, deux sens. Rien à confondre.
          </h2>
          <p className="mt-4 text-lg text-afri-slate">
            C'est la question qu'on nous pose le plus : si mes clients paient en Mobile Money, qu'est-ce que je paie,
            moi ?
          </p>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <div className="rounded-3xl border border-afri-teal/25 bg-afri-teal-mist p-8">
            <span className="mb-5 flex h-12 w-12 items-center justify-center rounded-2xl bg-afri-teal text-white">
              <Icon name="wallet" size={22} />
            </span>
            <p className="text-xs font-bold uppercase tracking-wider text-afri-teal-dark">Vos clients vous paient</p>
            <h3 className="mt-2 font-display text-2xl font-extrabold tracking-tight">C'est votre argent.</h3>
            <p className="mt-3 text-afri-slate">
              Quand vous envoyez une facture, votre client la règle en Mobile Money ou en espèces. L'argent arrive sur
              votre propre compte, pas chez AfriOS.
            </p>
            <ul className="mt-5 space-y-2.5 text-sm text-afri-navy">
              {[
                "Vous connectez votre compte FedaPay une seule fois",
                "Le client reçoit un lien de paiement par WhatsApp",
                "La facture passe en « Payée » après vérification",
                "Pas de compte FedaPay ? Vous encaissez en espèces",
              ].map((t) => (
                <li key={t} className="flex items-start gap-2.5">
                  <Icon name="check" size={16} strokeWidth={3} className="mt-0.5 shrink-0 text-afri-teal" />
                  {t}
                </li>
              ))}
            </ul>
          </div>

          <div className="rounded-3xl border border-afri-line bg-afri-mist p-8">
            <span className="mb-5 flex h-12 w-12 items-center justify-center rounded-2xl bg-afri-navy text-white">
              <Icon name="lock" size={22} />
            </span>
            <p className="text-xs font-bold uppercase tracking-wider text-afri-navy">Vous payez AfriOS</p>
            <h3 className="mt-2 font-display text-2xl font-extrabold tracking-tight">Uniquement votre abonnement.</h3>
            <p className="mt-3 text-afri-slate">
              Le seul paiement que vous faites à AfriOS, c'est l'abonnement à l'application. Le plan Gratuit ne coûte
              rien et suffit pour démarrer.
            </p>
            <ul className="mt-5 space-y-2.5 text-sm text-afri-navy">
              {[
                "Gratuit : 0 FCFA, avec des limites mensuelles",
                "Pro : 6 000 FCFA par mois, sans limites",
                "Vous gérez cela dans Paramètres → Abonnement AfriOS",
                "Sans lien avec l'argent de vos clients",
              ].map((t) => (
                <li key={t} className="flex items-start gap-2.5">
                  <Icon name="check" size={16} strokeWidth={3} className="mt-0.5 shrink-0 text-afri-navy" />
                  {t}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
