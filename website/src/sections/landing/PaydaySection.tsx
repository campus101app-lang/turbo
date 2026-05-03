import React, { useRef, useState } from "react";

interface CustomerStory {
  name: string;
  position: string;
  company: string;
  feedback: string;
  video: string;
  poster: string;
}

interface VideoCardProps {
  story: CustomerStory;
}

const CUSTOMER_STORIES = [
  {
    name: "Tunde Adeleke",
    position: "Founder",
    company: "Lagos Drip Co.",
    feedback: "\"I send invoices, track my store inventory, and collect USDC payments — all from one app. DayFi replaced three tools I was using.\"",
    video: "/vid/IMG_2662.MOV",
    poster: "/img/tunde-thumb.jpg"
  },
  {
    name: "Amaka Obi",
    position: "CEO",
    company: "Amaka's Kitchen",
    feedback: "\"My customers can tap their phone to pay now. The NFC checkout alone saved me from buying a POS terminal.\"",
    video: "/vid/amaka.mov",
    poster: "/img/amaka-thumb.jpg"
  },
  {
    name: "Emeka Nwosu",
    position: "Freelancer & Consultant",
    company: "Independent",
    feedback: "\"I bill foreign clients in USDC and receive naira locally. No more losing money on exchange rates.\"",
    video: "/videos/emeka.mp4",
    poster: "/img/emeka-thumb.jpg"
  }
];

const PaydaySection: React.FC = () => {
  return (
    <section id="payday" className="editorial-section bg-white py-20">
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] uppercase tracking-widest text-green-600 font-semibold">
            Customer Stories
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Our customers get <span className="italic text-green-600">real results</span>
          </h2>
          <p className="font-body mt-4 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink md:text-[20px]">
            Over 1,000 CFOs, controllers, accountants, and finance admins rely on DayFi to manage finances better.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {CUSTOMER_STORIES.map((story, index) => (
            <VideoCard key={index} story={story} />
          ))}
        </div>
      </div>
    </section>
  );
};

const VideoCard: React.FC<VideoCardProps> = ({ story }) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isMuted, setIsMuted] = useState(false);
  const [isHovered, setIsHovered] = useState(false);

  const handleMouseEnter = () => {
    setIsHovered(true);
    if (videoRef.current) {
      videoRef.current.muted = false; // try unmuted first
      videoRef.current.play().catch(() => {
        // Browser blocked it — fall back to muted and retry
        if (videoRef.current) {
          videoRef.current.muted = true;
          setIsMuted(true);
          videoRef.current.play().catch(err => console.error("Play failed:", err));
        }
      });
    }
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
    if (videoRef.current) {
      videoRef.current.pause();
      videoRef.current.currentTime = 0;
      // Reset to muted for next hover
      videoRef.current.muted = true;
      setIsMuted(true);
    }
  };

  const toggleMute = (e: React.MouseEvent) => {
    e.stopPropagation(); // don't bubble to card
    if (videoRef.current) {
      const next = !isMuted;
      videoRef.current.muted = next;
      setIsMuted(next);
    }
  };

  return (
    <div
      className="group relative h-[600px] w-full overflow-hidden rounded-3xl bg-black transition-all duration-300"
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      <video
        ref={videoRef}
        src={story.video}
        poster={story.poster}
        loop
        playsInline
        className="h-full w-full object-cover opacity-60 transition-opacity duration-500 group-hover:opacity-100"
      />

      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />

      {/* 🔊 Mute toggle — only visible on hover */}
      {/* {isHovered && (
        <button
          onClick={toggleMute}
          className="absolute top-4 right-4 z-10 flex items-center justify-center w-9 h-9 rounded-full bg-white/20 backdrop-blur-sm border border-white/30 text-white transition-all hover:bg-white/30"
          aria-label={isMuted ? "Unmute" : "Mute"}
        >
          {isMuted ? (
            // Muted icon
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
              <line x1="23" y1="9" x2="17" y2="15" />
              <line x1="17" y1="9" x2="23" y2="15" />
            </svg>
          ) : (
            // Unmuted icon
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" />
              <path d="M19.07 4.93a10 10 0 0 1 0 14.14" />
              <path d="M15.54 8.46a5 5 0 0 1 0 7.07" />
            </svg>
          )}
        </button>
      )} */}

      <div className="absolute inset-0 flex flex-col justify-end p-8 text-white">
        <div className="transform transition-transform duration-300 group-hover:-translate-y-2">
          <h3 className="font-display text-[24px] font-bold leading-none">
            {story.name}
          </h3>
          <p className="font-body mt-1 text-[14px] opacity-80">
            {story.position}, {story.company}
          </p>
          <div className="mt-6">
            <p className="font-body text-[16px] leading-relaxed line-clamp-4">
              {story.feedback}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PaydaySection;