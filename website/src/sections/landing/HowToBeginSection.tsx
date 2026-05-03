import React from "react";
import { Link } from "react-router-dom";

// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useCreatorOnboardingCta } from "@/hooks/useCreatorOnboardingCta";

const stats = [
  {
    value: "2 mins",
    label: "average time to create and send an invoice",
    isGreen: true,
  },
  {
    value: "₦0",
    label: "fees to receive USDC payments",
    isGreen: true,
  },
  {
    value: "3-in-1",
    label: "payments, invoicing, and store management in one app",
    isGreen: true,
  },
  {
    value: "instant",
    label: "NFC and QR checkout — no POS terminal needed",
    isGreen: true,
  },
];

const HowToBeginSection: React.FC = () => {
  return (
    <section id="how-it-works" className="editorial-section bg-[#0A0A0A]">
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] text-[#4ADE80] uppercase tracking-widest font-semibold">
            Real results
          </p>
          <h2 className="font-display font-semibold pt-4 mt-4 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-white md:mt-0">
            Numbers that <span className="italic">speak for themselves</span>
          </h2>
          <p className="font-body mt-4 mx-auto w-full max-w-[600px] text-[16px] leading-snug text-white/50 md:text-[18px]">
            Built for Nigerian businesses that are serious about their money.
          </p>
        </div>
      </div>

      {/* Stats Grid */}
      {/* Stats Grid */}
      <div className="relative border-t border-white/10">
        <div className="editorial-container mx-auto w-full max-w-[1200px] px-4">
          <div className="grid grid-cols-2 md:grid-cols-4">
            {stats.map((stat, index) => (
              <div
                key={index}
                className={`p-8 border-white/10
            ${index < 3 ? "border-r" : ""}
          `}
              >
                <h3 className="font-display text-[36px] md:text-[48px] font-normal leading-none mb-2 text-[#4ADE80]">
                  {stat.value}
                </h3>
                <p className="font-body text-[13px] md:text-[14px] text-white/50 max-w-[180px] leading-snug">
                  {stat.label}
                </p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default HowToBeginSection;
