import React, { useEffect, useRef, useState } from "react";
import { motion } from "framer-motion";
import { useNavigate } from "react-router-dom";
import { Link } from "react-router-dom";


const stagger = 0.06;
const fadeUp = {
  initial: { opacity: 0, y: 8 },
  animate: { opacity: 1, y: 0 },
};

const BIOS = [
  "Building in public. Sharing the journey one post at a time.",
  "Creator on Zap402. Here to connect, share, and get supported.",
  "Making things worth supporting. Appreciate every tip.",
  "Independent creator. Fuelled by curiosity and community.",
  "Shipping ideas, stories, and experiments. Support welcome.",
  "On-chain creator. Every contribution keeps the work going.",
  "Creating freely. Supported by people who get it.",
  "New to Zap402. Still figuring it out — come along for the ride.",
];

function generateUsername(publicKey: string): string {
  const segment = (publicKey.slice(2, 6) + publicKey.slice(-6)).toLowerCase();
  return `user_${segment}`;
}
function generateDisplayName(publicKey: string): string {
  return `User ${publicKey.slice(-4).toUpperCase()}`;
}
function generateBio(): string {
  return BIOS[Math.floor(Math.random() * BIOS.length)];
}

const HeroSection: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const hasFired = useRef(false);

  return (
    <section
      id="hero"
      className="editorial-section bg-white overflow-hidden px-0 py-16"
    >
      <div className="editorial-container mx-auto w-full max-w-[900px] px-4">
        <div className="flex flex-col md:flex-row items-center gap-10 md:gap-12">

          {/* Text + CTA */}
          <div className="flex flex-col items-center text-center flex-1 min-w-0">
            <img src="img/hero_logo.png" alt="" className="w-44 h-44 object-contain" />
            <motion.p
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 3 }}
              className="font-body w-full mb-5 text-[16px] leading-snug text-zap-ink md:text-[20px]"
            >

            </motion.p>
            <motion.h1
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 2 }}
              className="font-display font-bold w-full text-[clamp(3.8rem,7vw,4.5rem)] leading-[.95] tracking-tight text-zap-faint"
            >
              Built for <span className="italic">Nigerian businesses</span> that move fast.
            </motion.h1>

            <motion.p
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 3 }}
              className="font-body mt-5 w-full text-[18px] leading-snug text-zap-ink-muted md:text-[22px]"
            >
              Send money, get paid, run your store, and track every kobo — all in one place.</motion.p>
            <motion.div
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 4 }}
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


          {/* Hero image */}
          {/* <motion.img
            {...fadeUp}
            transition={{ duration: 0.55, delay: stagger * 5 }}
            src="/img/hero.webp"
            alt="Hero illustration"
            className="w-full md:w-[46%] shrink-0 rounded-2xl"
          /> */}

        </div>
      </div>
    </section>
  );
};

export default HeroSection;