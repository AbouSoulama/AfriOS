import { useEffect, useState } from "react";
import afriosLogo from "../assets/afrios-logo.png";
import Icon from "./Icon";

const links = [
  { label: "Comment ça marche", href: "#how" },
  { label: "L'application", href: "#app" },
  { label: "Qui paie quoi ?", href: "#who-pays" },
  { label: "Tarifs", href: "#pricing" },
  { label: "FAQ", href: "#faq" },
];

export default function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${
        scrolled ? "border-b border-afri-line bg-white/85 shadow-sm backdrop-blur-xl" : "bg-transparent"
      }`}
    >
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between lg:h-20">
          <a href="#" className="flex items-center gap-2.5">
            <img src={afriosLogo} alt="AfriOS" className="h-10 w-auto rounded-xl" />
          </a>

          <nav className="hidden items-center gap-1 lg:flex">
            {links.map((l) => (
              <a
                key={l.href}
                href={l.href}
                className="rounded-full px-4 py-2 text-sm font-medium text-afri-navy transition-colors hover:bg-afri-teal-mist hover:text-afri-teal-dark"
              >
                {l.label}
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-2">
            <a
              href="/download/AfriOS.apk"
              download="AfriOS.apk"
              className="inline-flex items-center gap-2 rounded-full bg-afri-teal px-5 py-2.5 text-sm font-bold text-white transition-colors hover:bg-afri-teal-dark"
            >
              <Icon name="download" size={16} />
              Télécharger
            </a>
            <button
              type="button"
              onClick={() => setOpen(!open)}
              className="rounded-lg p-2 hover:bg-afri-mist lg:hidden"
              aria-label="Menu"
              aria-expanded={open}
            >
              <Icon name={open ? "close" : "menu"} size={22} />
            </button>
          </div>
        </div>

        {open && (
          <div className="animate-fade-in-up border-t border-afri-line bg-white py-3 lg:hidden">
            {links.map((l) => (
              <a
                key={l.href}
                href={l.href}
                onClick={() => setOpen(false)}
                className="block rounded-xl px-4 py-3 text-sm font-medium text-afri-navy hover:bg-afri-teal-mist hover:text-afri-teal-dark"
              >
                {l.label}
              </a>
            ))}
          </div>
        )}
      </div>
    </header>
  );
}
