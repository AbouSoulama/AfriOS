import AppPhone from "./AppPhone";
import Icon from "./Icon";

export default function Hero() {
  return (
    <section className="relative overflow-hidden pb-20 pt-28 lg:pb-28 lg:pt-36">
      <div className="absolute inset-0 bg-gradient-to-b from-afri-teal-mist via-white to-white" />
      <div className="absolute -left-40 top-20 h-[460px] w-[460px] rounded-full bg-afri-teal-bright/20 blur-3xl" />

      <div className="relative mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid items-center gap-14 lg:grid-cols-2">
          <div className="animate-fade-in-up">
            <span className="mb-6 inline-flex items-center gap-2 rounded-full border border-afri-teal/25 bg-white px-3.5 py-1.5 text-xs font-semibold text-afri-navy shadow-sm">
              <span className="h-2 w-2 rounded-full bg-afri-teal" />
              Bêta Android · Afrique de l'Ouest
            </span>

            <h1 className="font-display text-4xl font-extrabold leading-[1.08] tracking-tight sm:text-5xl lg:text-6xl">
              Facturez, suivez vos <span className="text-gradient">encaissements</span>, gardez vos clients.
            </h1>

            <p className="mt-6 max-w-xl text-lg leading-relaxed text-afri-slate">
              AfriOS est l'application des commerçants et prestataires qui vendent à crédit ou sur WhatsApp. Vous créez
              la facture, votre client la règle (Mobile Money ou espèces), et vous voyez tout de suite qui a payé.
            </p>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <a
                href="#get-app"
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-afri-teal px-7 py-4 text-base font-bold text-white shadow-lg shadow-afri-teal/30 transition-colors hover:bg-afri-teal-dark"
              >
                <Icon name="smartphone" size={19} />
                Rejoindre la bêta
              </a>
              <a
                href="#app"
                className="inline-flex items-center justify-center gap-2 rounded-2xl border-2 border-afri-line bg-white px-7 py-4 text-base font-bold text-afri-navy transition-colors hover:border-afri-teal hover:text-afri-teal-dark"
              >
                Voir l'application
                <Icon name="arrowRight" size={18} />
              </a>
            </div>

            <ul className="mt-8 grid gap-3 text-sm text-afri-slate sm:grid-cols-3">
              {[
                ["Gratuit pour commencer", "check"],
                ["Montants en FCFA", "banknote"],
                ["Fonctionne hors ligne", "wifiOff"],
              ].map(([label, icon]) => (
                <li key={label} className="flex items-center gap-2">
                  <span className="flex h-7 w-7 items-center justify-center rounded-full bg-afri-teal-soft text-afri-teal-dark">
                    <Icon name={icon as "check"} size={14} />
                  </span>
                  {label}
                </li>
              ))}
            </ul>
          </div>

          <div className="flex flex-col items-center">
            <AppPhone screen="home" className="animate-float" />
            <p className="mt-6 text-xs text-afri-slate-light">Capture fidèle de l'écran d'accueil · chiffres d'exemple</p>
          </div>
        </div>
      </div>
    </section>
  );
}
