# YieldForge – Full Product Requirements Document (PRD)

**Automated External Yield Optimization Hook for Uniswap v4**  
**Goal:** Turn every Uniswap v4 LP position into a self-compounding, higher-yield money machine — without the LP ever having to claim fees manually.

### 1. One-Liner

YieldForge is the Uniswap v4 hook that automatically sweeps accrued trading fees and redeploys them into the highest risk-adjusted external yield opportunities (Aave, Compound, Yearn, Pendle, Morpho, EigenLayer LSTs, etc.) based on each LP’s chosen strategy.

### 2. Core User Stories (MVP)

| User                   | Story                                                                                         | Priority |
| ---------------------- | --------------------------------------------------------------------------------------------- | -------- |
| Retail LP              | I add liquidity → pick “Medium risk” → my fees automatically go to Aave/Compound and compound | P0       |
| Power user / DAO       | I choose “Aggressive” → fees go to 3x leveraged ETH farming or Pendle YT                      | P0       |
| Conservative stable LP | I choose “Safe” → fees go to sDAI vault or Circle’s USDC reserve vault                        | P0       |
| LP (any)               | I can change or withdraw my strategy at any time                                              | P1       |
| LP                     | I can see real-time “extra yield earned thanks to YieldForge” on a dashboard                  | P1       |

### 3. High-Level Architecture (MVP – no EigenLayer/FHE needed)

```
Uniswap v4 Pool → YieldForge Hook (singleton) → Strategy Vaults (Aave, Compound, Yearn, etc.)

Key contracts:
1. `YieldForgeHook.sol` – main hook (implements IHooks)
2. `YieldForgeFactory.sol` – deploys per-pool hook instances (optional – can also use one global hook)
3. `StrategyRegistry.sol` – whitelisted yield strategies + risk scores (governance upgradable)
4. `PositionConfig.sol` – stores each NFT position’s chosen strategy + min threshold

### 4. Exact Hook Callbacks Used
| Callback                  | What we do here                                                                                 |
|---------------------------|--------------------------------------------------------------------------------------------------|
| `afterInitialize`         | Register the pool with the hook                                                                 |
| `beforeModifyLiquidity`   | When LP adds liquidity → set or update their strategy + fee threshold                          |
| `afterSwap`               | Accrue fees → check if total unclaimed fees for all positions → if > global threshold → trigger sweep |
| `beforeDonate` (optional) | Allow direct donation path for extra fees                                                       |
| `afterModifyLiquidity`    | Return compounded tokens when LP burns position (or keep them in the strategy until withdraw)   |

### 5. Step-by-Step Build Plan (7–10 days to working mainnet-ready PoC)

| Day | Milestone                                                                                 | Repo / Deliverable                                          |
|-----|--------------------------------------------------------------------------------------------|-------------------------------------------------------------|
| 1   | Fork Uniswap/v4-template + v4-periphery                                                   | GitHub repo ready                                                  |
| 2   | Implement basic hook skeleton + factory (use DynamicFee example as base)                 | Hook deploys, pool initializes correctly                           |
| 3   | Add position → strategy mapping + UI to set strategy on deposit                           | `setStrategy(positionId, strategyId, threshold)` works             |
| 4   | Implement fee accrual tracking per position (use PoolManager.take() + settle())           | Fees correctly accounted inside hook                               |
| 5   | Implement sweep logic using flash accounting (no external flash loan needed)              | `sweepAndInvest()` pulls all accrued fees in one tx                |
| 6   | Integrate first 3 strategies (Aave v3, Compound v3, Yearn USDC vault)                    | Real yield starts flowing                                          |
| 7   | Add claim/compounding logic on withdraw                                                   | LP gets back original + compounded yield                           |
| 8   | Frontend dashboard (Next.js + wagmi + viem) showing extra yield earned                   | Live demo ready                                                    |
| 9   | Security review + basic tests (reentrancy, delta accounting bugs)                        | 100% test coverage on critical paths                               |
| 10  | Deploy to Ethereum mainnet + Sepolia demo + write killer README                           | Submission-ready                                                   |

### 6. Major Bottlenecks & How to Solve Them

| Bottleneck                              | Severity | Solution                                                                                          |
|-----------------------------------------|----------|---------------------------------------------------------------------------------------------------|
| Gas cost of sweeping many positions     | High     | Batch many positions in one sweep + use transient storage + EIP-1153                            |
| External call failures (Aave down?)     | High     | Circuit-breaker pattern: if external call fails → hold fees in hook until next successful sweep   |
| Accounting precision & rounding attacks | Medium   | Use 1e18 fixed point everywhere track shares instead of absolute amounts                         |
| Front-running the sweep transaction     | Medium   | Anyone can call sweep() → make it permissionless + reward caller with 1–2 % of swept fees         |
| Too many strategies → complex registry  | Medium   | Start with 3 vetted strategies only governance can add more later                               |

### 7. Critical Risks & Mitigations

| Risk                                          | Likelihood | Impact | Mitigation                                                                 |
|-----------------------------------------------|------------|--------|----------------------------------------------------------------------------|
| Delta accounting bug drains pool              | Low        | Catastrophic | Copy exact patterns from Uniswap example hooks + full Foundry invariant tests |
| External protocol exploit (Aave hack)         | Medium     | High   | Diversify strategies allow LPs to instantly switch to “Safe Park” mode     |
| Hook gets griefed (someone spams sweep)       | Medium     | Medium | Add small cooldown or min threshold per sweep                              |
| Governance key compromised → rogue strategy   | Low        | High   | 6-of-10 multisig + Timelock (min 48 h)                                      |
| Users confused about where their yield went   | High       | Medium | Transparent dashboard + on-chain events + clear docs                       |

### 8. Go-to-Market & Adoption Levers
- Launch with 0 % hook fee for first 3 months → pure altruism play
- Partner with top 10 Uniswap v4 pools (USDC-ETH 0.05 %, WSTETH-ETH, etc.)
- One-click “Activate YieldForge” button in Uniswap app (via hook allowance)
- Share 20–50 % of future hook fees with LPs who lock longer

YieldForge has real shot at becoming the default “turbo mode” for every serious LP on Uniswap v4. Build the MVP exactly as above and you will have a production-grade, revenue-generating hook by end of December 2025.
```
