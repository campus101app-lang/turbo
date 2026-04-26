import React from "react";

const whyFeatures = [
  {
    title: "Intelligent assistant",
    description: "We are a natural extension of your team, automating tedious tasks and delivering thoughtful suggestions—all with you in control.",
    icon: "✨",
    bgColor: "bg-[#F0FDF4]",
    iconBg: "bg-green-100",
    large: true,
  },
  {
    title: "Completely customizable",
    description: "Customize Bujeti for your business with policies, roles, and approval workflows.",
    icon: "🎛️",
    bgColor: "bg-white",
    iconBg: "bg-orange-50",
  },
  {
    title: "Works globally",
    description: "Send international payments and reimburse employees in local currencies in 5 seconds.",
    icon: "🌍",
    bgColor: "bg-white",
    iconBg: "bg-blue-50",
  },
  {
    title: "Dedicated support",
    description: "Personalised support and guaranteed 3-minute response ensure your success.",
    icon: "💬",
    bgColor: "bg-white",
    iconBg: "bg-purple-50",
  },
  {
    title: "Unrivalled security",
    description: "Bujeti provides top-tier, bank-level security, compliant with GDPR and NDPR.",
    icon: "🔒",
    bgColor: "bg-white",
    iconBg: "bg-red-50",
  },
];

const MissionSection: React.FC = () => {
  return (
    <section id="mission" className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] text-[#4ADE80] uppercase tracking-widest font-semibold opacity-100 text-green-800">
            Why Bujeti?
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight md:mt-0">
            Africa's leading finance management solution
          </h2>
        </div>

        {/* Grid Layout */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-start">

          {/* Column 1: Main Large Card */}
          <div className="flex flex-col justify-between rounded-3xl bg-[#E8F3ED] p-10 border border-zinc-100 min-h-[500px]">
            <div>
              <div className="w-12 h-12 rounded-xl bg-green-100 flex items-center justify-center text-xl mb-8">
                {whyFeatures[0].icon}
              </div>
              <h3 className="font-display text-[24px] font-bold text-zinc-900 mb-4">
                {whyFeatures[0].title}
              </h3>
              <p className="font-body text-[16px] leading-relaxed text-zinc-600">
                {whyFeatures[0].description}
              </p>
            </div>
            <button className="mt-12 w-fit px-6 py-2 rounded-full bg-zinc-900 text-white font-body text-[14px] hover:bg-zinc-800 transition-colors">
              Try for free
            </button>
          </div>

          {/* Column 2: Two Stacked Cards */}
          <div className="flex flex-col gap-6">
            {whyFeatures.slice(1, 3).map((feature, idx) => (
              <div key={idx} className="rounded-3xl bg-white p-8 border border-zinc-100 shadow-sm">
                <div className={`w-10 h-10 rounded-lg ${feature.iconBg} flex items-center justify-center text-lg mb-6`}>
                  {feature.icon}
                </div>
                <h3 className="font-display text-[20px] font-bold text-zinc-900 mb-3">{feature.title}</h3>
                <p className="font-body text-[15px] leading-relaxed text-zinc-500">{feature.description}</p>
              </div>
            ))}
          </div>

          {/* Column 3: Two Stacked Cards */}
          <div className="flex flex-col gap-6">
            {whyFeatures.slice(3, 5).map((feature, idx) => (
              <div key={idx} className="rounded-3xl bg-white p-8 border border-zinc-100 shadow-sm">
                <div className={`w-10 h-10 rounded-lg ${feature.iconBg} flex items-center justify-center text-lg mb-6`}>
                  {feature.icon}
                </div>
                <h3 className="font-display text-[20px] font-bold text-zinc-900 mb-3">{feature.title}</h3>
                <p className="font-body text-[15px] leading-relaxed text-zinc-500">{feature.description}</p>
              </div>
            ))}
          </div>

        </div>
      </div>
    </section>
  );
};

export default MissionSection;
