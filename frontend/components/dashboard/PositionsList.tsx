"use client";

import { useState } from "react";
import { useAccount } from "wagmi";

interface Position {
  poolId: string;
  token0: string;
  token1: string;
  pendingFees0: string;
  pendingFees1: string;
  yieldShares: string;
  claimableYield0: string;
  claimableYield1: string;
  strategy: string;
  apy: string;
}

// Demo data - in production, this would come from contract reads
const DEMO_POSITIONS: Position[] = [
  {
    poolId: "0x1234...5678",
    token0: "ETH",
    token1: "USDC",
    pendingFees0: "0.0542",
    pendingFees1: "142.50",
    yieldShares: "1,234",
    claimableYield0: "0.0123",
    claimableYield1: "32.45",
    strategy: "Aave V3",
    apy: "4.2%",
  },
  {
    poolId: "0xabcd...efgh",
    token0: "WBTC",
    token1: "ETH",
    pendingFees0: "0.00234",
    pendingFees1: "0.145",
    yieldShares: "567",
    claimableYield0: "0.00056",
    claimableYield1: "0.034",
    strategy: "Compound V3",
    apy: "3.8%",
  },
];

export function PositionsList() {
  const { isConnected } = useAccount();
  const [positions] = useState<Position[]>(DEMO_POSITIONS);

  if (!isConnected) {
    return (
      <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 p-8 text-center backdrop-blur-xl">
        <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-violet-500/10">
          <svg
            className="h-8 w-8 text-violet-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
        </div>
        <h3 className="text-lg font-semibold text-white">
          Connect Your Wallet
        </h3>
        <p className="mt-2 text-sm text-gray-400">
          Connect your wallet to view your YieldForge positions
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {positions.map((position, index) => (
        <PositionCard key={index} position={position} />
      ))}
    </div>
  );
}

function PositionCard({ position }: { position: Position }) {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div className="overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 backdrop-blur-xl transition-all duration-300 hover:border-white/20">
      {/* Header */}
      <div
        className="flex cursor-pointer items-center justify-between p-6"
        onClick={() => setIsExpanded(!isExpanded)}
      >
        <div className="flex items-center gap-4">
          {/* Token Pair */}
          <div className="flex -space-x-2">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-violet-500 to-purple-600 text-sm font-bold text-white ring-2 ring-gray-900">
              {position.token0.slice(0, 2)}
            </div>
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-cyan-600 text-sm font-bold text-white ring-2 ring-gray-900">
              {position.token1.slice(0, 2)}
            </div>
          </div>

          <div>
            <h3 className="font-semibold text-white">
              {position.token0}/{position.token1}
            </h3>
            <p className="text-xs text-gray-500">Pool: {position.poolId}</p>
          </div>
        </div>

        <div className="flex items-center gap-6">
          {/* Strategy Badge */}
          <div className="hidden sm:flex items-center gap-2">
            <span className="rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-medium text-emerald-400">
              {position.strategy}
            </span>
            <span className="text-sm font-medium text-emerald-400">
              {position.apy} APY
            </span>
          </div>

          {/* Expand Icon */}
          <svg
            className={`h-5 w-5 text-gray-400 transition-transform ${
              isExpanded ? "rotate-180" : ""
            }`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </div>
      </div>

      {/* Expanded Content */}
      {isExpanded && (
        <div className="border-t border-white/5 bg-black/20 p-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {/* Pending Fees */}
            <div className="rounded-xl bg-white/5 p-4">
              <p className="text-xs font-medium text-gray-400">Pending Fees</p>
              <div className="mt-2 space-y-1">
                <p className="text-lg font-semibold text-white">
                  {position.pendingFees0} {position.token0}
                </p>
                <p className="text-lg font-semibold text-white">
                  {position.pendingFees1} {position.token1}
                </p>
              </div>
            </div>

            {/* Claimable Yield */}
            <div className="rounded-xl bg-emerald-500/5 p-4">
              <p className="text-xs font-medium text-emerald-400">
                Claimable Yield
              </p>
              <div className="mt-2 space-y-1">
                <p className="text-lg font-semibold text-emerald-300">
                  {position.claimableYield0} {position.token0}
                </p>
                <p className="text-lg font-semibold text-emerald-300">
                  {position.claimableYield1} {position.token1}
                </p>
              </div>
            </div>

            {/* Yield Shares */}
            <div className="rounded-xl bg-violet-500/5 p-4">
              <p className="text-xs font-medium text-violet-400">
                Yield Shares
              </p>
              <p className="mt-2 text-lg font-semibold text-violet-300">
                {position.yieldShares}
              </p>
              <p className="text-xs text-gray-500">
                Your share of pool deposits
              </p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="mt-6 flex flex-wrap gap-3">
            <button className="flex-1 rounded-xl bg-gradient-to-r from-emerald-500 to-emerald-600 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-emerald-500/25 transition-all hover:shadow-xl hover:shadow-emerald-500/30 sm:flex-none">
              Claim Yield
            </button>
            <button className="flex-1 rounded-xl border border-white/10 bg-white/5 px-6 py-3 text-sm font-semibold text-white transition-all hover:bg-white/10 sm:flex-none">
              Change Strategy
            </button>
            <button className="flex-1 rounded-xl border border-amber-500/30 bg-amber-500/5 px-6 py-3 text-sm font-semibold text-amber-400 transition-all hover:bg-amber-500/10 sm:flex-none">
              Trigger Sweep
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
