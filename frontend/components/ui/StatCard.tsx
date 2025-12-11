"use client";

interface StatCardProps {
  title: string;
  value: string;
  subValue?: string;
  icon: React.ReactNode;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  gradient: string;
}

export function StatCard({
  title,
  value,
  subValue,
  icon,
  trend,
  gradient,
}: StatCardProps) {
  return (
    <div className="relative group overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 p-6 backdrop-blur-xl transition-all duration-300 hover:border-white/20 hover:shadow-xl hover:shadow-violet-500/5">
      {/* Background gradient glow */}
      <div
        className={`absolute -right-10 -top-10 h-40 w-40 rounded-full ${gradient} opacity-20 blur-3xl transition-opacity group-hover:opacity-30`}
      />

      {/* Content */}
      <div className="relative z-10">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium text-gray-400">{title}</p>
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/5">
            {icon}
          </div>
        </div>

        <div className="mt-4">
          <p className="text-3xl font-bold text-white">{value}</p>
          {subValue && <p className="mt-1 text-sm text-gray-500">{subValue}</p>}
        </div>

        {trend && (
          <div className="mt-4 flex items-center gap-2">
            <span
              className={`flex items-center gap-1 rounded-full px-2 py-1 text-xs font-medium ${
                trend.isPositive
                  ? "bg-emerald-500/10 text-emerald-400"
                  : "bg-red-500/10 text-red-400"
              }`}
            >
              {trend.isPositive ? "↑" : "↓"} {trend.value}
            </span>
            <span className="text-xs text-gray-500">vs last week</span>
          </div>
        )}
      </div>
    </div>
  );
}

// Icons for stat cards
export const Icons = {
  yield: (
    <svg
      className="h-5 w-5 text-emerald-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"
      />
    </svg>
  ),
  position: (
    <svg
      className="h-5 w-5 text-violet-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      />
    </svg>
  ),
  fees: (
    <svg
      className="h-5 w-5 text-amber-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    </svg>
  ),
  strategy: (
    <svg
      className="h-5 w-5 text-blue-400"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
      />
    </svg>
  ),
};
