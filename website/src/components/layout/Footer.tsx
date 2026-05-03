import React from "react";
import { Twitter, Instagram, Linkedin } from "lucide-react";
import { Link, useLocation } from "react-router-dom";
import { LogoTiles } from "../protocol/LogoTiles";

const Footer: React.FC = () => {
    const link =
        "font-body text-zap-ink transition-colors hover:text-zap-brand md:mt-0 md:text-[18px]";

    return (
        <footer className="bg-[#F9FAFB] py-0 text-zap-ink">
            <div className="editorial-container">
                <div className="rounded-3xl bg-white px-8 py-10 shadow-sm sm:px-8 sm:py-8">
                    <div className="flex flex-col items-center gap-6 sm:flex-row sm:justify-between">

                        {/* Brand */}
                        <LogoTiles variant="wordmark" />

                        {/* Links */}
                        <div className="flex items-center gap-6">
                            <Link to="/privacy" className={link}>Privacy Policy</Link>
                            <Link to="/terms" className={link}>Terms & Conditions</Link>
                        </div>

                        {/* Socials */}
                        <div className="flex items-center gap-4">
                            <a href="" target="_blank" rel="noopener noreferrer" className={link}>
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.746l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                                </svg>
                            </a>
                            <a href="" target="_blank" rel="noopener noreferrer" className={link}>
                                <Instagram size={18} />
                            </a>
                            <a href="" target="_blank" rel="noopener noreferrer" className={link}>
                                <Linkedin size={18} />
                            </a>
                        </div>

                    </div>
                </div>
            </div>

            <div className="editorial-container mt-4 mb-4">
                <p className="text-center font-body text-xs text-zap-ink-muted">
                    DayFi © {new Date().getFullYear()}
                </p>
            </div>
        </footer>
    );
};

export default Footer;
