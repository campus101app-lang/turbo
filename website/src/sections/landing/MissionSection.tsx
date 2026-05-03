import React from "react";
import { Link } from "react-router-dom";

const whyFeatures = [
  {
    title: "Nigerian-first intelligence",
    description: "DayFi understands how money moves in Nigeria — OPay, Kuda, PalmPay, GTBank. We classify your transactions automatically so you never have to.",
    icon: "🇳🇬",
    bgColor: "bg-[#F0FDF4]",
    iconBg: "bg-green-100",
    large: true,
  },
  {
    title: "Naira and USDC",
    description: "Accept payments and send money in both naira and USDC. No extra apps, no conversion headaches.",
    icon: "💸",
    bgColor: "bg-white",
    iconBg: "bg-orange-50",
  },
  {
    title: "Works everywhere",
    description: "Bill foreign clients in dollars, collect locally in naira. DayFi bridges both worlds seamlessly.",
    icon: "🌍",
    bgColor: "bg-white",
    iconBg: "bg-blue-50",
  },
  {
    title: "No POS needed",
    description: "Accept payments in your store with QR codes or NFC tap. Your phone is your terminal.",
    icon: "📲",
    bgColor: "bg-white",
    iconBg: "bg-purple-50",
  },
  {
    title: "Bank-grade security",
    description: "Your money and data are protected with end-to-end encryption, biometric auth, and NDPR compliance.",
    icon: "🔒",
    bgColor: "bg-white",
    iconBg: "bg-red-50",
  },
];
const MissionSection: React.FC = () => {
  return (
    <section id="why-dayfi" className="editorial-section bg-[#F9FAFB]">
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] text-green-600 uppercase tracking-widest font-semibold opacity-100 text-green-600">
            Why DayFi?
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight md:mt-0">
            Built for Nigeria. <span className="italic text-green-600">Ready for the world.</span>
          </h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">

          {/* Column 1 — single tall card */}
          <div className="group cursor-pointer rounded-2xl p-8 border border-zinc-100 bg-[#E8F3ED] flex flex-col justify-between min-h-[420px] transition-colors duration-300 hover:bg-[#daeee4]">
            <div>
              <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center text-lg mb-6 transition-transform duration-500 group-hover:scale-110">
                {whyFeatures[0].icon}
              </div>
              <h3 className="font-display text-[20px] font-bold text-zinc-900 mb-3">
                {whyFeatures[0].title}
              </h3>

              {/* Reveal Container */}
              <div className="grid transition-all duration-300 ease-in-out grid-rows-[1fr] group-hover:grid-rows-[1fr]">
                <div className="overflow-hidden">
                  <p className="font-body text-[15px] leading-relaxed text-zinc-500 opacity-100 transition-opacity duration-300 group-hover:opacity-100 mt-2">
                    {whyFeatures[0].description}
                  </p>
                </div>
              </div>
            </div>

            <Link
              to="/signup"
              className="mt-8 w-fit inline-flex items-center justify-center font-body text-[13px] font-semibold text-zap-ink border border-zap-ink/20 px-5 py-2 rounded-full hover:border-zap-ink/40 transition-colors"
            >
              Try for free →
            </Link>
          </div>

          {/* Column 2 — two stacked */}
          <div className="flex flex-col gap-4">
            {whyFeatures.slice(1, 3).map((feature, idx) => (
              <div key={idx} className="group cursor-pointer rounded-2xl p-7 border border-zinc-100 bg-white transition-colors duration-300 hover:bg-zinc-50 flex-1">
                <div className={`w-10 h-10 rounded-xl ${feature.iconBg} flex items-center justify-center text-lg mb-5 transition-transform duration-500 group-hover:scale-110`}>
                  {feature.icon}
                </div>
                <h3 className="font-display text-[18px] font-bold text-zinc-900 mb-2 leading-snug">
                  {feature.title}
                </h3>

                {/* Reveal Container */}
                <div className="grid transition-all duration-300 ease-in-out grid-rows-[1fr] group-hover:grid-rows-[1fr]">
                  <div className="overflow-hidden">
                    <p className="font-body text-[14px] leading-relaxed text-zinc-500 opacity-100 transition-opacity duration-300 group-hover:opacity-100 mt-2">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Column 3 — two stacked */}
          <div className="flex flex-col gap-4">
            {whyFeatures.slice(3, 5).map((feature, idx) => (
              <div key={idx} className="group cursor-pointer rounded-2xl p-7 border border-zinc-100 bg-white transition-colors duration-300 hover:bg-zinc-50 flex-1">
                <div className={`w-10 h-10 rounded-xl ${feature.iconBg} flex items-center justify-center text-lg mb-5 transition-transform duration-500 group-hover:scale-110`}>
                  {feature.icon}
                </div>
                <h3 className="font-display text-[18px] font-bold text-zinc-900 mb-2 leading-snug">
                  {feature.title}
                </h3>

                {/* Reveal Container */}
                <div className="grid transition-all duration-300 ease-in-out grid-rows-[1fr] group-hover:grid-rows-[1fr]">
                  <div className="overflow-hidden">
                    <p className="font-body text-[14px] leading-relaxed text-zinc-500 opacity-100 transition-opacity duration-300 group-hover:opacity-100 mt-2">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>

        </div>

      </div>
    </section>
  );
};

export default MissionSection;
