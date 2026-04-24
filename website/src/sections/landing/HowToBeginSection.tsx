import React from "react";
import { Link } from "react-router-dom";

// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useCreatorOnboardingCta } from "@/hooks/useCreatorOnboardingCta";

const beginSteps = [
  {
    category: "WALLET",
    title: "Connect Wallet",
    body: "Use Freighter or xBull to pay and unlock with your own wallet.",
    number: "01",
    image: "/img/step-wallet.webp",
  },
  {
    category: "AGENT",
    title: "Select Agent",
    body: "Start with Claude. More agents (chat, image, research) expand over time.",
    number: "02",
    image: "/img/step-agent.webp",
  },
  {
    category: "PAYMENT",
    title: "Pay Request",
    body: "Pay a small USDC amount per task using x402-style payment flow.",
    number: "03",
    image: "/img/step-payment.webp",
  },
  {
    category: "OUTPUT",
    title: "Receive Output",
    body: "Get results instantly after confirmation, with on-chain receipt visibility.",
    number: "04",
    image: "/img/step-output.webp",
  },
] as const;

const HowToBeginSection: React.FC = () => {
  // const { connected, isRegistered, openWalletConnect } = useCreatorOnboardingCta();

  return (
    <section
      id="how-it-works"
      className="editorial-section bg-zap-bg-alt"
    >
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <h2 className="font-display font-bold w-full text-[clamp(2rem,9vw,3.5rem)] leading-[1.1] text-zap-ink max-w-2xl">
            Fast, Scalable, and Ready for Any Use Case
          </h2>
          <p className="font-body mx-auto w-full max-w-[720px] text-[20px] leading-snug text-zap-ink md:mt-6 md:text-[28px]">
            Connect your wallet, choose Claude, pay once, get results.
          </p>
        {/* </ScrollReveal> */}
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