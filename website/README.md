# Zap402 · Frontend

React 18 + Vite + TypeScript client for the Zap402 pay-per-query AI agent marketplace. Users browse AI agents, pay per prompt in USDC via Stellar, and get responses from 20+ models — with full on-chain receipts and a compare flow across agents in the same category.

---

## Stack

| Tool | Purpose |
|------|---------|
| **React 18 + TypeScript** | UI components and type safety |
| **Vite** | Dev server, HMR, production build |
| **TailwindCSS** | Utility classes with Zap402 design tokens |
| **Zustand** | Wallet, profile, and conversation state |
| **React Router v6** | Shell layout, terminal tabs, `/@handle` pages |
| **Groq API** | `llama-3.3-70b-versatile` — primary model + automatic fallback |
| **Anthropic API** | `claude-sonnet-4-20250514` — premium model for Anthropic agents |

---

## Quick start

```bash
cd frontend-scaffold
cp .env.example .env
# Fill in required variables (see below)
npm install
npm run dev
```

`npm run dev` starts Vite + the local dev API together. Use `npm run dev:vite` for frontend only.

---

## Environment variables

Copy `.env.example` to `.env` in this folder. **Restart the dev server after any change.**

| Variable | Required | Purpose |
|----------|----------|---------|
| `VITE_CONTRACT_ID` | **Yes** | Deployed Soroban contract address (`C…`). Without this, on-chain features are disabled and an amber banner appears. |
| `VITE_GROQ_API_KEY` | **Yes** | Powers `llama-3.3-70b-versatile` — used for all non-Anthropic agents and as the automatic fallback for all agents. |
| `VITE_ANTHROPIC_API_KEY` | **Yes** | Powers `claude-sonnet-4-20250514` — used for Anthropic-provider agents (Claude Agent, etc.). |
| `VITE_NETWORK` | No | `TESTNET` (default) \| `MAINNET` |
| `VITE_HORIZON_URL` | No | Horizon HTTP base URL override |
| `VITE_NETWORK_PASSPHRASE` | No | Network passphrase (defaults in `.env.example`) |
| `VITE_SOROBAN_RPC_URL` | No | Soroban RPC override |
| `VITE_USDC_CONTRACT_ID` | No | USDC SAC override (required for mainnet) |
| `VITE_IMGBB_API_KEY` | No | Profile photo upload; users can paste an `https` URL without it |

---

## npm scripts

| Script | What it does |
|--------|-------------|
| `npm run dev` | Vite + local dev API (recommended) |
| `npm run dev:vite` | Frontend only |
| `npm run dev:api` | Dev API only |
| `npm run build` | Production bundle → `build/` |
| `npm run preview` | Serve production build locally |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run lint` | ESLint on `src/` |
| `npm test` | Vitest once |
| `npm run test:watch` | Vitest watch mode |

---

## Routes

| Route | Component | Purpose |
|-------|-----------|---------|
| `/terminal/chat` | `TerminalChatPage` | Pay-per-query chat, payment gate, compare flow |
| `/terminal/discover` | `SearchPage` | Agent discovery with category filters |
| `/terminal/purchases` | `PurchasesTab` | Deal history with resume + compare |
| `/terminal/profile` | Profile tab | User profile and settings |
| `/terminal/earnings` | Earnings tab | Transaction history + withdraw |
| `/@:handle` | `ZapPage` | Agent portfolio — capabilities, pricing, sample prompts |
| `/network` | Network page | Creator discovery leaderboard |
| `/register` | Register page | New profile creation |

---

## Core user flows

### Pay-per-query (TerminalChatPage)

1. Select an agent from the sidebar (filtered by category)
2. Type a prompt — the **category classifier** (`src/lib/categoryClassifier.ts`) detects intent automatically
3. Hit Send → `PaymentGateCard` appears with agent name, category, USDC price
4. Click **Pay** → `payToAsk()` calls Stellar contract → wallet signs → TX confirmed
5. `TxConfirmedBubble` renders: hash, "Copy Hash", "View on Explorer"
6. AI response arrives (Claude for Anthropic agents, Groq/Llama for others; automatic Llama fallback if primary fails — shown with "llama-3.3 fallback" badge)
7. **Compare strip** under the response — same-category agents not yet used in this conversation

### Compare flow

- Click any agent in the compare strip
- New `PaymentGateCard` queued with the same original prompt
- Pay → response stacked below previous responses
- All agents used in a conversation tracked in `usedAgentIds`

### Agent portfolio (ZapPage)

- Visit `/@handle` for any registered agent
- See: category, provider color, live stats, capability list, how-it-works steps
- Click a sample prompt → navigates to `/terminal/chat` with agent pre-selected and prompt auto-sent
- Click "Try [Agent]" → Chat page with agent activated and keyboard focused

### Deal history (PurchasesTab)

- All conversations persisted to `localStorage` under key `zap402_conversations_v2`
- Each card shows: agents used, USDC spent, TX hashes, response preview
- **Continue** → resumes conversation at `/terminal/chat` with `resumeConvId` in navigation state
- **Compare in [Category]** → modal with unused same-category agents → navigate to chat with compare pre-queued

---

## Navigation state contract

Pages communicate via `useNavigate(..., { state })`. The shape accepted by `TerminalChatPage`:

```typescript
interface ChatNavState {
  agent?: AgentOption;       // pre-select this agent
  resumeConvId?: string;     // resume an existing conversation
  promptText?: string;       // pre-fill input AND auto-send after mount
  focusInput?: boolean;      // just focus the textarea, no auto-send
}
```

Example from ZapPage sample prompt click:
```typescript
navigate("/terminal/chat", {
  state: { agent: agentOption, promptText: "Analyze DeFi in Africa 2025", focusInput: true }
});
```

The `promptText` field triggers `window.dispatchEvent(new CustomEvent("zap402:autosend", ...))` after a 250ms delay, which `TerminalChatPage` listens for via `useEffect`. This avoids stale-closure issues with `handleSend` at navigation time.

---

## Conversation persistence

Conversations are stored in `localStorage`:

```typescript
// Key: "zap402_conversations_v2"
interface Conversation {
  id: string;
  title: string;
  category: CategoryType;
  createdAt: number;
  updatedAt: number;
  messages: ConvMessage[];
  usedAgentIds: string[];   // prevents duplicate compare suggestions
}

interface ConvMessage {
  id: string;
  role: "user" | "assistant";
  content: string;           // TX bubbles use "__TX_CONFIRMED__:hash:price" prefix
  agentId: string;
  agentName: string;
  agentProvider: string;
  timestamp: number;
  txHash?: string;
  category?: CategoryType;
  phase: "pending_payment" | "paid" | "free";
}
```

TX confirmation messages use a special prefix so they render as `TxConfirmedBubble` components rather than text bubbles.

---

## Category classifier

`src/lib/categoryClassifier.ts` — auto-detects prompt intent before routing to a payment gate.

```typescript
import { classifyCategory } from "@/lib/categoryClassifier";

classifyCategory("write a Soroban smart contract in Rust");  // → "code"
classifyCategory("what is the fintech market in West Africa"); // → "research"
classifyCategory("a neon cyberpunk city at night, ultra HD");  // → "image"
```

Algorithm:
1. Score each category against ~200 weighted keyword/phrase signals
2. Apply 1.5× bonus for signals appearing in the first 8 words
3. Apply structural regex bonuses (camelCase → code; question starters → research; "in the style of" → image)
4. Return highest-scoring category; ties broken toward "research"; no-signal defaults to "chat"

---

## AI routing

| Agent provider | Primary model | Fallback |
|---------------|--------------|---------|
| Anthropic / Claude | `claude-sonnet-4-20250514` | `llama-3.3-70b-versatile` |
| All others | `llama-3.3-70b-versatile` | `llama-3.3-70b-versatile` (different system prompt) |

When the fallback is used, the response is tagged with a `llama-3.3 fallback` badge in the UI. The system prompt for fallback responses includes a note identifying it as a Llama stand-in on behalf of the original agent.

---

## Layout architecture

`DashboardLayout` (`components/layout/DashboardLayout.tsx`) uses a fixed full-viewport flex column:

```
fixed inset-0 flex flex-col
├── DashboardTopBar     (h-14, shrink-0)
└── flex flex-1 min-h-0
    ├── DashboardSidebar    (fixed width, internal scroll)
    └── main                (flex-1 min-w-0 min-h-0 overflow-y-auto)
        └── flex flex-col flex-1 min-h-0
            └── <Outlet />
```

**Critical rule:** every flex ancestor between the shell and a scrollable element must have `min-h-0`. Without this, `overflow-y-auto` never activates because the browser calculates infinite available height.

For `TerminalChatPage` specifically:
- `isCenterState` → outer div is `min-h-full` (natural vertical centering, shell scrolls)
- Active chat → outer div is `flex-1 min-h-0` (shell constrains height, message list scrolls internally)

---

## Design system

- **Fonts:** Bebas Neue (display), Space Mono (body/mono)
- **Colors (CSS vars):** `--color-ink`, `--color-teal` (`#00d4aa`), `--color-brand` (`#ff6b00`), semantic success/error
- **Tailwind classes:** `zap-ink`, `zap-brand`, `zap-teal`, `zap-bg-raised`, `zap-border`, `zap-ink-faint`, `zap-ink-muted`
- **Agent colors:** provider-keyed (Anthropic → amber, OpenAI → emerald, Google → blue, Perplexity → purple, etc.)
- **Receipt aesthetic:** every response is a deal receipt — agent avatar, category badge, TX hash, timestamp all visible

---

## Project layout

```
src/
  pages/
    terminal/
      TerminalChatPage.tsx    # pay-per-query chat, payment gate, compare
      SearchPage.tsx          # agent discovery + category filters
      PurchasesTab.tsx        # deal history, resume, compare modal
    ZapPage.tsx               # agent portfolio page
  components/
    layout/
      DashboardLayout.tsx     # app shell
      DashboardSidebar.tsx    # nav
      DashboardTopBar.tsx     # header
    wallet/                   # WalletConnectModal, wallet primitives
    clone/                    # legacy CloneChat
    primitives/               # Loader, Avatar, Card, etc.
  hooks/
    useWallet.ts              # Freighter + xBull connection
    useZapPayment.ts          # payToAsk, payment helpers
    useContract.ts            # Soroban contract calls
    useOnChainAgents.ts       # fetch agent profiles from chain
  state/
    profileStore.ts           # Zustand profile state
    walletStore.ts            # Zustand wallet state
  lib/
    categoryClassifier.ts     # prompt intent detection
  constants/
    terminalNav.ts            # sidebar nav config
server/
  dev-api.mjs                 # local dev API (legacy clone proxy)
```

---

## Build & quality

```bash
npm run build       # production bundle
npm run typecheck   # TypeScript check
npm run lint        # ESLint
npm test            # Vitest
```

CI: `.github/workflows/frontend-ci.yml` runs build + lint on every push.

---

## Common issues

**Amber banner ("contract ID not configured")** — set `VITE_CONTRACT_ID` in `.env` after deploying the Soroban contract, then restart Vite.

**AI responses not working** — check `VITE_GROQ_API_KEY` (required for all agents) and `VITE_ANTHROPIC_API_KEY` (required for Claude agents). Both must be set and valid.

**Payment fails with "InsufficientBalance"** — top up your testnet wallet. Get testnet XLM from `https://friendbot.stellar.org/?addr=<YOUR_ADDRESS>`.

**Layout broken / chat doesn't scroll** — ensure the page's outer div uses `flex-1 min-h-0` when in active chat state and `min-h-full` in center state. Every ancestor in the flex tree must have `min-h-0`.

**Compare strip not appearing** — only appears on the most recent assistant message in a conversation. If all same-category agents have already been used (`usedAgentIds`), the strip is hidden.