import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Web3Provider } from "@/components/providers/Web3Provider";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
});

export const metadata: Metadata = {
  title: "YieldForge | Uniswap v4 Yield Optimizer",
  description:
    "Automated external yield optimization hook for Uniswap v4. Turn every LP position into a self-compounding, higher-yield money machine.",
  keywords: [
    "Uniswap",
    "DeFi",
    "Yield",
    "LP",
    "Hook",
    "v4",
    "Aave",
    "Compound",
  ],
  openGraph: {
    title: "YieldForge | Uniswap v4 Yield Optimizer",
    description: "Automated external yield optimization hook for Uniswap v4",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} dark`}>
      <body className="min-h-screen bg-black font-sans antialiased">
        {/* Global background */}
        <div className="fixed inset-0 -z-10">
          {/* Gradient orbs */}
          <div className="absolute left-1/4 top-0 h-[500px] w-[500px] rounded-full bg-violet-500/20 blur-[128px]" />
          <div className="absolute right-1/4 top-1/3 h-[400px] w-[400px] rounded-full bg-blue-500/10 blur-[100px]" />
          <div className="absolute bottom-0 left-1/2 h-[300px] w-[300px] -translate-x-1/2 rounded-full bg-emerald-500/10 blur-[80px]" />

          {/* Grid overlay */}
          <div
            className="absolute inset-0 opacity-20"
            style={{
              backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%239C92AC' fill-opacity='0.1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
            }}
          />
        </div>

        <Web3Provider>{children}</Web3Provider>
      </body>
    </html>
  );
}
