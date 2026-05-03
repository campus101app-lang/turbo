import React, { useState } from "react";
import { Link } from "react-router-dom";
import { LogoTiles } from "@/components/protocol/LogoTiles";
import { Menu, X } from "lucide-react";

const NAV_LINKS: { label: string; href: string }[] = [
  { label: "Features", href: "#features" },
  { label: "How it works", href: "#how-it-works" },
  { label: "Why DayFi", href: "#why-dayfi" },
  { label: "FAQ", href: "#faq" },
];

const Header: React.FC = () => {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="header-chrome sticky top-0 z-50 min-h-14 bg-white">
     <div className="editorial-container relative flex h-full min-h-14 w-full items-center justify-between gap-3 py-2">
        
        {/* Logo — left */}
        <LogoTiles variant="wordmark" />

        {/* Nav links — center (desktop only) */}
         <nav className="hidden md:flex absolute left-1/2 -translate-x-1/2 items-center gap-6">
    {NAV_LINKS.map((l) => (
      <a
        key={l.label}
        href={l.href}
        className="font-body text-[15px] text-zap-ink opacity-60 hover:opacity-100 transition-opacity"
      >
        {l.label}
      </a>
    ))}
  </nav>

        {/* CTA buttons — right */}
        <div className="hidden md:flex items-center gap-3">
          <Link
            to="/login"
            className="font-body text-[15px] font-semibold text-zap-ink opacity-70 hover:opacity-100 transition-opacity px-4 py-2"
          >
            Log in
          </Link>
          <Link
            to="/signup"
            className="inline-flex items-center justify-center font-body text-[15px] font-semibold bg-zap-ink text-white px-5 py-2 rounded-full hover:opacity-90 transition-opacity"
          >
            Get started
          </Link>
        </div>

        {/* Mobile menu toggle */}
        <button
          className="md:hidden p-2 text-zap-ink"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          {menuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden bg-white border-t border-zap-ink/10 px-6 py-4 flex flex-col gap-4">
          {NAV_LINKS.map((l) => (
            <a
              key={l.label}
              href={l.href}
              onClick={() => setMenuOpen(false)}
              className="font-body text-[15px] text-zap-ink opacity-70 hover:opacity-100"
            >
              {l.label}
            </a>
          ))}
          <div className="flex flex-col gap-3 pt-2 border-t border-zap-ink/10">
            <Link
              to="/login"
              onClick={() => setMenuOpen(false)}
              className="font-body text-[15px] font-semibold text-zap-ink text-center py-2 border border-zap-ink/20 rounded-full"
            >
              Log in
            </Link>
            <Link
              to="/signup"
              onClick={() => setMenuOpen(false)}
              className="font-body text-[15px] font-semibold bg-zap-ink text-white text-center py-2 rounded-full"
            >
              Get started
            </Link>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;