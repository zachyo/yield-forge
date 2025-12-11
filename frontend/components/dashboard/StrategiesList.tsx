"use client";

interface Strategy {
  id: number;
  name: string;
  protocol: string;
  apy: string;
  tvl: string;
  risk: "Low" | "Medium" | "High";
  description: string;
  logo: string;
}

const STRATEGIES: Strategy[] = [
  {
    id: 1,
    name: "Aave V3 Lending",
    protocol: "Aave",
    apy: "4.2%",
    tvl: "$1.2M",
    risk: "Low",
    description: "Supply assets to Aave V3 lending pools to earn interest",
    logo: "🏦",
  },
  {
    id: 2,
    name: "Compound V3 Supply",
    protocol: "Compound",
    apy: "3.8%",
    tvl: "$890K",
    risk: "Low",
    description: "Deposit into Compound V3 markets for stable yield",
    logo: "💰",
  },
  {
    id: 3,
    name: "Yearn USDC Vault",
    protocol: "Yearn",
    apy: "5.1%",
    tvl: "$450K",
    risk: "Medium",
    description: "Auto-compounding yield strategies via Yearn Finance",
    logo: "🔵",
  },
  {
    id: 4,
    name: "Pendle PT Strategy",
    protocol: "Pendle",
    apy: "6.5%",
    tvl: "$320K",
    risk: "Medium",
    description: "Fixed yield through Pendle Principal Tokens",
    logo: "⚡",
  },
];

export function StrategiesList() {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {STRATEGIES.map((strategy) => (
        <StrategyCard key={strategy.id} strategy={strategy} />
      ))}
    </div>
  );
}

function StrategyCard({ strategy }: { strategy: Strategy }) {
  const riskColors = {
    Low: "text-emerald-400 bg-emerald-500/10",
    Medium: "text-amber-400 bg-amber-500/10",
    High: "text-red-400 bg-red-500/10",
  };

  return (
    <div className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 p-6 backdrop-blur-xl transition-all duration-300 hover:border-violet-500/30 hover:shadow-xl hover:shadow-violet-500/5">
      {/* Glow effect */}
      <div className="absolute -right-10 -top-10 h-32 w-32 rounded-full bg-violet-500/10 blur-3xl transition-opacity group-hover:opacity-30" />

      <div className="relative z-10">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white/5 text-2xl">
              {strategy.logo}
            </div>
            <div>
              <h3 className="font-semibold text-white">{strategy.name}</h3>
              <p className="text-sm text-gray-500">{strategy.protocol}</p>
            </div>
          </div>
          <span
            className={`rounded-full px-3 py-1 text-xs font-medium ${
              riskColors[strategy.risk]
            }`}
          >
            {strategy.risk} Risk
          </span>
        </div>

        {/* Description */}
        <p className="mt-4 text-sm text-gray-400">{strategy.description}</p>

        {/* Stats */}
        <div className="mt-6 flex items-center justify-between border-t border-white/5 pt-4">
          <div>
            <p className="text-xs text-gray-500">Current APY</p>
            <p className="text-xl font-bold text-emerald-400">{strategy.apy}</p>
          </div>
          <div className="text-right">
            <p className="text-xs text-gray-500">TVL</p>
            <p className="text-xl font-bold text-white">{strategy.tvl}</p>
          </div>
        </div>

        {/* Action */}
        <button className="mt-4 w-full rounded-xl border border-violet-500/30 bg-violet-500/10 py-3 text-sm font-semibold text-violet-400 transition-all hover:bg-violet-500/20">
          Select Strategy
        </button>
      </div>
    </div>
  );
}
