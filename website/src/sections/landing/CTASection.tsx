import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";


const CTASection: React.FC = () => {
  const [totalCreators, setTotalCreators] = useState<number>(4);

  useEffect(() => {
    // getStats()
    //   .then((stats) => setTotalCreators(Math.max(4, stats.totalCreators)))
    //   .catch(() => { });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const scrollToThreeWays = () => {
    document.getElementById("three-ways")?.scrollIntoView({ behavior: "smooth" });
  };

  // const openWalletConnect = useOpenWalletConnect();

  return (
    <section className="editorial-section bg-zap-bg-alt">
      <div className="editorial-container relative flex flex-col items-center justify-center text-center">
        {/* <ScrollReveal> */}
          {/* Background Glow */}
          <div
            className="pointer-events-none absolute left-1/2 top-1/2 -z-10 h-[75%] w-[75%] -translate-x-1/2 -translate-y-1/2 rounded-full bg-zap-brand-dim blur-3xl"
            aria-hidden
          />

          {/* Heading */}
          <h2 className="font-display font-bold mx-auto text-[clamp(2rem,9vw,3.5rem)] leading-[1.1] tracking-tight text-zap-ink">
            All your fast
            <br />
            growing business needs
          </h2>

          {/* Button */}
          {/* <button
            type="button"
            onClick={() => openWalletConnect()}
            className="btn-primary mt-10 inline-flex min-w-[200px] items-center justify-center text-center normal-case tracking-normal sm:w-auto !rounded-8xl !py-5 !text-lg"
          >
            Get started
          </button> */}
        {/* </ScrollReveal> */}
      </div>
    </section>
  );
};

export default CTASection;
