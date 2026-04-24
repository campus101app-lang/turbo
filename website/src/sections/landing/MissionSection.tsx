import React from "react";

// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { docsUrl } from "@/config/site";

/**
 * Ko-fi "home of creative joy" tone + Zap402 / open settlement story.
 */
const MissionSection: React.FC = () => {
  return (
    <section id="mission" className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container">
        <div>
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="font-body text-[clamp(2rem,5vw,3.25rem)] font-normal leading-[1.05] tracking-tight text-zap-ink">
              The home of open payouts
            </h2>
            <div className="mt-8 space-y-5 text-left font-body text-base leading-relaxed text-zap-ink-muted md:text-[17px]">
              <p>
                When did chasing algorithms and opaque payout rails become the default? Zap402 doesn&apos;t
                replace your community — it gives you a <span className="font-semibold text-zap-ink">direct</span>{" "}
                path from supporter to creator: Soroban for execution, USDC for clarity, and x402-inspired
                flows so &quot;payment required&quot; can live on the same web your fans already use.
              </p>
              <p>
                Whether you&apos;re shipping art, code, or coaching — or cheering someone on — Zap402 exists so
                you can create, share, and get paid on{" "}
                <span className="font-semibold text-zap-ink">your</span> terms, with verifiable settlement on
                Stellar.
              </p>
            </div>
            {/* <a
              href={docsUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="mt-10 inline-flex items-center justify-center font-body text-sm font-semibold text-zap-brand underline decoration-zap-brand/35 underline-offset-4 transition-opacity hover:opacity-85"
            >
              Read the project overview ↗
            </a> */}
          </div>
        </div>
      </div>
    </section>
  );
};

export default MissionSection;
