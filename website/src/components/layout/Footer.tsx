import React from "react";
import { MessageCircle, Twitter } from "lucide-react";
import { Link, useLocation } from "react-router-dom";
import { LogoTiles } from "../protocol/LogoTiles";

// import { LogoTiles } from "@/components/protocol/LogoTiles";
// import { blogUrl, contractSpecUrl, docsUrl, site } from "@/config/site";
// import { env } from "@/config/env";
// import { useWallet } from "@/hooks/useWallet";
// import { useProfileStore } from "@/state/profileStore";
// import { stellarExpertContractUrl } from "@/utils/format";

// function contractFooterLine(): { text: string; href: string | null } {
//   const id = env.contractId;
//   if (!id) {
//     return {
//       text: "Contract not configured — set VITE_CONTRACT_ID in .env",
//       href: null,
//     };
//   }
//   const short = `${id.slice(0, 6)}…${id.slice(-4)}`;
//   const isMain = env.network === "MAINNET";
//   const netLabel =
//     env.network === "MAINNET"
//       ? "Mainnet"
//       : env.network === "FUTURENET"
//         ? "Futurenet"
//         : "Testnet";
//   return {
//     text: `Contract ${short} · ${netLabel}`,
//     href: stellarExpertContractUrl(id, isMain ? "PUBLIC" : "TESTNET"),
//   };
// }

const Footer: React.FC = () => {
    const { pathname } = useLocation();
    const hideNetworkNav = pathname === "/";
    //   const { connected } = useWallet();
    //   const profile = useProfileStore((s) => s.profile);
    //   const isRegistered = useProfileStore((s) => s.isRegistered);

    //   const profileLinkTo = connected ? "/terminal/profile" : "/register";
    //   const profileLinkLabel =
    //     connected && (Boolean(profile) || isRegistered) ? "Profile" : "Create profile";

    const link =
        "font-body text-zap-ink transition-colors hover:text-zap-brand md:mt-0 md:text-[18px]";
    const heading =
        "font-body font-semibold leading-snug text-zap-ink md:mt-0 md:text-[18px]";

    //   const contractLine = contractFooterLine();

    return (
        <footer className="bg-[#f5efe8] py-8 text-zap-ink dark:bg-neutral-950 dark:text-white">
            <div className="editorial-container">
                {/* Rounded container with padding */}
                <div
                    className="
        rounded-3xl
        bg-white
        px-8 py-10
        shadow-sm
        backdrop-blur-sm
        dark:border-white/10
        dark:bg-neutral-900/70
        sm:px-8 sm:py-8
      "
                >
                    <div className="grid grid-cols-1 gap-10 sm:grid-cols-2 sm:gap-12 lg:grid-cols-4">
                        {/* Brand Section */}
                        <div className="flex flex-col gap-3 sm:col-span-2 lg:col-span-1">
                            <LogoTiles variant="wordmark" />
                            <p className="font-body leading-snug text-zap-ink md:text-[18px] dark:text-white/70">
                                Pay AI agents for outcomes with USDC on Stellar.
                            </p>
                        </div>

                        {/* Product */}
                        <div className="flex flex-col gap-2">
                            <h3 className={heading}>Product</h3>
                            <Link to="/" className={link}>Home</Link>
                            {!hideNetworkNav && (
                                <Link to="/network" className={link}>Network</Link>
                            )}
                            <Link to="/terminal" className={link}>Terminal</Link>
                            <Link to="/#comparison" className={link}>Why Zap402</Link>
                            {/* <Link to={profileLinkTo} className={link}>
            {profileLinkLabel}
          </Link> */}
                        </div>

                        {/* Developers */}
                        <div className="flex flex-col gap-2">
                            <h3 className={heading}>Developers</h3>
                            <a href="https://github.com/klarqqs/zap402" target="_blank" rel="noopener noreferrer" className={link}>GitHub</a>
                            <a href="https://github.com/klarqqs/zap402/blob/main/README.md" target="_blank" rel="noopener noreferrer" className={link}>Docs</a>
                            <a href="https://github.com/klarqqs/zap402/issues" target="_blank" rel="noopener noreferrer" className={link}>Issues</a>
                        </div>

                        {/* Community */}
                        <div className="flex flex-col gap-2">
                            <h3 className={heading}>Community</h3>
                            <a
                                href=""
                                target="_blank"
                                rel="noopener noreferrer"
                                className={`flex items-center gap-2 ${link}`}
                            >
                                <Twitter size={16} className="shrink-0 opacity-90" aria-hidden />
                                X / Twitter
                            </a>
                            <a
                                href=""
                                target="_blank"
                                rel="noopener noreferrer"
                                className={`flex items-center gap-2 ${link}`}
                            >
                                <MessageCircle size={16} className="shrink-0 opacity-90" aria-hidden />
                                Stellar Discord
                            </a>
                            <span className={`${link} cursor-default opacity-70`}>
                                Newsletter — soon
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            {/* ✅ Copyright placed OUTSIDE the rounded container */}
            <div className="editorial-container mt-2">
                <p className="text-center font-body text-xs text-zap-ink-muted dark:text-white/60">
                    Zap402 Labs © {new Date().getFullYear()}
                </p>
            </div>
        </footer>
    );
};

export default Footer;
