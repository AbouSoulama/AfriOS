interface Props {
  onDemo: () => void;
}

export default function CTA({ onDemo }: Props) {
  return (
    <section className="relative py-24 overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="relative rounded-[2.5rem] overflow-hidden bg-gradient-to-br from-slate-900 via-blue-900 to-teal-900 p-8 sm:p-12 lg:p-16 shadow-2xl">
          {/* Decorative */}
          <div className="absolute top-0 right-0 w-[500px] h-[500px] rounded-full bg-gradient-to-br from-teal-400/20 to-transparent blur-3xl" />
          <div className="absolute bottom-0 left-0 w-[400px] h-[400px] rounded-full bg-gradient-to-br from-orange-400/20 to-transparent blur-3xl" />
          <div className="absolute inset-0 bg-dots opacity-10" />

          <div className="relative grid lg:grid-cols-2 gap-10 items-center">
            <div>
              <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 border border-white/20 text-teal-300 text-xs font-bold uppercase tracking-wider mb-6">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-teal-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-teal-400"></span>
                </span>
                Disponible maintenant
              </span>

              <h2 className="font-display text-4xl sm:text-5xl lg:text-6xl font-extrabold text-white tracking-tight mb-6 leading-[1.05]">
                Prêt à <span className="text-teal-300">transformer</span> votre business ?
              </h2>

              <p className="text-lg text-blue-100 mb-8 leading-relaxed max-w-xl">
                Rejoignez des centaines de commerçants africains qui ont déjà simplifié leur quotidien avec AfriOS. Gratuit, sans engagement, installable en 60 secondes.
              </p>

              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 mb-8">
                <button
                  onClick={onDemo}
                  className="btn-shine inline-flex items-center justify-center gap-2.5 px-7 py-4 text-base font-black text-slate-900 rounded-2xl bg-white hover:shadow-2xl hover:shadow-white/20 transition-all"
                >
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 15.341c-.328 0-.594-.266-.594-.594 0-.328.266-.594.594-.594.328 0 .594.266.594.594 0 .328-.266.594-.594.594zm-11.046 0c-.328 0-.594-.266-.594-.594 0-.328.266-.594.594-.594.328 0 .594.266.594.594 0 .328-.266.594-.594.594zM12 0C5.373 0 0 4.68 0 10.436c0 3.114 1.33 5.91 3.462 7.807-.155.62-.68 2.383-.72 2.553-.05.207.074.207.155.15.108-.074 1.728-1.175 2.428-1.65 1.96.722 4.184 1.128 6.554 1.128 6.627 0 12-4.68 12-10.436C24 4.68 18.627 0 12 0z"/></svg>
                  Tester la démo interactive
                </button>
                <a
                  href="mailto:beta@afrios.app?subject=Inscription%20Beta%20AfriOS"
                  className="inline-flex items-center justify-center gap-2.5 px-7 py-4 text-base font-black text-white rounded-2xl border-2 border-white/20 hover:bg-white/10 transition-all"
                >
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12.001 4.8c-3.2 0-5.2 1.6-6 4.8 1.2-1.6 2.6-2.2 4.2-1.8.913.228 1.565.89 2.288 1.624C13.666 10.618 15.027 12 18.001 12c3.2 0 5.2-1.6 6-4.8-1.2 1.6-2.6 2.2-4.2 1.8-.913-.228-1.565-.89-2.288-1.624C16.337 6.182 14.976 4.8 12.001 4.8zm-6 7.2c-3.2 0-5.2 1.6-6 4.8 1.2-1.6 2.6-2.2 4.2-1.8.913.228 1.565.89 2.288 1.624 1.177 1.194 2.538 2.576 5.512 2.576 3.2 0 5.2-1.6 6-4.8-1.2 1.6-2.6 2.2-4.2 1.8-.913-.228-1.565-.89-2.288-1.624C10.337 13.382 8.976 12 6.001 12z"/></svg>
                  Télécharger sur Android
                </a>
              </div>

              <div className="flex flex-wrap items-center gap-x-8 gap-y-3 text-sm text-blue-200">
                <div className="flex items-center gap-2">
                  <svg className="w-4 h-4 text-teal-300" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                  <span>Gratuit pour commencer</span>
                </div>
                <div className="flex items-center gap-2">
                  <svg className="w-4 h-4 text-teal-300" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                  <span>Pas de carte bancaire</span>
                </div>
                <div className="flex items-center gap-2">
                  <svg className="w-4 h-4 text-teal-300" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                  <span>Installation en 60s</span>
                </div>
                <div className="flex items-center gap-2">
                  <svg className="w-4 h-4 text-teal-300" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/></svg>
                  <span>Moins de 80 MB</span>
                </div>
              </div>
            </div>

            {/* Right - phone cluster */}
            <div className="relative h-[400px] sm:h-[500px] hidden lg:block">
              <div className="absolute top-0 left-8 w-[220px] animate-float-slow">
                <MiniPhone variant="invoice" />
              </div>
              <div className="absolute top-10 right-0 w-[220px] animate-float" style={{ animationDelay: "1s" }}>
                <MiniPhone variant="payment" />
              </div>
              <div className="absolute bottom-0 left-20 w-[220px] animate-float" style={{ animationDelay: "2s" }}>
                <MiniPhone variant="ai" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function MiniPhone({ variant }: { variant: "invoice" | "payment" | "ai" }) {
  return (
    <div className="relative rounded-[2rem] p-1.5 bg-gradient-to-b from-slate-800 to-slate-900 shadow-2xl">
      <div className="relative rounded-[1.6rem] overflow-hidden bg-white aspect-[9/19]">
        <div className="absolute top-0 inset-x-0 h-4 bg-slate-900 z-10">
          <div className="absolute left-1/2 -translate-x-1/2 top-0.5 w-12 h-2 bg-black rounded-full" />
        </div>
        <div className="pt-5 p-3">
          {variant === "invoice" && (
            <div className="space-y-2">
              <div className="rounded-lg bg-gradient-to-br from-teal-500 to-blue-700 p-3 text-white">
                <p className="text-[8px] text-teal-100">Facture #002</p>
                <p className="text-base font-black">116 820</p>
                <p className="text-[8px] text-teal-100">FCFA</p>
              </div>
              {[1, 2, 3].map((i) => (
                <div key={i} className="flex items-center justify-between p-2 rounded-lg bg-slate-50">
                  <div>
                    <p className="text-[9px] font-bold">Produit {i}</p>
                    <p className="text-[7px] text-slate-500">2 × 15 000</p>
                  </div>
                  <p className="text-[9px] font-black">30 000</p>
                </div>
              ))}
              <button className="w-full py-2 rounded-lg bg-gradient-to-r from-emerald-500 to-teal-600 text-white text-[9px] font-bold">
                💬 Envoyer WhatsApp
              </button>
            </div>
          )}
          {variant === "payment" && (
            <div className="space-y-2">
              <p className="text-center text-[9px] text-slate-500">Facture #001</p>
              <p className="text-center text-sm font-black">45 000 FCFA</p>
              {[
                { l: "Wave", c: "from-emerald-500 to-teal-600", t: "Recommandé" },
                { l: "Orange Money", c: "from-orange-500 to-orange-600" },
                { l: "MTN MoMo", c: "from-yellow-400 to-amber-500" },
              ].map((m) => (
                <div key={m.l} className="flex items-center gap-2 p-2 rounded-lg border-2 border-slate-200">
                  <div className={`w-6 h-6 rounded-lg bg-gradient-to-br ${m.c} flex items-center justify-center text-white text-[8px] font-black`}>
                    {m.l[0]}
                  </div>
                  <p className="text-[9px] font-bold flex-1">{m.l}</p>
                  {m.t && <span className="text-[7px] font-bold text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded">{m.t}</span>}
                </div>
              ))}
              <div className="rounded-lg bg-emerald-50 border border-emerald-200 p-2 text-center">
                <p className="text-[8px] font-bold text-emerald-700">✓ Paiement reçu</p>
              </div>
            </div>
          )}
          {variant === "ai" && (
            <div className="space-y-2">
              <div className="flex items-center gap-1.5 pb-2 border-b border-slate-100">
                <div className="w-5 h-5 rounded-lg bg-gradient-to-br from-violet-500 to-blue-600 flex items-center justify-center text-[8px]">✨</div>
                <div>
                  <p className="text-[8px] font-bold">Assistant</p>
                  <p className="text-[6px] text-emerald-600">● En ligne</p>
                </div>
              </div>
              <div className="flex justify-end">
                <div className="max-w-[80%] rounded-xl rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white p-2">
                  <p className="text-[8px]">CA ce mois ?</p>
                </div>
              </div>
              <div className="flex justify-start">
                <div className="max-w-[85%] rounded-xl rounded-tl-sm bg-slate-50 border border-slate-200 p-2">
                  <p className="text-[8px]"><strong>1 245 000 FCFA</strong>. 8 factures en attente.</p>
                </div>
              </div>
              <div className="flex justify-end">
                <div className="max-w-[80%] rounded-xl rounded-tr-sm bg-gradient-to-br from-teal-500 to-blue-700 text-white p-2">
                  <p className="text-[8px]">Relance les clients</p>
                </div>
              </div>
              <div className="flex justify-start">
                <div className="max-w-[85%] rounded-xl rounded-tl-sm bg-emerald-50 border border-emerald-200 p-2">
                  <p className="text-[8px] font-bold text-emerald-800">✓ 8 relances envoyées</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
