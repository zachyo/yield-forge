"use client";

import { ConnectButton } from "@/components/ui/ConnectButton";

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-white/10 bg-black/50 backdrop-blur-xl">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        {/* Logo */}
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-purple-600 shadow-lg shadow-violet-500/25">
            <svg
              className="h-6 w-6 text-white"
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
          <div className="flex flex-col">
            <span className="text-xl font-bold bg-gradient-to-r from-violet-400 to-purple-400 bg-clip-text text-transparent">
              YieldForge
            </span>
            <span className="text-xs text-gray-500">
              Uniswap v4 Yield Optimizer
            </span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="hidden md:flex items-center gap-6">
          <a
            href="#positions"
            className="text-sm text-gray-400 hover:text-white transition-colors"
          >
            Positions
          </a>
          <a
            href="#strategies"
            className="text-sm text-gray-400 hover:text-white transition-colors"
          >
            Strategies
          </a>
          <a
            href="#analytics"
            className="text-sm text-gray-400 hover:text-white transition-colors"
          >
            Analytics
          </a>
          <a
            href="https://github.com"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-gray-400 hover:text-white transition-colors"
          >
            Docs
          </a>
        </nav>

        {/* Connect Wallet */}
        <ConnectButton />
      </div>
    </header>
  );
}
