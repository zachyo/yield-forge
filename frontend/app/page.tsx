"use client";

import { Header } from "@/components/layout/Header";
import { StatCard, Icons } from "@/components/ui/StatCard";
import { PositionsList } from "@/components/dashboard/PositionsList";
import { StrategiesList } from "@/components/dashboard/StrategiesList";
import { RecentActivity } from "@/components/dashboard/RecentActivity";
import { useAccount } from "wagmi";

export default function Dashboard() {
  const { isConnected, address } = useAccount();

  return (
    <div className="min-h-screen">
      <Header />

      <main className="container mx-auto px-4 py-8">
        {/* Hero Section */}
        <section className="mb-12 text-center">
          <div className="inline-flex items-center gap-2 rounded-full bg-violet-500/10 px-4 py-2 text-sm text-violet-400 mb-6">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            Live on Ethereum Mainnet
          </div>
          <h1 className="text-4xl font-bold text-white md:text-5xl lg:text-6xl">
            Turn LP Fees into
            <span className="block gradient-text">Compounding Yield</span>
          </h1>
          <p className="mt-6 text-lg text-gray-400 max-w-2xl mx-auto">
            YieldForge automatically sweeps your Uniswap v4 trading fees and
            deposits them into the best yield strategies — Aave, Compound,
            Yearn, and more.
          </p>
          {!isConnected && (
            <div className="mt-8">
              <button className="rounded-xl bg-gradient-to-r from-violet-500 to-purple-600 px-8 py-4 text-lg font-semibold text-white shadow-xl shadow-violet-500/25 transition-all hover:shadow-2xl hover:shadow-violet-500/30">
                Connect Wallet to Start
              </button>
            </div>
          )}
        </section>

        {/* Stats Section */}
        <section className="mb-12">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            <StatCard
              title="Total Yield Earned"
              value="$12,450"
              subValue="≈ 4.2 ETH"
              icon={Icons.yield}
              trend={{ value: "12.5%", isPositive: true }}
              gradient="bg-emerald-500"
            />
            <StatCard
              title="Active Positions"
              value="5"
              subValue="3 pools"
              icon={Icons.position}
              gradient="bg-violet-500"
            />
            <StatCard
              title="Pending Fees"
              value="$342.50"
              subValue="Ready to sweep"
              icon={Icons.fees}
              trend={{ value: "8.3%", isPositive: true }}
              gradient="bg-amber-500"
            />
            <StatCard
              title="Avg. APY Boost"
              value="+4.2%"
              subValue="above base LP"
              icon={Icons.strategy}
              gradient="bg-blue-500"
            />
          </div>
        </section>

        {/* Main Content Grid */}
        <div className="grid gap-8 lg:grid-cols-3">
          {/* Positions - Takes 2 columns */}
          <section className="lg:col-span-2" id="positions">
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold text-white">
                  Your Positions
                </h2>
                <p className="text-gray-500">
                  Manage your LP positions and yield strategies
                </p>
              </div>
              <button className="rounded-xl bg-gradient-to-r from-violet-500/10 to-purple-500/10 border border-violet-500/20 px-4 py-2 text-sm font-medium text-violet-400 transition-all hover:bg-violet-500/20">
                + Add Position
              </button>
            </div>
            <PositionsList />
          </section>

          {/* Activity Sidebar */}
          <section className="lg:col-span-1">
            <RecentActivity />
          </section>
        </div>

        {/* Strategies Section */}
        <section className="mt-12" id="strategies">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-white">
              Available Strategies
            </h2>
            <p className="text-gray-500">Choose how your fees are invested</p>
          </div>
          <StrategiesList />
        </section>

        {/* How It Works Section */}
        <section className="mt-16 rounded-3xl border border-white/10 bg-gradient-to-br from-gray-900/90 to-gray-900/50 p-8 backdrop-blur-xl md:p-12">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-white">
              How YieldForge Works
            </h2>
            <p className="mt-2 text-gray-400">
              Automated yield optimization in 3 simple steps
            </p>
          </div>

          <div className="grid gap-8 md:grid-cols-3">
            <div className="text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-violet-500/10 text-3xl">
                1️⃣
              </div>
              <h3 className="text-lg font-semibold text-white">
                Add Liquidity
              </h3>
              <p className="mt-2 text-sm text-gray-400">
                Add liquidity to any Uniswap v4 pool with YieldForge enabled
              </p>
            </div>

            <div className="text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-emerald-500/10 text-3xl">
                2️⃣
              </div>
              <h3 className="text-lg font-semibold text-white">
                Fees Accumulate
              </h3>
              <p className="mt-2 text-sm text-gray-400">
                Trading fees automatically accumulate and get swept to yield
                strategies
              </p>
            </div>

            <div className="text-center">
              <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-amber-500/10 text-3xl">
                3️⃣
              </div>
              <h3 className="text-lg font-semibold text-white">
                Earn Extra Yield
              </h3>
              <p className="mt-2 text-sm text-gray-400">
                Claim your compounded yield anytime — both LP fees + strategy
                returns
              </p>
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-white/10 mt-20">
        <div className="container mx-auto px-4 py-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500 to-purple-600">
                <svg
                  className="h-4 w-4 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M13 10V3L4 14h7v7l9-11h-7z"
                  />
                </svg>
              </div>
              <span className="font-semibold text-white">YieldForge</span>
            </div>

            <div className="flex items-center gap-6 text-sm text-gray-500">
              <a href="#" className="hover:text-white transition-colors">
                Documentation
              </a>
              <a href="#" className="hover:text-white transition-colors">
                GitHub
              </a>
              <a href="#" className="hover:text-white transition-colors">
                Discord
              </a>
              <a href="#" className="hover:text-white transition-colors">
                Twitter
              </a>
            </div>

            <p className="text-sm text-gray-600">
              Built for Uniswap v4 Hookathon
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
