import { useEffect, useState } from "react";

interface Props {
  onClose: () => void;
}

type Tab = "home" | "invoices" | "clients" | "stock" | "ai";

const tabs: { id: Tab; label: string; icon: string }[] = [
  { id: "home", label: "Accueil", icon: "🏠" },
  { id: "invoices", label: "Factures", icon: "📄" },
  { id: "clients", label: "Clients", icon: "👥" },
  { id: "stock", label: "Stock", icon: "📦" },
  { id: "ai", label: "IA", icon: "✨" },
];

export default function PhoneDemoModal({ onClose }: Props) {
  const [tab, setTab] = useState<Tab>("home");
  const [notif, setNotif] = useState<string | null>(null);

  useEffect(() => {
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = "";
    };
  }, []);

  useEffect(() => {
    const t = setTimeout(() => {
      setNotif("💸 Paiement Wave reçu · +45 000 FCFA");
    }, 2500);
    const t2 = setTimeout(() => setNotif(null), 6500);
    return () => {
      clearTimeout(t);
      clearTimeout(t2);
    };
  }, []);

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-8 bg-slate-900/70 backdrop-blur-md animate-fade-in-up" onClick={onClose}>
      <div className="absolute top-4 right-4 flex items-center gap-2 z-10">
        <button
          onClick={onClose}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/10 border border-white/20 text-white text-sm font-bold hover:bg-white/20 backdrop-blur-sm"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12"/></svg>
          Fermer
        </button>
      </div>

      <div className="relative w-full max-w-6xl" onClick={(e) => e.stopPropagation()}>
        <div className="grid lg:grid-cols-5 gap-6 items-start">
          {/* Left info */}
          <div className="lg:col-span-2 text-white space-y-4 hidden lg:block">
            <span className="inline-block px-3 py-1 rounded-full bg-teal-500/20 text-teal-300 text-xs font-bold uppercase tracking-wider border border-teal-500/30">
              Démo interactive
            </span>
            <h2 className="font-display text-4xl font-extrabold leading-tight">
              Essayez AfriOS,<br />sans installer.
            </h2>
            <p className="text-blue-200 text-base leading-relaxed">
              Naviguez entre les onglets comme dans la vraie application. Tout est simulé mais l'expérience est identique.
            </p>

            <div className="space-y-3 pt-4">
              {[
                { icon: "🏠", title: "Accueil", desc: "Tableau de bord business en un coup d'œil." },
                { icon: "📄", title: "Factures", desc: "Créez et envoyez des factures pro." },
                { icon: "👥", title: "Clients", desc: "Votre CRM simplissime." },
                { icon: "📦", title: "Stock", desc: "Gestion et alertes stock faible." },
                { icon: "✨", title: "IA", desc: "Assistant conversationnel." },
              ].map((t) => (
                <div key={t.title} className="flex items-start gap-3 p-3 rounded-2xl bg-white/5 border border-white/10 backdrop-blur-sm">
                  <div className="w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center text-lg">{t.icon}</div>
                  <div>
                    <p className="font-bold text-sm">{t.title}</p>
                    <p className="text-xs text-blue-200">{t.desc}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="rounded-2xl p-4 bg-gradient-to-br from-teal-500/20 to-blue-500/20 border border-teal-500/30">
              <p className="text-xs text-teal-200 font-bold mb-1">💡 Conseil</p>
              <p className="text-sm text-white">Cliquez sur les onglets en bas de l'écran pour naviguer.</p>
            </div>
          </div>

          {/* Phone */}
          <div className="lg:col-span-3 flex justify-center">
            <div className="relative w-[340px] sm:w-[380px]">
              {/* Notification */}
              {notif && (
                <div className="absolute -top-4 left-4 right-4 z-30 animate-notif">
                  <div className="rounded-2xl bg-white shadow-2xl border border-slate-200 p-3 flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center text-white text-lg shadow-md">💸</div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-bold text-slate-900">AfriOS</p>
                      <p className="text-[11px] text-slate-600 truncate">{notif}</p>
                    </div>
                    <span className="text-[10px] text-slate-400">maintenant</span>
                  </div>
                </div>
              )}

              <div className="absolute -inset-8 bg-gradient-to-br from-teal-400/20 via-blue-400/20 to-orange-300/10 rounded-[4rem] blur-3xl" />
              <div className="relative rounded-[3rem] p-3 bg-gradient-to-b from-slate-800 to-slate-900 phone-shadow">
                <div className="relative rounded-[2.4rem] overflow-hidden bg-gradient-to-b from-slate-50 to-white aspect-[9/19]">
                  {/* Status bar */}
                  <div className="absolute top-0 inset-x-0 h-7 bg-slate-900 z-30 flex items-center justify-between px-6 text-[10px] text-white font-semibold">
                    <span>9:41</span>
                    <div className="absolute left-1/2 -translate-x-1/2 top-1.5 w-24 h-4 bg-black rounded-full" />
                    <div className="flex items-center gap-1">
                      <span>📶</span>
                      <span>🔋 100%</span>
                    </div>
                  </div>

                  {/* Content */}
                  <div className="absolute inset-0 pt-7 pb-20 overflow-y-auto">
                    {tab === "home" && <DemoHome />}
                    {tab === "invoices" && <DemoInvoices />}
                    {tab === "clients" && <DemoClients />}
                    {tab === "stock" && <DemoStock />}
                    {tab === "ai" && <DemoAI />}
                  </div>

                  {/* Bottom nav */}
                  <div className="absolute bottom-0 inset-x-0 h-16 bg-white/95 backdrop-blur border-t border-slate-200 flex items-center justify-around z-20">
                    {tabs.map((t) => (
                      <button
                        key={t.id}
                        onClick={() => setTab(t.id)}
                        className={`flex flex-col items-center gap-0.5 px-2 py-1 transition-all ${tab === t.id ? "text-teal-600 scale-110" : "text-slate-400"}`}
                      >
                        <span className="text-lg leading-none">{t.icon}</span>
                        <span className="text-[9px] font-bold">{t.label}</span>
                        {tab === t.id && <span className="w-1 h-1 rounded-full bg-teal-600" />}
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
  );
}

function DemoHome() {
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
        <div className="flex items-center justify-between mb-1">
          <p className="text-[10px] text-teal-100">CA · Ce mois</p>
          <span className="text-[9px] font-bold bg-white/20 px-2 py-0.5 rounded-lg">+18%</span>
        </div>
        <p className="text-3xl font-black mb-1">1 245 000</p>
        <p className="text-[10px] text-teal-200 mb-3">FCFA · 23 factures</p>
        <div className="flex items-end gap-1 h-12">
          {[40, 65, 45, 80, 55, 90, 70, 95, 85, 100, 75, 110].map((h, i) => (
            <div key={i} className="flex-1 rounded-t bg-white/30 hover:bg-white/50 transition-colors" style={{ height: `${h * 0.55}%` }} />
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

function DemoInvoices() {
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
            { l: "Attente", v: "8", c: "bg-amber-500/30" },
            { l: "Retard", v: "3", c: "bg-rose-500/30" },
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
        { n: "#006", c: "Ibrahima Gueye", t: "95 000", s: "Payée", sc: "bg-emerald-100 text-emerald-700" },
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

function DemoClients() {
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
        { n: "Oumar Sy", p: "76 777 88 99", total: "150 000", due: "12 000", c: "from-cyan-400 to-blue-500" },
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

function DemoStock() {
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
        { n: "Sac à dos Eastpak", q: 15, p: 12000, l: false },
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

function DemoAI() {
  const [messages, setMessages] = useState<{ from: "user" | "ai"; text: string; badge?: string; action?: string }[]>([
    { from: "ai", text: "Bonjour ! Je suis l'assistant AfriOS. Pose-moi une question sur ton business, ou clique sur une suggestion ci-dessous 👇", badge: "En ligne" },
  ]);
  const [typing, setTyping] = useState(false);

  const suggestions = [
    "Combien j'ai facturé ce mois ?",
    "Relance les clients en retard",
    "Stock faible ?",
    "Meilleurs clients ?",
  ];

  const responses: Record<string, string> = {
    "Combien j'ai facturé ce mois ?": "Tu as facturé **1 245 000 FCFA** ce mois-ci. C'est **+18%** vs mois dernier. 8 factures en attente pour 320 000 FCFA.",
    "Relance les clients en retard": "✅ Relances WhatsApp envoyées à **8 clients** pour **320 000 FCFA**. Tu recevras une notification dès qu'un paiement arrivera.",
    "Stock faible ?": "**3 produits** sont en stock faible :\n• Baskets Adidas — 12 unités\n• Casquette Gucci — 3 unités\n• Montre Casio — 2 unités\n\nJe recommande un réappro.",
    "Meilleurs clients ?": "Ton TOP 3 :\n\n🥇 Ibrahima Gueye — 890 000 FCFA\n🥈 Fatou Ndiaye — 580 000 FCFA\n🥉 Aïssatou Ba — 450 000 FCFA",
  };

  const ask = (q: string) => {
    setMessages((m) => [...m, { from: "user", text: q }]);
    setTyping(true);
    setTimeout(() => {
      setMessages((m) => [...m, { from: "ai", text: responses[q] || "Je consulte tes données..." }]);
      setTyping(false);
    }, 1200);
  };

  return (
    <div className="p-4 space-y-3 h-full">
      <div className="flex items-center gap-2 pb-3 border-b border-slate-200">
        <div className="relative w-9 h-9 rounded-2xl bg-gradient-to-br from-violet-500 via-fuchsia-500 to-blue-600 flex items-center justify-center shadow-md">
          <span className="text-white text-sm">✨</span>
        </div>
        <div className="flex-1">
          <p className="text-xs font-bold">Assistant AfriOS</p>
          <p className="text-[10px] text-emerald-600 font-semibold">● En ligne · temps réel</p>
        </div>
      </div>

      <div className="space-y-3 pb-20 max-h-[380px] overflow-y-auto">
        {messages.map((m, i) => (
          <div key={i} className={`flex ${m.from === "user" ? "justify-end" : "justify-start"} animate-slide-in-right`}>
            {m.from === "ai" && (
              <div className="w-7 h-7 flex-shrink-0 rounded-full bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center text-white text-[10px] mr-2 mt-1">✨</div>
            )}
            <div className="max-w-[80%]">
              {m.badge && <span className="inline-block text-[9px] font-bold text-violet-700 bg-violet-50 px-2 py-0.5 rounded-full mb-1.5 border border-violet-100">{m.badge}</span>}
              <div className={`rounded-2xl p-3 shadow-sm ${m.from === "user" ? "rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white" : "rounded-tl-sm bg-white border border-slate-200 text-slate-800"}`}>
                <p className="text-xs leading-relaxed whitespace-pre-line">
                  {m.text.split("**").map((part, idx) => (idx % 2 === 1 ? <strong key={idx}>{part}</strong> : part))}
                </p>
              </div>
            </div>
          </div>
        ))}
        {typing && (
          <div className="flex justify-start animate-slide-in-right">
            <div className="w-7 h-7 flex-shrink-0 rounded-full bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center text-white text-[10px] mr-2 mt-1">✨</div>
            <div className="flex items-center gap-1.5 px-4 py-3 rounded-2xl rounded-tl-sm bg-white border border-slate-200 shadow-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
            </div>
          </div>
        )}
      </div>

      <div className="absolute bottom-20 left-4 right-4">
        <div className="flex gap-1.5 overflow-x-auto pb-1 mb-1">
          {suggestions.map((s) => (
            <button key={s} onClick={() => ask(s)} className="flex-shrink-0 px-3 py-1.5 rounded-full bg-white border border-slate-200 text-[10px] font-bold text-slate-700 hover:border-teal-400 hover:text-teal-700 transition-colors whitespace-nowrap">
              {s}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
