import type { ReactNode } from "react";
import heroImage from "../assets/home_hero.jpg";
import Icon, { type IconName } from "./Icon";

/**
 * Maquette fidèle de l'application mobile AfriOS (Flutter) : mêmes couleurs,
 * mêmes polices, même barre de navigation flottante à 5 onglets, mêmes libellés.
 * Les chiffres affichés sont des données d'exemple.
 */

export type ScreenId = "home" | "invoices" | "invoice" | "clients" | "stock" | "ai";

const navItems: { id: "home" | "invoices" | "clients" | "stock" | "ai"; label: string; icon: IconName }[] = [
  { id: "home", label: "Accueil", icon: "grid" },
  { id: "invoices", label: "Factures", icon: "receipt" },
  { id: "clients", label: "Clients", icon: "users" },
  { id: "stock", label: "Stock", icon: "package" },
  { id: "ai", label: "IA", icon: "sparkles" },
];

interface Props {
  screen: ScreenId;
  onNavigate?: (screen: ScreenId) => void;
  className?: string;
}

export default function AppPhone({ screen, onNavigate, className = "" }: Props) {
  const activeNav = screen === "invoice" ? "invoices" : screen;
  const darkStatus = screen === "home";

  return (
    <div className={`relative w-[300px] shrink-0 ${className}`}>
      <div className="absolute -inset-10 rounded-[4rem] bg-afri-teal/20 blur-3xl" />
      <div className="relative rounded-[2.6rem] bg-afri-ink p-2.5 phone-shadow">
        <div className="relative h-[610px] overflow-hidden rounded-[2.1rem] bg-afri-mist font-sans text-afri-ink">
          {/* Barre d'état */}
          <div
            className={`pointer-events-none absolute inset-x-0 top-0 z-30 flex h-7 items-center justify-between px-6 text-[10px] font-semibold ${
              darkStatus ? "text-white" : "text-afri-ink"
            }`}
          >
            <span>9:41</span>
            <span className="absolute left-1/2 top-1.5 h-4 w-20 -translate-x-1/2 rounded-full bg-black" />
            <span>100%</span>
          </div>

          <div key={screen} className="absolute inset-0 animate-fade-in-up overflow-y-auto pb-24 no-scrollbar">
            {screen === "home" && <HomeScreen />}
            {screen === "invoices" && <InvoicesScreen />}
            {screen === "invoice" && <InvoiceDetailScreen />}
            {screen === "clients" && <ClientsScreen />}
            {screen === "stock" && <StockScreen />}
            {screen === "ai" && <AiScreen />}
          </div>

          {/* Barre de navigation flottante, identique à l'app */}
          <div className="absolute inset-x-3 bottom-3 z-20 rounded-[22px] border border-afri-line bg-white shadow-[0_10px_30px_-10px_rgba(8,13,24,0.25)]">
            <div className="flex h-[58px] items-center px-1">
              {navItems.map((item) => {
                const selected = item.id === activeNav;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => onNavigate?.(item.id)}
                    className={`flex flex-1 flex-col items-center justify-center gap-0.5 rounded-2xl py-1.5 transition-colors ${
                      selected ? "bg-afri-teal-soft/85 text-afri-teal-dark" : "text-afri-slate-light"
                    }`}
                    aria-label={item.label}
                    aria-current={selected ? "page" : undefined}
                  >
                    <Icon name={item.icon} size={19} strokeWidth={selected ? 2.4 : 2} />
                    <span className={`text-[9.5px] ${selected ? "font-extrabold" : "font-semibold"}`}>
                      {item.label}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Éléments partagés ---------- */

function Header({ title, subtitle, action }: { title: string; subtitle?: string; action?: ReactNode }) {
  return (
    <div className="flex items-start justify-between px-5 pb-3 pt-10">
      <div>
        <h3 className="font-display text-[21px] font-extrabold leading-tight tracking-tight">{title}</h3>
        {subtitle && <p className="mt-0.5 text-[11px] text-afri-slate-light">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

type Tone = "success" | "navy" | "orange" | "slate";
const toneClass: Record<Tone, string> = {
  success: "bg-afri-success/12 text-afri-success",
  navy: "bg-afri-navy/10 text-afri-navy",
  orange: "bg-afri-orange/15 text-afri-orange",
  slate: "bg-slate-200/70 text-afri-slate",
};

function Pill({ label, tone }: { label: string; tone: Tone }) {
  return (
    <span className={`inline-block rounded-full px-2 py-0.5 text-[9px] font-extrabold uppercase tracking-wide ${toneClass[tone]}`}>
      {label}
    </span>
  );
}

function Avatar({ name }: { name: string }) {
  const initials = name
    .split(" ")
    .map((p) => p[0])
    .join("")
    .slice(0, 2);
  return (
    <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-afri-teal-soft text-[11px] font-extrabold text-afri-teal-dark">
      {initials}
    </span>
  );
}

function Card({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`rounded-2xl border border-afri-line bg-white ${className}`}>{children}</div>;
}

/* ---------- Écrans ---------- */

function HomeScreen() {
  return (
    <div>
      <div className="relative h-[196px]">
        <div className="absolute inset-x-0 top-0 h-[196px] overflow-hidden rounded-b-[26px] bg-afri-ink">
          <img src={heroImage} alt="" className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-b from-afri-ink/40 via-transparent to-afri-ink/50" />
        </div>
        <div className="absolute inset-x-0 top-0 flex items-center justify-between px-5 pt-9">
          <span className="font-display text-[19px] font-extrabold tracking-tight text-white">AfriOS</span>
          <span className="flex h-8 w-8 items-center justify-center rounded-full border border-white/25 bg-white/15 text-white">
            <Icon name="settings" size={15} />
          </span>
        </div>
        <div className="absolute inset-x-0 top-[104px] px-5">
          <p className="text-[11px] font-semibold text-white/80">Bonjour</p>
          <p className="font-display text-[22px] font-extrabold tracking-tight text-white">Boutique Fatou</p>
        </div>
        <div className="absolute inset-x-5 -bottom-6 z-10 flex items-center rounded-2xl border border-afri-line bg-white px-3 py-2.5 shadow-[0_12px_28px_-12px_rgba(8,13,24,0.3)]">
          <div className="shrink-0 whitespace-nowrap">
            <p className="text-[9px] font-semibold text-afri-slate-light">Encaissé aujourd'hui</p>
            <p className="font-display text-[14px] font-extrabold tracking-tight">85 000 FCFA</p>
          </div>
          <span className="mx-2 h-7 w-px shrink-0 bg-afri-line" />
          <div className="flex-1 whitespace-nowrap text-center">
            <p className="font-display text-[14px] font-extrabold text-afri-navy">8</p>
            <p className="text-[8.5px] font-semibold text-afri-slate-light">en attente</p>
          </div>
          <span className="mx-1 h-7 w-px shrink-0 bg-afri-line" />
          <div className="flex-1 whitespace-nowrap text-center">
            <p className="font-display text-[14px] font-extrabold text-afri-orange">3</p>
            <p className="text-[8.5px] font-semibold text-afri-slate-light">en retard</p>
          </div>
        </div>
      </div>

      <div className="space-y-2.5 px-5 pt-10">
        <div className="hero-gradient rounded-2xl p-4 text-white">
          <div className="flex items-center justify-between">
            <p className="text-[10.5px] font-semibold text-white/75">Encaissé ce mois</p>
            <Icon name="trendingUp" size={15} className="text-afri-teal-bright" />
          </div>
          <p className="mt-1 font-display text-[24px] font-extrabold tracking-tight">1 245 000 FCFA</p>
          <span className="mt-1.5 inline-block rounded-full bg-white/15 px-2 py-0.5 text-[9.5px] font-bold text-afri-teal-bright">
            +18 % vs mois dernier
          </span>
        </div>
        <div className="grid grid-cols-2 gap-2.5">
          <Card className="p-3">
            <div className="flex items-center gap-1.5 text-afri-navy">
              <Icon name="clock" size={13} />
              <span className="text-[10px] font-semibold text-afri-slate">En attente</span>
            </div>
            <p className="mt-1 font-display text-[20px] font-extrabold">8</p>
            <p className="text-[9.5px] text-afri-slate-light">320 000 FCFA</p>
          </Card>
          <Card className="p-3">
            <div className="flex items-center gap-1.5 text-afri-orange">
              <Icon name="alert" size={13} />
              <span className="text-[10px] font-semibold text-afri-slate">Stock faible</span>
            </div>
            <p className="mt-1 font-display text-[20px] font-extrabold">3</p>
            <p className="text-[9.5px] text-afri-slate-light">produits à réapprovisionner</p>
          </Card>
        </div>

        <div className="pt-2">
          <p className="font-display text-[14px] font-extrabold tracking-tight">Actions rapides</p>
          <p className="text-[10px] text-afri-slate-light">Les gestes du quotidien</p>
        </div>
        {[
          { l: "Créer une facture", s: "Encaisse en moins d'une minute", i: "receipt" as IconName, c: "text-afri-teal bg-afri-teal-soft" },
          { l: "Relancer les impayés", s: "3 facture(s) en retard", i: "bell" as IconName, c: "text-afri-orange bg-afri-orange/15" },
          { l: "Ajouter un client", s: "Enrichis ton carnet commercial", i: "userPlus" as IconName, c: "text-afri-navy bg-afri-navy/10" },
          { l: "Assistant IA", s: "Pose une question sur ton business", i: "sparkles" as IconName, c: "text-afri-gold bg-afri-gold/15" },
        ].map((a) => (
          <Card key={a.l} className="flex items-center gap-3 p-2.5">
            <span className={`flex h-9 w-9 items-center justify-center rounded-xl ${a.c}`}>
              <Icon name={a.i} size={17} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[12px] font-bold">{a.l}</p>
              <p className="truncate text-[10px] text-afri-slate-light">{a.s}</p>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

function InvoicesScreen() {
  const filters = ["Toutes", "En attente", "En retard", "Payées"];
  const rows: { n: string; c: string; t: string; s: string; tone: Tone }[] = [
    { n: "F-0008", c: "Amadou Diallo", t: "45 000", s: "En attente", tone: "navy" },
    { n: "F-0007", c: "Fatou Ndiaye", t: "120 000", s: "Payée", tone: "success" },
    { n: "F-0006", c: "Moussa Sarr", t: "80 000", s: "En retard", tone: "orange" },
    { n: "F-0005", c: "Aïssatou Ba", t: "65 000", s: "Payée", tone: "success" },
    { n: "F-0004", c: "Khady Fall", t: "35 000", s: "Brouillon", tone: "slate" },
  ];
  return (
    <div>
      <Header title="Factures" subtitle="Suis ce qui est dû et ce qui est encaissé" />
      <div className="flex gap-1.5 overflow-x-auto px-5 pb-3 no-scrollbar">
        {filters.map((f, i) => (
          <span
            key={f}
            className={`shrink-0 rounded-full px-3 py-1.5 text-[10.5px] font-bold ${
              i === 0 ? "bg-afri-teal text-white" : "border border-afri-line bg-white text-afri-slate"
            }`}
          >
            {f}
          </span>
        ))}
      </div>
      <div className="space-y-2 px-5">
        {rows.map((r) => (
          <Card key={r.n} className="flex items-center gap-3 p-3">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-afri-teal-mist text-afri-teal-dark">
              <Icon name="receipt" size={16} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[12px] font-bold">{r.c}</p>
              <p className="text-[10px] text-afri-slate-light">{r.n}</p>
            </div>
            <div className="text-right">
              <p className="text-[12px] font-extrabold">{r.t} FCFA</p>
              <Pill label={r.s} tone={r.tone} />
            </div>
          </Card>
        ))}
        <div className="flex items-center justify-center gap-1.5 rounded-2xl bg-afri-teal py-3 text-[12px] font-bold text-white">
          <Icon name="plus" size={15} /> Nouvelle facture
        </div>
      </div>
    </div>
  );
}

function InvoiceDetailScreen() {
  return (
    <div>
      <div className="px-5 pb-3 pt-10">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-afri-slate-light">Facture F-0008</p>
        <h3 className="font-display text-[21px] font-extrabold tracking-tight">Amadou Diallo</h3>
        <div className="mt-1 flex items-center gap-2">
          <span className="font-display text-[18px] font-extrabold text-afri-teal-dark">45 000 FCFA</span>
          <Pill label="En attente" tone="navy" />
        </div>
      </div>
      <div className="space-y-2.5 px-5">
        <Card className="divide-y divide-afri-line">
          {[
            ["T-shirt coton × 3", "30 000"],
            ["Casquette × 2", "15 000"],
          ].map(([l, p]) => (
            <div key={l} className="flex items-center justify-between px-3 py-2.5 text-[11px]">
              <span className="font-semibold">{l}</span>
              <span className="font-extrabold">{p}</span>
            </div>
          ))}
        </Card>

        <div className="pt-1">
          <p className="font-display text-[14px] font-extrabold tracking-tight">Encaissement</p>
          <p className="text-[10.5px] leading-snug text-afri-slate">
            C'est ton client qui paie. Toi, tu suis ou tu confirmes l'encaissement.
          </p>
        </div>
        <div className="flex items-center justify-center gap-1.5 rounded-2xl bg-afri-teal py-2.5 text-[11px] font-bold text-white">
          <Icon name="send" size={14} /> Envoyer le lien de paiement au client
        </div>
        {[
          { l: "Vérifier l'encaissement", i: "checkCircle" as IconName },
          { l: "Client a payé en espèces", i: "banknote" as IconName },
          { l: "Relancer le client", i: "message" as IconName },
        ].map((b) => (
          <div
            key={b.l}
            className="flex items-center justify-center gap-1.5 rounded-2xl border border-afri-line bg-white py-2.5 text-[11px] font-bold text-afri-navy"
          >
            <Icon name={b.i} size={14} /> {b.l}
          </div>
        ))}
      </div>
    </div>
  );
}

function ClientsScreen() {
  const rows = [
    { n: "Amadou Diallo", p: "+226 70 12 34 56", due: "45 000" },
    { n: "Fatou Ndiaye", p: "+226 75 98 76 54", due: "0" },
    { n: "Moussa Sarr", p: "+226 76 11 22 33", due: "80 000" },
    { n: "Aïssatou Ba", p: "+226 71 33 44 55", due: "0" },
    { n: "Khady Fall", p: "+226 74 44 55 66", due: "35 000" },
  ];
  return (
    <div>
      <Header
        title="Clients"
        subtitle="Ton carnet commercial"
        action={
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-afri-teal text-white">
            <Icon name="plus" size={17} />
          </span>
        }
      />
      <div className="space-y-2 px-5">
        {rows.map((c) => (
          <Card key={c.n} className="flex items-center gap-3 p-2.5">
            <Avatar name={c.n} />
            <div className="min-w-0 flex-1">
              <p className="truncate text-[12px] font-bold">{c.n}</p>
              <p className="text-[10px] text-afri-slate-light">{c.p}</p>
            </div>
            {c.due === "0" ? (
              <Pill label="Soldé" tone="success" />
            ) : (
              <span className="text-[11px] font-extrabold text-afri-orange">{c.due} dû</span>
            )}
          </Card>
        ))}
      </div>
    </div>
  );
}

function StockScreen() {
  const rows = [
    { n: "T-shirt coton", q: 45, p: "15 000", low: false },
    { n: "Baskets", q: 12, p: "45 000", low: false },
    { n: "Casquette", q: 3, p: "8 000", low: true },
    { n: "Sac à dos", q: 15, p: "12 000", low: false },
    { n: "Montre", q: 2, p: "35 000", low: true },
  ];
  return (
    <div>
      <Header
        title="Stock"
        subtitle="Produits & alertes"
        action={
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-afri-teal text-white">
            <Icon name="plus" size={17} />
          </span>
        }
      />
      <div className="space-y-2 px-5">
        {rows.map((p) => (
          <Card key={p.n} className="flex items-center gap-3 p-2.5">
            <span
              className={`flex h-9 w-9 items-center justify-center rounded-xl ${
                p.low ? "bg-afri-orange/15 text-afri-orange" : "bg-afri-teal-mist text-afri-teal-dark"
              }`}
            >
              <Icon name="package" size={16} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[12px] font-bold">{p.n}</p>
              <p className="text-[10px] text-afri-slate-light">{p.p} FCFA</p>
            </div>
            <div className="text-right">
              <p className={`font-display text-[14px] font-extrabold ${p.low ? "text-afri-orange" : ""}`}>{p.q}</p>
              {p.low && <Pill label="Faible" tone="orange" />}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

function AiScreen() {
  return (
    <div>
      <div className="flex items-center gap-2.5 px-5 pb-3 pt-10">
        <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-afri-teal text-white">
          <Icon name="sparkles" size={18} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="font-display text-[15px] font-extrabold tracking-tight">Assistant AfriOS</p>
          <p className="text-[10px] text-afri-slate-light">Pose une question, AfriOS agit.</p>
        </div>
        <Pill label="En ligne" tone="success" />
      </div>
      <div className="space-y-2.5 px-4">
        <Bubble>
          Bonjour ! Je suis ton assistant AfriOS. Demande-moi ton chiffre du mois, tes impayés ou une idée pour vendre
          plus.
        </Bubble>
        <Bubble user>Combien j'ai facturé ce mois ?</Bubble>
        <Bubble>
          Ce mois, tu as <strong>facturé 1 565 000 FCFA</strong> et <strong>encaissé 1 245 000 FCFA</strong>. Il reste 8
          factures en attente (320 000 FCFA).
        </Bubble>
        <div className="flex gap-1.5 overflow-x-auto pb-1 no-scrollbar">
          {["Factures impayées ?", "Stock faible ?"].map((s) => (
            <span
              key={s}
              className="shrink-0 rounded-full border border-afri-teal/25 bg-afri-teal-mist px-3 py-1.5 text-[10px] font-bold text-afri-teal-dark"
            >
              {s}
            </span>
          ))}
        </div>
        <div className="flex">
          <div className="flex items-center gap-1 rounded-2xl rounded-bl-sm border border-afri-line bg-white px-3 py-2.5">
            <span className="typing-dot h-1.5 w-1.5 rounded-full bg-afri-slate-light" />
            <span className="typing-dot h-1.5 w-1.5 rounded-full bg-afri-slate-light" />
            <span className="typing-dot h-1.5 w-1.5 rounded-full bg-afri-slate-light" />
          </div>
        </div>
      </div>
    </div>
  );
}

function Bubble({ children, user = false }: { children: ReactNode; user?: boolean }) {
  return (
    <div className={`flex ${user ? "justify-end" : "justify-start"}`}>
      <div
        className={`max-w-[84%] rounded-2xl px-3 py-2.5 text-[11px] leading-snug ${
          user
            ? "rounded-br-sm bg-afri-teal text-white"
            : "rounded-bl-sm border border-afri-line bg-white text-afri-ink"
        }`}
      >
        {children}
      </div>
    </div>
  );
}
