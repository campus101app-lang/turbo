/// <reference types="vite/client" />

declare module "stellar-identicon-js";

interface ImportMetaEnv {
  readonly DEV: boolean;
  readonly PROD: boolean;
  readonly MODE: string;
  readonly VITE_SOROBAN_RPC_URL?: string;
  readonly VITE_HORIZON_URL: string;
  readonly VITE_NETWORK_PASSPHRASE: string;
  readonly VITE_CONTRACT_ID: string;
  readonly VITE_NETWORK: string;
  readonly VITE_USDC_CONTRACT_ID?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

declare module "*.svg?react" {
  import React from "react";
  const ReactComponent: React.FC<React.SVGProps<SVGSVGElement>>;
  export default ReactComponent;
}