import React from "react";
// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useOpenWalletConnect } from "@/components/wallet/WalletConnectModal";

/**
 * Ko-fi–style "Payday your way" block with Zap402 / x402 + Stellar positioning.
 */
const PaydaySection: React.FC = () => {
  // const openWalletConnect = useOpenWalletConnect();

  return (
    <section id="payday" className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container">
        {/* <ScrollReveal> */}
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="font-display font-bold mx-auto w-full text-[clamp(2rem,9vw,3.5rem)] leading-[1.1] tracking-tight text-zap-ink">
              Why now?
            </h2>
            <p className="font-body mx-auto w-full max-w-[720px] text-[20px] leading-snug text-zap-ink-muted md:mt-6 md:text-[28px]">
              AI can deliver value in seconds. Payments should be just as fast.
              Zap402 connects AI execution to internet-native payments with{" "}
              <span className="font-semibold text-zap-ink">USDC</span> on Stellar and{" "}
              <span className="font-semibold text-zap-ink">x402</span>-style flows.
            </p>
            {/* <button
              type="button"
              onClick={() => openWalletConnect()}
              className="btn-primary mt-10 inline-flex w-full min-w-[200px] font-body justify-center text-center normal-case tracking-normal sm:w-auto !rounded-8xl !py-5 !text-lg"
            >
              Get started
            </button> */}
          </div>
        {/* </ScrollReveal> */}
      </div>
    </section>
  );
};

export default PaydaySection;
