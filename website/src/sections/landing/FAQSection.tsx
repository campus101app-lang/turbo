import React, { useState } from "react";
// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { docsUrl } from "@/config/site";

type FaqItem = { q: string; a: React.ReactNode };

const FAQS: FaqItem[] = [
  {
    q: "What is Zap402?",
    a: (
      <>
        Zap402 is a pay-per-request AI agent marketplace built on USDC and Stellar. Whether you're a
        developer, researcher, or business — you can access Claude, Codex, Midjourney, and more AI agents
        instantly. No subscriptions. No monthly bills. Just pay for what you use, when you use it.
      </>
    ),
  },
  {
    q: "How does Zap402 work?",
    a: (
      <>
        Connect your Stellar wallet, pick an agent, and send a request. Your USDC payment is processed
        on-chain in seconds. The agent completes your task — whether that's writing, coding, image
        generation, or analysis — and you receive a cryptographically signed receipt confirming delivery.
        Every request is verifiable, every payment is on-chain.
      </>
    ),
  },
  {
    q: "How much does it cost to use an agent?",
    a: (
      <>
        Pricing starts as low as <span className="font-semibold text-zap-ink">$0.02 per request</span> for
        chat agents and scales based on the agent's capability. Research agents run around $0.05–$0.08,
        code agents $0.09–$0.12, and image or video agents $0.15–$0.30. You only pay when you send a
        request — there are no setup fees, no minimums, and no hidden charges.
      </>
    ),
  },
  {
    q: "Can I use Zap402 if I'm just getting started with AI?",
    a: (
      <>
        Absolutely. Start with Claude — it's the most capable general-purpose agent on the platform and
        handles everything from writing and research to summarization and Q&A. You don't need to know
        how blockchain works to get started. Connect a wallet, fund it with a few dollars of USDC, and
        you're ready to go in under two minutes.
      </>
    ),
  },
  {
    q: "How do payments and settlement work?",
    a: (
      <>
        All payments are made in <span className="font-semibold text-zap-ink">USDC on Stellar</span> —
        one of the fastest and lowest-fee settlement networks available. Transactions confirm in
        seconds. Every completed request generates a wallet-signed receipt stored on-chain, so you
        always have proof of delivery. No chargebacks, no delays, no middlemen taking a cut between
        you and the agent.
      </>
    ),
  },
  {
    q: "How is Zap402 different from ChatGPT Plus or Claude Pro?",
    a: (
      <>
        Subscriptions lock you into a monthly fee whether you use the service or not. Zap402 is
        request-native — you pay only for what you actually run. You also get access to{" "}
        <span className="font-semibold text-zap-ink">multiple AI providers in one place</span>: Claude,
        GPT, Gemini, Midjourney, and more — all under a single wallet. Every transaction is
        on-chain and verifiable, making Zap402 the first AI marketplace built for programmable,
        auditable AI commerce. See{" "}
        {/* <a href={docsUrl} className="font-semibold text-zap-brand underline underline-offset-2" target="_blank" rel="noreferrer">
          docs
        </a>{" "} */}
        for the full technical scope.
      </>
    ),
  },
];

const FAQSection: React.FC = () => {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="editorial-section bg-zap-brand-dim">
      <div

        className="
      editorial-container 
      max-w-2xl
        rounded-3xl
        bg-white
        px-8 py-10
        shadow-sm
        backdrop-blur-sm
        dark:border-white/10
        dark:bg-neutral-900/70
        sm:px-8 sm:py-8
      ">

        {/* <ScrollReveal>
          <h2 className="text-center font-display font-bold text-[clamp(2rem,5vw,3rem)] leading-tight text-zap-ink">
            Questions
          </h2>
          <p className="mt-3 text-center font-body text-base text-zap-ink-muted">
            Clear answers first. Technical detail is available in docs.
          </p>
        </ScrollReveal> */}

        <ul className="mt-10 space-y-3">
          {FAQS.map((item, i) => {
            const isOpen = open === i;
            return (
              <li key={item.q}>
                <button
                  type="button"
                  className={`flex w-full items-center justify-between gap-3 rounded-full px-6 py-1 text-left font-body text-[28px] font-semibold transition-colors duration-150 ${isOpen
                    ? "bg-zap-brand/20 hover:bg-zap-brand/25"
                    : "bg-zap-brand/10 hover:bg-zap-brand/15"
                    }`}
                  onClick={() => setOpen(isOpen ? null : i)}
                  aria-expanded={isOpen}

                >
                  {item.q}
                  <span className="shrink-0 font-body text-[20px] font-semibold" aria-hidden>
                    {isOpen ? "−" : "+"}
                  </span>
                </button>
                {isOpen ? (
                  <div className="mt-8 mb-8 block rounded-full px-6 py-1 font-body text-[26px] transition-colors duration-150">
                    {item.a}
                  </div>
                ) : null}
              </li>
            );
          })}
        </ul>
      </div>
    </section>
  );
};

export default FAQSection;