import React from "react";

type Iphone17ProProps = {
  src?: string;
  width?: number;
  height?: number;
  className?: string;
  children?: React.ReactNode;
};

export const Iphone17Pro: React.FC<Iphone17ProProps> = ({
  src,
  width = 390,
  height = 844,
  className = "",
  children,
}) => {
  return (
    <div className={`relative ${className}`} style={{ width, height }}>
      <div className="absolute inset-0 rounded-[62px] bg-gradient-to-b from-zinc-800 via-black to-zinc-900 shadow-[0_24px_70px_rgba(0,0,0,0.52)]" />
      <div className="absolute inset-[2px] rounded-[60px] border border-zinc-700/70" />
      <div className="absolute inset-[8px] rounded-[54px] border border-zinc-800/90 bg-black" />

      <div className="absolute right-[-2px] top-[168px] h-20 w-1 rounded-l-full bg-zinc-700" />
      <div className="absolute left-[-2px] top-[150px] h-12 w-1 rounded-r-full bg-zinc-700" />
      <div className="absolute left-[-2px] top-[216px] h-20 w-1 rounded-r-full bg-zinc-700" />
      <div className="absolute left-[-2px] top-[306px] h-20 w-1 rounded-r-full bg-zinc-700" />

      <div className="relative h-full w-full overflow-hidden rounded-[62px]">
        <div className="absolute inset-[14px] overflow-hidden rounded-[46px] bg-black">
          {src ? (
            <img
              src={src}
              alt="iPhone 17 Pro preview"
              className="absolute inset-0 h-full w-full object-cover"
            />
          ) : null}
          {children}
        </div>
        <div className="pointer-events-none absolute left-1/2 top-[20px] z-30 h-[34px] w-[126px] -translate-x-1/2 rounded-[20px] bg-black">
          <div className="absolute left-[18px] top-1/2 h-[10px] w-[10px] -translate-y-1/2 rounded-full bg-zinc-800" />
          <div className="absolute left-[34px] top-1/2 h-[8px] w-[8px] -translate-y-1/2 rounded-full bg-zinc-700" />
        </div>
      </div>
      <div className="pointer-events-none absolute inset-[9px] rounded-[54px] ring-1 ring-white/10" />
      <div className="pointer-events-none absolute inset-[14px] rounded-[46px] ring-1 ring-white/5" />
    </div>
  );
};

