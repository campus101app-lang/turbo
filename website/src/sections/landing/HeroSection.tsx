import React, { useEffect, useRef, useState } from "react";
import { motion } from "framer-motion";
import { useNavigate } from "react-router-dom";

// import { useOpenWalletConnect } from "@/components/wallet/WalletConnectModal";
// import { useWallet } from "@/hooks";
// import { useContract } from "@/hooks";
// import { useProfileStore } from "@/state/profileStore";
// import { useWalletStore } from "@/state/walletStore";
// import { useToastStore } from "@/state/toastStore";
// import { useInteractionHistoryStore } from "@/state/interactionHistoryStore";
// import { ProfileFormData } from "@/types/profile";
// import { TERMINAL_DEFAULT_PATH } from "@/constants/terminalNav";
// import {
//   ERRORS,
//   formatUserFacingContractError,
//   isAlreadyRegisteredContractError,
//   isLikelyNetworkError,
// } from "@/utils/error";

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
  // const { connected } = useWallet();
  // const publicKey = useWalletStore((s) => s.publicKey);
  // const openWalletConnect = useOpenWalletConnect();
  // const isRegistered = useProfileStore((s) => s.isRegistered);
  // const { registerProfile } = useContract();
  // const { addToast } = useToastStore();

  const [loading, setLoading] = useState(false);
  const hasFired = useRef(false);

  // If already registered and wallet connects, go straight to dashboard
  // useEffect(() => {
  //   if (connected && isRegistered) {
  //     navigate(TERMINAL_DEFAULT_PATH, { replace: true });
  //   }
  // }, [connected, isRegistered, navigate]);

  // Auto-register once wallet connects (not yet registered)
  // useEffect(() => {
  //   if (!connected || !publicKey || isRegistered || hasFired.current) return;
  //   hasFired.current = true;

  //   const run = async () => {
  //    Promise.resolve().then(() => setLoading(true));
  //     const data: ProfileFormData = {
  //       username: generateUsername(publicKey),
  //       displayName: generateDisplayName(publicKey),
  //       bio: generateBio(),
  //       imageUrl: "",
  //       xHandle: "",
  //       instagramUrl: "",
  //       tiktokUrl: "",
  //       youtubeUrl: "",
  //     };

  //     try {
  //       await registerProfile(data);
  //       addToast({
  //         message: "You're live — welcome to Zap402.",
  //         type: "success",
  //         duration: 4000,
  //       });
  //       navigate(TERMINAL_DEFAULT_PATH, { replace: true });
  //     } catch (err) {
  //       hasFired.current = false;
  //       setLoading(false);

  //       if (isAlreadyRegisteredContractError(err)) {
  //         useInteractionHistoryStore.getState().setActiveJourneyId(null);
  //         navigate(TERMINAL_DEFAULT_PATH, { replace: true });
  //         return;
  //       }
  //       if (isLikelyNetworkError(err)) {
  //         addToast({ message: ERRORS.NETWORK, type: "error", duration: 5000 });
  //         return;
  //       }
  //       const msg = formatUserFacingContractError(err);
  //       const lower = msg.toLowerCase();
  //       if (
  //         lower.includes("reject") ||
  //         lower.includes("denied") ||
  //         lower.includes("cancel") ||
  //         lower.includes("user declined")
  //       ) {
  //         addToast({
  //           message: "Signature declined — try again when ready.",
  //           type: "error",
  //           duration: 4000,
  //         });
  //       } else {
  //         addToast({ message: msg, type: "error", duration: 5000 });
  //       }
  //     }
  //   };

  //   void run();
  // }, [connected, publicKey, isRegistered]);

  // const handleCta = () => {
  //   if (connected && isRegistered) {
  //     navigate(TERMINAL_DEFAULT_PATH);
  //   } else {
  //     openWalletConnect();
  //   }
  // };

  // const ctaLabel = loading
  //   ? "Setting up…"
  //   : connected && isRegistered
  //   ? "Go to dashboard"
  //   : "Get started";

  return (
    <section
      id="hero"
      className="editorial-section overflow-hidden px-0 py-16"
    >
      <div className="editorial-container mx-auto w-full max-w-[1200px] px-4">
        <div className="flex flex-col md:flex-row items-center gap-10 md:gap-24">

          {/* Text + CTA */}
          <div className="flex flex-col items-center text-center flex-1 min-w-0">
            <img src="public/img/hero_logo.png" alt="" className="w-44 h-44 object-contain" />
            <motion.p
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 3 }}
              className="font-body w-full mb-5 text-[16px] leading-snug text-zap-ink md:text-[20px]"
            >
              Grow your business
            </motion.p>
            <motion.h1
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 2 }}
              className="font-display font-bold w-full text-[clamp(3.8rem,7vw,4.5rem)] leading-[.95] tracking-tight text-zap-faint"
            >
              For fast moving businesses
            </motion.h1>

            <motion.p
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 3 }}
              className="font-body mt-5 w-full text-[18px] leading-snug text-zap-ink-muted md:text-[22px]"
            >
              A wallet built for real business: your wealth, remittances, and everyday transfers. Simple, powerful, yours. </motion.p>
    
            <motion.div
              {...fadeUp}
              transition={{ duration: 0.45, delay: stagger * 4 }}
              className="mt-8"
            >
              <div className="flex flex-col items-center gap-3">
                <button
                  type="button"
                  onClick={() => { }}
                  disabled={loading}
                  className="inline-flex min-w-[340px] items-center justify-center gap-2 rounded-lg border border-white/80 bg-transparent text-white py-2 text-base font-light tracking-normal hover:bg-white/5 transition-colors disabled:pointer-events-none"
                >
                  {loading && (
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                  )}
                  Download it now
                </button>

                <button
                  type="button"
                  onClick={() => { }}
                  className="inline-flex min-w-[340px] items-center justify-center gap-2 rounded-lg border border-white/80 bg-transparent text-white py-2 text-base font-light tracking-normal hover:bg-white/5 transition-colors disabled:pointer-events-none"
                >
                  See all features
                </button>
              </div>
            </motion.div>
          </div>


          {/* Hero image */}
          <motion.img
            {...fadeUp}
            transition={{ duration: 0.55, delay: stagger * 5 }}
            src="/img/hero.webp"
            alt="Hero illustration"
            className="w-full md:w-[46%] shrink-0 rounded-2xl"
          />

        </div>
      </div>
    </section>
  );
};

export default HeroSection;