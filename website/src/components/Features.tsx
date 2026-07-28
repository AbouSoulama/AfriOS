import { useState } from "react";

const features = [
  {
    id: "invoices",
    label: "Facturation",
    icon: "📄",
    title: "Des factures professionnelles en 30 secondes",
    desc: "Créez, envoyez et suivez vos factures depuis votre téléphone. Envoi par WhatsApp en un clic. Statuts de paiement en temps réel.",
    bullets: ["Modèles personnalisables", "TVA et totaux automatiques", "Envoi WhatsApp & SMS", "Statuts Brouillon / Envoyée / Payée"],
    gradient: "from-teal-500 to-emerald-600",
    screen: "invoice",
  },
  {
    id: "clients",
    label: "CRM",
    icon: "👥",
    title: "Tous vos clients, parfaitement organisés",
    desc: "Fiches clients complètes, historique des transactions, montants dus et relances automatiques. Ne perdez plus aucun client.",
    bullets: ["Fiches clients détaillées", "Historique par client", "Recherche intelligente", "Montants dus en direct"],
    gradient: "from-blue-500 to-indigo-600",
    screen: "client",
  },
  {
    id: "stock",
    label: "Stock",
    icon: "📦",
    title: "Gestion de stock simplissime",
    desc: "Ajoutez vos produits, suivez les mouvements et recevez des alertes stock faible. Plus de rupture, plus de perte.",
    bullets: ["Mouvements entrée/sortie", "Alertes stock bas", "Catégories de produits", "Prix et coûts automatiques"],
    gradient: "from-orange-500 to-rose-500",
    screen: "stock",
  },
  {
    id: "money",
    label: "Mobile Money",
    icon: "💸",
    title: "Paiements Wave, Orange Money, MTN MoMo",
    desc: "Recevez des paiements directement sur vos factures. Statut automatique, historique complet, commissions transparentes.",
    bullets: ["Wave · Orange Money · MTN", "Paiement en 1 clic", "Statut automatique", "Conforme aux réglementations"],
    gradient: "from-emerald-500 to-teal-600",
    screen: "payment",
  },
  {
    id: "reminders",
    label: "Relances",
    icon: "🔔",
    title: "Relances automatiques qui fonctionnent",
    desc: "Programmez vos relances (3j, 7j, 14j après échéance). L'app contacte vos clients automatiquement par WhatsApp.",
    bullets: ["Règles programmables", "Templates personnalisables", "Envoi WhatsApp + SMS", "Historique des relances"],
    gradient: "from-amber-500 to-orange-600",
    screen: "reminder",
  },
  {
    id: "ai",
    label: "IA Business",
    icon: "🤖",
    title: "Un assistant IA qui comprend votre business",
    desc: "« Combien j'ai facturé ce mois ? » · « Relance les clients en retard » · L'IA résume, agit et conseille en français simple.",
    bullets: ["Questions en langage naturel", "Actions directes (relances)", "Alertes intelligentes", "Conseils business personnalisés"],
    gradient: "from-violet-500 via-fuchsia-500 to-blue-600",
    screen: "ai",
  },
];

export default function Features() {
  const [active, setActive] = useState(0);
  const feat = features[active];

  return (
    <section id="features" className="relative py-24 bg-white overflow-hidden">
      <div className="absolute inset-0 bg-dots opacity-30" />
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <span className="inline-block px-4 py-1.5 rounded-full bg-teal-50 text-teal-700 text-xs font-bold uppercase tracking-wider mb-4">
            Une super-app complète
          </span>
          <h2 className="font-display text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight mb-6">
            Tout ce qu'il faut pour <span className="gradient-text-teal-navy">gérer son business</span>.
          </h2>
          <p className="text-lg text-slate-600">
            Une application unique qui remplace WhatsApp, les cahiers, Excel et les 5 apps que vous utilisez déjà.
          </p>
        </div>

        {/* Tab navigation */}
        <div className="flex flex-wrap justify-center gap-2 mb-12">
          {features.map((f, i) => (
            <button
              key={f.id}
              onClick={() => setActive(i)}
              className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-full text-sm font-bold transition-all ${
                active === i
                  ? "tab-active"
                  : "bg-slate-100 text-slate-700 hover:bg-slate-200"
              }`}
            >
              <span>{f.icon}</span>
              <span>{f.label}</span>
            </button>
          ))}
        </div>

        {/* Feature detail */}
        <div className="grid lg:grid-cols-2 gap-10 items-center">
          <div key={feat.id} className="animate-fade-in-up">
            <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r ${feat.gradient} text-white text-xs font-bold mb-4`}>
              <span>{feat.icon}</span>
              <span>{feat.label}</span>
            </div>
            <h3 className="font-display text-3xl sm:text-4xl font-extrabold tracking-tight mb-4">
              {feat.title}
            </h3>
            <p className="text-lg text-slate-600 mb-6 leading-relaxed">{feat.desc}</p>

            <ul className="space-y-3 mb-8">
              {feat.bullets.map((b) => (
                <li key={b} className="flex items-start gap-3">
                  <div className={`flex-shrink-0 w-6 h-6 rounded-full bg-gradient-to-br ${feat.gradient} flex items-center justify-center shadow-md`}>
                    <svg className="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7"/></svg>
                  </div>
                  <span className="text-slate-700 font-medium pt-0.5">{b}</span>
                </li>
              ))}
            </ul>

            <div className="flex items-center gap-4">
              <button className="btn-shine inline-flex items-center gap-2 px-6 py-3 text-sm font-bold text-white rounded-2xl bg-gradient-to-r from-teal-600 to-blue-800 shadow-lg shadow-teal-500/30">
                Essayer gratuitement
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 8l4 4m0 0l-4 4m4-4H3"/></svg>
              </button>
              <span className="text-sm text-slate-500">Disponible sur Android · moins de 80 MB</span>
            </div>
          </div>

          {/* Screen mockup */}
          <div className="relative flex justify-center">
            <div className={`absolute -inset-10 bg-gradient-to-br ${feat.gradient} opacity-10 rounded-[3rem] blur-3xl`} />
            <FeatureScreen type={feat.screen} />
          </div>
        </div>

        {/* Feature grid */}
        <div className="mt-24 grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {[
            { icon: "⚡", title: "Rapide", desc: "S'ouvre en moins de 3 secondes sur n'importe quel Android." },
            { icon: "📶", title: "Mode offline", desc: "Consultez vos données même sans connexion internet." },
            { icon: "🔒", title: "Sécurisé", desc: "Chiffrement de bout en bout. Vos données restent les vôtres." },
            { icon: "🇸🇳", title: "Local", desc: "FCFA, français, WhatsApp, Mobile Money — pensé pour l'Afrique." },
            { icon: "📱", title: "Android-first", desc: "Optimisé pour les téléphones les plus utilisés en Afrique." },
            { icon: "💡", title: "Intelligent", desc: "L'IA vous suggère les prochaines actions à chaque instant." },
          ].map((c) => (
            <div key={c.title} className="card-lift p-6 rounded-3xl bg-white border border-slate-200/70 shadow-sm">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-teal-50 to-blue-50 border border-teal-100 flex items-center justify-center text-2xl mb-4">
                {c.icon}
              </div>
              <h4 className="font-display text-lg font-bold mb-2">{c.title}</h4>
              <p className="text-sm text-slate-600 leading-relaxed">{c.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function FeatureScreen({ type }: { type: string }) {
  return (
    <div className="relative w-[300px] animate-float">
      <div className="relative rounded-[2.5rem] p-2.5 bg-gradient-to-b from-slate-800 to-slate-900 phone-shadow">
        <div className="relative rounded-[2rem] overflow-hidden bg-slate-50 aspect-[9/19]">
          <div className="absolute top-0 inset-x-0 h-6 bg-slate-900 z-20 flex items-center justify-between px-5 text-[9px] text-white font-semibold">
            <span>9:41</span>
            <div className="absolute left-1/2 -translate-x-1/2 top-1 w-16 h-3 bg-black rounded-full" />
            <span>100%</span>
          </div>
          <div className="absolute inset-0 pt-6 pb-2 overflow-y-auto">
            {type === "invoice" && <InvoiceScreen />}
            {type === "client" && <ClientScreen />}
            {type === "stock" && <StockScreen />}
            {type === "payment" && <PaymentScreen />}
            {type === "reminder" && <ReminderScreen />}
            {type === "ai" && <AIScreen />}
          </div>
        </div>
      </div>
    </div>
  );
}

function InvoiceScreen() {
  return (
    <div className="p-4">
      <p className="text-[10px] text-slate-500 mb-1">Facture #002</p>
      <h3 className="text-base font-black text-slate-900 mb-3">Boutique Fatou</h3>
      <div className="rounded-xl bg-white border border-slate-200 p-3 mb-3">
        <p className="text-[10px] text-slate-500 mb-0.5">Client</p>
        <p className="text-xs font-bold text-slate-900">Amadou Diallo</p>
        <p className="text-[10px] text-slate-500">+221 77 123 45 67</p>
      </div>
      <div className="rounded-xl bg-white border border-slate-200 divide-y divide-slate-100 mb-3">
        {[
          { name: "T-shirt Nike", qty: 2, price: 15000 },
          { name: "Baskets Adidas", qty: 1, price: 45000 },
          { name: "Casquette Gucci", qty: 3, price: 8000 },
        ].map((it, i) => (
          <div key={i} className="flex items-center justify-between p-3">
            <div>
              <p className="text-xs font-bold text-slate-900">{it.name}</p>
              <p className="text-[10px] text-slate-500">{it.qty} × {it.price.toLocaleString()} FCFA</p>
            </div>
            <p className="text-xs font-black text-slate-900">{(it.qty * it.price).toLocaleString()}</p>
          </div>
        ))}
      </div>
      <div className="rounded-xl bg-gradient-to-br from-teal-600 to-blue-800 p-4 text-white mb-3">
        <div className="flex justify-between text-[10px] text-teal-100 mb-1">
          <span>Sous-total</span><span>99 000 FCFA</span>
        </div>
        <div className="flex justify-between text-[10px] text-teal-100 mb-2">
          <span>TVA 18%</span><span>17 820 FCFA</span>
        </div>
        <div className="flex justify-between items-end border-t border-white/20 pt-2">
          <span className="text-xs font-bold">Total</span>
          <span className="text-xl font-black">116 820</span>
        </div>
      </div>
      <button className="w-full py-2.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-600 text-white text-xs font-bold shadow-lg">
        💬 Envoyer par WhatsApp
      </button>
    </div>
  );
}

function ClientScreen() {
  const clients = [
    { name: "Amadou Diallo", phone: "77 123 45 67", total: "320 000", due: "45 000", late: true },
    { name: "Fatou Ndiaye", phone: "78 987 65 43", total: "580 000", due: "0", late: false },
    { name: "Moussa Sarr", phone: "70 111 22 33", total: "120 000", due: "80 000", late: true },
    { name: "Aïssatou Ba", phone: "76 333 44 55", total: "450 000", due: "0", late: false },
  ];
  return (
    <div className="p-4">
      <div className="flex items-center justify-between mb-3">
        <div>
          <p className="text-[10px] text-slate-500">Mes clients</p>
          <h3 className="text-base font-black text-slate-900">128 contacts</h3>
        </div>
        <button className="w-8 h-8 rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white text-lg font-bold">+</button>
      </div>
      <div className="relative mb-3">
        <input className="w-full pl-8 pr-3 py-2 rounded-xl bg-white border border-slate-200 text-xs" placeholder="Rechercher..." />
        <svg className="absolute left-2.5 top-2.5 w-4 h-4 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
      </div>
      <div className="space-y-2">
        {clients.map((c, i) => (
          <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-white border border-slate-200">
            <div className="w-9 h-9 rounded-full bg-gradient-to-br from-teal-400 to-blue-600 flex items-center justify-center text-white text-xs font-bold">
              {c.name.split(" ").map(n => n[0]).join("")}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-bold text-slate-900 truncate">{c.name}</p>
              <p className="text-[10px] text-slate-500">+221 {c.phone}</p>
            </div>
            <div className="text-right">
              <p className="text-[10px] font-bold text-slate-900">{c.total} FCFA</p>
              {c.due !== "0" ? (
                <p className={`text-[10px] font-bold ${c.late ? "text-rose-600" : "text-amber-600"}`}>{c.due} dû</p>
              ) : (
                <p className="text-[10px] text-emerald-600 font-bold">✓ Soldé</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function StockScreen() {
  const products = [
    { name: "T-shirt Nike", qty: 45, price: 15000, low: false },
    { name: "Baskets Adidas", qty: 12, price: 45000, low: true },
    { name: "Casquette Gucci", qty: 3, price: 8000, low: true },
    { name: "Jean Levi's", qty: 28, price: 22000, low: false },
  ];
  return (
    <div className="p-4">
      <div className="rounded-2xl bg-gradient-to-br from-orange-500 to-rose-500 p-4 text-white mb-3">
        <p className="text-[10px] text-orange-100 mb-1">Valeur stock</p>
        <p className="text-xl font-black mb-0.5">2 340 000 FCFA</p>
        <div className="flex items-center gap-2 mt-2">
          <span className="text-[9px] font-bold bg-white/20 px-2 py-1 rounded-lg">⚠ 3 produits en stock faible</span>
        </div>
      </div>
      <div className="flex items-center justify-between mb-2">
        <p className="text-xs font-bold text-slate-900">Produits</p>
        <button className="w-7 h-7 rounded-lg bg-gradient-to-br from-orange-500 to-rose-500 text-white text-sm font-bold">+</button>
      </div>
      <div className="space-y-2">
        {products.map((p, i) => (
          <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-white border border-slate-200">
            <div className={`w-10 h-10 rounded-xl ${p.low ? "bg-rose-100" : "bg-orange-100"} flex items-center justify-center text-base`}>📦</div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-bold text-slate-900 truncate">{p.name}</p>
              <p className="text-[10px] text-slate-500">{p.price.toLocaleString()} FCFA</p>
            </div>
            <div className="text-right">
              <p className={`text-sm font-black ${p.low ? "text-rose-600" : "text-slate-900"}`}>{p.qty}</p>
              <p className="text-[9px] text-slate-500">unités</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function PaymentScreen() {
  return (
    <div className="p-4">
      <p className="text-[10px] text-slate-500 mb-1 text-center">Facture #001</p>
      <h3 className="text-center text-base font-black text-slate-900 mb-4">45 000 FCFA</h3>
      <div className="rounded-2xl bg-white border border-slate-200 p-4 mb-3">
        <p className="text-[10px] text-slate-500 text-center mb-3">Choisir un mode de paiement</p>
        <div className="space-y-2">
          {[
            { name: "Wave", color: "from-emerald-500 to-teal-600", letter: "W", tag: "Recommandé" },
            { name: "Orange Money", color: "from-orange-500 to-orange-600", letter: "OM" },
            { name: "MTN MoMo", color: "from-yellow-400 to-amber-500", letter: "M" },
          ].map((m, i) => (
            <button key={i} className="w-full flex items-center gap-3 p-3 rounded-xl border-2 border-slate-200 hover:border-teal-500 transition-colors">
              <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${m.color} flex items-center justify-center text-white text-sm font-black shadow-md`}>{m.letter}</div>
              <div className="flex-1 text-left">
                <p className="text-xs font-bold text-slate-900">{m.name}</p>
                <p className="text-[10px] text-slate-500">Paiement instantané</p>
              </div>
              {m.tag && <span className="text-[9px] font-bold bg-teal-100 text-teal-700 px-2 py-1 rounded-lg">{m.tag}</span>}
            </button>
          ))}
        </div>
      </div>
      <button className="w-full py-2.5 rounded-xl bg-emerald-50 text-emerald-700 text-xs font-bold border border-emerald-200">
        ✓ Marquer comme payé (espèces)
      </button>
    </div>
  );
}

function ReminderScreen() {
  return (
    <div className="p-4">
      <div className="rounded-2xl bg-gradient-to-br from-amber-500 to-orange-600 p-4 text-white mb-3">
        <p className="text-[10px] text-amber-100 mb-1">À relancer</p>
        <p className="text-2xl font-black mb-1">8 clients</p>
        <p className="text-[10px] text-amber-100">320 000 FCFA en attente</p>
        <button className="mt-3 w-full py-2 rounded-xl bg-white text-orange-600 text-xs font-bold">🔔 Relancer tous maintenant</button>
      </div>
      {[
        { name: "Amadou Diallo", amount: "45 000", days: 12, invoice: "#001" },
        { name: "Moussa Sarr", amount: "80 000", days: 5, invoice: "#003" },
        { name: "Khady Fall", amount: "35 000", days: 2, invoice: "#007" },
      ].map((c, i) => (
        <div key={i} className="flex items-center gap-2 p-2.5 rounded-xl bg-white border border-slate-200 mb-2">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-amber-400 to-orange-500 flex items-center justify-center text-white text-xs font-bold">
            {c.name.split(" ").map(n => n[0]).join("")}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-bold text-slate-900 truncate">{c.name}</p>
            <p className="text-[10px] text-rose-600 font-semibold">{c.days}j de retard · Facture {`#${c.invoice.replace("#", "")}`}</p>
          </div>
          <button className="px-3 py-1.5 rounded-lg bg-amber-100 text-amber-700 text-[10px] font-bold">💬 Relancer</button>
        </div>
      ))}
    </div>
  );
}

function AIScreen() {
  return (
    <div className="p-4">
      <div className="flex items-center gap-2 mb-4 pb-3 border-b border-slate-200">
        <div className="relative w-9 h-9 rounded-2xl bg-gradient-to-br from-violet-500 via-fuchsia-500 to-blue-600 flex items-center justify-center">
          <span className="text-white text-sm">✨</span>
        </div>
        <div>
          <p className="text-xs font-bold text-slate-900">Assistant AfriOS</p>
          <p className="text-[10px] text-emerald-600 font-semibold">● En ligne</p>
        </div>
      </div>
      <div className="space-y-3">
        <div className="flex justify-end">
          <div className="max-w-[80%] rounded-2xl rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white p-3 shadow-md">
            <p className="text-xs font-medium">Combien j'ai facturé ce mois ?</p>
          </div>
        </div>
        <div className="flex justify-start">
          <div className="max-w-[85%] rounded-2xl rounded-tl-sm bg-white border border-slate-200 p-3 shadow-sm">
            <p className="text-xs text-slate-700 mb-2">Tu as facturé <strong>1 245 000 FCFA</strong> ce mois-ci. Tu as <strong>8 factures</strong> en attente.</p>
            <div className="flex flex-wrap gap-1.5">
              {["Relancer les clients", "Voir détail", "Comparer mois dernier"].map((s, i) => (
                <button key={i} className="px-2.5 py-1 rounded-lg bg-teal-50 text-teal-700 text-[10px] font-bold border border-teal-100">{s}</button>
              ))}
            </div>
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
      <div className="fixed bottom-2 left-4 right-4">
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
