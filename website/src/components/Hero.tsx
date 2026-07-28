interface Props {
  onDemo: () => void;
}

export default function Hero({ onDemo }: Props) {
  return (
    <section className="relative pt-28 lg:pt-36 pb-20 overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-teal-50/60 via-white to-white" />
      <div className="absolute inset-0 bg-grid opacity-40" />
      <div className="absolute top-20 -left-40 w-[500px] h-[500px] rounded-full bg-gradient-to-br from-teal-300/30 to-transparent blur-3xl" />
      <div className="absolute top-40 -right-40 w-[600px] h-[600px] rounded-full bg-gradient-to-br from-orange-300/20 via-blue-300/20 to-transparent blur-3xl" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left - Copy */}
          <div className="animate-fade-in-up">
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white border border-teal-200 shadow-sm mb-6">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-teal-500"></span>
              </span>
              <span className="text-xs font-semibold text-slate-700">MVP disponible · Tous les pays 🌍</span>
            </div>

            <h1 className="font-display text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.05] mb-6">
              L'<span className="gradient-text">Operating System</span>
              <br />
              des PME <span className="text-teal-700">africaines.</span>
            </h1>

            <p className="text-lg sm:text-xl text-slate-600 leading-relaxed mb-8 max-w-xl">
              Facturation, stock, clients, paiements <strong className="text-slate-900">Mobile Money</strong> et assistant IA — réunis dans une seule application mobile pensée pour l'Afrique.
            </p>

            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 mb-10">
              <button
                onClick={onDemo}
                className="btn-shine inline-flex items-center justify-center gap-2.5 px-7 py-4 text-base font-bold text-white rounded-2xl bg-gradient-to-r from-teal-600 via-blue-700 to-blue-900 shadow-xl shadow-teal-500/30 hover:shadow-2xl hover:shadow-blue-500/40 transition-all"
              >
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 15.341c-.328 0-.594-.266-.594-.594 0-.328.266-.594.594-.594.328 0 .594.266.594.594 0 .328-.266.594-.594.594zm-11.046 0c-.328 0-.594-.266-.594-.594 0-.328.266-.594.594-.594.328 0 .594.266.594.594 0 .328-.266.594-.594.594zM12 0C5.373 0 0 4.68 0 10.436c0 3.114 1.33 5.91 3.462 7.807-.155.62-.68 2.383-.72 2.553-.05.207.074.207.155.15.108-.074 1.728-1.175 2.428-1.65 1.96.722 4.184 1.128 6.554 1.128 6.627 0 12-4.68 12-10.436C24 4.68 18.627 0 12 0z"/></svg>
                Tester la démo interactive
              </button>
              <a
                href="#features"
                className="inline-flex items-center justify-center gap-2 px-7 py-4 text-base font-bold text-slate-900 rounded-2xl bg-white border-2 border-slate-200 hover:border-teal-500 hover:text-teal-700 transition-all"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                Voir les fonctionnalités
              </a>
            </div>

            {/* Social proof */}
            <div className="flex flex-wrap items-center gap-6">
              <div className="flex -space-x-3">
                {["#0D9488", "#1E3A8A", "#F97316", "#EAB308", "#059669"].map((c, i) => (
                  <div key={i} className="w-10 h-10 rounded-full border-2 border-white shadow-md flex items-center justify-center text-white font-bold text-sm" style={{ background: c }}>
                    {["A", "F", "M", "S", "K"][i]}
                  </div>
                ))}
              </div>
              <div>
                <div className="flex items-center gap-1 mb-0.5">
                  {[...Array(5)].map((_, i) => (
                    <svg key={i} className="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                  ))}
                </div>
                <p className="text-sm text-slate-600 font-medium"><span className="font-bold text-slate-900">4.8/5</span> · 1 200+ commerçants déjà équipés</p>
              </div>
            </div>
          </div>

          {/* Right - Phone mockup cluster */}
          <div className="relative h-[560px] lg:h-[640px]">
            {/* Main phone */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[280px] sm:w-[300px] animate-float">
              <HeroPhone />
            </div>
            {/* Floating card - CA */}
            <div className="absolute top-8 -left-2 sm:left-0 w-52 bg-white rounded-2xl shadow-2xl shadow-blue-500/20 border border-slate-100 p-4 animate-float-slow hidden sm:block">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 rounded-xl bg-teal-100 flex items-center justify-center">
                  <svg className="w-4 h-4 text-teal-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/></svg>
                </div>
                <span className="text-xs font-semibold text-slate-500">Ce mois</span>
              </div>
              <p className="text-2xl font-extrabold text-slate-900 mb-1">1 245 000</p>
              <p className="text-xs text-slate-500 mb-3">FCFA · Chiffre d'affaires</p>
              <div className="flex items-center gap-1.5 px-2 py-1 rounded-lg bg-emerald-50 w-fit">
                <svg className="w-3 h-3 text-emerald-600" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd"/></svg>
                <span className="text-xs font-bold text-emerald-700">+18%</span>
              </div>
            </div>

            {/* Floating card - Mobile Money */}
            <div className="absolute bottom-12 -right-2 sm:right-0 w-56 bg-white rounded-2xl shadow-2xl shadow-orange-500/20 border border-slate-100 p-4 animate-float hidden sm:block" style={{ animationDelay: "1s" }}>
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center">
                    <span className="text-white text-xs font-black">W</span>
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-900">Wave</p>
                    <p className="text-[10px] text-slate-500">Paiement reçu</p>
                  </div>
                </div>
                <div className="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center">
                  <svg className="w-3.5 h-3.5 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7"/></svg>
                </div>
              </div>
              <p className="text-xl font-extrabold text-slate-900 mb-0.5">+45 000 FCFA</p>
              <p className="text-[11px] text-slate-500">Facture #001 · Amadou Diallo</p>
            </div>

            {/* Floating card - IA */}
            <div className="absolute bottom-0 left-0 w-60 bg-gradient-to-br from-slate-900 to-blue-900 rounded-2xl shadow-2xl shadow-slate-900/40 p-4 text-white animate-float-slow hidden md:block" style={{ animationDelay: "2s" }}>
              <div className="flex items-center gap-2 mb-2">
                <div className="relative w-8 h-8 rounded-xl bg-gradient-to-br from-teal-400 to-blue-500 flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20"><path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"/></svg>
                </div>
                <span className="text-xs font-bold">Assistant IA</span>
              </div>
              <p className="text-[11px] text-blue-200 mb-2">« Combien j'ai facturé ce mois ? »</p>
              <div className="bg-white/10 rounded-xl p-2.5 backdrop-blur-sm">
                <p className="text-xs font-semibold leading-snug">1 245 000 FCFA. 8 factures en attente. Veux-tu relancer ?</p>
              </div>
            </div>

            {/* Decorative circles */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[420px] h-[420px] rounded-full border-2 border-dashed border-teal-200/50 -z-10" />
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[560px] h-[560px] rounded-full border border-blue-100 -z-10" />
          </div>
        </div>
      </div>
    </section>
  );
}

function HeroPhone() {
  return (
    <div className="relative">
      {/* Glow */}
      <div className="absolute -inset-8 bg-gradient-to-br from-teal-400/30 via-blue-500/20 to-orange-400/20 rounded-[60px] blur-3xl" />
      <div className="relative rounded-[3rem] p-3 bg-gradient-to-b from-slate-800 to-slate-900 phone-shadow">
        <div className="relative rounded-[2.3rem] overflow-hidden bg-white aspect-[9/19]">
          {/* Status bar */}
          <div className="absolute top-0 inset-x-0 h-7 bg-slate-900 flex items-center justify-between px-6 text-[10px] text-white font-semibold z-30">
            <span>9:41</span>
            <div className="absolute left-1/2 -translate-x-1/2 top-1.5 w-20 h-4 bg-black rounded-full" />
            <div className="flex items-center gap-1">
              <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path d="M2 10a1 1 0 011-1h1a1 1 0 110 2H3a1 1 0 01-1-1zm3-3a1 1 0 011-1h1a1 1 0 110 2H6a1 1 0 01-1-1zm3-3a1 1 0 011-1h1a1 1 0 110 2h-1a1 1 0 01-1-1zm3 3a1 1 0 011-1h1a1 1 0 110 2h-1a1 1 0 01-1-1z"/></svg>
              <span>100%</span>
            </div>
          </div>

          {/* Dashboard content */}
          <div className="absolute inset-0 pt-7 pb-20 overflow-hidden">
            <div className="h-full overflow-y-auto px-4 pt-4 pb-4">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <p className="text-[10px] text-slate-500">Bonjour 👋</p>
                  <p className="text-sm font-bold text-slate-900">Boutique Fatou</p>
                </div>
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-teal-500 to-blue-700 flex items-center justify-center text-white text-xs font-bold">BF</div>
              </div>

              {/* CA Card */}
              <div className="rounded-2xl bg-gradient-to-br from-teal-600 via-blue-700 to-blue-900 p-4 text-white mb-3 shadow-lg shadow-blue-500/30">
                <p className="text-[10px] text-teal-100 mb-1">Chiffre d'affaires · Ce mois</p>
                <p className="text-2xl font-black mb-1">1 245 000</p>
                <p className="text-[10px] text-teal-200 mb-3">FCFA</p>
                <div className="flex items-center gap-2">
                  <span className="text-[10px] font-bold bg-white/20 px-2 py-1 rounded-lg">+18%</span>
                  <span className="text-[10px] text-teal-100">vs mois dernier</span>
                </div>
              </div>

              {/* Quick actions */}
              <div className="grid grid-cols-4 gap-2 mb-3">
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

              {/* Stats */}
              <div className="grid grid-cols-2 gap-2 mb-3">
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

              {/* Recent */}
              <p className="text-[11px] font-bold text-slate-900 mb-2">Derniers mouvements</p>
              <div className="space-y-2">
                {[
                  { name: "Amadou Diallo", amount: "+45 000", type: "Paiement Wave", color: "bg-emerald-100 text-emerald-700" },
                  { name: "Fatou Ndiaye", amount: "120 000", type: "Facture #002", color: "bg-blue-100 text-blue-700" },
                ].map((t, i) => (
                  <div key={i} className="flex items-center gap-2 p-2 rounded-xl bg-slate-50">
                    <div className={`w-8 h-8 rounded-lg ${t.color} flex items-center justify-center text-[10px] font-bold`}>FC</div>
                    <div className="flex-1 min-w-0">
                      <p className="text-[11px] font-bold text-slate-900 truncate">{t.name}</p>
                      <p className="text-[9px] text-slate-500">{t.type}</p>
                    </div>
                    <p className="text-[11px] font-black text-slate-900">{t.amount}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Bottom nav */}
          <div className="absolute bottom-0 inset-x-0 h-16 bg-white border-t border-slate-100 flex items-center justify-around px-2 pb-2 z-20">
            {[
              { label: "Accueil", active: true, icon: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" },
              { label: "Factures", icon: "M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" },
              { label: "", center: true, icon: "+" },
              { label: "Clients", icon: "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" },
              { label: "IA", icon: "M13 10V3L4 14h7v7l9-11h-7z" },
            ].map((item, i) => (
              item.center ? (
                <button key={i} className="relative -mt-6 w-12 h-12 rounded-2xl bg-gradient-to-br from-teal-500 to-blue-700 flex items-center justify-center text-white text-2xl font-bold shadow-lg shadow-teal-500/40">
                  +
                </button>
              ) : (
                <button key={i} className={`flex flex-col items-center gap-0.5 ${item.active ? "text-teal-600" : "text-slate-400"}`}>
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={item.active ? 2.5 : 2} d={item.icon}/></svg>
                  <span className="text-[9px] font-semibold">{item.label}</span>
                </button>
              )
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
