# YieldForge Code & Test Walkthrough Script (3 Minutes)

**Target Duration:** ~3:00 minutes
**Goal:** Explain the technical implementation and verification of the YieldForge Uniswap v4 Hook.

---

### 0:00 - 0:30 | Introduction & Architecture

**[Visual: Show `README.md` Architecture Diagram or GitHub Repo Main Page]**

**Voiceover:**
"Hi, this is [Your Name] from the YieldForge team. Today, I'm going to walk you through the code and tests behind YieldForge, our Uniswap v4 hook that turns idle LP fees into auto-compounding yield.

At a high level, YieldForge works by intercepting fee accrual in Uniswap v4. Instead of letting fees sit idle in the pool, our hook tracks them per position and, once a threshold is reached, sweeps them into external yield protocols like Aave or Compound."

---

### 0:30 - 1:30 | Core Hook Logic (`YieldForgeHook.sol`)

**[Visual: Open `src/YieldForgeHook.sol` in VS Code]**

**Voiceover:**
"Let's dive into the core contract, `YieldForgeHook.sol`.

**[Visual: Scroll to `beforeModifyLiquidity` / `afterModifyLiquidity`]**
We implement the `IHooks` interface. The magic starts in our liquidity callbacks. We use `beforeModifyLiquidity` to register the user's chosen strategy—stored in `hookData`—and `afterModifyLiquidity` to accurately track fee accrual using the `BalanceDelta` returned by the PoolManager.

**[Visual: Highlight `_trackFees` function]**
Here in `_trackFees`, we maintain a mapping of `accumulatedFees` for each position. This is critical because it allows us to batch updates and only trigger expensive external calls when it's gas-efficient.

**[Visual: Highlight `sweep` function]**
The `sweep` function is permissionless. Anyone can call it. It checks if the accrued fees exceed the `minSweepAmount`. If they do, it pulls the tokens from the PoolManager and deposits them into the registered strategy. We also reward the caller with a small percentage of the fees to incentivize keepers."

---

### 1:30 - 2:00 | Strategy Integration (`AaveV3Strategy.sol`)

**[Visual: Open `src/strategies/AaveV3Strategy.sol`]**

**Voiceover:**
"For the yield generation, we use a modular strategy pattern. Here's our `AaveV3Strategy`.

It implements our `IYieldForgeStrategy` interface. When `deposit` is called by the hook, this contract supplies the underlying asset—like USDC or ETH—to the Aave V3 Pool.

**[Visual: Highlight `withdraw` function]**
We also handle withdrawals. Since Aave gives us aTokens, we track the 'shares' each position owns. When an LP wants to claim their yield, we calculate their share of the aTokens, withdraw from Aave, and send the underlying asset back to them."

---

### 2:00 - 2:45 | Testing & Verification

**[Visual: Open `test/YieldForgeHook.t.sol`]**

**Voiceover:**
"Security is paramount, so we've written extensive tests using Foundry.

In `YieldForgeHook.t.sol`, we cover the unit logic. We verify that fees are tracked correctly down to the wei, and that the sweep logic respects the minimum thresholds.

**[Visual: Open `test/StrategyIntegration.t.sol` and run `forge test` in terminal]**
But the real test is integration. In `StrategyIntegration.t.sol`, we fork Mainnet.

**[Visual: Show terminal output with green passing tests]**
We simulate real interactions with the live Aave and Compound protocols. We verify that:

1.  We can successfully deposit real USDC into Aave.
2.  We accrue actual interest over time.
3.  And most importantly, LPs can withdraw their principal plus that earned interest.

As you can see, all 19 tests are passing, confirming our integration works on a mainnet fork."

---

### 2:45 - 3:00 | Conclusion

**[Visual: Briefly show the Frontend Dashboard code or running app]**

**Voiceover:**
"We've also built a full Next.js dashboard to visualize this data, but the heart of YieldForge is this robust, gas-optimized set of smart contracts.

YieldForge is ready to make Uniswap v4 liquidity more capital efficient from day one. Thanks for watching!"
