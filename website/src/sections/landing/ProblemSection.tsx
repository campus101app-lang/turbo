import React from "react";
import { Link } from "react-router-dom";

// import ScrollReveal from "@/components/feedback/ScrollReveal";
// import { useCreatorOnboardingCta } from "@/hooks/useCreatorOnboardingCta";

const lines = [
  "PATREON       → Nigerian payouts: BLOCKED",
  "KO-FI         → West Africa: UNSUPPORTED",
  "STRIPE        → NG / GH: ACCESS_DENIED",
  "PAYPAL        → Settlement: 7–30 days / UNRELIABLE",
  "500K_FOLLOWERS → PAYMENT_RECEIVED: null",
];

const ProblemSection: React.FC = () => {
  // const { connected, isRegistered, profileHref, openWalletConnect } =
  //   useCreatorOnboardingCta();

  return (
    <section id="problem" className="editorial-section border-y border-zap-bg-alt bg-zap-bg-alt">
      <div className="editorial-container text-center">
        <div>
          <p className="text-label-caps text-label-caps--accent mb-4">// WHY_ZAP402</p>
          <h2 className="mx-auto max-w-4xl font-body text-[clamp(2.5rem,6vw,4.5rem)] font-normal leading-[0.95] text-zap-ink">
            The legacy rails are broken.
            <br />
            We built new ones.
          </h2>
          <ul className="mx-auto mt-10 max-w-2xl space-y-3 text-left font-mono text-[13px] leading-relaxed text-zap-ink-muted md:text-sm">
            {lines.map((line) => (
              <li key={line} className="border border-zap-bg-alt bg-zap-bg-raised px-4 py-3 text-zap-ink">
                {line}
              </li>
            ))}
          </ul>
          <p className="mx-auto mt-10 max-w-xl font-body text-[13px] leading-[1.9] text-zap-ink-muted">
            Your earnings exist. The infrastructure to receive them didn&apos;t — until now.
          </p>
          {/* {!connected ? (
            <button
              type="button"
              onClick={() => openWalletConnect()}
              className="btn-primary mx-auto mt-10 inline-flex justify-center text-center"
            >
              Connect Wallet
            </button>
          ) : isRegistered ? (
            <Link
              to={profileHref}
              className="btn-primary mx-auto mt-10 inline-flex justify-center text-center no-underline"
            >
              OPEN YOUR PAGE
            </Link>
          ) : (
            <Link
              to="/register"
              className="btn-primary mx-auto mt-10 inline-flex justify-center text-center no-underline"
            >
              INITIALIZE PROFILE
            </Link>
          )} */}
        </div>
      </div>
    </section>
  );
};

export default ProblemSection;
