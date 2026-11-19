import Icon from "./Icon";

const APK_URL = "/download/AfriOS.apk";

export default function CTA() {
  return (
    <section id="get-app" className="bg-afri-mist py-24">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <div className="hero-gradient relative overflow-hidden rounded-[2.5rem] p-8 text-center shadow-2xl sm:p-12 lg:p-16">
          <div className="absolute -right-24 -top-24 h-72 w-72 rounded-full bg-afri-teal-bright/20 blur-3xl" />
          <div className="relative">
            <span className="mb-5 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-afri-teal-bright">
              <Icon name="smartphone" size={14} />
              Android · Téléchargement direct
            </span>
            <h2 className="font-display text-3xl font-extrabold tracking-tight text-white sm:text-4xl lg:text-5xl">
              Installez AfriOS en un clic.
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-lg leading-relaxed text-white/75">
              Téléchargez l'APK sur votre téléphone Android. Les prochaines versions
              s'installent par-dessus : vos données et votre compte restent en place.
            </p>
            <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <a
                href={APK_URL}
                download="AfriOS.apk"
                className="inline-flex items-center justify-center gap-2 rounded-2xl bg-white px-7 py-4 text-base font-bold text-afri-ink transition-colors hover:bg-afri-teal-soft"
              >
                <Icon name="download" size={18} />
                Télécharger AfriOS (Android)
              </a>
              <a
                href="https://wa.me/22604046190?text=Bonjour%2C%20j%27ai%20besoin%20d%27aide%20pour%20installer%20AfriOS"
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center gap-2 rounded-2xl border-2 border-white/30 bg-white/10 px-7 py-4 text-base font-bold text-white transition-colors hover:bg-white/15"
              >
                <Icon name="messageCircle" size={18} />
                Aide WhatsApp
              </a>
            </div>
            <ol className="mx-auto mt-8 max-w-lg space-y-2 text-left text-sm text-white/70">
              <li>1. Ouvrez ce site sur votre téléphone Android.</li>
              <li>2. Appuyez sur « Télécharger », puis « Installer ».</li>
              <li>3. Si Android le demande, autorisez l’installation depuis le navigateur.</li>
            </ol>
            <p className="mt-6 text-sm text-white/60">
              Gratuit pour commencer · Android 8 et plus · Afrique de l'Ouest
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
