import { motion } from "framer-motion";
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
    <section className="editorial-section bg-[#F9FAFB]">
      <div className="editorial-container relative flex flex-col items-center justify-center text-center">
        {/* <ScrollReveal> */}
        {/* Background Glow */}
        <div
          className="pointer-events-none absolute left-1/2 top-1/2 -z-10 h-[75%] w-[75%] -translate-x-1/2 -translate-y-1/2 rounded-full bg-zap-brand-dim blur-3xl"
          aria-hidden
        />

        {/* Heading */}
        <h2 className="font-display font-bold mx-auto text-[clamp(2rem,9vw,3.5rem)] leading-[1.1] tracking-tight text-zap-ink">
          One app for
          <br />
          your entire business
        </h2>
        <motion.div
          className="mt-8"
        >
          <div className="flex flex-col sm:flex-row items-center gap-3">
            {/* Internal link using Link from react-router-dom */}
            <Link
              to="/signup"
              className="inline-flex min-w-[180px] items-center justify-center font-body text-[15px] font-semibold bg-zap-ink text-white px-6 py-3 rounded-full hover:opacity-90 transition-opacity"
            >
              Get started free
            </Link>

            {/* Anchor link for page sections */}
            <a
              href="#features"
              className="inline-flex min-w-[180px] items-center justify-center font-body text-[15px] font-semibold text-zap-ink border border-zap-ink/20 px-6 py-3 rounded-full hover:border-zap-ink/40 transition-colors"
            >
              See all features
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default CTASection;
