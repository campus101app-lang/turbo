import React from "react";
import { Link } from "react-router-dom";

// import ScrollReveal from "@/components/feedback/ScrollReveal";

/** Infrastructure story — complements Core modules + How to begin. */
const rails = [
  {
    category: "LEDGER",
    title: "Soroban truth",
    body: "Profiles, tip history, and balances live on-chain. Fans verify payouts; you verify volume — no opaque platform ledger.",
    number: "01",
  },
  {
    category: "STELLAR",
    title: "Global rails",
    body: "USDC-forward settlement on a public network: compatible wallets everywhere, ~5 second finality where the chain allows, with only a minimal Stellar fee reserve (not part of your USDC balance).",
    number: "02",
  },
  {
    category: "TERMINAL",
    title: "Creator hub",
    body: "Balances, activity, and withdrawals in one place after you connect — your operational view on top of the same contract.",
    number: "03",
  },
] as const;

const OpenRailsSection: React.FC = () => {
  return (
    <section className="editorial-section border-t border-zap-bg-alt bg-zap-bg">
      <div className="editorial-container">
        <div>
          <p className="text-label-caps text-label-caps--accent mb-4 text-center">
            // OPEN_RAILS
          </p>
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="font-body text-[clamp(2.5rem,6vw,4.5rem)] font-normal leading-[0.95] text-zap-ink">
              PUBLIC
              <br />
              NETWORK
            </h2>
            <p className="mx-auto mt-6 max-w-xl font-body text-[13px] leading-[1.9] text-zap-ink-muted">
              The same protocol for every creator — open wallets, open chain, one contract
              deployment.
            </p>
          </div>
        </div>

        <div className="mt-14 grid grid-cols-1 gap-6 md:grid-cols-3">
          {rails.map((r) => (
            <article
              key={r.category}
              className="group flex min-h-[260px] flex-col border border-zap-bg-alt bg-zap-bg-raised p-6 transition-[border-color,background-color] duration-200 ease-out md:min-h-[300px] md:p-8 hover:border-zap-bg-alt-bright hover:bg-zap-bg-overlay"
            >
              <div className="flex flex-col text-left">
                <span
                  className="pointer-events-none mt-5 inline-block font-body text-7xl tabular-nums leading-none text-zap-ink-faint opacity-25 transition-opacity duration-200 ease-out group-hover:opacity-40"
                  aria-hidden
                >
                  {r.number}
                </span>
                <p className="font-body text-[10px] uppercase tracking-[0.2em] text-zap-ink-muted">
                  {r.category}
                </p>
                <h3 className="mt-2 font-body text-lg font-normal uppercase tracking-tight text-zap-ink md:text-2xl">
                  {r.title}
                </h3>
              </div>
              <p className="mt-6 flex-1 text-left font-body text-[13px] leading-[1.85] text-zap-ink-muted">
                {r.body}
              </p>
            </article>
          ))}
        </div>

        <div className="mt-10 flex flex-wrap justify-center gap-4">
          <Link
            to="/terminal"
            className="btn-ghost inline-flex min-h-[44px] font-body min-w-[180px] items-center justify-center px-6 no-underline"
          >
            ACCESS TERMINAL
          </Link>
        </div>
      </div>
    </section>
  );
};

export default OpenRailsSection;
