import afriosLogo from "../assets/afrios-logo.png";

export default function Footer() {
  const cols = [
    {
      title: "Produit",
      links: ["Fonctionnalités", "Facturation", "Gestion de stock", "Mobile Money", "Assistant IA", "Tarifs"],
    },
    {
      title: "Ressources",
      links: ["Documentation", "Guides utilisateur", "API & intégrations", "Statut", "Blog", "Roadmap"],
    },
    {
      title: "Entreprise",
      links: ["À propos", "Clients & témoignages", "Carrières", "Presse", "Contact", "Partenaires"],
    },
    {
      title: "Légal",
      links: ["Conditions d'utilisation", "Politique de confidentialité", "Sécurité des données", "Conformité", "Cookies"],
    },
  ];

  return (
    <footer className="relative bg-slate-950 text-slate-300 overflow-hidden">
      <div className="absolute inset-0 bg-dots opacity-5" />
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-teal-500/40 to-transparent" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid lg:grid-cols-12 gap-10 mb-12">
          <div className="lg:col-span-4">
            <a href="#" className="flex items-center gap-2.5 mb-5">
              <img src={afriosLogo} alt="AfriOS" className="h-10 w-auto" />
            </a>
            <p className="text-sm text-slate-400 leading-relaxed mb-6 max-w-sm">
              Une application mobile tout-en-un qui permet aux PME africaines de gérer facturation, stock, clients, paiements Mobile Money et IA — simplement.
            </p>
            <div className="flex items-center gap-3 mb-6">
              {[
                { label: "WhatsApp", color: "from-emerald-500 to-teal-600", icon: "💬" },
                { label: "LinkedIn", color: "from-blue-500 to-blue-700", icon: "in" },
                { label: "Twitter", color: "from-slate-700 to-slate-900", icon: "𝕏" },
                { label: "TikTok", color: "from-fuchsia-500 to-pink-600", icon: "♪" },
              ].map((s) => (
                <a key={s.label} href="#" className={`w-10 h-10 rounded-xl bg-gradient-to-br ${s.color} flex items-center justify-center text-white text-sm font-bold shadow-md hover:scale-110 transition-transform`} aria-label={s.label}>
                  {s.icon}
                </a>
              ))}
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4 backdrop-blur-sm">
              <p className="text-xs font-bold text-white mb-2">📩 Recevez nos actualités</p>
              <p className="text-xs text-slate-400 mb-3">Conseils business, nouveautés, offres exclusives.</p>
              <div className="flex gap-2">
                <input className="flex-1 px-3 py-2 rounded-xl bg-white/10 border border-white/10 text-xs text-white placeholder:text-slate-500 outline-none focus:border-teal-400" placeholder="votre@email.com" />
                <button className="px-4 py-2 rounded-xl bg-gradient-to-r from-teal-500 to-blue-700 text-white text-xs font-bold">OK</button>
              </div>
            </div>
          </div>

          <div className="lg:col-span-8 grid grid-cols-2 md:grid-cols-4 gap-8">
            {cols.map((col) => (
              <div key={col.title}>
                <h4 className="text-sm font-bold text-white mb-4">{col.title}</h4>
                <ul className="space-y-2.5">
                  {col.links.map((l) => (
                    <li key={l}>
                      <a href="#" className="text-sm text-slate-400 hover:text-teal-300 transition-colors">{l}</a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>

        {/* Countries */}
        <div className="flex flex-wrap items-center justify-center gap-3 py-6 border-y border-white/10 mb-8">
          <span className="text-xs font-bold uppercase tracking-wider text-slate-500">Disponible dans</span>
          {[
            { flag: "🇸🇳", name: "Sénégal" },
            { flag: "🇨🇮", name: "Côte d'Ivoire" },
            { flag: "🇬🇭", name: "Ghana (bientôt)" },
            { flag: "🇳🇬", name: "Nigeria (bientôt)" },
            { flag: "🇰🇪", name: "Kenya (bientôt)" },
            { flag: "🇲🇱", name: "Mali (bientôt)" },
          ].map((c) => (
            <span key={c.name} className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/5 border border-white/10 text-xs text-slate-300">
              <span>{c.flag}</span>
              <span>{c.name}</span>
            </span>
          ))}
        </div>

        <div className="flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-slate-500">
          <p>© 2026 AfriOS SAS. Tous droits réservés. Fait avec ❤️ en Afrique.</p>
          <div className="flex items-center gap-4">
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Tous les services opérationnels</span>
            </span>
            <span>·</span>
            <span>v1.0 · MVP</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
