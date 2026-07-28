import { useState } from "react";

const tabs = [
  { id: "home", label: "Accueil", icon: "🏠" },
  { id: "invoices", label: "Factures", icon: "📄" },
  { id: "clients", label: "Clients", icon: "👥" },
  { id: "stock", label: "Stock", icon: "📦" },
  { id: "ai", label: "IA", icon: "✨" },
];

export default function PhoneShowcase() {
  const [tab, setTab] = useState("home");

  return (
    <section id="showcase" className="relative py-24 bg-gradient-to-b from-slate-50 via-white to-teal-50/30 overflow-hidden">
      <div className="absolute top-40 left-1/4 w-96 h-96 rounded-full bg-gradient-to-br from-teal-200/40 to-transparent blur-3xl" />
      <div className="absolute bottom-40 right-1/4 w-96 h-96 rounded-full bg-gradient-to-br from-orange-200/40 to-transparent blur-3xl" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-12">
          <span className="inline-block px-4 py-1.5 rounded-full bg-blue-50 text-blue-700 text-xs font-bold uppercase tracking-wider mb-4">
            Design mobile-first
          </span>
          <h2 className="font-display text-4xl sm:text-5xl font-extrabold tracking-tight mb-4">
            Une app <span className="gradient-text-teal-navy">extrêmement simple</span>.
          </h2>
          <p className="text-lg text-slate-600">
            Inspirée de WhatsApp, Wave et Notion. Une barre de navigation, 5 onglets, zéro friction.
          </p>
        </div>

        {/* Tab selector */}
        <div className="flex flex-wrap justify-center gap-2 mb-10">
          {tabs.map((t) => (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={`inline-flex items-center gap-2 px-5 py-2.5 rounded-full text-sm font-bold transition-all ${
                tab === t.id
                  ? "bg-slate-900 text-white shadow-xl shadow-slate-900/30"
                  : "bg-white text-slate-700 border border-slate-200 hover:border-slate-300"
              }`}
            >
              <span>{t.icon}</span>
              <span>{t.label}</span>
            </button>
          ))}
        </div>

        {/* Big phone */}
        <div className="relative max-w-5xl mx-auto">
          <div className="grid lg:grid-cols-5 gap-8 items-center">
            <div className="lg:col-span-2 space-y-4">
              {tab === "home" && (
                <>
                  <h3 className="font-display text-3xl font-extrabold">Le tableau de bord, en un coup d'œil.</h3>
                  <p className="text-slate-600">Chiffre d'affaires, factures en attente, stock faible, clients à relancer. Tout ce qui compte est sur l'écran d'accueil.</p>
                  <ul className="space-y-2 text-sm text-slate-700">
                    {["Graphiques CA jour/semaine/mois", "Raccourcis rapides (facture, client, stock)", "Alertes intelligentes en temps réel", "Notifications push personnalisées"].map((x) => (
                      <li key={x} className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center text-xs font-bold">✓</span>
                        {x}
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {tab === "invoices" && (
                <>
                  <h3 className="font-display text-3xl font-extrabold">Créez une facture en 30 secondes.</h3>
                  <p className="text-slate-600">Sélectionnez un client, ajoutez des produits, choisissez le mode d'envoi. L'app calcule tout : sous-total, TVA, remise, total.</p>
                  <ul className="space-y-2 text-sm text-slate-700">
                    {["Envoi WhatsApp et PDF généré", "Statut Brouillon → Envoyée → Payée", "Historique complet", "Modèles réutilisables"].map((x) => (
                      <li key={x} className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center text-xs font-bold">✓</span>
                        {x}
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {tab === "clients" && (
                <>
                  <h3 className="font-display text-3xl font-extrabold">Votre CRM, ultra-léger.</h3>
                  <p className="text-slate-600">Fiches clients, historiques, montants dus. Une recherche rapide par nom ou téléphone.</p>
                  <ul className="space-y-2 text-sm text-slate-700">
                    {["Profil client détaillé", "Historique factures/paiements", "1 clic pour appeler ou WhatsApp", "Tags et notes privées"].map((x) => (
                      <li key={x} className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center text-xs font-bold">✓</span>
                        {x}
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {tab === "stock" && (
                <>
                  <h3 className="font-display text-3xl font-extrabold">Plus de rupture de stock.</h3>
                  <p className="text-slate-600">Suivez vos entrées et sorties. Recevez une alerte dès qu'un produit passe sous le seuil configuré.</p>
                  <ul className="space-y-2 text-sm text-slate-700">
                    {["Mouvements tracés et horodatés", "Alertes push stock bas", "Valeur totale du stock", "Catégories et recherche"].map((x) => (
                      <li key={x} className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center text-xs font-bold">✓</span>
                        {x}
                      </li>
                    ))}
                  </ul>
                </>
              )}
              {tab === "ai" && (
                <>
                  <h3 className="font-display text-3xl font-extrabold">L'IA qui comprend votre business.</h3>
                  <p className="text-slate-600">Posez vos questions en français simple. L'IA interroge vos données et peut même agir à votre place.</p>
                  <ul className="space-y-2 text-sm text-slate-700">
                    {["« Relance tous les clients en retard »", "« Quel est mon CA ce mois ? »", "« Quels produits sont en stock faible ? »", "Conseils business personnalisés"].map((x) => (
                      <li key={x} className="flex items-center gap-2">
                        <span className="w-5 h-5 rounded-full bg-teal-100 text-teal-700 flex items-center justify-center text-xs font-bold">✓</span>
                        {x}
                      </li>
                    ))}
                  </ul>
                </>
              )}
            </div>

            <div className="lg:col-span-3 flex justify-center">
              <div className="relative w-[340px] sm:w-[380px]">
                <div className="absolute -inset-12 bg-gradient-to-br from-teal-400/20 via-blue-400/20 to-orange-300/20 rounded-[4rem] blur-3xl" />
                <div className="relative rounded-[3rem] p-3 bg-gradient-to-b from-slate-800 to-slate-900 phone-shadow animate-float">
                  <div className="relative rounded-[2.4rem] overflow-hidden bg-white aspect-[9/19]">
                    <div className="absolute top-0 inset-x-0 h-7 bg-slate-900 z-20 flex items-center justify-between px-6 text-[10px] text-white font-semibold">
                      <span>9:41</span>
                      <div className="absolute left-1/2 -translate-x-1/2 top-1.5 w-24 h-4 bg-black rounded-full" />
                      <span>🔋 100%</span>
                    </div>
                    <div className="absolute inset-0 pt-7 pb-20 overflow-y-auto">
                      <ShowcaseContent tab={tab} />
                    </div>
                    <div className="absolute bottom-0 inset-x-0 h-16 bg-white/95 backdrop-blur border-t border-slate-200 flex items-center justify-around z-20">
                      {tabs.map((t) => (
                        <button
                          key={t.id}
                          onClick={() => setTab(t.id)}
                          className={`flex flex-col items-center gap-0.5 ${tab === t.id ? "text-teal-600" : "text-slate-400"}`}
                        >
                          <span className="text-lg leading-none">{t.icon}</span>
                          <span className="text-[9px] font-bold">{t.label}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function ShowcaseContent({ tab }: { tab: string }) {
  if (tab === "home") {
    return (
      <div className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[10px] text-slate-500">Bonjour 👋</p>
            <p className="text-sm font-bold">Boutique Fatou</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-teal-500 to-blue-700 flex items-center justify-center text-white text-xs font-bold">BF</div>
        </div>
        <div className="rounded-2xl bg-gradient-to-br from-teal-600 via-blue-700 to-blue-900 p-4 text-white shadow-lg">
          <p className="text-[10px] text-teal-100 mb-1">CA · Ce mois</p>
          <p className="text-3xl font-black mb-1">1 245 000</p>
          <p className="text-[10px] text-teal-200 mb-3">FCFA</p>
          {/* Mini chart */}
          <div className="flex items-end gap-1 h-14">
            {[40, 65, 45, 80, 55, 90, 70, 95, 85, 100, 75, 110].map((h, i) => (
              <div key={i} className="flex-1 rounded-t bg-white/30" style={{ height: `${h * 0.6}%` }} />
            ))}
          </div>
        </div>
        <div className="grid grid-cols-4 gap-2">
          {[
            { label: "Facture", color: "from-teal-500 to-teal-700", icon: "📄" },
            { label: "Client", color: "from-blue-500 to-blue-700", icon: "👤" },
            { label: "Stock", color: "from-orange-500 to-orange-700", icon: "📦" },
            { label: "Paiement", color: "from-emerald-500 to-emerald-700", icon: "💸" },
          ].map((a) => (
            <div key={a.label} className="flex flex-col items-center gap-1">
              <div className={`w-11 h-11 rounded-2xl bg-gradient-to-br ${a.color} flex items-center justify-center text-base shadow-md`}>{a.icon}</div>
              <span className="text-[9px] font-semibold text-slate-700">{a.label}</span>
            </div>
          ))}
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div className="rounded-xl bg-amber-50 border border-amber-100 p-3">
            <p className="text-[9px] text-amber-700 font-semibold mb-1">Factures en attente</p>
            <p className="text-lg font-black text-amber-900">8</p>
            <p className="text-[9px] text-amber-700">320 000 FCFA</p>
          </div>
          <div className="rounded-xl bg-rose-50 border border-rose-100 p-3">
            <p className="text-[9px] text-rose-700 font-semibold mb-1">Stock faible</p>
            <p className="text-lg font-black text-rose-900">3</p>
            <p className="text-[9px] text-rose-700">produits</p>
          </div>
        </div>
        <p className="text-[11px] font-bold">Derniers mouvements</p>
        {[
          { name: "Amadou Diallo", amount: "+45 000", type: "Paiement Wave", color: "bg-emerald-100 text-emerald-700" },
          { name: "Fatou Ndiaye", amount: "120 000", type: "Facture #002", color: "bg-blue-100 text-blue-700" },
          { name: "Moussa Sarr", amount: "+80 000", type: "Orange Money", color: "bg-emerald-100 text-emerald-700" },
        ].map((t, i) => (
          <div key={i} className="flex items-center gap-2 p-2 rounded-xl bg-slate-50">
            <div className={`w-8 h-8 rounded-lg ${t.color} flex items-center justify-center text-[10px] font-bold`}>✓</div>
            <div className="flex-1 min-w-0">
              <p className="text-[11px] font-bold truncate">{t.name}</p>
              <p className="text-[9px] text-slate-500">{t.type}</p>
            </div>
            <p className="text-[11px] font-black">{t.amount}</p>
          </div>
        ))}
      </div>
    );
  }

  if (tab === "invoices") {
    return (
      <div className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[10px] text-slate-500">Factures</p>
            <p className="text-sm font-bold">Ce mois</p>
          </div>
          <button className="w-9 h-9 rounded-xl bg-gradient-to-br from-teal-500 to-blue-700 text-white text-lg font-bold shadow-md">+</button>
        </div>
        <div className="rounded-2xl bg-gradient-to-br from-teal-600 to-blue-800 p-4 text-white">
          <p className="text-[10px] text-teal-100">Total facturé</p>
          <p className="text-2xl font-black">1 245 000 FCFA</p>
          <div className="flex gap-2 mt-3">
            {[
              { l: "Payée", v: "12", c: "bg-white/20" },
              { l: "En attente", v: "8", c: "bg-amber-500/30" },
              { l: "En retard", v: "3", c: "bg-rose-500/30" },
            ].map((s) => (
              <div key={s.l} className={`flex-1 ${s.c} rounded-xl p-2 text-center`}>
                <p className="text-lg font-black">{s.v}</p>
                <p className="text-[9px]">{s.l}</p>
              </div>
            ))}
          </div>
        </div>
        {[
          { n: "#001", c: "Amadou Diallo", t: "45 000", s: "En attente", sc: "bg-amber-100 text-amber-700" },
          { n: "#002", c: "Fatou Ndiaye", t: "120 000", s: "Payée", sc: "bg-emerald-100 text-emerald-700" },
          { n: "#003", c: "Moussa Sarr", t: "80 000", s: "En retard", sc: "bg-rose-100 text-rose-700" },
          { n: "#004", c: "Aïssatou Ba", t: "65 000", s: "Payée", sc: "bg-emerald-100 text-emerald-700" },
          { n: "#005", c: "Khady Fall", t: "35 000", s: "Brouillon", sc: "bg-slate-100 text-slate-700" },
        ].map((f, i) => (
          <div key={i} className="flex items-center gap-2 p-3 rounded-xl bg-white border border-slate-200">
            <div className="w-10 h-10 rounded-xl bg-teal-50 border border-teal-100 flex items-center justify-center text-[10px] font-bold text-teal-700">{f.n}</div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-bold truncate">{f.c}</p>
              <p className="text-[10px] text-slate-500">Facture {f.n}</p>
            </div>
            <div className="text-right">
              <p className="text-xs font-black">{f.t}</p>
              <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${f.sc}`}>{f.s}</span>
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (tab === "clients") {
    return (
      <div className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[10px] text-slate-500">Clients</p>
            <p className="text-sm font-bold">128 contacts</p>
          </div>
          <button className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white text-lg font-bold shadow-md">+</button>
        </div>
        <div className="relative">
          <input className="w-full pl-8 pr-3 py-2 rounded-xl bg-white border border-slate-200 text-xs" placeholder="Rechercher..." />
          <svg className="absolute left-2.5 top-2.5 w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
        </div>
        {[
          { n: "Amadou Diallo", p: "77 123 45 67", total: "320 000", due: "45 000", c: "from-teal-400 to-blue-600" },
          { n: "Fatou Ndiaye", p: "78 987 65 43", total: "580 000", due: "0", c: "from-orange-400 to-rose-500" },
          { n: "Moussa Sarr", p: "70 111 22 33", total: "120 000", due: "80 000", c: "from-amber-400 to-orange-500" },
          { n: "Aïssatou Ba", p: "76 333 44 55", total: "450 000", due: "0", c: "from-violet-400 to-blue-500" },
          { n: "Khady Fall", p: "75 444 55 66", total: "210 000", due: "35 000", c: "from-emerald-400 to-teal-500" },
          { n: "Ibrahima Gueye", p: "77 555 66 77", total: "890 000", due: "0", c: "from-rose-400 to-pink-500" },
        ].map((c, i) => (
          <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-white border border-slate-200">
            <div className={`w-9 h-9 rounded-full bg-gradient-to-br ${c.c} flex items-center justify-center text-white text-xs font-bold`}>
              {c.n.split(" ").map((x) => x[0]).join("")}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-bold truncate">{c.n}</p>
              <p className="text-[10px] text-slate-500">+221 {c.p}</p>
            </div>
            <div className="text-right">
              <p className="text-[10px] font-bold">{c.total}</p>
              {c.due !== "0" ? <p className="text-[10px] font-bold text-rose-600">{c.due} dû</p> : <p className="text-[10px] text-emerald-600 font-bold">✓ Soldé</p>}
            </div>
          </div>
        ))}
      </div>
    );
  }

  if (tab === "stock") {
    return (
      <div className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-[10px] text-slate-500">Stock</p>
            <p className="text-sm font-bold">47 produits</p>
          </div>
          <button className="w-9 h-9 rounded-xl bg-gradient-to-br from-orange-500 to-rose-500 text-white text-lg font-bold shadow-md">+</button>
        </div>
        <div className="rounded-2xl bg-gradient-to-br from-orange-500 to-rose-500 p-4 text-white">
          <p className="text-[10px] text-orange-100 mb-1">Valeur stock</p>
          <p className="text-2xl font-black mb-1">2 340 000 FCFA</p>
          <div className="flex items-center gap-2 mt-2 text-[9px]">
            <span className="font-bold bg-white/20 px-2 py-1 rounded-lg">⚠ 3 produits en stock faible</span>
          </div>
        </div>
        {[
          { n: "T-shirt Nike", q: 45, p: 15000, l: false },
          { n: "Baskets Adidas", q: 12, p: 45000, l: true },
          { n: "Casquette Gucci", q: 3, p: 8000, l: true },
          { n: "Jean Levi's", q: 28, p: 22000, l: false },
          { n: "Sac à dos", q: 15, p: 12000, l: false },
          { n: "Montre Casio", q: 2, p: 35000, l: true },
          { n: "Lunettes Ray-Ban", q: 8, p: 28000, l: false },
        ].map((p, i) => (
          <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-white border border-slate-200">
            <div className={`w-10 h-10 rounded-xl ${p.l ? "bg-rose-100" : "bg-orange-100"} flex items-center justify-center text-base`}>📦</div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-bold truncate">{p.n}</p>
              <p className="text-[10px] text-slate-500">{p.p.toLocaleString()} FCFA</p>
            </div>
            <div className="text-right">
              <p className={`text-sm font-black ${p.l ? "text-rose-600" : "text-slate-900"}`}>{p.q}</p>
              <p className="text-[9px] text-slate-500">unités</p>
            </div>
          </div>
        ))}
      </div>
    );
  }

  // AI
  return (
    <div className="p-4 space-y-3">
      <div className="flex items-center gap-2 pb-3 border-b border-slate-200">
        <div className="relative w-9 h-9 rounded-2xl bg-gradient-to-br from-violet-500 via-fuchsia-500 to-blue-600 flex items-center justify-center">
          <span className="text-white text-sm">✨</span>
        </div>
        <div className="flex-1">
          <p className="text-xs font-bold">Assistant AfriOS</p>
          <p className="text-[10px] text-emerald-600 font-semibold">● En ligne</p>
        </div>
      </div>
      <div className="space-y-3 pb-16">
        <div className="flex justify-end">
          <div className="max-w-[80%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white p-3 shadow-md">
            <p className="text-xs font-medium">Combien j'ai facturé ce mois ?</p>
          </div>
        </div>
        <div className="flex justify-start">
          <div className="max-w-[85%] rounded-2xl rounded-tl-sm bg-white border border-slate-200 p-3 shadow-sm">
            <p className="text-xs text-slate-700 mb-2">Tu as facturé <strong>1 245 000 FCFA</strong> ce mois. 8 factures en attente (320 000 FCFA).</p>
            <div className="flex flex-wrap gap-1.5">
              {["Relancer les clients", "Comparer mois dernier", "Voir détail CA"].map((s, i) => (
                <button key={i} className="px-2.5 py-1 rounded-lg bg-teal-50 text-teal-700 text-[10px] font-bold border border-teal-100">{s}</button>
              ))}
            </div>
          </div>
        </div>
        <div className="flex justify-end">
          <div className="max-w-[80%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white p-3 shadow-md">
            <p className="text-xs font-medium">Relance les clients en retard</p>
          </div>
        </div>
        <div className="flex justify-start">
          <div className="max-w-[85%] rounded-2xl rounded-tl-sm bg-gradient-to-br from-emerald-50 to-teal-50 border border-emerald-200 p-3">
            <div className="flex items-center gap-2 mb-2">
              <div className="w-6 h-6 rounded-full bg-emerald-500 flex items-center justify-center">
                <svg className="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7"/></svg>
              </div>
              <p className="text-xs font-bold text-emerald-900">Action effectuée</p>
            </div>
            <p className="text-xs text-emerald-800">Relance WhatsApp envoyée à <strong>8 clients</strong>. Montant total à recouvrer : <strong>320 000 FCFA</strong>.</p>
          </div>
        </div>
        <div className="flex justify-start">
          <div className="flex items-center gap-1.5 px-3 py-2 rounded-2xl bg-white border border-slate-200">
            <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
            <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
            <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
          </div>
        </div>
      </div>
      <div className="absolute bottom-20 left-4 right-4">
        <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-full pl-4 pr-2 py-2 shadow-lg">
          <input className="flex-1 text-xs bg-transparent outline-none" placeholder="Demande quelque chose..." />
          <button className="w-8 h-8 rounded-full bg-gradient-to-br from-violet-500 to-blue-600 text-white flex items-center justify-center">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z"/></svg>
          </button>
        </div>
      </div>
    </div>
  );
}
