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
  Icon,
} from "lucide-react";

// import ScrollReveal from "@/components/feedback/ScrollReveal";

const KINDS = [
  { label: "Expense management", description: "Organise transactions and enforce policies", image: "/images/expense.jpg" },
  { label: "Corporate cards", description: "Flexible multi-currency cards for your teams", image: "/images/cards.jpg" },
  { label: "Payments automation", description: "Efficient payments with approval rules", image: "/images/payments.jpg" },
  { label: "Bank connect", description: "Connect and manage bank accounts", image: "/images/bank.jpg" },
  { label: "Invoicing", description: "Create and send invoices in minutes", image: "/images/invoicing.jpg" },
  { label: "Tax Management", description: "Configure taxes once, apply everywhere", image: "/images/tax.jpg" },
  { label: "Payroll", description: "Automated and intelligent payroll", image: "/images/payroll.jpg" },
  { label: "Inventory management", description: "Track products and company assets", image: "/images/inventory.jpg" },

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
          <p className="font-body text-[14px] uppercase tracking-widest text-zap-ink font-semibold opacity-100 text-green-800">
             Products
          </p> 
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            One platform,{" "}<span className="italic">more control</span>{" "}and complete visibility
          </h2>
          {/* <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[20px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[28px]">
            One platform, more control and complete visibility
          </p> */}
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
          <div className="grid grid-cols-1 gap-4 p-4 sm:grid-cols-4 lg:grid-cols-4">

            {KINDS.map(({ label, description, image }) => {
              return (
                <div key={label} className="relative w-full"> {/* Changed mx-auto max-w-2xl to w-full */}
                  {/* Back container */}
                  <div
                    className="absolute inset-0 translate-x-2 translate-y-2 rounded-2xl border-2 border-zap-bg-alt"
                    style={{
                      backgroundImage: "radial-gradient(var(--color-ink) 1px, transparent 1px)",
                      backgroundSize: "4px 4px",
                    }}
                  />

                  {/* Front container */}
                  <article className="relative flex flex-col h-full overflow-hidden rounded-2xl border-2 border-zap-bg-alt bg-zap-bg-raised transition-all duration-200">

                    {/* Image Section (Take up ~2/3 of visual weight) */}
                    <div className="relative h-48 w-full overflow-hidden bg-zap-bg-alt">
                      <img
                        src={image}
                        alt={label}
                        className="h-full w-full object-cover transition-transform duration-500 group-hover:scale-110"
                      />
                      {/* Gradient Overlay for style */}
                      <div className="absolute inset-0 bg-gradient-to-t from-zap-bg-raised/20 to-transparent" />
                    </div>


                    <div className="flex flex-col pl-6 pr-4 pb-4">
                      {/* Title: Removed max-width and fixed height triggers */}
                      <h3 className="relative font-display font-bold mt-8 text-[20px] text-zap-ink">
                        {label}
                      </h3>

                      {/* Description: Added this back in correctly */}
                      <p className="relative font-body text-[16px] leading-[1.25] mt-2 text-zap-ink opacity-80">
                        {description}
                      </p></div>
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
