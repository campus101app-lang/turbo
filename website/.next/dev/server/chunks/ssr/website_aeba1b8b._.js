module.exports = [
"[project]/website/db/faqData.ts [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "FaqQuestions",
    ()=>FaqQuestions,
    "FaqQuestionsWithGroup",
    ()=>FaqQuestionsWithGroup
]);
const FaqQuestions = [
    {
        ques: "What is DayFi?",
        ans: "DayFi is a fintech platform on a mission to make payments accessible for Africa. We enable fast, secure, and affordable cross-border transfers using stablecoin technology (USDC), making it easier for Africans to send and receive money globally."
    },
    {
        ques: "How do I create a DayFi account?",
        ans: "Simply download the app, enter your email address, verify it with the OTP sent to your inbox, create a secure password and passcode, then complete your profile with basic information. It takes less than 5 minutes!"
    },
    {
        ques: "Is DayFi available in my country?",
        ans: "DayFi is currently available in Nigeria and expanding across Africa. We're working hard to bring our services to more African countries soon. Stay tuned for updates!"
    },
    {
        ques: "What is USDC and why does DayFi use it?",
        ans: "USDC (USD Coin) is a stablecoin pegged 1:1 to the US Dollar. We use USDC because it enables instant, low-cost transfers without the volatility of traditional cryptocurrencies. Your money maintains its value throughout the transfer process."
    },
    {
        ques: "How fast are DayFi transfers?",
        ans: "Most transfers are completed within minutes! Because we leverage blockchain technology and USDC, we can process transfers much faster than traditional banking systems."
    },
    {
        ques: "How secure is DayFi?",
        ans: "Security is our top priority. We use bank-grade encryption, secure passcodes, biometric authentication (Face ID/Fingerprint), and partner with Smile ID for identity verification. Your funds and data are always protected."
    },
    {
        ques: "What makes DayFi different from other money transfer apps?",
        ans: "DayFi combines the speed and low cost of blockchain technology with the simplicity of traditional apps. We're built specifically for Africa, understanding local needs, and backed by trusted partners like Yellow Card and Smile ID to deliver a seamless experience."
    },
    {
        ques: "How do I contact DayFi support?",
        ans: "You can reach our support team through the in-app chat, email us at support@dayfi.co, or visit our Help Center. We're here to help 24/7!"
    }
];
const FaqQuestionsWithGroup = [
    // Getting Started
    {
        ques: "What is DayFi?",
        ans: "DayFi is a fintech platform on a mission to make payments accessible for Africa. We enable fast, secure, and affordable cross-border transfers using stablecoin technology (USDC), making it easier for Africans to send and receive money globally.",
        group: "Getting Started"
    },
    {
        ques: "How do I create a DayFi account?",
        ans: "Simply download the app, enter your email address, verify it with the OTP sent to your inbox, create a secure password and passcode, then complete your profile with basic information. It takes less than 5 minutes!",
        group: "Getting Started"
    },
    {
        ques: "Is DayFi available in my country?",
        ans: "DayFi is currently available in Nigeria and expanding across Africa. We're working hard to bring our services to more African countries soon. Stay tuned for updates!",
        group: "Getting Started"
    },
    {
        ques: "What documents do I need to verify my account?",
        ans: "You'll need a valid government-issued ID (National ID, International Passport, or Driver's License). Our identity verification is powered by Smile ID, ensuring your data is secure and the process is seamless.",
        group: "Getting Started"
    },
    {
        ques: "What makes DayFi different from other money transfer apps?",
        ans: "DayFi combines the speed and low cost of blockchain technology with the simplicity of traditional apps. We're built specifically for Africa, understanding local needs, and backed by trusted partners like Yellow Card and Smile ID to deliver a seamless experience.",
        group: "Getting Started"
    },
    // About USDC & Transfers
    {
        ques: "What is USDC and why does DayFi use it?",
        ans: "USDC (USD Coin) is a stablecoin pegged 1:1 to the US Dollar. We use USDC because it enables instant, low-cost transfers without the volatility of traditional cryptocurrencies. Your money maintains its value throughout the transfer process.",
        group: "USDC & Transfers"
    },
    {
        ques: "How fast are DayFi transfers?",
        ans: "Most transfers are completed within minutes! Because we leverage blockchain technology and USDC, we can process transfers much faster than traditional banking systems.",
        group: "USDC & Transfers"
    },
    {
        ques: "What are the transfer fees?",
        ans: "DayFi offers competitive rates with transparent pricing. You'll always see the exact fees before confirming any transfer. No hidden charges, ever.",
        group: "USDC & Transfers"
    },
    {
        ques: "What's the minimum and maximum transfer amount?",
        ans: "Transfer limits depend on your verification level. Basic verified users can send up to a certain limit, while fully verified users enjoy higher limits. Check your profile for your specific limits.",
        group: "USDC & Transfers"
    },
    // Security
    {
        ques: "How secure is DayFi?",
        ans: "Security is our top priority. We use bank-grade encryption, secure passcodes, biometric authentication (Face ID/Fingerprint), and partner with Smile ID for identity verification. Your funds and data are always protected.",
        group: "Security"
    },
    {
        ques: "What is a transaction PIN?",
        ans: "Your transaction PIN is a 4-digit code required to authorize all wallet transfers. It adds an extra layer of security to ensure only you can move your funds.",
        group: "Security"
    },
    {
        ques: "What should I do if I forget my passcode?",
        ans: "If you forget your passcode, you can reset it by logging out and using the 'Forgot Password' option. You'll verify your identity via email, then create a new passcode.",
        group: "Security"
    },
    {
        ques: "Can I enable biometric login?",
        ans: "Yes! DayFi supports Face ID and Fingerprint authentication for quick and secure access. You can enable this in your profile settings after setting up your passcode.",
        group: "Security"
    },
    // Partners & Technology
    {
        ques: "Who is Yellow Card?",
        ans: "Yellow Card is our trusted partner for crypto-to-fiat conversions. They're Africa's largest cryptocurrency exchange, enabling us to provide seamless cash-out options across multiple African countries.",
        group: "Partners & Technology"
    },
    {
        ques: "Who is Smile ID?",
        ans: "Smile ID is Africa's leading identity verification provider. They power our KYC (Know Your Customer) process, ensuring secure and reliable identity verification while keeping your personal data safe.",
        group: "Partners & Technology"
    },
    {
        ques: "Is my personal information safe with DayFi?",
        ans: "Absolutely. We follow strict data protection protocols and only collect information necessary to provide our services. Your data is encrypted and never shared with unauthorized third parties.",
        group: "Partners & Technology"
    },
    // Troubleshooting
    {
        ques: "My transfer is taking longer than expected. What should I do?",
        ans: "While most transfers complete in minutes, occasionally there may be delays due to network congestion or additional verification. If your transfer hasn't completed within 24 hours, please contact our support team.",
        group: "Troubleshooting"
    },
    {
        ques: "I sent money to the wrong recipient. Can I reverse it?",
        ans: "Unfortunately, once a transfer is confirmed, it cannot be reversed due to the nature of blockchain transactions. Always double-check recipient details before confirming. Contact support if you need assistance.",
        group: "Troubleshooting"
    },
    {
        ques: "Why was my transaction declined?",
        ans: "Transactions may be declined due to insufficient balance, exceeded limits, or security flags. Check your balance and verification status. If issues persist, contact support for assistance.",
        group: "Troubleshooting"
    },
    {
        ques: "How do I contact DayFi support?",
        ans: "You can reach our support team through the in-app chat, email us at support@dayfi.co, or visit our Help Center. We're here to help 24/7!",
        group: "Troubleshooting"
    }
];
}),
"[project]/website/app/(website)/(landing)/faq.tsx [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>__TURBOPACK__default__export__
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react-jsx-dev-runtime.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$db$2f$faqData$2e$ts__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/db/faqData.ts [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/image.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/client/app-dir/link.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react.js [app-ssr] (ecmascript)");
"use client";
;
;
;
;
;
function Faq() {
    const [activeIndex, setActiveIndex] = (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["useState"])(null);
    const toggleAccordion = (index)=>{
        setActiveIndex((prevIndex)=>prevIndex === index ? null : index);
    };
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
            className: "py-[80px]",
            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "max-content",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "container",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex flex-col items-center",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "relative inline-block mb-[8px]",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                            className: "text-[#5645F5] font-tertiary font-[700] text-[20px] leading-[28px] relative z-10",
                                            children: [
                                                "Answered Questions",
                                                " "
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                            lineNumber: 21,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "absolute inset-0 bg-[#45D5F5] h-[4px] top-[70%] transform -translate-y-[100%] opacity-60"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                            lineNumber: 25,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                    lineNumber: 20,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "w-[400px] max-xlsm:w-full relative",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "font-secondary  text-center font-[400] text-[30px] leading-[48px] text-[#2A0079]",
                                            children: [
                                                "Questions? We've got answers!",
                                                " "
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                            lineNumber: 29,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                            src: "/assets/svg/productStar.svg",
                                            blurDataURL: "/assets/svg/productStar.svg",
                                            priority: true,
                                            unoptimized: false,
                                            alt: "image",
                                            width: 23,
                                            height: 23,
                                            className: "absolute top-0 -right-4 w-[23px] h-[23px]"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                            lineNumber: 32,
                                            columnNumber: 17
                                        }, this),
                                        " "
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                    lineNumber: 28,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                            lineNumber: 19,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex justify-center",
                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "w-[786px] max-md:w-full mt-[32px]",
                                children: __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$db$2f$faqData$2e$ts__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["FaqQuestions"]?.slice(0, 4)?.map((item, index)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: `py-4 px-6 border-b border-[#D9D3FF] cursor-pointer transition-all duration-300 ${activeIndex === index ? "border-t-2 border-[#BDB6FB] pb-6" : ""}`,
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "flex items-center justify-between cursor-pointer",
                                                onClick: ()=>toggleAccordion(index),
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                                        className: "font-tertiary text-[18px] leading-[24px] text-[#2A0079] font-bold",
                                                        children: item.ques
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                        lineNumber: 60,
                                                        columnNumber: 23
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "transition-transform transform flex-shrink-0",
                                                        children: activeIndex === index ? /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "flex-shrink-0 transition ease-out rotate-[45deg] duration-300",
                                                            children: [
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                                    src: "/assets/svg/faqOpen.svg",
                                                                    blurDataURL: "/assets/svg/faqOpen.svg",
                                                                    priority: true,
                                                                    unoptimized: false,
                                                                    alt: "image",
                                                                    width: 20,
                                                                    height: 20,
                                                                    className: " w-[20px] h-[20px]"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                                    lineNumber: 66,
                                                                    columnNumber: 29
                                                                }, this),
                                                                " "
                                                            ]
                                                        }, void 0, true, {
                                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                            lineNumber: 65,
                                                            columnNumber: 27
                                                        }, this) : /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                            className: "flex-shrink-0 ease-out duration-300",
                                                            children: [
                                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                                    src: "/assets/svg/faqOpen.svg",
                                                                    blurDataURL: "/assets/svg/faqOpen.svg",
                                                                    priority: true,
                                                                    unoptimized: false,
                                                                    alt: "image",
                                                                    width: 20,
                                                                    height: 20,
                                                                    className: " w-[20px] h-[20px]"
                                                                }, void 0, false, {
                                                                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                                    lineNumber: 79,
                                                                    columnNumber: 29
                                                                }, this),
                                                                " "
                                                            ]
                                                        }, void 0, true, {
                                                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                            lineNumber: 78,
                                                            columnNumber: 27
                                                        }, this)
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                        lineNumber: 63,
                                                        columnNumber: 23
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                lineNumber: 56,
                                                columnNumber: 21
                                            }, this),
                                            activeIndex === index && /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: " mt-[20px] ",
                                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                                    className: "font-[400] font-primary text-[14px] leading-[20px]  text-[#302D53] ease-in-out duration-800",
                                                    children: item?.ans
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                    lineNumber: 95,
                                                    columnNumber: 25
                                                }, this)
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                                lineNumber: 94,
                                                columnNumber: 23
                                            }, this)
                                        ]
                                    }, index, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                        lineNumber: 49,
                                        columnNumber: 19
                                    }, this))
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                lineNumber: 47,
                                columnNumber: 15
                            }, this)
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                            lineNumber: 46,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex justify-center mt-[24px]",
                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$client$2f$app$2d$dir$2f$link$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                href: "/faqs",
                                className: "btn-primary flex justify-center items-center gap-2",
                                children: [
                                    "See All Questions",
                                    " "
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                                lineNumber: 108,
                                columnNumber: 15
                            }, this)
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                            lineNumber: 107,
                            columnNumber: 13
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                    lineNumber: 18,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
                lineNumber: 17,
                columnNumber: 9
            }, this)
        }, void 0, false, {
            fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
            lineNumber: 16,
            columnNumber: 7
        }, this)
    }, void 0, false, {
        fileName: "[project]/website/app/(website)/(landing)/faq.tsx",
        lineNumber: 15,
        columnNumber: 5
    }, this);
}
const __TURBOPACK__default__export__ = Faq;
}),
"[project]/website/app/(website)/(landing)/hero.tsx [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>__TURBOPACK__default__export__
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react-jsx-dev-runtime.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$styled$2d$jsx$2f$style$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/styled-jsx/style.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/image.js [app-ssr] (ecmascript)");
"use client";
;
;
;
function HomeHero() {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        className: "jsx-50dfa19f37f28187" + " " + "bg-white relative overflow-hidden min-h-[800px] max-lg:min-h-[700px] max-xlsm:min-h-[600px]",
        children: [
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$styled$2d$jsx$2f$style$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                id: "50dfa19f37f28187",
                children: "@keyframes shimmer{0%{background-position:-200%}to{background-position:200%}}.gradient-text.jsx-50dfa19f37f28187{-webkit-text-fill-color:transparent;background:linear-gradient(90deg,#2a0079 0%,#5645f5 25%,#45d5f5 50%,#5645f5 75%,#2a0079 100%) 0 0/200%;-webkit-background-clip:text;background-clip:text;animation:4s linear infinite shimmer}@keyframes pulse-glow{0%,to{box-shadow:0 0 #5645f566}50%{box-shadow:0 0 20px 5px #5645f533}}.btn-glow.jsx-50dfa19f37f28187:hover{animation:1.5s ease-in-out infinite pulse-glow}@keyframes float{0%,to{transform:translateY(0)}50%{transform:translateY(-5px)}}.float-badge.jsx-50dfa19f37f28187{animation:3s ease-in-out infinite float}"
            }, void 0, false, void 0, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "jsx-50dfa19f37f28187" + " " + "absolute inset-0 w-full h-full",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                    src: "/assets/png/heroBg.png",
                    blurDataURL: "/assets/png/heroBg.png",
                    priority: true,
                    unoptimized: false,
                    alt: "Hero background",
                    fill: true,
                    className: "object-cover object-center max-xlsm:blur-sm"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                    lineNumber: 40,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                lineNumber: 39,
                columnNumber: 7
            }, this),
            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "jsx-50dfa19f37f28187" + " " + "absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "jsx-50dfa19f37f28187" + " " + "flex items-center justify-center h-full  w-full",
                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "jsx-50dfa19f37f28187" + " " + "max-content",
                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "jsx-50dfa19f37f28187" + " " + "container",
                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "jsx-50dfa19f37f28187" + " " + "flex flex-col items-center w-[721px] max-mdxl:w-[500px] max-xlsm:w-[400px] max-sm:w-[270px]",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "jsx-50dfa19f37f28187" + " " + "float-badge mb-[24px] inline-flex items-center gap-[8px] bg-[#F6F5FE] border border-[#CAC5FC] rounded-full px-[16px] py-[8px]",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "jsx-50dfa19f37f28187" + " " + "w-[8px] h-[8px] bg-[#45D5F5] rounded-full animate-pulse"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 57,
                                                columnNumber: 20
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "jsx-50dfa19f37f28187" + " " + "font-primary font-[500] text-[14px] leading-[20px] text-[#5645F5]",
                                                children: "The Future of African Payments"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 58,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 56,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "jsx-50dfa19f37f28187" + " " + "font-secondary text-center font-[400] text-[60px] leading-[86px] max-mdxl:text-[40px] max-mdxl:leading-[50px] max-xlsm:text-[30px] max-xlsm:leading-[40px] text-[#2A0079]",
                                        children: [
                                            "Send Money",
                                            " ",
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "jsx-50dfa19f37f28187" + " " + "gradient-text",
                                                children: "Without Borders"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 66,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 64,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "jsx-50dfa19f37f28187" + " " + "mt-[32px] mr-[32px] ml-[32px] font-primary text-center font-[400] text-[16px] leading-[24px] text-[#302D53]",
                                        children: [
                                            "Seamless international payments for everyone. ",
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("br", {
                                                className: "jsx-50dfa19f37f28187"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 69,
                                                columnNumber: 65
                                            }, this),
                                            "Send, receive, and manage money across Africa and beyond with Dayfi's secure platform."
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 68,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "jsx-50dfa19f37f28187" + " " + "mt-[24px] flex items-center gap-[12px]",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                className: "jsx-50dfa19f37f28187" + " " + "flex -space-x-[8px]",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "jsx-50dfa19f37f28187" + " " + "w-[32px] h-[32px] rounded-full bg-[#CAC5FC] border-[2px] border-white flex items-center justify-center",
                                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            className: "jsx-50dfa19f37f28187" + " " + "text-[12px]",
                                                            children: "👩🏾"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                            lineNumber: 76,
                                                            columnNumber: 23
                                                        }, this)
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 75,
                                                        columnNumber: 21
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "jsx-50dfa19f37f28187" + " " + "w-[32px] h-[32px] rounded-full bg-[#95DBC4] border-[2px] border-white flex items-center justify-center",
                                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            className: "jsx-50dfa19f37f28187" + " " + "text-[12px]",
                                                            children: "👨🏿"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                            lineNumber: 79,
                                                            columnNumber: 23
                                                        }, this)
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 78,
                                                        columnNumber: 21
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "jsx-50dfa19f37f28187" + " " + "w-[32px] h-[32px] rounded-full bg-[#FFADD2] border-[2px] border-white flex items-center justify-center",
                                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                            className: "jsx-50dfa19f37f28187" + " " + "text-[12px]",
                                                            children: "👩🏽"
                                                        }, void 0, false, {
                                                            fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                            lineNumber: 82,
                                                            columnNumber: 23
                                                        }, this)
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 81,
                                                        columnNumber: 21
                                                    }, this),
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                                        className: "jsx-50dfa19f37f28187" + " " + "w-[32px] h-[32px] rounded-full bg-[#5645F5] border-[2px] border-white flex items-center justify-center text-white font-primary font-[600] text-[10px]",
                                                        children: "+1K"
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 84,
                                                        columnNumber: 21
                                                    }, this)
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 74,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                className: "jsx-50dfa19f37f28187" + " " + "font-primary font-[400] text-[12px] text-[#302D53]",
                                                children: "Active Users"
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 88,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 73,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("a", {
                                        href: "https://app.dayfi.co",
                                        target: "_blank",
                                        rel: "noopener noreferrer",
                                        className: "jsx-50dfa19f37f28187",
                                        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                            className: "jsx-50dfa19f37f28187" + " " + "mt-[68px] btn-primary !w-auto font-primary group flex items-center justify-center gap-[8px]",
                                            children: [
                                                "Start Sending Money",
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                    src: "/assets/svg/nextRoundArrow.svg",
                                                    blurDataURL: "/assets/svg/nextRoundArrow.svg",
                                                    priority: true,
                                                    unoptimized: false,
                                                    alt: "image",
                                                    width: 22,
                                                    height: 20,
                                                    className: " w-[22px] h-[20px]"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                    lineNumber: 101,
                                                    columnNumber: 21
                                                }, this),
                                                " "
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                            lineNumber: 99,
                                            columnNumber: 19
                                        }, this)
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 94,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "jsx-50dfa19f37f28187" + " " + "mt-[40px] font-primary text-center font-[400] text-[12px] leading-[16px] text-[#5A5775]",
                                        children: "Coming to"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 114,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                        src: "/assets/svg/comingArrow.svg",
                                        blurDataURL: "/assets/svg/comingArrow.svg",
                                        priority: true,
                                        unoptimized: false,
                                        alt: "image",
                                        width: 17,
                                        height: 37,
                                        className: "mt-[4px] w-[17px] h-[37px]"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 117,
                                        columnNumber: 17
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "jsx-50dfa19f37f28187" + " " + "mt-[3px] flex items-center justify-center max-sm:flex-wrap gap-[8px]",
                                        children: [
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                className: "jsx-50dfa19f37f28187" + " " + "btn-secondary !w-auto !py-[10px] flex items-center justify-center gap-[5px]",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                        src: "/assets/svg/appstore.svg",
                                                        blurDataURL: "/assets/svg/appstore.svg",
                                                        priority: true,
                                                        unoptimized: false,
                                                        alt: "image",
                                                        width: 13,
                                                        height: 15,
                                                        className: "w-[13px] h-[15px]"
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 129,
                                                        columnNumber: 21
                                                    }, this),
                                                    " ",
                                                    "App Store",
                                                    " "
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 128,
                                                columnNumber: 19
                                            }, this),
                                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("button", {
                                                className: "jsx-50dfa19f37f28187" + " " + "btn-secondary !w-auto !py-[10px] flex items-center justify-center gap-[5px]",
                                                children: [
                                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                        src: "/assets/svg/playstore.svg",
                                                        blurDataURL: "/assets/svg/playstore.svg",
                                                        priority: true,
                                                        unoptimized: false,
                                                        alt: "image",
                                                        width: 17,
                                                        height: 17,
                                                        className: "w-[17px] h-[17px]"
                                                    }, void 0, false, {
                                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                        lineNumber: 142,
                                                        columnNumber: 21
                                                    }, this),
                                                    " ",
                                                    "Play Store",
                                                    " "
                                                ]
                                            }, void 0, true, {
                                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                                lineNumber: 141,
                                                columnNumber: 19
                                            }, this)
                                        ]
                                    }, void 0, true, {
                                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                        lineNumber: 127,
                                        columnNumber: 17
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                                lineNumber: 54,
                                columnNumber: 15
                            }, this)
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                            lineNumber: 53,
                            columnNumber: 13
                        }, this)
                    }, void 0, false, {
                        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                        lineNumber: 52,
                        columnNumber: 11
                    }, this)
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                    lineNumber: 51,
                    columnNumber: 9
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
                lineNumber: 50,
                columnNumber: 7
            }, this)
        ]
    }, void 0, true, {
        fileName: "[project]/website/app/(website)/(landing)/hero.tsx",
        lineNumber: 7,
        columnNumber: 5
    }, this);
}
const __TURBOPACK__default__export__ = HomeHero;
}),
"[project]/website/app/(website)/(landing)/homePartners.tsx [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>__TURBOPACK__default__export__
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react-jsx-dev-runtime.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/image.js [app-ssr] (ecmascript)");
"use client";
;
;
const partners = [
    {
        name: "Stellar",
        logo: "/assets/svg/partners/stellar.png"
    },
    // { name: "Mastercard", logo: "/assets/svg/partners/mastercard.svg" },
    {
        name: "Flutterwave",
        logo: "/assets/svg/partners/flutterwave.png"
    },
    //   { name: "Paystack", logo: "/assets/svg/partners/paystack.svg" },
    {
        name: "Yellow Card",
        logo: "/assets/svg/partners/yellowcard.svg"
    },
    // { name: "Visa", logo: "/assets/svg/partners/visa.png", scale: "scale-[0.75]" },
    {
        name: "AWS",
        logo: "/assets/svg/partners/aws.svg",
        scale: "scale-[0.8]"
    }
];
function HomePartners() {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
            className: "py-[80px] bg-white",
            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "max-content",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "container",
                    children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                        className: "flex flex-col items-center",
                        children: [
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "relative inline-block mb-[8px]",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                        className: "text-[#5645F5] font-tertiary font-[700] text-[20px] leading-[28px] relative z-10",
                                        children: "Trusted Partners"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                        lineNumber: 23,
                                        columnNumber: 33
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                        className: "absolute inset-0 bg-[#45D5F5] h-[4px] top-[70%] transform -translate-y-[100%] opacity-60"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                        lineNumber: 27,
                                        columnNumber: 33
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                lineNumber: 22,
                                columnNumber: 29
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "w-[500px] max-xlsm:w-full relative",
                                children: [
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                        className: "font-secondary text-center font-[400] text-[30px] leading-[48px] text-[#2A0079]",
                                        children: "Backed by industry leaders"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                        lineNumber: 31,
                                        columnNumber: 33
                                    }, this),
                                    /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                        src: "/assets/svg/productStar.svg",
                                        blurDataURL: "/assets/svg/productStar.svg",
                                        priority: true,
                                        unoptimized: false,
                                        alt: "image",
                                        width: 23,
                                        height: 23,
                                        className: "absolute top-0 -right-4 w-[23px] h-[23px]"
                                    }, void 0, false, {
                                        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                        lineNumber: 34,
                                        columnNumber: 33
                                    }, this)
                                ]
                            }, void 0, true, {
                                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                lineNumber: 30,
                                columnNumber: 29
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                className: "mt-[10px] w-[685px] text-center max-sixm:w-full text-[#302D53] font-primary font-[400] text-[16px] leading-[24px]",
                                children: "We partner with world-class financial institutions and technology providers to deliver secure, reliable cross-border payments."
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                lineNumber: 46,
                                columnNumber: 29
                            }, this),
                            /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                className: "mt-[48px] w-full overflow-hidden",
                                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "flex items-center justify-center gap-[56px] max-md:gap-[40px] flex-wrap",
                                    children: partners.map((partner, index)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "w-[160px] h-[70px] flex items-center justify-center hover:scale-110 transition-all duration-300",
                                            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                                src: partner.logo,
                                                alt: partner.name,
                                                width: 140,
                                                height: 50,
                                                className: `object-contain max-h-[50px] w-auto ${partner.scale || ""}`
                                            }, void 0, false, {
                                                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                                lineNumber: 58,
                                                columnNumber: 45
                                            }, this)
                                        }, index, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                            lineNumber: 54,
                                            columnNumber: 41
                                        }, this))
                                }, void 0, false, {
                                    fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                    lineNumber: 52,
                                    columnNumber: 33
                                }, this)
                            }, void 0, false, {
                                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                                lineNumber: 51,
                                columnNumber: 29
                            }, this)
                        ]
                    }, void 0, true, {
                        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                        lineNumber: 21,
                        columnNumber: 25
                    }, this)
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                    lineNumber: 20,
                    columnNumber: 21
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
                lineNumber: 19,
                columnNumber: 17
            }, this)
        }, void 0, false, {
            fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
            lineNumber: 18,
            columnNumber: 13
        }, this)
    }, void 0, false, {
        fileName: "[project]/website/app/(website)/(landing)/homePartners.tsx",
        lineNumber: 17,
        columnNumber: 9
    }, this);
}
const __TURBOPACK__default__export__ = HomePartners;
}),
"[project]/website/app/(website)/(landing)/homeSecurity.tsx [app-ssr] (ecmascript)", ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s([
    "default",
    ()=>__TURBOPACK__default__export__
]);
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/dist/server/route-modules/app-page/vendored/ssr/react-jsx-dev-runtime.js [app-ssr] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/website/node_modules/next/image.js [app-ssr] (ecmascript)");
"use client";
;
;
const securityFeatures = [
    {
        icon: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
            width: "28",
            height: "28",
            viewBox: "0 0 24 24",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M12 22C12 22 20 18 20 12V5L12 2L4 5V12C4 18 12 22 12 22Z",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 9,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0)),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M9 12L11 14L15 10",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 10,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0))
            ]
        }, void 0, true, {
            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
            lineNumber: 8,
            columnNumber: 7
        }, ("TURBOPACK compile-time value", void 0)),
        title: "Bank-Grade Encryption",
        description: "AES-256 encryption protects every byte of your data",
        gradient: "from-[#5645F5] to-[#8B7BF7]"
    },
    {
        icon: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
            width: "28",
            height: "28",
            viewBox: "0 0 24 24",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("rect", {
                    x: "3",
                    y: "11",
                    width: "18",
                    height: "11",
                    rx: "2",
                    ry: "2",
                    stroke: "currentColor",
                    strokeWidth: "2"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 20,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0)),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M7 11V7C7 5.67392 7.52678 4.40215 8.46447 3.46447C9.40215 2.52678 10.6739 2 12 2C13.3261 2 14.5979 2.52678 15.5355 3.46447C16.4732 4.40215 17 5.67392 17 7V11",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 21,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0)),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("circle", {
                    cx: "12",
                    cy: "16",
                    r: "1",
                    fill: "currentColor"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 22,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0))
            ]
        }, void 0, true, {
            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
            lineNumber: 19,
            columnNumber: 7
        }, ("TURBOPACK compile-time value", void 0)),
        title: "2FA & Biometrics",
        description: "Multi-layer authentication for every transaction",
        gradient: "from-[#10B981] to-[#34D399]"
    },
    {
        icon: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
            width: "28",
            height: "28",
            viewBox: "0 0 24 24",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M22 11.08V12C21.9988 14.1564 21.3005 16.2547 20.0093 17.9818C18.7182 19.709 16.9033 20.9725 14.8354 21.5839C12.7674 22.1953 10.5573 22.1219 8.53447 21.3746C6.51168 20.6273 4.78465 19.2461 3.61096 17.4371C2.43727 15.628 1.87979 13.4881 2.02168 11.3363C2.16356 9.18455 2.99721 7.13631 4.39828 5.49706C5.79935 3.85781 7.69279 2.71537 9.79619 2.24013C11.8996 1.7649 14.1003 1.98232 16.07 2.85999",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 32,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0)),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M22 4L12 14.01L9 11.01",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 33,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0))
            ]
        }, void 0, true, {
            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
            lineNumber: 31,
            columnNumber: 7
        }, ("TURBOPACK compile-time value", void 0)),
        title: "Licensed & Regulated",
        description: "Full compliance across all operating jurisdictions",
        gradient: "from-[#EC4899] to-[#F472B6]"
    },
    {
        icon: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
            width: "28",
            height: "28",
            viewBox: "0 0 24 24",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2Z",
                    stroke: "currentColor",
                    strokeWidth: "2"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 43,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0)),
                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                    d: "M12 6V12L16 14",
                    stroke: "currentColor",
                    strokeWidth: "2",
                    strokeLinecap: "round",
                    strokeLinejoin: "round"
                }, void 0, false, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 44,
                    columnNumber: 9
                }, ("TURBOPACK compile-time value", void 0))
            ]
        }, void 0, true, {
            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
            lineNumber: 42,
            columnNumber: 7
        }, ("TURBOPACK compile-time value", void 0)),
        title: "24/7 Monitoring",
        description: "AI-powered fraud detection that never sleeps",
        gradient: "from-[#45D5F5] to-[#67E8F9]"
    }
];
const certifications = [
    {
        name: "PCI DSS",
        desc: "Level 1"
    },
    {
        name: "ISO 27001",
        desc: "Certified"
    },
    {
        name: "SOC 2",
        desc: "Type II"
    },
    {
        name: "GDPR",
        desc: "Compliant"
    }
];
function HomeSecurity() {
    return /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("section", {
        className: "py-[100px] bg-gradient-to-br from-[#0A0520] via-[#1A0F3C] to-[#0A0520] relative overflow-hidden",
        children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
            className: "max-content relative z-10",
            children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                className: "container",
                children: /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                    className: "flex flex-col items-center",
                    children: [
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "flex flex-col items-center text-center mb-[48px]",
                            children: [
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "relative inline-block mb-[8px]",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("h3", {
                                            className: "text-[#45D5F5] font-tertiary font-[700] text-[20px] leading-[28px] relative z-10",
                                            children: "Bank-Level Security"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 100,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: "absolute inset-0 bg-[#5645F5] h-[4px] top-[70%] transform -translate-y-[100%] opacity-60"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 103,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                    lineNumber: 99,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "relative mt-[8px]",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "font-secondary font-[400] text-[36px] leading-[48px] max-xlsm:text-[28px] max-xlsm:leading-[38px] text-white",
                                            children: [
                                                "Your money is protected",
                                                " ",
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                                    className: "text-[#45D5F5]",
                                                    children: "24/7/365"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                                    lineNumber: 109,
                                                    columnNumber: 19
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 107,
                                            columnNumber: 17
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])(__TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$image$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["default"], {
                                            src: "/assets/svg/productStar.svg",
                                            blurDataURL: "/assets/svg/productStar.svg",
                                            priority: true,
                                            unoptimized: false,
                                            alt: "star",
                                            width: 23,
                                            height: 23,
                                            className: "absolute top-0 -right-8 w-[23px] h-[23px] max-lg:hidden"
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 111,
                                            columnNumber: 17
                                        }, this)
                                    ]
                                }, void 0, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                    lineNumber: 106,
                                    columnNumber: 15
                                }, this),
                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                    className: "mt-[16px] max-w-[580px] text-[#A9A6B8] font-primary font-[400] text-[16px] leading-[26px]",
                                    children: "Every transaction passes through multiple layers of enterprise-grade security. Your funds are never at risk."
                                }, void 0, false, {
                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                    lineNumber: 123,
                                    columnNumber: 15
                                }, this)
                            ]
                        }, void 0, true, {
                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                            lineNumber: 98,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "w-full max-w-[900px] grid grid-cols-4 max-lg:grid-cols-2 max-sm:grid-cols-1 gap-[16px]",
                            children: securityFeatures.map((feature, index)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "group relative bg-white/5 backdrop-blur-sm rounded-[16px] p-[20px] border border-white/10 hover:border-[#5645F5]/50 hover:bg-white/10 transition-all duration-300 flex flex-col items-center text-center",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                            className: `w-[52px] h-[52px] rounded-[12px] bg-gradient-to-br ${feature.gradient} flex items-center justify-center text-white mb-[16px] group-hover:scale-110 transition-transform duration-300`,
                                            children: feature.icon
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 136,
                                            columnNumber: 19
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "font-tertiary font-[600] text-[16px] leading-[22px] text-white",
                                            children: feature.title
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 139,
                                            columnNumber: 19
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("p", {
                                            className: "mt-[8px] font-primary font-[400] text-[13px] leading-[20px] text-[#A9A6B8]",
                                            children: feature.description
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 142,
                                            columnNumber: 19
                                        }, this)
                                    ]
                                }, index, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                    lineNumber: 132,
                                    columnNumber: 17
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                            lineNumber: 130,
                            columnNumber: 13
                        }, this),
                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                            className: "mt-[40px] flex flex-wrap items-center justify-center gap-[12px]",
                            children: certifications.map((cert, index)=>/*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("div", {
                                    className: "flex items-center gap-[6px] bg-[#5645F5]/10 border border-[#5645F5]/30 rounded-full px-[14px] py-[6px]",
                                    children: [
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("svg", {
                                            width: "14",
                                            height: "14",
                                            viewBox: "0 0 24 24",
                                            fill: "none",
                                            xmlns: "http://www.w3.org/2000/svg",
                                            children: [
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                                    d: "M12 22C12 22 20 18 20 12V5L12 2L4 5V12C4 18 12 22 12 22Z",
                                                    stroke: "#5645F5",
                                                    strokeWidth: "2",
                                                    strokeLinecap: "round",
                                                    strokeLinejoin: "round"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                                    lineNumber: 157,
                                                    columnNumber: 21
                                                }, this),
                                                /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("path", {
                                                    d: "M9 12L11 14L15 10",
                                                    stroke: "#5645F5",
                                                    strokeWidth: "2",
                                                    strokeLinecap: "round",
                                                    strokeLinejoin: "round"
                                                }, void 0, false, {
                                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                                    lineNumber: 158,
                                                    columnNumber: 21
                                                }, this)
                                            ]
                                        }, void 0, true, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 156,
                                            columnNumber: 19
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-primary font-[500] text-[12px] text-white",
                                            children: cert.name
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 160,
                                            columnNumber: 19
                                        }, this),
                                        /*#__PURE__*/ (0, __TURBOPACK__imported__module__$5b$project$5d2f$website$2f$node_modules$2f$next$2f$dist$2f$server$2f$route$2d$modules$2f$app$2d$page$2f$vendored$2f$ssr$2f$react$2d$jsx$2d$dev$2d$runtime$2e$js__$5b$app$2d$ssr$5d$__$28$ecmascript$29$__["jsxDEV"])("span", {
                                            className: "font-primary font-[400] text-[11px] text-[#A9A6B8]",
                                            children: cert.desc
                                        }, void 0, false, {
                                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                            lineNumber: 161,
                                            columnNumber: 19
                                        }, this)
                                    ]
                                }, index, true, {
                                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                                    lineNumber: 152,
                                    columnNumber: 17
                                }, this))
                        }, void 0, false, {
                            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                            lineNumber: 150,
                            columnNumber: 13
                        }, this)
                    ]
                }, void 0, true, {
                    fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                    lineNumber: 96,
                    columnNumber: 11
                }, this)
            }, void 0, false, {
                fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
                lineNumber: 95,
                columnNumber: 9
            }, this)
        }, void 0, false, {
            fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
            lineNumber: 94,
            columnNumber: 7
        }, this)
    }, void 0, false, {
        fileName: "[project]/website/app/(website)/(landing)/homeSecurity.tsx",
        lineNumber: 62,
        columnNumber: 5
    }, this);
}
const __TURBOPACK__default__export__ = HomeSecurity;
}),
];

//# sourceMappingURL=website_aeba1b8b._.js.map