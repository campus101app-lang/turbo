import React from "react";
import { Link } from "react-router-dom";
import Logo from "@/components/primitives/Logo";

const LETTERS = ["Z", "A", "P", "4", "0", "2"] as const;

type LogoTilesProps = {
  /** header: nav chrome · hero: landing · footer: compact wordmark · wordmark: sans-serif name (dashboard) */
  variant?: "header" | "hero" | "footer" | "wordmark";
  className?: string;
  /** Link target for header/footer wordmark (default `/`). Dashboard chrome uses `/terminal`. */
  homeTo?: string;
};

export function LogoTiles({
  variant = "header",
  className = "",
  homeTo = "/",
}: LogoTilesProps) {
  if (variant === "wordmark") {
    return (
      <Link
        to={homeTo}
        className={`inline-flex shrink-0 items-center no-underline ${className}`}
        aria-label="Zap402 home"
      >
        <Logo className="h-8 w-auto text-zap-ink" />
      </Link>
    );
  }

  const tileH =
    variant === "hero" ? 48 : variant === "footer" ? 22 : 28;
  const tileW =
    variant === "hero" ? 42 : variant === "footer" ? 20 : 26;
  const fontSize =
    variant === "hero"
      ? "clamp(1.2rem, 2.8vw, 1.65rem)"
      : variant === "footer"
        ? "11px"
        : "15px";
  const gap = variant === "hero" ? 2 : variant === "footer" ? 2 : 3;

  const inner = (
    <div className={`logo-tiles flex ${className}`} style={{ gap }}>
      {LETTERS.map((letter, i) => (
        <div
          key={i}
          className="logo-tile flex items-center justify-center border border-zap-bg-alt bg-zap-bg-tile text-zap-ink"
          style={{
            width: tileW,
            height: tileH,
            fontFamily: "var(--font-body)",
            fontSize,
            lineHeight: 1,
            transitionDelay: `${i * 25}ms`,
          }}
        >
          {letter}
        </div>
      ))}
    </div>
  );

  if (variant === "header" || variant === "footer") {
    return (
      <Link to={homeTo} className="inline-flex shrink-0" aria-label="Zap402 home">
        {inner}
      </Link>
    );
  }

  return <div className="inline-flex">{inner}</div>;
}
