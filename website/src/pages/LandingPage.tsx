import React from "react";

import HeroSection from "@/sections/landing/HeroSection";
import PaydaySection from "@/sections/landing/PaydaySection";
import CreatorsKindsSection from "@/sections/landing/CreatorsKindsSection";
import HowToBeginSection from "@/sections/landing/HowToBeginSection";
import TopCreatorsSection from "@/sections/landing/TopCreatorsSection";
import FAQSection from "@/sections/landing/FAQSection";
import CTASection from "@/sections/landing/CTASection";
import MainProductSection from "@/sections/landing/MainProductSection";
import ComparisonSection from "@/sections/landing/ComparisonSection";
import HowItWorksSection from "@/sections/landing/HowItWorksSection";
import MissionSection from "@/sections/landing/MissionSection";
import OpenRailsSection from "@/sections/landing/OpenRailsSection";
import ProblemSection from "@/sections/landing/ProblemSection";
import ThreeWaysSection from "@/sections/landing/ThreeWaysSection";

const LandingPage: React.FC = () => {
  // usePageTitle("Zap402 — pay AI agents per request");

  return (
    <div
      id="main-content"
      tabIndex={-1}
      className="relative min-h-screen bg-zap-bg text-zap-ink outline-none"
    >
      <HeroSection />
      <CreatorsKindsSection />
      <PaydaySection />
      <ThreeWaysSection />
      <ProblemSection />
      <OpenRailsSection />
      <HowToBeginSection />
      <MissionSection />
      <FAQSection />
      <CTASection />
    </div>
  );
};

export default LandingPage;
