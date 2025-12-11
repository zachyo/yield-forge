"use client";

import { useEffect, useState } from "react";

interface Activity {
  id: string;
  type: "sweep" | "claim" | "deposit";
  pool: string;
  amount0: string;
  amount1: string;
  token0: string;
  token1: string;
  txHash: string;
  timestamp: Date;
}

const DEMO_ACTIVITIES: Activity[] = [
  {
    id: "1",
    type: "sweep",
    pool: "ETH/USDC",
    amount0: "0.0834",
    amount1: "215.50",
    token0: "ETH",
    token1: "USDC",
    txHash: "0x1234...5678",
    timestamp: new Date(Date.now() - 1000 * 60 * 15), // 15 min ago
  },
  {
    id: "2",
    type: "claim",
    pool: "WBTC/ETH",
    amount0: "0.00123",
    amount1: "0.0456",
    token0: "WBTC",
    token1: "ETH",
    txHash: "0xabcd...efgh",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
  },
  {
    id: "3",
    type: "deposit",
    pool: "ETH/USDC",
    amount0: "0.125",
    amount1: "312.50",
    token0: "ETH",
    token1: "USDC",
    txHash: "0x9876...5432",
    timestamp: new Date(Date.now() - 1000 * 60 * 60 * 5), // 5 hours ago
  },
];

export function RecentActivity() {
  const [activities] = useState<Activity[]>(DEMO_ACTIVITIES);

  const getTypeStyles = (type: Activity["type"]) => {
    switch (type) {
      case "sweep":
        return "text-amber-400 bg-amber-500/10";
      case "claim":
        return "text-emerald-400 bg-emerald-500/10";
      case "deposit":
        return "text-blue-400 bg-blue-500/10";
    }
  };

  const getTypeIcon = (type: Activity["type"]) => {
    switch (type) {
      case "sweep":
        return "🧹";
      case "claim":
        return "💎";
      case "deposit":
        return "📥";
    }
  };

  const formatTime = (date: Date) => {
    const diff = Date.now() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return `${minutes}m ago`;
  };

  return (
    <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 backdrop-blur-xl">
      <div className="border-b border-white/5 p-6">
        <h2 className="text-lg font-semibold text-white">Recent Activity</h2>
        <p className="text-sm text-gray-500">
          Latest sweeps, claims, and deposits
        </p>
      </div>

      <div className="divide-y divide-white/5">
        {activities.map((activity) => (
          <div
            key={activity.id}
            className="flex items-center justify-between p-4 transition-colors hover:bg-white/5"
          >
            <div className="flex items-center gap-4">
              <div
                className={`rounded-lg p-2 text-lg ${getTypeStyles(
                  activity.type
                )}`}
              >
                {getTypeIcon(activity.type)}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-medium text-white capitalize">
                    {activity.type}
                  </span>
                  <span className="text-gray-500">•</span>
                  <span className="text-sm text-gray-400">{activity.pool}</span>
                </div>
                <p className="text-sm text-gray-500">
                  {activity.amount0} {activity.token0} + {activity.amount1}{" "}
                  {activity.token1}
                </p>
              </div>
            </div>

            <div className="text-right">
              <p className="text-sm text-gray-400">
                {formatTime(activity.timestamp)}
              </p>
              <a
                href={`https://etherscan.io/tx/${activity.txHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs text-violet-400 hover:text-violet-300"
              >
                {activity.txHash}
              </a>
            </div>
          </div>
        ))}
      </div>

      <div className="border-t border-white/5 p-4">
        <button className="w-full rounded-xl border border-white/10 bg-white/5 py-2 text-sm font-medium text-gray-400 transition-colors hover:bg-white/10 hover:text-white">
          View All Activity
        </button>
      </div>
    </div>
  );
}
