import React, { useRef, useState } from "react";
import { useLocation } from "react-router-dom";

// import { useOpenWalletConnect } from "@/components/wallet/WalletConnectModal";
import { LogoTiles } from "@/components/protocol/LogoTiles";
// import { useWallet } from "@/hooks/useWallet";

const Header: React.FC = () => {
  // const openConnectModal = useOpenWalletConnect();
  // const { connected, publicKey, disconnect } = useWallet();

  // const truncated =
  //   connected && publicKey
  //     ? `${publicKey.slice(0, 4)}…${publicKey.slice(-4)}`
  //     : null;

  return (
    <header className="header-chrome sticky top-0 z-50 min-h-14">
      <div className="editorial-container flex h-full min-h-14 w-full items-center justify-between gap-3 py-2">
        {/* Logo — left */}
        <LogoTiles variant="wordmark" />

        {/* Connect Wallet — right */}
        {/* <button
          type="button"
          onClick={connected ? disconnect : openConnectModal}
          className="shrink-0 inline-flex items-center justify-center text-[15px] h-12 !rounded-4xl !py-5 px-5 bg-zap-ink text-zap-bg font-body font-semibold normal-case tracking-normal transition-opacity hover:opacity-90"
        >
          {truncated ? `Wallet · ${truncated}` : "Connect Wallet"}
        </button> */}
      </div>
    </header>
  );
};

export default Header;