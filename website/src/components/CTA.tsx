import Icon from "./Icon";

export default function CTA() {
  return (
    <section id="get-app" className="bg-afri-mist py-24">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="hero-gradient relative overflow-hidden rounded-[2.5rem] p-8 text-center shadow-2xl sm:p-12 lg:p-16">
          <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-afri-teal-bright/20 blur-3xl" />
          <div className="relative">
            <span className="mb-5 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-bright">
              <Icon name="smartphone" size={14} />
              Bêta fermée · Android
            </span>
            <h2 className="font-display text-3xl font-extrabold tracking-tight text-white sm:text-4xl lg:text-5xl">
              Testez AfriOS dans votre commerce.
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-lg leading-relaxed text-white/75">
              L'application n'est pas encore sur le Play Store. Écrivez-nous avec votre nom, votre activité et votre pays :
              nous vous envoyons l'accès à la bêta et nous restons disponibles pour vous aider.
            </p>
            <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <a
                href="mailto:info.afrios@gmail.com?subject=Inscription%20bêta%20AfriOS&body=Nom%20%3A%0AActivit%C3%A9%20%3A%0APays%20%3A%0AT%C3%A9l%C3%A9phone%20WhatsApp%20%3A"
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-7 py-4 text-base font-bold text-afri-ink transition-colors hover:bg-afri-teal-soft"
              >
                <Icon name="send" size={18} />
                Demander l'accès à la bêta
              </a>
            </div>
            <p className="mt-6 text-sm text-white/60">
              Gratuit pour commencer · Android 8 et plus · Afrique de l'Ouest
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
