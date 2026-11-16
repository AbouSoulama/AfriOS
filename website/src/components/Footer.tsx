import afriosLogo from "../assets/afrios-logo.png";

const links = [
  { label: "Comment ça marche", href: "#how" },
  { label: "L'application", href: "#app" },
  { label: "Qui paie quoi ?", href: "#who-pays" },
  { label: "Tarifs", href: "#pricing" },
  { label: "FAQ", href: "#faq" },
];

export default function Footer() {
  return (
    <footer className="bg-afri-ink text-white/70">
      <div className="mx-auto max-w-7xl px-4 py-14 sm:px-6 lg:px-8">
        <div className="grid gap-10 md:grid-cols-2">
          <div>
            <a href="#" className="mb-4 inline-block">
              <img src={afriosLogo} alt="AfriOS" className="h-10 w-auto rounded-xl" />
            </a>
            <p className="max-w-sm text-sm leading-relaxed">
              L'application mobile qui aide les commerçants et prestataires d'Afrique de l'Ouest à facturer, suivre leurs
              encaissements et gérer clients et stock.
            </p>
          </div>

          <div className="grid gap-8 sm:grid-cols-2">
            <div>
              <h4 className="mb-4 text-sm font-bold text-white">Sur cette page</h4>
              <ul className="space-y-2.5 text-sm">
                {links.map((l) => (
                  <li key={l.href}>
                    <a href={l.href} className="transition-colors hover:text-afri-teal-bright">
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h4 className="mb-4 text-sm font-bold text-white">Contact</h4>
              <ul className="space-y-2.5 text-sm">
                <li>
                  <a href="mailto:info.afrios@gmail.com" className="transition-colors hover:text-afri-teal-bright">
                    info.afrios@gmail.com
                  </a>
                </li>
                <li>
                  <a href="https://wa.me/22604046190" className="transition-colors hover:text-afri-teal-bright">
                    WhatsApp : +226 04 04 61 90
                  </a>
                </li>
                <li>Bêta Android · Afrique de l'Ouest</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mt-12 border-t border-white/10 pt-6 text-xs text-white/50">
          © 2026 AfriOS. Application en phase bêta : certaines fonctions évoluent encore.
        </div>
      </div>
    </footer>
  );
}
