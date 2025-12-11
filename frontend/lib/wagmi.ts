"use client";

import { http, createConfig } from "wagmi";
import { mainnet, sepolia, baseSepolia } from "wagmi/chains";
import { injected, walletConnect } from "wagmi/connectors";

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "demo";

export const config = createConfig({
  chains: [mainnet, sepolia, baseSepolia],
  connectors: [injected(), walletConnect({ projectId })],
  transports: {
    [mainnet.id]: http(),
    [sepolia.id]: http(),
    [baseSepolia.id]: http(),
  },
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
