import { useState } from "react";
import afriosLogo from "../assets/afrios-logo.png";

interface Props {
  scrollY: number;
  onDemo: () => void;
}

export default function Navbar({ scrollY, onDemo }: Props) {
  const [open, setOpen] = useState(false);
  const scrolled = scrollY > 20;

  const links = [
    { label: "Fonctionnalités", href: "#features" },
    { label: "Démo App", href: "#showcase" },
    { label: "Mobile Money", href: "#mobile-money" },
    { label: "IA Business", href: "#ai" },
    { label: "Tarifs", href: "#pricing" },
  ];

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled
          ? "bg-white/80 backdrop-blur-xl border-b border-slate-200/60 shadow-sm"
          : "bg-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 lg:h-20">
          <a href="#" className="flex items-center gap-2.5 group">
            <img
              src={afriosLogo}
              alt="AfriOS"
              className="h-10 w-auto group-hover:scale-105 transition-transform"
            />
          </a>

          <nav className="hidden lg:flex items-center gap-1">
            {links.map((l) => (
              <a
                key={l.href}
                href={l.href}
                className="px-4 py-2 text-sm font-medium text-slate-700 hover:text-teal-700 rounded-full hover:bg-teal-50 transition-colors"
              >
                {l.label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-2">
            <button
              onClick={onDemo}
              className="hidden sm:inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-slate-700 hover:text-teal-700 rounded-full hover:bg-slate-100 transition-colors"
            >
              Essayer démo
            </button>
            <button
              onClick={onDemo}
              className="btn-shine inline-flex items-center gap-2 px-5 py-2.5 text-sm font-bold text-white rounded-full bg-gradient-to-r from-teal-600 to-blue-800 hover:shadow-xl hover:shadow-teal-500/30 transition-all"
            >
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10 2a3 3 0 00-3 3v1H6a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2V8a2 2 0 00-2-2h-1V5a3 3 0 00-3-3zm0 2a1 1 0 011 1v1H9V5a1 1 0 011-1z"/></svg>
              Installer
            </button>
            <button
              onClick={() => setOpen(!open)}
              className="lg:hidden p-2 rounded-lg hover:bg-slate-100"
              aria-label="Menu"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={open ? "M6 18L18 6M6 6l12 12" : "M4 6h16M4 12h16M4 18h16"}/></svg>
            </button>
          </div>
        </div>

        {open && (
          <div className="lg:hidden py-4 border-t border-slate-200 animate-fade-in-up">
            <div className="flex flex-col gap-1">
              {links.map((l) => (
                <a
                  key={l.href}
                  href={l.href}
                  onClick={() => setOpen(false)}
                  className="px-4 py-3 text-sm font-medium text-slate-700 rounded-xl hover:bg-teal-50 hover:text-teal-700"
                >
                  {l.label}
                </a>
              ))}
            </div>
          </div>
        )}
      </div>
    </header>
  );
}
