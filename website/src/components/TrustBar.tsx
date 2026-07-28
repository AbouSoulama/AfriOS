export default function TrustBar() {
  const items = [
    { label: "Wave", hint: "Paiements" },
    { label: "Orange Money", hint: "Mobile Money" },
    { label: "MTN MoMo", hint: "Paiements" },
    { label: "WhatsApp Business", hint: "Relances" },
    { label: "Flutterwave", hint: "Agrégateur" },
    { label: "Firebase", hint: "Infrastructure" },
    { label: "OpenAI", hint: "IA" },
    { label: "Supabase", hint: "Backend" },
  ];

  return (
    <section className="py-12 border-y border-slate-100 bg-gradient-to-b from-white to-slate-50 overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <p className="text-center text-xs font-bold uppercase tracking-[0.2em] text-slate-500 mb-6">
          Intégré avec les meilleurs services africains & mondiaux
        </p>
        <div className="relative">
          <div className="flex gap-12 animate-marquee w-max">
            {[...items, ...items].map((it, i) => (
              <div key={i} className="flex items-center gap-3 whitespace-nowrap flex-shrink-0">
                <div className="w-10 h-10 rounded-xl bg-white border border-slate-200 shadow-sm flex items-center justify-center">
                  <div className="w-5 h-5 rounded-md bg-gradient-to-br from-slate-700 to-slate-900" />
                </div>
                <div>
                  <p className="text-sm font-bold text-slate-900">{it.label}</p>
                  <p className="text-[10px] text-slate-500 uppercase tracking-wider">{it.hint}</p>
                </div>
              </div>
            ))}
          </div>
          <div className="pointer-events-none absolute inset-y-0 left-0 w-32 bg-gradient-to-r from-slate-50 to-transparent" />
          <div className="pointer-events-none absolute inset-y-0 right-0 w-32 bg-gradient-to-l from-slate-50 to-transparent" />
        </div>
      </div>
    </section>
  );
}
