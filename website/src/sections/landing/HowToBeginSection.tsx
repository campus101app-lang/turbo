import React from "react";
import { Link } from "react-router-dom";

// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useCreatorOnboardingCta } from "@/hooks/useCreatorOnboardingCta";

const stats = [
  {
    value: "₦1,252,687.69",
    label: "saved per employee annually",
    isGreen: true,
  },
  {
    value: "89%",
    label: "expense report errors are autocorrected",
    isGreen: true,
  },
  {
    value: "54%",
    label: "increase in the productivity",
    isGreen: true,
  },
  {
    value: "37%",
    label: "faster employee reimbursement",
    isGreen: true,
  },
];
const HowToBeginSection: React.FC = () => {
  // const { connected, isRegistered, openWalletConnect } = useCreatorOnboardingCta();

  return (
    <section
      id="how-it-works"
      className="editorial-section bg-[#0A0A0A]"
    >
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] text-[#4ADE80] uppercase tracking-widest font-semibold opacity-100 text-green-800">
            Save and earn more          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight md:mt-0">
            Businesses save more with Bujeti
          </h2>
          <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[20px]">
            Positive customer ROI in 5 months, reaching 4.5x within 3 years.</p>
        </div>
      </div>

      {/* Globe/Graphic Overlay */}
      <div className="absolute -right-20 top-1/2 -translate-y-1/2 opacity-40 md:opacity-100 pointer-events-none">
        {/* You can replace this with your actual Globe image */}
        <div className="w-[400px] h-[400px] md:w-[600px] md:h-[600px] rounded-full bg-gradient-to-br from-green-900/20 to-transparent blur-3xl absolute inset-0" />
        <img
          src="/img/globe-dots.svg"
          alt="data visualization"
          className="relative w-[500px] md:w-[700px] object-contain"
        />
      </div>

      {/* Stats Grid */}
      <div className="relative border-t border-white/10">
        <div className="grid grid-cols-1 md:grid-cols-2">
          {stats.map((stat, index) => (
            <div
              key={index}
              className={`p-10 md:p-16 border-white/10 
                  ${index % 2 === 0 ? "md:border-r" : ""} 
                  ${index < 2 ? "border-b" : ""}
                `}
            >
              <h3 className={`font-display text-[48px] md:text-[64px] font-normal leading-none mb-4 ${stat.isGreen ? "text-[#4ADE80]" : "text-white"}`}>
                {stat.value}
              </h3>
              <p className="font-body text-[16px] md:text-[18px] opacity-50 max-w-[240px]">
                {stat.label}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default HowToBeginSection;

// {/* <div className="mx-auto mt-14 max-w-4xl divide-y divide-zap-border">
// {beginSteps.map((m) => (
//   <article
//     key={m.category}
//     className="group flex items-center gap-8 py-8"
//   >
//     {/* Left — text */}
// <div className="flex flex-1 items-start gap-5 min-w-0">
//   <span className="shrink-0 font-body text-[11px] tabular-nums text-zap-ink-faint pt-1">
//     {m.number}
//   </span>
//   <div className="min-w-0">
//     <p className="font-body text-[10px] uppercase tracking-[0.2em] text-zap-ink-muted">
//       {m.category}
//     </p>
//     <h3 className="mt-1 font-body text-[1.2rem] font-semibold leading-tight tracking-tight text-zap-ink">
//       {m.title}
//     </h3>
//     <p className="mt-2 font-body text-[13px] leading-relaxed text-zap-ink-muted">
//       {m.body}
//     </p>
//   </div>
// </div>

{/* Right — image */ }
//     <div className="shrink-0 w-[160px] md:w-[200px]">
//       <img
//         src={m.image}
//         alt={m.title}
//         className="w-full rounded-xl border border-zap-bg-alt object-cover"
//       />
//     </div>
//   </article>
// ))}
// </div> 