export default function MobileMoney() {
  const providers = [
    { name: "Wave", color: "from-emerald-500 to-teal-600", letter: "W", tag: "0,8%", flag: "🇸🇳🇨🇮", desc: "Le plus utilisé au Sénégal & CI" },
    { name: "Orange Money", color: "from-orange-500 to-orange-600", letter: "OM", tag: "1,0%", flag: "🇸🇳🇨🇮🇲🇱", desc: "Couverture panafricaine" },
    { name: "MTN MoMo", color: "from-yellow-400 to-amber-500", letter: "M", tag: "1,0%", flag: "🇨🇮🇬🇭🇳🇬", desc: "Leader en Afrique de l'Ouest" },
    { name: "Flutterwave", color: "from-fuchsia-500 to-pink-600", letter: "F", tag: "Agrégateur", flag: "🌍", desc: "+15 pays africains" },
  ];

  return (
    <section id="mobile-money" className="relative py-24 bg-gradient-to-b from-teal-50/30 to-white overflow-hidden">
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-teal-200 to-transparent" />
      <div className="absolute -top-40 -right-40 w-[500px] h-[500px] rounded-full bg-gradient-to-br from-emerald-300/30 to-transparent blur-3xl" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          <div>
            <span className="inline-block px-4 py-1.5 rounded-full bg-emerald-50 text-emerald-700 text-xs font-bold uppercase tracking-wider mb-4">
              💸 Paiements africains
            </span>
            <h2 className="font-display text-4xl sm:text-5xl font-extrabold tracking-tight mb-6">
              Recevez par <span className="gradient-text-teal-navy">Wave</span>, <span className="text-orange-600">Orange Money</span>, <span className="text-amber-500">MTN MoMo</span>.
            </h2>
            <p className="text-lg text-slate-600 mb-8 leading-relaxed">
              Vos clients paient en 1 clic depuis leur compte Mobile Money. La facture passe automatiquement en « Payée » et vous recevez une notification instantanée.
            </p>

            <div className="space-y-3 mb-8">
              {[
                { icon: "⚡", title: "Paiement instantané", desc: "L'argent arrive sur votre compte en moins d'une minute." },
                { icon: "🔄", title: "Statut automatique", desc: "La facture bascule en « Payée » dès réception confirmée." },
                { icon: "🔐", title: "Sécurisé & conforme", desc: "Intégrations officielles Wave, Orange, MTN via Flutterwave." },
                { icon: "📊", title: "Commissions transparentes", desc: "0,8% à 1,5% par transaction. Aucun frais caché." },
              ].map((f) => (
                <div key={f.title} className="flex items-start gap-3 p-4 rounded-2xl bg-white border border-slate-200/70 shadow-sm">
                  <div className="w-10 h-10 flex-shrink-0 rounded-xl bg-gradient-to-br from-emerald-100 to-teal-100 flex items-center justify-center text-lg">{f.icon}</div>
                  <div>
                    <p className="font-bold text-slate-900">{f.title}</p>
                    <p className="text-sm text-slate-600">{f.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Right - providers + flow */}
          <div className="relative">
            <div className="grid grid-cols-2 gap-4 mb-6">
              {providers.map((p, i) => (
                <div key={p.name} className="card-lift relative group rounded-3xl bg-white border border-slate-200/70 p-5 shadow-sm" style={{ animationDelay: `${i * 0.1}s` }}>
                  <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${p.color} flex items-center justify-center text-white text-xl font-black shadow-lg mb-3 group-hover:scale-110 transition-transform`}>
                    {p.letter}
                  </div>
                  <p className="font-bold text-slate-900 mb-1">{p.name}</p>
                  <p className="text-xs text-slate-500 mb-3">{p.desc}</p>
                  <div className="flex items-center justify-between">
                    <span className="text-lg">{p.flag}</span>
                    <span className="text-[10px] font-bold text-teal-700 bg-teal-50 px-2 py-1 rounded-lg">{p.tag}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Payment flow */}
            <div className="rounded-3xl bg-gradient-to-br from-slate-900 via-blue-900 to-teal-900 p-6 text-white shadow-2xl">
              <p className="text-xs font-bold uppercase tracking-wider text-teal-300 mb-4">Parcours de paiement</p>
              <div className="space-y-4">
                {[
                  { step: "01", title: "Création de facture", desc: "Vous créez la facture dans AfriOS." },
                  { step: "02", title: "Envoi WhatsApp", desc: "Le client reçoit la facture + lien de paiement." },
                  { step: "03", title: "Paiement 1 clic", desc: "Il choisit Wave / Orange Money / MTN et valide." },
                  { step: "04", title: "Facture marquée Payée", desc: "Notification push + webhook + mise à jour auto." },
                ].map((s, i) => (
                  <div key={s.step} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className="w-10 h-10 rounded-xl bg-white/10 border border-white/20 flex items-center justify-center text-sm font-black text-teal-300">{s.step}</div>
                      {i < 3 && <div className="flex-1 w-0.5 bg-gradient-to-b from-teal-400/50 to-transparent my-1" />}
                    </div>
                    <div className="flex-1 pb-2">
                      <p className="font-bold">{s.title}</p>
                      <p className="text-xs text-blue-200">{s.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
