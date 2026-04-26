(globalThis.TURBOPACK || (globalThis.TURBOPACK = [])).push([typeof document === "object" ? document.currentScript : undefined,
"[project]/website/app/(website)/(landing)/page.tsx [app-client] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>LandingPage
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/compiled/react/jsx-dev-runtime.js [app-client] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/compiled/react/index.js [app-client] (ecmascript)");
;
var _s = __turbopack_context__.k.signature();
'use client';
;
function LandingPage() {
    _s();
    const navRef = (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useRef"])(null);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "LandingPage.useEffect": ()=>{
            const handleScroll = {
                "LandingPage.useEffect.handleScroll": ()=>{
                    if (navRef.current) {
                        navRef.current.classList.toggle('scrolled', window.scrollY > 40);
                    }
                }
            }["LandingPage.useEffect.handleScroll"];
            window.addEventListener('scroll', handleScroll);
            return ({
                "LandingPage.useEffect": ()=>window.removeEventListener('scroll', handleScroll)
            })["LandingPage.useEffect"];
        }
    }["LandingPage.useEffect"], []);
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$index$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["useEffect"])({
        "LandingPage.useEffect": ()=>{
            const reveals = document.querySelectorAll('.reveal');
            const observer = new IntersectionObserver({
                "LandingPage.useEffect": (entries)=>{
                    entries.forEach({
                        "LandingPage.useEffect": (entry, i)=>{
                            if (entry.isIntersecting) {
                                setTimeout({
                                    "LandingPage.useEffect": ()=>entry.target.classList.add('visible')
                                }["LandingPage.useEffect"], i * 80);
                                observer.unobserve(entry.target);
                            }
                        }
                    }["LandingPage.useEffect"]);
                }
            }["LandingPage.useEffect"], {
                threshold: 0.08
            });
            reveals.forEach({
                "LandingPage.useEffect": (el)=>observer.observe(el)
            }["LandingPage.useEffect"]);
            return ({
                "LandingPage.useEffect": ()=>observer.disconnect()
            })["LandingPage.useEffect"];
        }
    }["LandingPage.useEffect"], []);
    const toggleFaq = (e)=>{
        const item = e.currentTarget.closest('.faq-item');
        item?.classList.toggle('open');
    };
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["Fragment"], {
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("style", {
                children: `
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
          --bg: #000000;
          --surface: #0A0A0A;
          --card: #111111;
          --border: #1E1E1E;
          --text: #FFFFFF;
          --muted: #888888;
          --dim: #444444;
          --green: #00E676;
          --red: #FF4444;
        }

        html { scroll-behavior: smooth; }

        body {
          font-family: 'Bricolage Grotesque', sans-serif;
          background: var(--bg);
          color: var(--text);
          overflow-x: hidden;
          -webkit-font-smoothing: antialiased;
        }

        /* NAV */
        .dayfi-nav {
          position: fixed; top: 0; left: 0; right: 0; z-index: 100;
          display: flex; align-items: center; justify-content: space-between;
          padding: 20px 48px;
          border-bottom: 1px solid transparent;
          transition: border-color 0.3s, background 0.3s;
        }
        .dayfi-nav.scrolled {
          background: rgba(0,0,0,0.88);
          backdrop-filter: blur(24px);
          border-color: var(--border);
        }
        .dayfi-logo {
          font-size: 20px; font-weight: 700; letter-spacing: -0.5px;
          color: var(--text); text-decoration: none; opacity: 0.45;
        }
        .nav-cta {
          display: flex; align-items: center; gap: 8px;
          background: transparent; color: var(--text);
          border: 1.5px solid rgba(255,255,255,0.9);
          padding: 10px 22px; border-radius: 12px;
          font-family: 'Bricolage Grotesque', sans-serif;
          font-size: 14px; font-weight: 500; text-decoration: none;
          transition: opacity 0.2s;
        }
        .nav-cta:hover { opacity: 0.7; }

        /* HERO */
        .hero {
          min-height: 100vh;
          display: flex; flex-direction: column; align-items: center; justify-content: center;
          text-align: center;
          padding: 120px 24px 80px;
          position: relative; overflow: hidden;
        }
        .hero h1 {
          font-size: clamp(52px, 9vw, 110px);
          font-weight: 800; line-height: 0.95;
          letter-spacing: -4px; margin-bottom: 32px; max-width: 900px;
          animation: fadeUp 0.7s ease both;
        }
        .hero p {
          font-size: clamp(16px, 2vw, 20px);
          color: var(--muted); max-width: 720px;
          line-height: 1.6; margin-bottom: 48px; font-weight: 400;
          animation: fadeUp 0.7s 0.1s ease both;
        }
        .hero-btns {
          display: flex; flex-direction: column; gap: 12px; align-items: center;
          width: 100%; max-width: 360px;
          animation: fadeUp 0.7s 0.2s ease both;
        }
        .btn-outline {
          width: 100%; display: flex; align-items: center; justify-content: center; gap: 10px;
          background: transparent; color: var(--text);
          border: 1.5px solid rgba(255,255,255,0.9);
          padding: 14px 28px; border-radius: 12px;
          font-family: 'Bricolage Grotesque', sans-serif;
          font-size: 15px; font-weight: 500; text-decoration: none;
          transition: opacity 0.2s;
        }
        .btn-outline:hover { opacity: 0.7; }
        .btn-ghost {
          width: 100%; display: flex; align-items: center; justify-content: center; gap: 10px;
          background: transparent; color: rgba(255,255,255,0.9);
          border: 1.5px solid transparent;
          padding: 14px 28px; border-radius: 12px;
          font-family: 'Bricolage Grotesque', sans-serif;
          font-size: 15px; font-weight: 400; text-decoration: none;
          transition: opacity 0.2s;
        }
        .btn-ghost:hover { opacity: 0.6; }

        /* PHONE MOCKUPS */
        .hero-phones {
          margin-top: 80px;
          display: flex; gap: 24px; align-items: flex-start; justify-content: center;
          animation: fadeUp 0.9s 0.3s ease both;
        }
        .phone-frame {
          width: 240px;
          background: var(--card); border: 1px solid var(--border);
          border-radius: 36px; padding: 16px;
          box-shadow: 0 48px 100px rgba(0,0,0,0.9), 0 0 0 1px rgba(255,255,255,0.04);
        }
        .phone-frame.secondary { transform: translateY(32px) scale(0.92); opacity: 0.7; }
        .phone-screen {
          background: #0A0A0A; border-radius: 26px;
          padding: 28px 16px 24px; min-height: 420px;
          display: flex; flex-direction: column; align-items: center;
        }
        .ph-logo { font-size: 13px; font-weight: 700; color: var(--dim); margin-bottom: 44px; opacity: 0.45; }
        .ph-label { font-size: 10px; color: var(--muted); letter-spacing: 0.4px; margin-bottom: 6px; }
        .ph-balance { font-size: 40px; font-weight: 400; letter-spacing: -1.5px; margin-bottom: 28px; }
        .ph-actions { width: 100%; display: flex; gap: 8px; margin-bottom: 20px; }
        .ph-btn { flex: 1; background: rgba(255,255,255,0.06); border: 1px solid var(--border); border-radius: 50px; padding: 10px; text-align: center; font-size: 12px; font-weight: 500; color: var(--muted); }
        .ph-txs { width: 100%; display: flex; flex-direction: column; gap: 8px; }
        .ph-tx { background: rgba(255,255,255,0.04); border: 1px solid var(--border); border-radius: 12px; padding: 10px 12px; display: flex; align-items: center; gap: 10px; }
        .ph-tx-icon { width: 30px; height: 30px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 11px; flex-shrink: 0; }
        .ph-tx-icon.r { background: rgba(0,230,118,0.12); color: var(--green); }
        .ph-tx-icon.s { background: rgba(255,68,68,0.12); color: var(--red); }
        .ph-tx-info { flex: 1; }
        .ph-tx-name { font-size: 11px; font-weight: 600; }
        .ph-tx-time { font-size: 10px; color: var(--muted); margin-top: 2px; }
        .ph-tx-amount { font-size: 12px; font-weight: 700; }
        .ph-tx-amount.r { color: var(--green); }
        .ph-tx-amount.s { color: var(--red); }
        .ph-send-screen {
          background: #0A0A0A; border-radius: 26px;
          padding: 20px 16px 24px; min-height: 420px;
          display: flex; flex-direction: column;
        }
        .ph-back { font-size: 18px; color: var(--muted); margin-bottom: 20px; }
        .ph-send-title { font-size: 17px; font-weight: 600; text-align: center; margin-bottom: 6px; }
        .ph-send-sub { font-size: 10px; color: var(--muted); text-align: center; margin-bottom: 20px; }
        .ph-input { background: rgba(255,255,255,0.06); border: none; border-radius: 10px; padding: 10px 12px; font-size: 12px; color: var(--text); font-family: 'Bricolage Grotesque', sans-serif; width: 100%; margin-bottom: 10px; }
        .ph-amount-big { text-align: center; font-size: 36px; font-weight: 400; letter-spacing: -1.5px; margin: 12px 0; }
        .ph-amount-sub { text-align: center; font-size: 10px; color: var(--muted); margin-bottom: 20px; }
        .ph-continue { background: var(--text); color: var(--bg); border: none; border-radius: 10px; padding: 12px; text-align: center; font-family: 'Bricolage Grotesque', sans-serif; font-size: 13px; font-weight: 600; width: 100%; }

        /* FEATURES */
        .features-section { padding: 120px 24px; }
        .features-grid {
          display: grid; grid-template-columns: repeat(3, 1fr);
          gap: 16px; max-width: 960px; margin: 0 auto;
        }
        .feature-card {
          background: var(--surface); border: 1px solid var(--border);
          border-radius: 24px; padding: 36px 28px;
          display: flex; flex-direction: column; gap: 16px;
        }
        .feature-icon {
          width: 48px; height: 48px; border-radius: 14px;
          background: var(--card); border: 1px solid var(--border);
          display: flex; align-items: center; justify-content: center;
          font-size: 22px;
        }
        .feature-card h3 { font-size: 18px; font-weight: 700; letter-spacing: -0.4px; line-height: 1.2; }
        .feature-card p { font-size: 14px; color: var(--muted); line-height: 1.6; }
        .section-label {
          text-align: center; font-size: 11px; font-weight: 600;
          color: var(--muted); letter-spacing: 1.5px; text-transform: uppercase;
          margin-bottom: 20px;
        }
        .section-title {
          text-align: center;
          font-size: clamp(36px, 5vw, 64px);
          font-weight: 800; letter-spacing: -3px;
          margin-bottom: 12px;
        }
        .section-sub {
          text-align: center; font-size: 16px;
          color: var(--muted); margin-bottom: 64px;
        }

        /* DOWNLOAD CTA */
        .cta-section { padding: 40px 24px 120px; }
        .cta-box {
          max-width: 680px; margin: 0 auto;
          background: var(--surface); border: 1px solid var(--border);
          border-radius: 32px; padding: 72px 48px;
          text-align: center; position: relative; overflow: hidden;
        }
        .cta-box::before {
          content: '';
          position: absolute; top: -120px; left: 50%; transform: translateX(-50%);
          width: 400px; height: 400px;
          background: radial-gradient(circle, rgba(255,255,255,0.025) 0%, transparent 70%);
          pointer-events: none;
        }
        .cta-box h2 {
          font-size: clamp(32px, 4vw, 52px);
          font-weight: 800; letter-spacing: -2px;
          margin-bottom: 16px; line-height: 1.05;
          position: relative; z-index: 1;
        }
        .cta-box p { font-size: 16px; color: var(--muted); margin-bottom: 40px; position: relative; z-index: 1; }
        .store-btns { display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; position: relative; z-index: 1; }
        .store-btn {
          display: flex; align-items: center; gap: 10px;
          background: var(--card); border: 1.5px solid rgba(255,255,255,0.15);
          border-radius: 12px; padding: 12px 20px;
          text-decoration: none; color: var(--text);
          transition: border-color 0.2s, transform 0.2s;
        }
        .store-btn:hover { border-color: rgba(255,255,255,0.4); transform: translateY(-2px); }
        .store-btn-text { display: flex; flex-direction: column; text-align: left; }
        .store-btn-sub { font-size: 10px; color: var(--muted); }
        .store-btn-name { font-size: 14px; font-weight: 600; }
        .apk-link {
          display: block; text-align: center; margin-top: 20px;
          color: var(--muted); font-size: 13px; text-decoration: underline;
          text-underline-offset: 3px; transition: color 0.2s; position: relative; z-index: 1;
        }
        .apk-link:hover { color: var(--text); }

        /* FOOTER */
        .dayfi-footer {
          border-top: 1px solid var(--border);
          padding: 32px 48px;
          display: flex; align-items: center; justify-content: space-between;
        }
        .dayfi-footer p { font-size: 12px; color: var(--dim); }
        .dayfi-footer a { color: var(--dim); font-size: 12px; text-decoration: none; transition: color 0.2s; }
        .dayfi-footer a:hover { color: var(--muted); }

        /* ANIMATIONS */
        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(20px); }
          to { opacity: 1; transform: translateY(0); }
        }
        .reveal { opacity: 0; transform: translateY(24px); transition: opacity 0.7s ease, transform 0.7s ease; }
        .reveal.visible { opacity: 1; transform: translateY(0); }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }

        /* RESPONSIVE */
        @media (max-width: 768px) {
          .dayfi-nav { padding: 16px 20px; }
          .features-grid { grid-template-columns: 1fr; }
          .hero-phones { flex-direction: column; align-items: center; }
          .phone-frame.secondary { transform: none; }
          .cta-box { padding: 48px 24px; }
          .dayfi-footer { flex-direction: column; gap: 12px; text-align: center; }
        }
      `
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 42,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("nav", {
                ref: navRef,
                className: "dayfi-nav",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                        href: "/",
                        className: "dayfi-logo",
                        children: "dayfi."
                    }, void 0, false, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 296,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                        href: "#download",
                        className: "nav-cta",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
                                width: "14",
                                height: "14",
                                fill: "none",
                                stroke: "currentColor",
                                strokeWidth: "2",
                                viewBox: "0 0 24 24",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                        d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 299,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("polyline", {
                                        points: "7,10 12,15 17,10"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 300,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("line", {
                                        x1: "12",
                                        y1: "15",
                                        x2: "12",
                                        y2: "3"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 301,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 298,
                                columnNumber: 11
                            }, this),
                            "Download"
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 297,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 295,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                className: "hero",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h1", {
                        children: [
                            "Digital Dollars,",
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("br", {}, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 309,
                                columnNumber: 29
                            }, this),
                            "Bitcoin and Gold."
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 309,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        children: "A wallet built for real life: your wealth, remittances, and everyday transfers. Simple, Powerful, Yours."
                    }, void 0, false, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 310,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "hero-btns",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                href: "#download",
                                className: "btn-outline",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
                                        width: "14",
                                        height: "14",
                                        fill: "none",
                                        stroke: "currentColor",
                                        strokeWidth: "2",
                                        viewBox: "0 0 24 24",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                                d: "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                lineNumber: 315,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("polyline", {
                                                points: "7,10 12,15 17,10"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                lineNumber: 316,
                                                columnNumber: 15
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("line", {
                                                x1: "12",
                                                y1: "15",
                                                x2: "12",
                                                y2: "3"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                lineNumber: 317,
                                                columnNumber: 15
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 314,
                                        columnNumber: 13
                                    }, this),
                                    "Download it now"
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 313,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                href: "#features",
                                className: "btn-ghost",
                                children: "See features"
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 321,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 312,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "hero-phones",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "phone-frame",
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "phone-screen",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-logo",
                                            children: "dayfi."
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 328,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-label",
                                            children: "Total Wallet Balance"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 329,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-balance",
                                            children: "$168.25"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 330,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-actions",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "ph-btn",
                                                    children: "↓ Receive"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 332,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "ph-btn",
                                                    children: "↑ Send"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 333,
                                                    columnNumber: 17
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 331,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-txs",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "ph-tx",
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-icon r",
                                                            children: "↓"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 337,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-info",
                                                            children: [
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-name",
                                                                    children: "@kemi"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 339,
                                                                    columnNumber: 21
                                                                }, this),
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-time",
                                                                    children: "2 min ago"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 340,
                                                                    columnNumber: 21
                                                                }, this)
                                                            ]
                                                        }, void 0, true, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 338,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-amount r",
                                                            children: "+$50.00"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 342,
                                                            columnNumber: 19
                                                        }, this)
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 336,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "ph-tx",
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-icon s",
                                                            children: "↑"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 345,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-info",
                                                            children: [
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-name",
                                                                    children: "@tunde"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 347,
                                                                    columnNumber: 21
                                                                }, this),
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-time",
                                                                    children: "1 hr ago"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 348,
                                                                    columnNumber: 21
                                                                }, this)
                                                            ]
                                                        }, void 0, true, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 346,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-amount s",
                                                            children: "-$120.00"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 350,
                                                            columnNumber: 19
                                                        }, this)
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 344,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                    className: "ph-tx",
                                                    children: [
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-icon r",
                                                            children: "↓"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 353,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-info",
                                                            children: [
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-name",
                                                                    children: "@ada"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 355,
                                                                    columnNumber: 21
                                                                }, this),
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                                    className: "ph-tx-time",
                                                                    children: "Yesterday"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                                    lineNumber: 356,
                                                                    columnNumber: 21
                                                                }, this)
                                                            ]
                                                        }, void 0, true, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 354,
                                                            columnNumber: 19
                                                        }, this),
                                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "ph-tx-amount r",
                                                            children: "+$300.00"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                            lineNumber: 358,
                                                            columnNumber: 19
                                                        }, this)
                                                    ]
                                                }, void 0, true, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 352,
                                                    columnNumber: 17
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 335,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                    lineNumber: 327,
                                    columnNumber: 13
                                }, this)
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 326,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "phone-frame secondary",
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "ph-send-screen",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-back",
                                            children: "‹"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 367,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-send-title",
                                            children: "Send Bitcoin"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 368,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-send-sub",
                                            children: "Recipient"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 369,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-input",
                                            children: "@ada@dayfi.me"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 370,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            style: {
                                                fontSize: 9,
                                                color: 'var(--muted)',
                                                marginBottom: 4,
                                                textAlign: 'center'
                                            },
                                            children: "You will send Bitcoin On-Chain"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 371,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-amount-big",
                                            children: [
                                                "$700",
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    style: {
                                                        fontSize: 22,
                                                        opacity: 0.5
                                                    },
                                                    children: ".00"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 375,
                                                    columnNumber: 21
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 374,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-amount-sub",
                                            children: "0.0098 BTC"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 377,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            style: {
                                                background: 'rgba(255,255,255,0.08)',
                                                borderRadius: 8,
                                                padding: '5px 10px',
                                                fontSize: 10,
                                                textAlign: 'center',
                                                marginBottom: 16,
                                                color: 'var(--muted)'
                                            },
                                            children: "$920.22 Max"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 378,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "ph-continue",
                                            children: "Continue"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 381,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                    lineNumber: 366,
                                    columnNumber: 13
                                }, this)
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 365,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 324,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 308,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                className: "features-section",
                id: "features",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "reveal",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "section-label",
                                children: "What's inside"
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 390,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "section-title",
                                children: "Built for real life"
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 391,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "section-sub",
                                children: "Seamless. Borderless. Yours."
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 392,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 389,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "features-grid reveal",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "feature-card",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "feature-icon",
                                        children: "$"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 397,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        children: "Digital Dollars, Bitcoin & Gold"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 398,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        children: "One wallet for the tokens people actually trust — USDC, XLM, and Bitcoin. No complexity, just your money."
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 399,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 396,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "feature-card",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "feature-icon",
                                        children: "@"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 402,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        children: "Your @dayfi.me username"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 403,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        children: "Ditch complicated addresses. Send and receive using just one easy-to-remember name. No copy-paste, no stress."
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 404,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 401,
                                columnNumber: 11
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "feature-card",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "feature-icon",
                                        children: "🌐"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 407,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        children: "Borderless by nature"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 408,
                                        columnNumber: 13
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        children: "Built on Stellar. Send money across borders in seconds, with fees fractions of a cent. Anytime, anywhere."
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                        lineNumber: 409,
                                        columnNumber: 13
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                lineNumber: 406,
                                columnNumber: 11
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 395,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 388,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
                className: "cta-section",
                id: "download",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "cta-box reveal",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("h2", {
                            children: [
                                "Your money.",
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("br", {}, void 0, false, {
                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                    lineNumber: 417,
                                    columnNumber: 26
                                }, this),
                                "Your wallet."
                            ]
                        }, void 0, true, {
                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                            lineNumber: 417,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                            children: "The simplest way to store and send your digital dollars and native assets. Total control, starting now."
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                            lineNumber: 418,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "store-btns",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                    href: "#",
                                    className: "store-btn",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
                                            width: "22",
                                            height: "22",
                                            fill: "currentColor",
                                            viewBox: "0 0 24 24",
                                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                                d: "M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                lineNumber: 423,
                                                columnNumber: 17
                                            }, this)
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 422,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "store-btn-text",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "store-btn-sub",
                                                    children: "Download on the"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 426,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "store-btn-name",
                                                    children: "App Store"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 427,
                                                    columnNumber: 17
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 425,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                    lineNumber: 421,
                                    columnNumber: 13
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                    href: "#",
                                    className: "store-btn",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
                                            width: "22",
                                            height: "22",
                                            fill: "currentColor",
                                            viewBox: "0 0 24 24",
                                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                                d: "M3.18 23.76c.29.17.63.19.95.07l12.69-7.27-2.68-2.68-10.96 9.88zm-1.11-20.5c-.05.18-.07.37-.07.57v19.34c0 .2.02.39.07.57l.06.05 10.83-10.83v-.26L2.12 2.97l-.05.29zm14.44 11.48l-2.89-2.89 2.89-2.89 3.27 1.88c.93.53.93 1.4 0 1.94l-3.27 1.96zm-14.43 8.64l.06.06 12.69-7.27-2.68-2.68-10.07 9.89z"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                lineNumber: 432,
                                                columnNumber: 17
                                            }, this)
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 431,
                                            columnNumber: 15
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "store-btn-text",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "store-btn-sub",
                                                    children: "Get it on"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 435,
                                                    columnNumber: 17
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "store-btn-name",
                                                    children: "Google Play"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                                    lineNumber: 436,
                                                    columnNumber: 17
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                            lineNumber: 434,
                                            columnNumber: 15
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                                    lineNumber: 430,
                                    columnNumber: 13
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                            lineNumber: 420,
                            columnNumber: 11
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                            href: "#",
                            className: "apk-link",
                            children: "Download APK"
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                            lineNumber: 440,
                            columnNumber: 11
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                    lineNumber: 416,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 415,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("footer", {
                className: "dayfi-footer",
                children: [
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                        children: "© 2026 DayFi. Built on Stellar."
                    }, void 0, false, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 446,
                        columnNumber: 9
                    }, this),
                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$compiled$2f$react$2f$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$client$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                        href: "/privacy-policy",
                        children: "Privacy Policy"
                    }, void 0, false, {
                        fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                        lineNumber: 447,
                        columnNumber: 9
                    }, this)
                ]
            }, void 0, true, {
                fileName: "[project]/website/app/(website)/(landing)/page.tsx",
                lineNumber: 445,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true);
}
_s(LandingPage, "C28RL2Qn3k0rD1b/EHC8aVPdpyQ=");
_c = LandingPage;
var _c;
__turbopack_context__.k.register(_c, "LandingPage");
if (typeof globalThis.$RefreshHelpers$ === 'object' && globalThis.$RefreshHelpers !== null) {
    __turbopack_context__.k.registerExports(__turbopack_context__.m, globalThis.$RefreshHelpers$);
}
}),
]);

//# sourceMappingURL=website_app_%28website%29_%28landing%29_page_tsx_08789a19._.js.map