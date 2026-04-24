import React from "react";
import {
  PenSquare,
  Search,
  Code2,
  Image as ImageIcon,
  Megaphone,
  Mic,
  Landmark,
  BrainCircuit,
  MessageSquareQuote,
  Sparkles,
} from "lucide-react";

// import ScrollReveal from "@/components/feedback/ScrollReveal";

const KINDS = [
  { label: "Writing agents", icon: PenSquare },
  { label: "Research agents", icon: Search },
  { label: "Coding agents", icon: Code2 },
  { label: "Image agents", icon: ImageIcon },
  { label: "Marketing agents", icon: Megaphone },
  { label: "Voice agents", icon: Mic },
  { label: "Finance agents", icon: Landmark },
  { label: "Strategy agents", icon: BrainCircuit },
  { label: "Thread agents", icon: MessageSquareQuote },
  { label: "Prompt agents", icon: Sparkles },
] as const;

const CreatorsKindsSection: React.FC = () => {
  return (
    <section
      id="creators"
      className="editorial-section bg-zap-bg"
    >
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="font-display font-semibold pt-8 mt-8 mx-auto w-full max-w-[560px] text-[clamp(2rem,9vw,3.5rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Ecosystem & Partners
            </h2>
            <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[20px] leading-snug text-zap-ink leading-[1] md:mt-8 md:text-[28px]">
              The future of work isn't one AI — it's the right agents, working together, on your terms.
            </p>
          </div>
        {/* </ScrollReveal> */}

        <div className="relative mx-auto mt-14 max-w-6xl">
          <div
            className="pointer-events-none absolute inset-0 -z-10 rounded-[28px] border border-zap-bg-alt opacity-60"
            aria-hidden
          />
          <div
            className="pointer-events-none absolute left-1/2 top-1/2 -z-10 h-[72%] w-[72%] -translate-x-1/2 -translate-y-1/2 rounded-full bg-zap-brand-dim blur-3xl"
            aria-hidden
          />
          <div className="grid grid-cols-1 gap-3 p-3 sm:grid-cols-2 lg:grid-cols-5">
            {KINDS.map(({ label, icon: Icon }) => {
              const [title, kind] = label.split(" ");
              return (
                <div className="relative mx-auto max-w-2xl">
                {/* Back container — dotted pattern, offset bottom-right */}
                <div
                  className="absolute inset-0 translate-x-2 translate-y-2 rounded-2xl border-2 border-zap-bg-alt"
                  style={{
                    backgroundImage: "radial-gradient(var(--color-ink) 1px, transparent 1px)",
                    backgroundSize: "4px 4px",
                  }}
                />
              
                {/* Front container — solid white card */}
                <article
                  key={label}
                  className="group relative overflow-hidden rounded-2xl border-2 border-zap-bg-alt bg-zap-bg-raised px-4 py-5 transition-all duration-200"
                >
                  <div
                    className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-200 group-hover:opacity-100"
                    aria-hidden
                    style={{
                      background: "linear-gradient(135deg, var(--color-brand-dim), transparent 45%)",
                    }}
                  />
                  <span className="relative items-center justify-center rounded-lg bg-zap-bg-alt text-zap-brand">
                    <Icon size={32} />
                  </span>
                  <h3  className="font-body pt-6 mt-6 w-full max-w-[600px] text-[20px] leading-snug text-zap-ink leading-[1] md:mt-8 md:text-[32px]">
           
                    {title} {kind}
                  </h3>
                  {/* <p className="relative mt-2 font-body text-[10px] uppercase tracking-[0.16em] text-zap-ink-faint">
                    AI MODULE
                  </p>
                  <p className="relative mt-1 font-body text-[10px] text-zap-ink-faint">
                    on Zap402
                  </p> */}
                </article>
              </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
};

export default CreatorsKindsSection;
