# 🌾 YieldForge

![YieldForge Banner](https://via.placeholder.com/1200x300?text=YieldForge+Uniswap+v4+Hook)

> **Turn every Uniswap v4 LP position into a self-compounding, higher-yield money machine.**

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/your-repo/yield-forge)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Uniswap v4](https://img.shields.io/badge/Uniswap-v4-pink)](https://github.com/Uniswap/v4-core)
[![Aave V3](https://img.shields.io/badge/Integrated-Aave%20V3-purple)](https://aave.com/)
[![Compound V3](https://img.shields.io/badge/Integrated-Compound%20V3-green)](https://compound.finance/)

## 📖 Table of Contents

- [The Problem](#-the-problem)
- [The Solution](#-the-solution)
- [Key Features](#-key-features)
- [Partner Integrations](#-partner-integrations)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Frontend Dashboard](#-frontend-dashboard)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Demo](#-demo)

## 🛑 The Problem

Liquidity Providers (LPs) on Uniswap v4 earn trading fees, but these fees often sit idle in the pool until manually claimed. This capital inefficiency means LPs miss out on potential yield from other DeFi protocols. Manually claiming and reinvesting fees is gas-expensive and time-consuming.

## 🚀 The Solution

**YieldForge** is a Uniswap v4 hook that automatically sweeps accrued trading fees and redeploys them into the highest risk-adjusted external yield opportunities.

- **Automated Sweeping:** Fees are automatically collected when they reach a threshold.
- **Yield Compounding:** Idle fees are deposited into Aave V3 or Compound V3 to earn lending interest.
- **Gas Efficient:** Batch processing and permissionless sweeping with incentives.

## ✨ Key Features

- **Strategy-Agnostic:** Supports multiple yield strategies (Aave, Compound, and extensible for more).
- **Per-Position Configuration:** LPs can choose different strategies for different positions.
- **Permissionless Sweeping:** Anyone can trigger the sweep and earn a reward (0.2% of swept fees).
- **Real-Time Dashboard:** A Next.js frontend to track extra yield earned and manage strategies.
- **Secure Accounting:** Uses the Checks-Effects-Interactions pattern and robust fee tracking via `PoolManager`.

## 🤝 Partner Integrations

YieldForge integrates with leading DeFi protocols to generate yield:

| Partner         | Integration Details                                                                                                             |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Aave V3**     | Fees are deposited into Aave V3 lending pools to earn interest on supplied assets (e.g., USDC, ETH). Uses `AaveV3Strategy.sol`. |
| **Compound V3** | Fees are supplied to Compound V3 (Comet) markets to earn yield on base assets. Uses `CompoundV3Strategy.sol`.                   |

## 🏗 Architecture

```mermaid
graph TD
    User[Liquidity Provider] -->|Add Liquidity| Pool[Uniswap v4 Pool]
    Pool -->|Hook Callback| Hook[YieldForgeHook]
    Hook -->|Track Fees| Storage[Fee Tracking]

    Keeper[Keeper/Sweeper] -->|Call sweep()| Hook
    Hook -->|1. Collect Fees| Pool
    Hook -->|2. Deposit Fees| Strategy[Strategy Registry]

    Strategy -->|Deposit| Aave[Aave V3]
    Strategy -->|Deposit| Compound[Compound V3]

    User -->|Withdraw Yield| Hook
    Hook -->|Redeem Shares| Strategy
```

## 🛠 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (v18+)
- [Bun](https://bun.sh/) or [Yarn](https://yarnpkg.com/)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/yield-forge.git
   cd yield-forge
   ```
2. Install dependencies:
   ```bash
   forge install
   cd frontend && npm install
   ```

## 🖥 Frontend Dashboard

YieldForge comes with a modern dashboard to manage your positions and view earned yield.

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Start the development server:
   ```bash
   npm run dev
   ```
3. Open [http://localhost:3000](http://localhost:3000) in your browser.

## 🧪 Testing

We have a comprehensive test suite covering core logic, strategy integrations, and fork tests.

**Run all tests:**

```bash
forge test
```

**Run specific strategy tests (requires Mainnet Fork):**

```bash
forge test --match-contract StrategyIntegrationTest
```

## 🚀 Deployment

To deploy the contracts to a network (e.g., Sepolia):

```bash
forge script script/DeployStrategies.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

## 🎥 Demo

Check out our demo video to see YieldForge in action:
[**Read the pitch deck**](#) _([Link to Pitch Deck](https://yieldforge-94u9wv4.gamma.site/))_

---

**Built for the Atrium Academy Uniswap Hook Incubator (UHI)**
