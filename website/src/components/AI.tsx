import { useState, useEffect, useRef } from "react";

const suggestions = [
  "Combien j'ai facturé ce mois ?",
  "Relance tous les clients en retard",
  "Quels produits ont un stock faible ?",
  "Quel est mon CA aujourd'hui ?",
  "Qui sont mes meilleurs clients ?",
  "Génère un rapport de la semaine",
];

const responses: Record<string, { text: string; action?: string; badge?: string }> = {
  "Combien j'ai facturé ce mois ?": {
    text: "Tu as facturé **1 245 000 FCFA** ce mois-ci. C'est **+18%** par rapport au mois dernier. Tu as 8 factures en attente pour un total de 320 000 FCFA.",
    action: "Relancer les clients en attente",
    badge: "Données en temps réel",
  },
  "Relance tous les clients en retard": {
    text: "✅ Relances WhatsApp envoyées à **8 clients** pour un montant total de **320 000 FCFA**. Tu recevras une notification dès qu'un paiement sera reçu.",
    badge: "Action effectuée",
  },
  "Quels produits ont un stock faible ?": {
    text: "**3 produits** sont sous le seuil d'alerte :\n\n• 🟡 Baskets Adidas — 12 unités\n• 🔴 Casquette Gucci — 3 unités\n• 🔴 Montre Casio — 2 unités\n\nJe recommande de réapprovisionner la catégorie « Accessoires »." ,
    action: "Voir la liste complète",
    badge: "3 produits en alerte",
  },
  "Quel est mon CA aujourd'hui ?": {
    text: "Aujourd'hui, tu as encaissé **85 000 FCFA** sur **3 ventes**. Le client qui a le plus contribué aujourd'hui est **Fatou Ndiaye** (45 000 FCFA).",
    badge: "Journée en cours",
  },
  "Qui sont mes meilleurs clients ?": {
    text: "Ton TOP 3 clients cette année :\n\n1. 🥇 Fatou Ndiaye — 580 000 FCFA\n2. 🥈 Ibrahima Gueye — 890 000 FCFA\n3. 🥉 Aïssatou Ba — 450 000 FCFA",
    badge: "TOP 3 · 2026",
  },
  "Génère un rapport de la semaine": {
    text: "**Résumé de la semaine**\n\n• 💰 CA : 420 000 FCFA (+12%)\n• 📄 Factures émises : 12\n• ✅ Factures payées : 9\n• 📦 Ventes : 28 produits\n• 🆕 Nouveaux clients : 3\n\n💡 Conseil : Tu pourrais augmenter tes prix de 5% sur les produits les plus vendus.",
    badge: "Rapport hebdo",
  },
};

export default function AI() {
  const [messages, setMessages] = useState<{ from: "user" | "ai"; text: string; badge?: string; action?: string }[]>([
    { from: "ai", text: "Bonjour ! Je suis l'assistant AfriOS. Pose-moi une question sur ton business, ou demande-moi d'agir pour toi 👇", badge: "En ligne" },
  ]);
  const [typing, setTyping] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, typing]);

  const ask = (q: string) => {
    setMessages((m) => [...m, { from: "user", text: q }]);
    setTyping(true);
    setTimeout(() => {
      const r = responses[q] || { text: "Je consulte tes données... Je reviens vers toi dans un instant." };
      setMessages((m) => [...m, { from: "ai", ...r }]);
      setTyping(false);
    }, 1400);
  };

  return (
    <section id="ai" className="relative py-24 bg-gradient-to-b from-white via-blue-50/30 to-white overflow-hidden">
      <div className="absolute top-20 left-1/3 w-[500px] h-[500px] rounded-full bg-gradient-to-br from-violet-300/20 via-blue-300/20 to-transparent blur-3xl" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-gradient-to-r from-violet-100 to-blue-100 text-violet-700 text-xs font-bold uppercase tracking-wider mb-4">
            <span>✨</span> IA Business
          </span>
          <h2 className="font-display text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight mb-6">
            Un assistant qui <span className="gradient-text">comprend</span> et <span className="gradient-text">agit</span>.
          </h2>
          <p className="text-lg text-slate-600">
            Plus besoin de chercher. Posez votre question en français simple. L'IA interroge vos données, résume, et peut même relancer vos clients à votre place.
          </p>
        </div>

        <div className="grid lg:grid-cols-5 gap-8 items-start">
          {/* Left - capabilities */}
          <div className="lg:col-span-2 space-y-4">
            {[
              { icon: "💬", title: "Langage naturel", desc: "Parlez comme avec un collaborateur. L'IA comprend vos questions.", color: "from-violet-500 to-fuchsia-600" },
              { icon: "⚡", title: "Actions directes", desc: "« Relance les clients en retard » → l'IA exécute immédiatement.", color: "from-teal-500 to-emerald-600" },
              { icon: "📊", title: "Résumés intelligents", desc: "Chiffres clés, tendances, anomalies — résumés en 1 ligne.", color: "from-blue-500 to-indigo-600" },
              { icon: "🔔", title: "Alertes proactives", desc: "« Attention, 3 produits en stock faible » — avant même de demander.", color: "from-amber-500 to-orange-600" },
              { icon: "🔒", title: "100% confidentiel", desc: "Vos données ne servent qu'à vous. Modèle sécurisé, jamais partagé.", color: "from-slate-700 to-slate-900" },
            ].map((c) => (
              <div key={c.title} className="card-lift flex items-start gap-4 p-5 rounded-2xl bg-white border border-slate-200/70 shadow-sm">
                <div className={`w-12 h-12 flex-shrink-0 rounded-2xl bg-gradient-to-br ${c.color} flex items-center justify-center text-xl shadow-md`}>{c.icon}</div>
                <div>
                  <p className="font-bold text-slate-900 mb-1">{c.title}</p>
                  <p className="text-sm text-slate-600">{c.desc}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Right - Chat mockup */}
          <div className="lg:col-span-3 flex justify-center">
            <div className="relative w-full max-w-md">
              <div className="absolute -inset-8 bg-gradient-to-br from-violet-400/20 via-blue-400/20 to-teal-300/20 rounded-[3rem] blur-3xl" />
              <div className="relative rounded-[2.5rem] p-2.5 bg-gradient-to-b from-slate-800 to-slate-900 phone-shadow">
                <div className="relative rounded-[2rem] overflow-hidden bg-gradient-to-b from-slate-50 to-white aspect-[9/19]">
                  {/* Status bar */}
                  <div className="absolute top-0 inset-x-0 h-7 bg-slate-900 z-20 flex items-center justify-between px-6 text-[10px] text-white font-semibold">
                    <span>9:41</span>
                    <div className="absolute left-1/2 -translate-x-1/2 top-1.5 w-24 h-4 bg-black rounded-full" />
                    <span>🔋 100%</span>
                  </div>

                  {/* Header */}
                  <div className="absolute top-7 inset-x-0 bg-white/90 backdrop-blur border-b border-slate-200 px-4 py-3 z-10">
                    <div className="flex items-center gap-3">
                      <div className="relative w-10 h-10 rounded-2xl bg-gradient-to-br from-violet-500 via-fuchsia-500 to-blue-600 flex items-center justify-center shadow-lg">
                        <span className="text-white text-lg">✨</span>
                        <span className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full bg-emerald-500 border-2 border-white" />
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-bold text-slate-900">Assistant AfriOS</p>
                        <p className="text-[10px] text-emerald-600 font-semibold">● En ligne · temps réel</p>
                      </div>
                      <button className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center">
                        <svg className="w-4 h-4 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v.01M12 12v.01M12 18v.01"/></svg>
                      </button>
                    </div>
                  </div>

                  {/* Messages */}
                  <div ref={scrollRef} className="absolute top-28 bottom-20 inset-x-0 overflow-y-auto px-4 py-4 space-y-3">
                    {messages.map((m, i) => (
                      <div key={i} className={`flex ${m.from === "user" ? "justify-end" : "justify-start"} animate-slide-in-right`}>
                        {m.from === "ai" && (
                          <div className="w-8 h-8 flex-shrink-0 rounded-full bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center text-white text-xs mr-2 mt-1">✨</div>
                        )}
                        <div className={`max-w-[80%] ${m.from === "user" ? "" : ""}`}>
                          {m.badge && m.from === "ai" && (
                            <span className="inline-block text-[9px] font-bold text-violet-700 bg-violet-50 px-2 py-0.5 rounded-full mb-1.5 border border-violet-100">{m.badge}</span>
                          )}
                          <div className={`rounded-2xl p-3 shadow-sm ${
                            m.from === "user"
                              ? "rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white"
                              : "rounded-tl-sm bg-white border border-slate-200 text-slate-800"
                          }`}>
                            <p className="text-xs leading-relaxed whitespace-pre-line">{m.text.split("**").map((part, idx) => idx % 2 === 1 ? <strong key={idx}>{part}</strong> : part)}</p>
                          </div>
                          {m.action && m.from === "ai" && (
                            <button onClick={() => ask("Relance tous les clients en retard")} className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-teal-50 text-teal-700 text-[10px] font-bold border border-teal-100 hover:bg-teal-100 transition-colors">
                              <span>⚡</span> {m.action}
                            </button>
                          )}
                        </div>
                      </div>
                    ))}
                    {typing && (
                      <div className="flex justify-start animate-slide-in-right">
                        <div className="w-8 h-8 flex-shrink-0 rounded-full bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center text-white text-xs mr-2 mt-1">✨</div>
                        <div className="flex items-center gap-1.5 px-4 py-3 rounded-2xl rounded-tl-sm bg-white border border-slate-200 shadow-sm">
                          <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
                          <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
                          <span className="w-1.5 h-1.5 rounded-full bg-slate-400 typing-dot" />
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Suggestions */}
                  <div className="absolute bottom-16 inset-x-0 px-3 pb-2">
                    <div className="flex gap-1.5 overflow-x-auto pb-1 no-scrollbar">
                      {suggestions.slice(0, 3).map((s) => (
                        <button key={s} onClick={() => ask(s)} className="flex-shrink-0 px-3 py-1.5 rounded-full bg-white border border-slate-200 text-[10px] font-bold text-slate-700 hover:border-teal-400 hover:text-teal-700 transition-colors whitespace-nowrap">
                          {s}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Input */}
                  <div className="absolute bottom-0 inset-x-0 h-16 bg-white border-t border-slate-200 flex items-center px-3 gap-2 z-10">
                    <button className="w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center text-slate-600">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13"/></svg>
                    </button>
                    <div className="flex-1 text-[11px] text-slate-400 px-3">Demande quelque chose...</div>
                    <button className="w-10 h-10 rounded-full bg-gradient-to-br from-violet-500 via-fuchsia-500 to-blue-600 flex items-center justify-center text-white shadow-lg">
                      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z"/></svg>
                    </button>
                  </div>
                </div>
              </div>

              {/* Floating suggestions */}
              <div className="hidden md:block absolute -left-24 top-20 w-48 p-3 rounded-2xl bg-white border border-slate-200 shadow-xl animate-float-slow">
                <p className="text-[10px] font-bold text-violet-700 mb-1.5">💡 Essaie aussi</p>
                <p className="text-xs text-slate-700 leading-snug">« Quel produit se vend le mieux ? »</p>
              </div>
              <div className="hidden md:block absolute -right-20 bottom-24 w-44 p-3 rounded-2xl bg-gradient-to-br from-emerald-500 to-teal-600 text-white shadow-xl animate-float">
                <p className="text-[10px] font-bold text-emerald-100 mb-1">Action</p>
                <p className="text-xs font-bold leading-snug">« Relance les clients en retard »</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
