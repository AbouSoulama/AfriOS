import { useEffect, useState } from "react";
import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import TrustBar from "./components/TrustBar";
import Features from "./components/Features";
import PhoneShowcase from "./components/PhoneShowcase";
import MobileMoney from "./components/MobileMoney";
import AI from "./components/AI";
import Pricing from "./components/Pricing";
import Roadmap from "./components/Roadmap";
import Stats from "./components/Stats";
import CTA from "./components/CTA";
import Footer from "./components/Footer";
import PhoneDemoModal from "./components/PhoneDemoModal";

export default function App() {
  const [showDemo, setShowDemo] = useState(false);
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    const onScroll = () => setScrollY(window.scrollY);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <div className="min-h-screen bg-white text-slate-900 overflow-x-hidden">
      <Navbar scrollY={scrollY} onDemo={() => setShowDemo(true)} />
      <main>
        <Hero onDemo={() => setShowDemo(true)} />
        <TrustBar />
        <Features />
        <PhoneShowcase />
        <MobileMoney />
        <AI />
        <Stats />
        <Pricing />
        <Roadmap />
        <CTA onDemo={() => setShowDemo(true)} />
      </main>
      <Footer />
      {showDemo && <PhoneDemoModal onClose={() => setShowDemo(false)} />}
    </div>
  );
}
