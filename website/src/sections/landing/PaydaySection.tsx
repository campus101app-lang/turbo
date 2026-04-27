import React, { useRef } from "react";

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
    name: "Seyi Ogunbiyi",
    position: "COO",
    company: "Selar",
    feedback: "“Before Dayfy, we managed expenses with Slack messages, emails, and stressful bank transfers. Now, we issue cards, fund a budget, and that’s it.”",
    video: "/videos/seyi.mp4", // Replace with your paths
    poster: "/img/seyi-thumb.jpg"
  },
  {
    name: "Chichi Arinze",
    position: "CEO & Co-founder",
    company: "AutoGirl",
    feedback: "“The visibility we get now is a game-changer. I can track every kobo spent across the entire team in real-time.”",
    video: "/videos/chichi.mp4",
    poster: "/img/chichi-thumb.jpg"
  },
  {
    name: "Abiodun Olamilekan",
    position: "Head, Business Unit",
    company: "Koolboks",
    feedback: "“Our operations are 10x faster now. No more manual reconciliations or chasing receipts.”",
    video: "/videos/abiodun.mp4",
    poster: "/img/abiodun-thumb.jpg"
  }
];

const PaydaySection: React.FC = () => {
  return (
    <section id="payday" className="editorial-section bg-zap-bg-alt py-20">
      <div className="editorial-container">
        <div className="mx-auto max-w-4xl text-center mb-16">
          <p className="font-body text-[14px] uppercase tracking-widest text-zap-ink font-semibold opacity-100 text-green-800">
            Customer Stories
          </p>
          <h2 className="font-display font-semibold pt-4 mt-8 mx-auto w-full max-w-[600px] text-[clamp(1.75rem,9vw,3rem)] font-normal leading-[1.1] tracking-tight text-zap-ink md:mt-0">
            Our customers get <span className="italic">real results</span>
          </h2>
          <p className="font-body pt-0 mt-0 mx-auto w-full max-w-[600px] text-[14px] leading-snug text-zap-ink leading-[1] md:mt-4 md:text-[20px]">
            Over 1,000 CFOs, controllers, accountants, and finance admins rely on Dayfy to manage finances better.
          </p>
        </div>

        {/* Grid Layout */}
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
  // 2. Tell the ref it's specifically for a video element
  const videoRef = useRef<HTMLVideoElement>(null);

  const handleMouseEnter = () => {
    // 3. Optional chaining (?.) handles the "possibly null" error
    videoRef.current?.play().catch(err => {
      // Browsers often block autoplay unless muted/interacted with
      console.error("Video play failed:", err);
    });
  };

  const handleMouseLeave = () => {
    if (videoRef.current) {
      videoRef.current.pause();
      videoRef.current.currentTime = 0;
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
        muted
        loop
        playsInline
        className="h-full w-full object-cover opacity-60 transition-opacity duration-500 group-hover:opacity-100"
      />

      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />

      <div className="absolute inset-0 flex flex-col justify-end p-8 text-white">
        <div className="transform transition-transform duration-300 group-hover:-translate-y-2">
          <h3 className="font-display text-[24px] font-bold leading-none">
            {story.name}
          </h3>
          <p className="font-body mt-1 text-[14px] opacity-80">
            {story.position}, {story.company}
          </p>

          <div className="mt-6">
            <p className="font-body text-[16px] leading-relaxed line-clamp-4 opacity-0 transition-all duration-500 group-hover:opacity-100">
              {story.feedback}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PaydaySection;