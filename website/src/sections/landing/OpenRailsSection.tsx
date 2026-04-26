import React from "react";
import { Link } from "react-router-dom";

const features = [
  {
    tag: "Automation",
    title: "Goodbye tedious accounting",
    description: "Bujeti automates tedious accounting, receipt chasing, reporting, compliance, and more.",
    image: "/assets/automation-ui.svg", // Replace with your screenshot assets
  },
  {
    tag: "Spend controls",
    title: "Control every kobo",
    description: "Customize approval flows, spending limits, issue cards with controls and stop out-of-budget spending.",
    image: "/assets/controls-ui.svg",
  },
  {
    tag: "Intelligent assistant",
    title: "Ask your finances",
    description: "Ask Bujeti about your finances for instant insights, analysis, and trend discovery.",
    image: "/assets/assistant-ui.svg",
  },
  {
    tag: "Spend optimisation",
    title: "Stay one step ahead",
    description: "Stay one step ahead of your company's finances and turn your data into cost-saving decisions.",
    image: "/assets/optimization-ui.svg",
  }
];

const OpenRailsSection: React.FC = () => {
  return (
    <section id="problem" className="editorial-section border-y border-zinc-100 bg-[#F9FAFB] py-24">
      <div className="editorial-container px-6">
        {/* Header */}
        <div className="mx-auto max-w-4xl text-center mb-4">
          <p className="font-body text-[14px] uppercase tracking-widest text-zap-ink font-semibold opacity-100 text-green-800">
            Modern Finance Platform
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Goodbye errors, <span className="italic text-green-800">hello intelligence</span>
          </h2>

          <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[20px]">
            Bujeti automates tasks, eliminates errors, monitors transactions, uncovering insights for spending control. </p>
        </div>
      </div>
      <section className="bg-[#F9FAFB]">
        {/* Container for the sticky interaction */}
        <div className="mx-auto max-w-7xl px-6">
          {features.map((feature, index) => (
            <div
              key={index}
              className="flex flex-col md:flex-row min-h-screen sticky top-0 items-center justify-between gap-12 py-20 bg-[#F9FAFB]"
            >
              {/* Left Side: Content */}
              <div className="w-full md:w-1/2 space-y-6">
                <h2 className="font-display text-[clamp(1.25rem,5vw,2rem)] leading-[1.1] text-zinc-900">
                  {feature.tag}
                  {/* {feature.title.includes(',') && <span className="italic font-serif text-green-700">, {feature.title.split(',')[1]}</span>} */}
                </h2>
                <p className="font-body text-[18px] text-zinc-600 max-w-md leading-relaxed">
                  {feature.description}
                </p>
                <button className="px-6 py-3 rounded-full border border-zinc-200 font-body text-[14px] hover:bg-zinc-50 transition-colors">
                  Try for free
                </button>
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
