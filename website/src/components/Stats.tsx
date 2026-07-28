import { useEffect, useRef, useState } from "react";

function useCountUp(target: number, duration = 2000, start = false) {
  const [value, setValue] = useState(0);
  useEffect(() => {
    if (!start) return;
    let raf = 0;
    const t0 = performance.now();
    const tick = (t: number) => {
      const p = Math.min(1, (t - t0) / duration);
      const eased = 1 - Math.pow(1 - p, 3);
      setValue(Math.round(target * eased));
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [target, duration, start]);
  return value;
}

export default function Stats() {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!ref.current) return;
    const obs = new IntersectionObserver(
      ([e]) => {
        if (e.isIntersecting) {
          setVisible(true);
          obs.disconnect();
        }
      },
      { threshold: 0.3 }
    );
    obs.observe(ref.current);
    return () => obs.disconnect();
  }, []);

  const users = useCountUp(1200, 2000, visible);
  const invoices = useCountUp(45000, 2000, visible);
  const volume = useCountUp(847, 2000, visible);
  const retention = useCountUp(42, 2000, visible);

  return (
    <section ref={ref} className="relative py-20 bg-gradient-to-br from-teal-600 via-blue-700 to-blue-900 overflow-hidden">
      <div className="absolute inset-0 bg-grid opacity-10" />
      <div className="absolute -top-40 -left-40 w-[500px] h-[500px] rounded-full bg-white/10 blur-3xl" />
      <div className="absolute -bottom-40 -right-40 w-[500px] h-[500px] rounded-full bg-orange-400/10 blur-3xl" />

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-12">
          <h2 className="font-display text-3xl sm:text-4xl font-extrabold text-white mb-3">
            Les chiffres qui parlent.
          </h2>
          <p className="text-teal-100 text-lg">
            Une traction prometteuse, dès les premiers mois de bêta.
          </p>
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
          {[
            { value: users, suffix: "+", label: "Commerçants équipés", hint: "Sénégal & Côte d'Ivoire" },
            { value: invoices, suffix: "+", label: "Factures émises", hint: "Depuis le lancement" },
            { value: volume, suffix: "M FCFA", label: "Volume de paiements", hint: "Traité via Mobile Money" },
            { value: retention, suffix: "%", label: "Rétention 30 jours", hint: "Bien au-dessus de la moyenne" },
          ].map((s, i) => (
            <div key={i} className="relative rounded-3xl bg-white/10 border border-white/15 backdrop-blur-sm p-6 sm:p-8 text-white overflow-hidden group hover:bg-white/15 transition-all">
              <div className="absolute -top-10 -right-10 w-32 h-32 rounded-full bg-gradient-to-br from-teal-400/20 to-orange-400/20 blur-2xl group-hover:scale-150 transition-transform" />
              <p className="font-display text-4xl sm:text-5xl font-black mb-2 tracking-tight">
                {s.value.toLocaleString("fr-FR")}<span className="text-teal-300 text-2xl sm:text-3xl">{s.suffix}</span>
              </p>
              <p className="font-bold text-white mb-1">{s.label}</p>
              <p className="text-xs text-teal-200">{s.hint}</p>
            </div>
          ))}
        </div>

        {/* Testimonials */}
        <div className="mt-16 grid md:grid-cols-3 gap-4">
          {[
            { name: "Fatou Ndiaye", role: "Boutique de vêtements · Dakar", quote: "Enfin une app pensée pour nous. Je crée une facture en 30 secondes et je l'envoie par WhatsApp. Mes clients adorent." },
            { name: "Amadou Diallo", role: "Restaurant · Abidjan", quote: "L'assistant IA me fait gagner un temps fou. « Relance les clients en retard » et c'est fait. Je recommande à tous mes amis commerçants." },
            { name: "Aïssatou Ba", role: "Prestataire de services · Dakar", quote: "J'ai essayé plein d'apps, AfriOS est la seule vraiment simple. Mes paiements Wave arrivent en 2 minutes. Le top." },
          ].map((t, i) => (
            <div key={i} className="rounded-2xl bg-white/10 border border-white/15 backdrop-blur-sm p-5 text-white">
              <div className="flex gap-0.5 mb-3">
                {[...Array(5)].map((_, j) => (
                  <svg key={j} className="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                ))}
              </div>
              <p className="text-sm leading-relaxed text-blue-50 mb-4 italic">« {t.quote} »</p>
              <div className="flex items-center gap-3 pt-3 border-t border-white/10">
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-teal-400 to-blue-500 flex items-center justify-center text-white text-xs font-bold">
                  {t.name.split(" ").map((n) => n[0]).join("")}
                </div>
                <div>
                  <p className="text-sm font-bold">{t.name}</p>
                  <p className="text-[11px] text-teal-200">{t.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
