import React, { useState } from "react";

type FaqItem = { q: string; a: React.ReactNode };

const FAQS: FaqItem[] = [
  {
    q: "What is DayFi?",
    a: (
      <>
        DayFi is a business finance app built for Nigerian SMEs, freelancers, and merchants.
        You can send and receive money, create invoices, run a merchant store with QR and NFC
        checkout, and track all your expenses — in one app.
      </>
    ),
  },
  {
    q: "What currencies does DayFi support?",
    a: (
      <>
        DayFi supports both <span className="font-semibold text-zap-ink">Naira (NGN)</span> and{" "}
        <span className="font-semibold text-zap-ink">USDC</span>. You can invoice clients in
        dollars, collect payments in naira, and swap between both — all inside the app.
      </>
    ),
  },
  {
    q: "How does the merchant checkout work?",
    a: (
      <>
        Add your products, set prices in USDC or Naira, and generate a QR code or enable NFC
        tap-to-pay. Your customer scans or taps, payment settles instantly. No POS terminal,
        no third-party app required.
      </>
    ),
  },
  {
    q: "How does invoicing work?",
    a: (
      <>
        Create a professional invoice in under two minutes — add line items, set a due date,
        and choose Naira or USDC. Share the payment link directly on WhatsApp or email.
        DayFi notifies you the moment your client pays.
      </>
    ),
  },
  {
    q: "How does DayFi track my expenses?",
    a: (
      <>
        DayFi automatically classifies every transaction using Nigerian-specific intelligence.
        It recognises OPay, Kuda, PalmPay, and other local wallets — and correctly identifies
        wallet-to-wallet transfers so they don't inflate your spending numbers.
      </>
    ),
  },
  {
    q: "Is DayFi secure?",
    a: (
      <>
        Yes. DayFi uses end-to-end encryption, biometric authentication, and is compliant with
        NDPR. Your financial data and wallet are protected at every layer.
      </>
    ),
  },
];

const FAQSection: React.FC = () => {
  const [open, setOpen] = useState<number | null>(0);

  return (
    <section id="faq" className="editorial-section bg-[#F9FAFB]">
      <div className="editorial-container max-w-3xl">

        <div className="text-center mb-12">
          <p className="font-body text-[14px] uppercase tracking-widest text-green-600 font-semibold mb-4">
            FAQ
          </p>
          <h2 className="font-display text-[clamp(1.75rem,5vw,2.5rem)] font-bold leading-tight tracking-tight text-zinc-900">
            Common questions
          </h2>
        </div>

        <ul className="space-y-2">
          {FAQS.map((item, i) => {
            const isOpen = open === i;
            return (
              <li
                key={item.q}
                className={`rounded-2xl border transition-colors duration-300 overflow-hidden ${
                  isOpen
                    ? "border-zinc-200 bg-white"
                    : "border-zinc-100 bg-white hover:border-zinc-200"
                }`}
              >
                <button
                  type="button"
                  className="flex w-full items-center justify-between gap-4 px-6 py-5 text-left"
                  onClick={() => setOpen(isOpen ? null : i)}
                  aria-expanded={isOpen}
                >
                  <span
                    className={`font-body text-[16px] font-semibold transition-colors duration-200 ${
                      isOpen ? "text-zinc-900" : "text-zinc-700"
                    }`}
                  >
                    {item.q}
                  </span>

                  {/* Animated +/− pill */}
                  <span
                    className={`shrink-0 w-7 h-7 rounded-full flex items-center justify-center transition-all duration-300 ${
                      isOpen
                        ? "bg-zinc-900 text-white rotate-45"
                        : "bg-zinc-100 text-zinc-500"
                    }`}
                    aria-hidden
                  >
                    <svg
                      width="12"
                      height="12"
                      viewBox="0 0 12 12"
                      fill="none"
                      xmlns="http://www.w3.org/2000/svg"
                    >
                      <path
                        d="M6 1V11M1 6H11"
                        stroke="currentColor"
                        strokeWidth="1.8"
                        strokeLinecap="round"
                      />
                    </svg>
                  </span>
                </button>

                {/* Smooth animated reveal */}
                <div
                  className={`grid transition-all duration-300 ease-in-out ${
                    isOpen ? "grid-rows-[1fr]" : "grid-rows-[0fr]"
                  }`}
                >
                  <div className="overflow-hidden">
                    <p
                      className={`px-6 pb-5 font-body text-[15px] leading-relaxed text-zinc-500 transition-opacity duration-300 ${
                        isOpen ? "opacity-100" : "opacity-0"
                      }`}
                    >
                      {item.a}
                    </p>
                  </div>
                </div>
              </li>
            );
          })}
        </ul>

      </div>
    </section>
  );
};

export default FAQSection;