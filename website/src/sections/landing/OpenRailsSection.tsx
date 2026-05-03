import React from "react";
import { Link } from "react-router-dom";

const features = [
  {
    tag: "Smart Categorization",
    title: "Your transactions, understood",
    description: "DayFi automatically classifies every transaction — OPay, Kuda, PalmPay, bank transfers. No manual tagging, no guesswork.",
    image: "/assets/categorization-ui.svg",
  },
  {
    tag: "Invoicing",
    title: "Get paid faster",
    description: "Create professional invoices in seconds, share via WhatsApp, and accept Naira or USDC. Know the moment you're paid.",
    image: "/assets/invoicing-ui.svg",
  },
  {
    tag: "Merchant Checkout",
    title: "Your store, your POS",
    description: "Generate QR codes or tap NFC to collect payments instantly. No terminal needed, no third-party app required.",
    image: "/assets/checkout-ui.svg",
  },
  {
    tag: "Cashflow Insights",
    title: "Know where every kobo went",
    description: "Real-time spending breakdown, income vs expenses, and trends built specifically for how Nigerian businesses actually move money.",
    image: "/assets/insights-ui.svg",
  },
];

const OpenRailsSection: React.FC = () => {
  return (
    <section id="problem" className="editorial-section border-y border-zinc-100 bg-[#F9FAFB] py-24">
      <div className="editorial-container px-6">
        {/* Header */}
        <div className="mx-auto max-w-4xl text-center mb-4">
          <p className="font-body text-[14px] uppercase tracking-widest text-green-600 font-semibold opacity-100 text-green-600">
            Built different
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Everything works <span className="italic text-green-600">the way you do</span>
          </h2>
          <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[20px]">
            DayFi understands Nigerian money — OPay transfers, Kuda wallets, naira volatility. No manual cleanup, no guesswork.
          </p>
        </div>
      </div>
      <section className="bg-[#F9FAFB]">
        {/* Container for the sticky interaction */}
        <div className="mx-auto max-w-7xl px-6">
          {features.map((feature, index) => (
            <div
              key={index}
              className="flex flex-col md:flex-row sticky top-0 items-center justify-between gap-12 py-12 bg-[#F9FAFB]"
            >
              {/* Left Side: Content */}
              <div className="w-full md:w-1/2 space-y-6">
                <h2 className="font-display text-[clamp(1.25rem,5vw,2rem)] leading-[1.1] text-zinc-900">
                  {feature.tag}
                  {/* {feature.title.includes(',') && <span className="italic font-serif text-green-600">, {feature.title.split(',')[1]}</span>} */}
                </h2>
                <p className="font-body text-[18px] text-zinc-600 max-w-md leading-relaxed">
                  {feature.description}
                </p>
                <Link
                  to="/signup"
                  className="inline-flex items-center justify-center font-body text-[13px] font-semibold text-zap-ink border border-zap-ink/20 px-5 py-2 rounded-full hover:border-zap-ink/40 transition-colors"
                >
                  Try for free
                </Link>
              </div>

              {/* Right Side: Visual (The "Swipe Up" Card) */}
              <div className="w-full md:w-2/3">
                <div className="aspect-[4/2.6] w-full rounded-3xl bg-[#E8F3ED] flex items-center justify-center p-8 shadow-sm">
                  <img
                    src={feature.image}
                    alt={feature.tag}
                    className="w-full h-full object-contain"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </section>
  );
};


export default OpenRailsSection;
