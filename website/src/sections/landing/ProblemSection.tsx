import React from "react";
import CheckIcon from "@/assets/checks.svg";
import ArrowBadge from "@/assets/arrow-badge-right.svg";

const timelineSteps = [
  {
    day: "Day 1",
    subtitle: "You're live in minutes",
    features: [
      "Sign up and verify your business",
      "Connect your existing bank accounts",
      "Send your first invoice or payment link",
      "Set up your merchant store",
    ],
  },
  {
    day: "Day 7",
    subtitle: "Money is moving",
    features: [
      "Accept Naira and USDC payments",
      "Track expenses automatically",
      "Share QR or NFC checkout with customers",
      "See your cashflow in real time",
    ],
  },
  {
    day: "Day 30",
    subtitle: "You're in full control",
    features: [
      "Invoices paid, inventory tracked, store running",
      "Know exactly where every kobo went",
      "Get paid by foreign clients in USDC",
      "Your entire business finance, one app",
    ],
  },
];

const ProblemSection: React.FC = () => {
  return (
    <section id="problem" className="editorial-section border-y border-zinc-100 bg-[#F9FAFB] py-24">
      <div className="editorial-container px-6">
        {/* Header */}
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] uppercase tracking-widest text-green-600 font-semibold opacity-100 text-green-600">
            DayFi in 30 days
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            From sign up to <span className="italic text-green-600">fully running</span>
          </h2>
        </div>

        {/* Timeline Grid */}
        <div className="relative flex flex-col gap-2 md:flex-row md:items-stretch">
          {timelineSteps.map((step, index) => (
            <div key={step.day} className="relative flex flex-1 flex-col">
              {/* Step Card */}
              <div className="flex h-full flex-col rounded-3xl border border-zinc-200 bg-white p-7 transition-all duration-300 hover:z-10 hover:shadow-xl">
                <h3 className="font-display text-[32px] text-zinc-900 font-normal mb-6">
                  {step.day}
                </h3>

                <p className="font-body text-[18px] font-semibold text-zinc-900 mb-6">
                  {step.subtitle}
                </p>
                <ul className="space-y-2">
                  {step.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-3">                      <img
                      src={CheckIcon}
                      alt="check"
                      className="mt-1 w-5 h-5 flex-shrink-0"
                    />
                      <span className="font-body text-[14px] text-zinc-600">{feature}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Arrow Connector (only between cards on desktop) */}
              {index < timelineSteps.length - 1 && (
                <div className="hidden md:flex absolute top-1/2 -right-5 z-20 -translate-y-1/2 items-center justify-center">
                  <div className="rounded-full bg-white border border-zinc-200 p-0.5 shadow-sm"> {/* Reduced p-1 to p-0.5 */}  <img
                    src={ArrowBadge}
                    alt="next"
                    className="w-6 h-6 opacity-50" />
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default ProblemSection;