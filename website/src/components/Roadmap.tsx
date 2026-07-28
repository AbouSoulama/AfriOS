export default function Roadmap() {
  const phases = [
    {
      phase: "Phase 1",
      period: "Juin – Sept 2026",
      title: "MVP · Fondations",
      status: "En cours",
      color: "from-teal-500 to-emerald-600",
      items: [
        "Authentification OTP + profil entreprise",
        "CRM basique & fiches clients",
        "Création & envoi de factures (WhatsApp + PDF)",
        "Gestion stock & alertes stock faible",
        "Intégration Wave + Orange Money",
        "Assistant IA conversationnel",
        "Tableau de bord & notifications push",
        "Lancement privé : Sénégal & Côte d'Ivoire",
      ],
    },
    {
      phase: "Phase 2",
      period: "Oct – Déc 2026",
      title: "Croissance · Retention",
      status: "À venir",
      color: "from-blue-500 to-indigo-600",
      items: [
        "Relances automatiques programmables",
        "Templates de messages WhatsApp/SMS",
        "Historiques & rapports exportables (PDF/Excel)",
        "Multi-devise (XOF, GHS, NGN, KES)",
        "Mode offline avancé & synchronisation",
        "Protection PIN & empreinte digitale",
        "Expansion : Ghana & Nigeria",
      ],
    },
    {
      phase: "Phase 3",
      period: "Jan – Juin 2027",
      title: "Business OS complet",
      status: "Plus tard",
      color: "from-violet-500 via-fuchsia-500 to-orange-500",
      items: [
        "Multi-utilisateurs & gestion de rôles",
        "Paie des employés & déclarations",
        "Comptabilité simplifiée & rapports fiscaux",
        "IA prédictive : prévisions CA, recommandations",
        "Crédit basé sur les données (partenariats bancaires)",
        "Marketplace d'extensions",
        "Version iOS & application desktop (web)",
      ],
    },
  ];

  return (
    <section className="relative py-24 bg-gradient-to-b from-slate-50 to-white overflow-hidden">
      <div className="absolute inset-0 bg-grid opacity-30" />
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <span className="inline-block px-4 py-1.5 rounded-full bg-violet-50 text-violet-700 text-xs font-bold uppercase tracking-wider mb-4">
            Roadmap produit
          </span>
          <h2 className="font-display text-4xl sm:text-5xl font-extrabold tracking-tight mb-4">
            Une vision <span className="gradient-text">claire</span> sur 12 mois.
          </h2>
          <p className="text-lg text-slate-600">
            Livrer un MVP solide en 4 mois, puis itérer vite avec les retours utilisateurs.
          </p>
        </div>

        <div className="relative">
          {/* Timeline line */}
          <div className="hidden lg:block absolute top-24 left-0 right-0 h-1 bg-gradient-to-r from-teal-200 via-blue-200 to-violet-200 rounded-full" />

          <div className="grid lg:grid-cols-3 gap-6">
          {phases.map((p) => (
            <div key={p.phase} className="relative">
                {/* Dot */}
                <div className="hidden lg:flex absolute -top-1 left-1/2 -translate-x-1/2 w-8 h-8 rounded-full bg-white border-4 border-teal-200 items-center justify-center z-10">
                  <div className={`w-3 h-3 rounded-full bg-gradient-to-br ${p.color}`} />
                </div>

                <div className="card-lift rounded-3xl bg-white border border-slate-200/70 p-6 shadow-sm h-full">
                  <div className="flex items-center justify-between mb-4">
                    <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r ${p.color} text-white text-xs font-black shadow-md`}>
                      {p.phase}
                    </div>
                    <span className={`text-[10px] font-bold uppercase tracking-wider ${
                      p.status === "En cours" ? "text-teal-700" : p.status === "À venir" ? "text-blue-700" : "text-violet-700"
                    }`}>
                      ● {p.status}
                    </span>
                  </div>

                  <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">{p.period}</p>
                  <h3 className="font-display text-xl font-extrabold mb-4">{p.title}</h3>

                  <ul className="space-y-2.5">
                    {p.items.map((it, idx) => (
                      <li key={idx} className="flex items-start gap-2.5 text-sm text-slate-700">
                        <span className={`flex-shrink-0 w-5 h-5 rounded-full bg-gradient-to-br ${p.color} flex items-center justify-center text-white text-[10px] font-black mt-0.5`}>{idx + 1}</span>
                        <span>{it}</span>
                      </li>
                    ))}
                  </ul>

                  <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between">
                    <span className="text-xs text-slate-500">{p.items.length} fonctionnalités</span>
                    <div className="flex -space-x-1">
                      {[...Array(Math.min(3, p.items.length))].map((_, idx) => (
                        <div key={idx} className={`w-6 h-6 rounded-full border-2 border-white bg-gradient-to-br ${p.color} opacity-${60 + idx * 15}`} />
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Stack tech */}
        <div className="mt-20 rounded-3xl bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 p-8 sm:p-12 text-white shadow-2xl">
          <div className="grid lg:grid-cols-2 gap-10 items-center">
            <div>
              <span className="inline-block px-3 py-1 rounded-full bg-white/10 text-teal-300 text-xs font-bold uppercase tracking-wider mb-4">
                Architecture technique
              </span>
              <h3 className="font-display text-3xl sm:text-4xl font-extrabold mb-4">
                Une stack moderne, <span className="text-teal-300">pensée pour l'Afrique.</span>
              </h3>
              <p className="text-blue-200 leading-relaxed mb-6">
                Flutter pour le mobile (performance Android native). Node.js/FastAPI pour le backend. PostgreSQL + Redis pour la donnée. Firebase pour l'auth OTP. OpenAI pour l'IA. Flutterwave pour les paiements.
              </p>
              <div className="flex flex-wrap gap-2">
                {["Flutter", "Dart", "Node.js", "FastAPI", "PostgreSQL", "Redis", "Firebase", "Supabase", "OpenAI", "Flutterwave", "AWS Afrique"].map((t) => (
                  <span key={t} className="px-3 py-1.5 rounded-full bg-white/10 border border-white/10 text-xs font-bold text-white">{t}</span>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              {[
                { label: "Taille app", value: "< 80 MB", color: "from-teal-500/20 to-teal-500/5" },
                { label: "Startup", value: "< 3s", color: "from-emerald-500/20 to-emerald-500/5" },
                { label: "Uptime", value: "99,5%", color: "from-blue-500/20 to-blue-500/5" },
                { label: "Sécurité", value: "Chiffré", color: "from-violet-500/20 to-violet-500/5" },
                { label: "Offline", value: "Partiel", color: "from-orange-500/20 to-orange-500/5" },
                { label: "Langues", value: "FR + locales", color: "from-rose-500/20 to-rose-500/5" },
              ].map((s) => (
                <div key={s.label} className={`rounded-2xl p-4 bg-gradient-to-br ${s.color} border border-white/10`}>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-blue-200 mb-1">{s.label}</p>
                  <p className="text-2xl font-black text-white">{s.value}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
