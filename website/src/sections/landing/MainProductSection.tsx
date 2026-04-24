import React from "react";
import { Zap, Clock, Shield, Globe, Layers, CheckCircle, Bot } from "lucide-react";
// import { Zap, Layers, } from "lucide-react";
/**
 * Ko-fi–style "Payday your way" block with Zap402 / x402 + Stellar positioning.
 */
const MainProductSection: React.FC = () => {
  // const openWalletConnect = useOpenWalletConnect();

  const stats = [
    {
      icon: <Zap size={28} />,
      value: "< 1 Second",
      label: "Payments verified and settled instantly on Stellar.",
    },
    {
      icon: <Layers size={28} />,
      value: "Pay-Per-Request",
      label: "Charge per API call, AI action, or usage.",
    },
    {
      icon: <CheckCircle size={28} />,
      value: "Instant Settlement",
      label: "No delays, no reconciliation.",
    },
    {
      icon: <Bot size={28} />,
      value: "Agent-Friendly",
      label: "Seamless payments between humans, apps, and autonomous AI agents.",
    },
  ];

  return (
    <section id="payday" className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <div className="flex flex-col md:flex-row items-center gap-10 md:gap-14">

            {/* Text */}
            {/* <div className="flex flex-col items-start text-left flex-1 min-w-0 pr-10">
              <div className="mb-3 text-zap-brand">
                <Zap size={28} />
              </div>
              <p className="font-display font-semibold w-full text-[clamp(1.5rem,7vw,2.5rem)] leading-[1.1] tracking-tight text-zap-ink mb-4">
                Simplify x402 Payments for AI & Apps
              </p>
              <p className="font-body text-[20px] text-zap-ink/70">
                Zap402 makes it effortless for merchants and developers to accept x402 payments. Enable usage-based, per-request payments for AI agents, APIs, SaaS, and digital services — with sub-second settlement on Stellar, and zero blockchain complexity.
              </p>
            </div> */}

            {/* Stats */}
            <div className="grid grid-cols-2 gap-8 shrink-0 md:w-[100%]">
              {stats.map((s) => (
                <div key={s.label} className="flex flex-col items-center text-center md:text-center">
                  <div className="mb-3 text-zap-brand">
                    {s.icon}
                  </div>
                  <p className="font-body text-[24px] font-semibold leading-tight text-zap-ink">
                    {s.value}
                  </p>
                  <p className="font-body text-[20px] text-zap-ink/70">
                    {s.label}
                  </p>
                </div>
              ))}
            </div>

          </div>
        {/* </ScrollReveal> */}
      </div>
    </section>
  );
};

export default MainProductSection;
