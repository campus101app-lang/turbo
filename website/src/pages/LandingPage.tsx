import React, { useEffect, useState } from "react";
import { Iphone17Pro } from "@/components/eldoraui/iphone-17-pro";

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

  return (
    <div
      id="main-content"
      tabIndex={-1}
      className="relative h-screen overflow-hidden bg-[#2f5d95] text-zap-ink outline-none"
    >

      <section className="flex h-full w-full items-center justify-center px-4 py-6">
        <Iphone17Pro
          width={370}
          height={780}
          className="max-w-full"
        >
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
                {/* <span>{currentTime}</span> */}
                {/* <span>Play</span> */}
              </div>
              {/* <p className="text-[46px] font-medium leading-none tracking-[-0.02em] text-white/90">
                DayFi
              </p> */}
            </div>

            <div className="pb-0">
              <h1 className="max-w-[320px] text-[64px] font-light leading-[1] tracking-[-0.035em] text-white/95">
                One point of sale, wherever you grow
              </h1>
            </div>

            <div className="space-y-3">
              <button className="h-12 w-full rounded-full bg-white text-[12px] font-semibold tracking-[-0.01em] text-black transition hover:bg-white/90">
                Create account
              </button>
              <button className="h-12 w-full rounded-full border border-white/10 bg-black/65 text-[12px] font-medium tracking-[-0.01em] text-white/90 transition hover:bg-black/75">
                Sign in
              </button>
            </div>
          </div>
        </Iphone17Pro>
      </section>
    </div>
  );
};

export default LandingPage;
