import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import HowItWorks from "./components/HowItWorks";
import AppShowcase from "./components/AppShowcase";
import WhoPays from "./components/WhoPays";
import Pricing from "./components/Pricing";
import FAQ from "./components/FAQ";
import CTA from "./components/CTA";
import Footer from "./components/Footer";

export default function App() {
  return (
    <div className="min-h-screen overflow-x-hidden bg-white text-afri-ink">
      <Navbar />
      <main>
        <Hero />
        <HowItWorks />
        <AppShowcase />
        <WhoPays />
        <Pricing />
        <FAQ />
        <CTA />
      </main>
      <Footer />
    </div>
  );
}
