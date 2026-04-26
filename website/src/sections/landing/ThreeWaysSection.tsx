import React from "react";

const businessStages = [
  {
    title: "Startups",
    description: "Take control of your finance with real-time expense tracking.",
    image: "/img/rocket.svg",
  },
  {
    title: "Mid-sized Businesses",
    description: "Scale operations with advanced automation and team controls.",
    image: "/img/shop.svg",
  },
  {
    title: "Large Businesses",
    description: "Complex workflows simplified with custom integrations.",
    image: "/img/building-small.svg",
  },
  {
    title: "Enterprises",
    description: "Maximum security and dedicated support for global scale.",
    image: "/img/building-large.svg",
  },
];


const ThreeWaysSection: React.FC = () => {
  return (
    <section id="three-ways" className="editorial-section bg-white py-24">
      <div className="editorial-container px-6">
        {/* Header */}
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] uppercase tracking-widest text-zap-ink font-semibold opacity-100 text-green-800">
            Solutions
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Built for businesses <span className="italic">at every stage</span>
          </h2>
          <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[20px]">
            Dayfy scales with your business through real-time control, automations, integrations, and customization.
          </p>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {businessStages.map((stage) => (
            <div key={stage.title} className="group cursor-pointer">
              {/* Image Container */}
              <div className="aspect-square w-full overflow-hidden rounded-2xl bg-zinc-50 p-12 transition-colors duration-300 group-hover:bg-zinc-100">
                <img
                  src={stage.image}
                  alt={stage.title}
                  className="h-full w-full object-contain transition-transform duration-500 group-hover:scale-110"
                />
              </div>

              {/* Text Content */}
              <div className="mt-6">
                <h3 className="font-display text-[20px] font-bold text-zinc-900">
                  {stage.title}
                </h3>

                {/* Reveal Container */}
                <div className="grid transition-all duration-300 ease-in-out grid-rows-[0fr] group-hover:grid-rows-[1fr]">
                  <div className="overflow-hidden">
                    <p className="font-body mt-2 text-[15px] leading-relaxed text-zinc-500 opacity-0 transition-opacity duration-300 group-hover:opacity-100">
                      {stage.description}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default ThreeWaysSection;
