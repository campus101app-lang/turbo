import React, { useEffect, useState } from "react";
import { Iphone17Pro } from "@/components/eldoraui/iphone-17-pro";
import appStoreBadge from "@/assets/pngs/coming_soon_to_the_app_store.png";
import googlePlayBadge from "@/assets/pngs/coming_soon_on_google_play.png";

const LandingPage: React.FC = () => {
  // usePageTitle("Zap402 — pay AI agents per request");
  const [currentTime, setCurrentTime] = useState("");

  useEffect(() => {
    const formatter = new Intl.DateTimeFormat([], {
      hour: "numeric",
      minute: "2-digit",
      hour12: false,
    });

    const updateTime = () => setCurrentTime(formatter.format(new Date()));
    updateTime();

    const timer = window.setInterval(updateTime, 1000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    const previousTheme = document.documentElement.getAttribute("data-theme");
    document.documentElement.setAttribute("data-theme", "dark");

    return () => {
      if (previousTheme) {
        document.documentElement.setAttribute("data-theme", previousTheme);
      } else {
        document.documentElement.removeAttribute("data-theme");
      }
    };
  }, []);

  return (
    <div
      id="main-content"
      tabIndex={-1}
      className="relative h-screen overflow-hidden bg-zap-bg text-zap-ink outline-none"
    >
      <section className="flex h-full w-full items-center justify-center px-20 py-6">
        <div className="flex w-full max-w-[1380px] items-center justify-between gap-6">
          <div className="hidden w-[320px] flex-col justify-center xl:flex">
            <img
              src="/img/hero_logo.png"
              alt=""
              className="mx-auto h-44 w-44 object-contain"
            />

            <p className="font-body mb-4 mt-2 w-full text-center text-[16px] leading-snug text-zap-ink md:text-[20px]">
              Every day is payday
            </p>
            <p className="font-body mt-4 w-full text-center text-[18px] leading-snug text-zap-ink-muted md:text-[22px]">
            Built for Nigerian merchants who move fast. Sell in-person, online, or on the go.
            </p>
          </div> 

          <Iphone17Pro width={370 * .9} height={780 * .9} className="mx-auto max-w-full shrink-0">
            <video
              autoPlay
              loop
              muted
              playsInline
              className="absolute inset-0 h-full w-full object-cover"
            >
              <source src="/vid/splash_vid.mp4" type="video/mp4" />
            </video>
            <div className="absolute inset-0 bg-gradient-to-b from-black/10 via-black/45 to-black/80" />

            <div
              className="relative z-10 flex h-full flex-col justify-between px-7 pb-7 pt-9 text-white"
              style={{ fontFamily: "'Karla', sans-serif" }}
            >
              <div className="space-y-6">
                <div className="flex items-center justify-between text-[13px] font-semibold tracking-tight text-white/90">
                  {/* <span>{currentTime}</span>
                  <span>Play</span> */}
                </div>
              </div>

              <div className="pb-0">
                <h1 className="max-w-[320px] text-[58px] font-light leading-[1.01] tracking-[-0.038em] text-white/95">
                  One point of sale, wherever you grow
                </h1>
              </div>

              <div className="space-y-3">
                <button className="h-12 w-full rounded-full bg-white text-[12px] font-semibold tracking-[-0.01em] text-black transition hover:bg-white/90">
                  Create account
                </button>
                <button className="h-12 w-full rounded-full bg-black/85 text-[12px] font-medium tracking-[-0.01em] text-white transition hover:bg-black/75">
                  Sign in
                </button>
              </div>
            </div>
          </Iphone17Pro>

          <div className="hidden w-[320px] flex-row items-center justify-center gap-2 xl:flex">
            <img
              src={appStoreBadge}
              alt="Coming soon to the App Store"
              className="w-full max-w-[122px]"
            />
            <img
              src={googlePlayBadge}
              alt="Coming soon on Google Play"
              className="w-full max-w-[122px]"
            />
          </div>
        </div>
      </section>
    </div>
  );
};

export default LandingPage;
