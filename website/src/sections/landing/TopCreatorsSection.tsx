import React, { useState } from "react";
// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useOnChainAgents } from "@/hooks";

const CATEGORIES = [
  { label: "Research", value: "research", icon: "🔬" },
  { label: "Chat", value: "chat", icon: "💬" },
  { label: "Code", value: "code", icon: "⌨️" },
  { label: "Image", value: "image", icon: "🎨" },
  { label: "Video", value: "video", icon: "🎬" },
];

const CATEGORY_COLORS: Record<string, string> = {
  research: "bg-blue-50",
  chat: "bg-amber-50",
  code: "bg-emerald-50",
  image: "bg-pink-50",
  video: "bg-violet-50",
};

function LiveBadge() {
  return (
    <span className="inline-flex items-center gap-1.5 rounded-full border border-zap-bg-alt bg-zap-bg-raised px-2.5 py-1 font-body text-[10px] uppercase tracking-[0.12em] text-zap-live">
      <span className="dot-pulse chain-pulse-dot chain-pulse-dot--static" />
      LIVE
    </span>
  );
}

const AGENT_STATS: Record<string, { requests: string; price: string; delivered: string }> = {
  claude_agent: { requests: "12.4k", price: "$0.10", delivered: "99.4%" },
  chatgpt_agent: { requests: "18.2k", price: "$0.10", delivered: "98.9%" },
  gemini_agent: { requests: "9.1k", price: "$0.10", delivered: "99.1%" },
  perplexity_agent: { requests: "6.3k", price: "$0.10", delivered: "98.7%" },
  grok_agent: { requests: "4.8k", price: "$0.10", delivered: "97.9%" },
  deepseek_agent: { requests: "7.2k", price: "$0.10", delivered: "98.2%" },
  codex_agent: { requests: "5.5k", price: "$0.15", delivered: "99.6%" },
  cursor_agent: { requests: "8.9k", price: "$0.20", delivered: "99.8%" },
  copilot_agent: { requests: "11.3k", price: "$0.15", delivered: "99.3%" },
  midjourney_agent: { requests: "22.1k", price: "$0.50", delivered: "98.5%" },
  sdxl_agent: { requests: "14.7k", price: "$0.20", delivered: "98.1%" },
  flux_agent: { requests: "9.4k", price: "$0.15", delivered: "97.8%" },
  dalle_agent: { requests: "16.8k", price: "$0.30", delivered: "99.0%" },
  logo_agent: { requests: "3.2k", price: "$0.50", delivered: "98.8%" },
  runway_agent: { requests: "2.8k", price: "$0.75", delivered: "97.5%" },
  pika_agent: { requests: "4.1k", price: "$0.50", delivered: "97.2%" },
  sora_agent: { requests: "1.9k", price: "$0.99", delivered: "96.8%" },
  veo_agent: { requests: "2.3k", price: "$0.75", delivered: "97.0%" },
};

function AgentCard({
  name,
  handle,
  provider,
  category,
  imageUrl,
}: {
  name: string;
  handle: string;
  provider: string;
  category: string;
  imageUrl?: string;
}) {
  const stats = AGENT_STATS[handle] ?? { requests: "1.0k", price: "$0.05", delivered: "98.0%" };

  return (
    <article className="flex flex-col overflow-hidden rounded-3xl border-2 border-zap-bg-alt bg-zap-bg-raised transition-all duration-200 hover:border-zap-bg-alt">
      {/* Top row — avatar + name + live */}
      <div className="flex items-center gap-3 px-4 pt-4">
        <div className="relative shrink-0">
          <div className="h-11 w-11 overflow-hidden rounded-full border-2 border-zap-bg-alt bg-zap-bg-tile">
            {imageUrl ? (
              <img src={imageUrl} alt={name} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center">
                <span className="font-body text-[18px] font-semibold  text-base font-bold text-zap-ink-muted">
                  {name.slice(0, 1)}
                </span>
              </div>
            )}
          </div>
          <span className="absolute -right-0 -top-0 h-2.5 w-2.5 rounded-full bg-zap-live ring-2 ring-zap-bg-raised" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="font-body text-[24px] font-semibold leading-tight text-zap-ink truncate">{name}</p>
          <p className="font-body text-[20px] text-zap-ink">{provider}</p>
        </div>
        {/* <span className="shrink-0 font-mono text-[10px] uppercase tracking-widest text-zap-live">Live</span> */}
      </div>

      {/* Divider */}
      {/* <div className="mx-4 mt-3 h-px bg-zap-ink" /> */}

      {/* Stats */}
      <div className="px-4 py-6 flex flex-col gap-1.5">
        <div className="flex items-center gap-1.5">

          {/* <span className="font-body font-body text-[20px] text-zap-ink-muted">
            {stats.requests} requests
          </span> */}
        </div>
        <div className="flex items-center justify-between">
          {/* <span className="font-body text-[18px] uppercase tracking-wide text-zap-ink-faint">
            Starts at
          </span> */}
          <span className="font-body font-body text-[18px]  text-zap-ink">
            <span className="text-zap-accent font-body font-body text-[20px]">⚡   </span>

            <span className="font-body font-body text-[24px] font-semibold text-zap-ink">   {stats.price} </span>
            <span className="font-body text-[20px] text-zap-ink-muted">/ request</span>
          </span>
        </div>
      </div>
    </article>
  );
}


export default function TopCreatorsSection() {
  // const { agents, loading, error } = useOnChainAgents();
  const [activeCategory, setActiveCategory] = useState<string>("research");

  // const filtered = (
  //   activeCategory
  //     ? agents.filter((a) => a.category === activeCategory)
  //     : agents
  // ).slice(0, 10);

  // if (error) return null;

  return (
    <section id="example-creators" className="editorial-section bg-zap-bg">
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="font-display font-bold mx-auto w-full text-[clamp(2rem,9vw,3.5rem)] leading-[1.1] tracking-tight text-zap-ink">
              Agents of all kinds, all kinds!
            </h2>
            <p className="font-body mx-auto w-full max-w-[600px] text-[20px] leading-snug text-zap-ink md:mt-6 md:text-[28px]">
              From research to execution, one request at a time.
            </p>

            {/* Chips */}
            <div className="mt-20 flex flex-wrap justify-center gap-3">
              {CATEGORIES.map(({ label, value, icon }) => (
                <button
                  key={label}
                  type="button"
                  onClick={() => setActiveCategory(value)}
                  className={`inline-flex items-center gap-3 rounded-full px-6 py-1 font-body text-[26px] font-semibold transition-colors duration-150 ${activeCategory === value
                    ? "border-2 border-zap-bg-alt bg-zap-bg-raised text-zap-ink"
                    : "border border-zap-bg-alt bg-zap-bg-tile text-zap-ink hover:border-zap-bg-alt-bright"
                    }`}
                >
                  <span>{icon}</span>
                  {label}
                </button>
              ))}
            </div>
          </div>
        {/* </ScrollReveal> */}

        <p className="text-center mx-auto w-full max-w-[600px] mt-12 font-body text-[20px] italic text-zap-ink-muted">Example agents on Zap402</p>

        {/* Agent cards */}
        {/* <div className="mx-auto mt-12 max-w-5xl">
          {loading ? (
            <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="editorial-skeleton h-72 rounded-3xl" />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <p className="text-center font-body text-sm text-zap-ink-muted">
              No agents in this category yet.
            </p>
          ) : (
            <div className="mt-8">
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {filtered.map((agent) => (
                  <AgentCard
                    key={agent.id}
                    name={agent.name}
                    handle={agent.handle}
                    provider={agent.provider}
                    category={agent.category}
                    imageUrl={agent.imageUrl}
                  />
                ))}
              </div>
            </div>
          )}
        </div> */}
      </div>
    </section>
  );
}