import React from "react";

// import ScrollReveal from "@/components/feedback/ScrollReveal";

const columns = ["\u00A0", "PATREON", "KO-FI", "ZAP402"] as const;

const rows: { feature: string; values: [string, string, string] }[] = [
  {
    feature: "AI_NATIVE",
    values: ["❌", "❌", "✅"],
  },
  {
    feature: "PER_REQUEST",
    values: ["❌", "⚠", "✅"],
  },
  {
    feature: "INSTANT_USDC",
    values: ["❌", "❌", "✅"],
  },
  {
    feature: "WALLET_NATIVE",
    values: ["❌", "❌", "✅"],
  },
  {
    feature: "X402_COMPATIBLE",
    values: ["❌", "❌", "✅"],
  },
];

const ComparisonSection: React.FC = () => {
  return (
    <section id="comparison" className="editorial-section bg-zap-bg">
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <p className="text-label-caps text-label-caps--accent mb-4 text-center">// COMPETITIVE_ANALYSIS</p>
          <div className="mx-auto max-w-4xl text-center">
            <h2 className="font-body text-[clamp(2.5rem,6vw,4.5rem)] font-normal leading-[0.95] text-zap-ink">
              Legacy subscriptions
              <br />
              vs pay-per-agent
            </h2>
          </div>
        {/* </ScrollReveal> */}

        <div className="mt-12">
          <div className="card-editorial overflow-hidden p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[560px] border-collapse text-left font-body text-[14px] leading-relaxed text-zap-ink">
                <thead>
                  <tr className="border-b border-zap-bg-alt">
                    {columns.map((col, i) => (
                      <th
                        key={col}
                        className={`px-4 py-4 font-mono text-[11px] font-normal uppercase tracking-[0.08em] first:pl-6 last:pr-6 ${
                          i === 3
                            ? "bg-zap-brand-dim text-zap-brand"
                            : "bg-zap-bg-alt text-zap-ink-muted"
                        }`}
                      >
                        {col}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row) => (
                    <tr key={row.feature} className="border-b border-zap-bg-alt last:border-0">
                      <td className="px-6 py-4 font-mono text-[12px] font-medium text-zap-ink">
                        {row.feature}
                      </td>
                      {row.values.map((val, ci) => {
                        const isZap = ci === 3;
                        return (
                          <td
                            key={ci}
                            className={`px-4 py-4 align-middle font-mono text-[12px] ${
                              isZap
                                ? "bg-zap-brand-dim/50 font-medium text-zap-ink"
                                : "bg-zap-surface text-zap-ink-muted"
                            }`}
                          >
                            {val}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default ComparisonSection;
