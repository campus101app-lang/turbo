import React from "react";
import type { LucideIcon } from "lucide-react";
import { Link2, MessageCircle, UserCircle, Wallet } from "lucide-react";

// import ScrollReveal from "@/components/feedback/ScrollReveal";

const steps: {
  n: string;
  title: string;
  body: string;
  Icon: LucideIcon;
}[] = [
  {
    n: "01",
    title: "Connect wallet",
    body: "Link Freighter, xBull, Albedo, or any Stellar-compatible wallet. Your keys, your funds — non-custodial from day one.",
    Icon: Wallet,
  },
  {
    n: "02",
    title: "Create your profile",
    body: "Sign one transaction to register on-chain. Your username lives in the Zap402 Soroban contract — not in our database.",
    Icon: UserCircle,
  },
  {
    n: "03",
    title: "Share your link",
    body: "Your page lives at /@handle. Share it on X, YouTube, newsletters — anyone with a wallet can tip or unlock content.",
    Icon: Link2,
  },
  {
    n: "04",
    title: "Get paid in USDC",
    body: "Settlements land in your wallet in ~5 seconds. No platform holds your balance — no withdrawal queue.",
    Icon: MessageCircle,
  },
];

const HowItWorksSection: React.FC = () => {
  return (
    <section id="how-it-works" className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container">
        <div>
          <p className="mb-4 text-center font-body text-xs font-semibold uppercase tracking-[0.12em] text-zap-accent">
            How it works
          </p>
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="font-body text-[clamp(2.25rem,5.5vw,3.75rem)] font-normal leading-[1.05] text-zap-ink">
              Four steps to go live on-chain
            </h2>
            <p className="mx-auto mt-6 max-w-xl font-body text-[15px] leading-relaxed text-zap-ink-muted">
              Wallet → deploy → broadcast → settle. USDC on Stellar — no card processor in the path.
            </p>
          </div>
        </div>

        <ol className="mx-auto mt-16 max-w-2xl list-none space-y-0 sm:mt-20">
          {steps.map((step, i) => {
            const { Icon } = step;
            const isLast = i === steps.length - 1;
            return (
              <li key={step.n}>
                <div>
                  <div className="flex gap-4 sm:gap-6">
                    <div className="flex w-12 shrink-0 flex-col items-center sm:w-14">
                      <div className="flex h-9 w-9 items-center justify-center border border-zap-accent bg-zap-bg-raised font-body text-[10px] font-medium tabular-nums leading-none text-zap-accent sm:h-10 sm:w-10">
                        {step.n}
                      </div>
                      {!isLast ? (
                        <div
                          className="mt-3 w-px flex-1 min-h-[3rem] bg-zap-border sm:min-h-[3.5rem]"
                          aria-hidden
                        />
                      ) : null}
                    </div>
                    <div className="min-w-0 flex-1 pb-12 pt-0.5 sm:pb-14">
                      <div className="flex flex-wrap items-center gap-2 sm:gap-3">
                        <Icon
                          className="h-5 w-5 shrink-0 text-zap-teal"
                          strokeWidth={2}
                          aria-hidden
                        />
                        <h3 className="font-body text-base font-semibold tracking-tight text-zap-ink">
                          {step.title}
                        </h3>
                      </div>
                      <p className="mt-3 max-w-lg font-body text-[14px] leading-[1.75] text-zap-ink-muted sm:mt-4 sm:text-[15px] sm:leading-[1.7]">
                        {step.body}
                      </p>
                    </div>
                  </div>
                </div>
              </li>
            );
          })}
        </ol>
      </div>
    </section>
  );
};

export default HowItWorksSection;
