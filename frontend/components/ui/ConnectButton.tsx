"use client";

import { useAccount, useConnect, useDisconnect } from "wagmi";

export function ConnectButton() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 rounded-xl bg-white/5 px-4 py-2 border border-white/10">
          <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          <span className="text-sm font-medium text-white">
            {address.slice(0, 6)}...{address.slice(-4)}
          </span>
        </div>
        <button
          onClick={() => disconnect()}
          className="rounded-xl bg-red-500/10 border border-red-500/20 px-4 py-2 text-sm font-medium text-red-400 transition-all hover:bg-red-500/20"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2">
      {connectors.map((connector) => (
        <button
          key={connector.uid}
          onClick={() => connect({ connector })}
          disabled={isPending}
          className="rounded-xl bg-gradient-to-r from-violet-500 to-purple-600 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-violet-500/25 transition-all hover:shadow-xl hover:shadow-violet-500/30 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isPending
            ? "Connecting..."
            : `Connect ${
                connector.name === "Injected" ? "Wallet" : connector.name
              }`}
        </button>
      ))}
    </div>
  );
}
