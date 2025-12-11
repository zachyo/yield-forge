// YieldForgeHook Contract ABI - Generated from Solidity contract
export const YIELD_FORGE_HOOK_ABI = [
  // View Functions
  {
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "owner", type: "address" },
    ],
    name: "getAccumulatedFees",
    outputs: [
      { name: "amount0", type: "int256" },
      { name: "amount1", type: "int256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "poolId", type: "bytes32" }],
    name: "getTotalPoolFees",
    outputs: [
      { name: "amount0", type: "int256" },
      { name: "amount1", type: "int256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "poolId", type: "bytes32" }],
    name: "getActivePositionsCount",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "poolId", type: "bytes32" }],
    name: "getActivePositions",
    outputs: [{ name: "", type: "address[]" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "owner", type: "address" },
    ],
    name: "getClaimableYield",
    outputs: [
      { name: "claimable0", type: "uint256" },
      { name: "claimable1", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "owner", type: "address" },
    ],
    name: "getYieldShares",
    outputs: [
      { name: "shares", type: "uint256" },
      { name: "totalShares", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "owner", type: "address" },
    ],
    name: "getPositionDeposits",
    outputs: [
      { name: "deposited0", type: "uint256" },
      { name: "deposited1", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "poolId", type: "bytes32" }],
    name: "getTotalDeposits",
    outputs: [
      { name: "total0", type: "uint256" },
      { name: "total1", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "poolId", type: "bytes32" },
      { name: "owner", type: "address" },
    ],
    name: "getPositionInfo",
    outputs: [
      { name: "pendingFees0", type: "int256" },
      { name: "pendingFees1", type: "int256" },
      { name: "yieldShares_", type: "uint256" },
      { name: "claimable0", type: "uint256" },
      { name: "claimable1", type: "uint256" },
    ],
    stateMutability: "view",
    type: "function",
  },
  // Write Functions
  {
    inputs: [
      {
        components: [
          { name: "currency0", type: "address" },
          { name: "currency1", type: "address" },
          { name: "fee", type: "uint24" },
          { name: "tickSpacing", type: "int24" },
          { name: "hooks", type: "address" },
        ],
        name: "key",
        type: "tuple",
      },
    ],
    name: "sweep",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          { name: "currency0", type: "address" },
          { name: "currency1", type: "address" },
          { name: "fee", type: "uint24" },
          { name: "tickSpacing", type: "int24" },
          { name: "hooks", type: "address" },
        ],
        name: "key",
        type: "tuple",
      },
      { name: "sharesToWithdraw", type: "uint256" },
    ],
    name: "withdrawYield",
    outputs: [
      { name: "amount0", type: "uint256" },
      { name: "amount1", type: "uint256" },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  // Events
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "poolId", type: "bytes32" },
      { indexed: true, name: "owner", type: "address" },
      { indexed: false, name: "amount0", type: "int256" },
      { indexed: false, name: "amount1", type: "int256" },
    ],
    name: "FeesAccrued",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "poolId", type: "bytes32" },
      { indexed: false, name: "totalFees0", type: "uint256" },
      { indexed: false, name: "totalFees1", type: "uint256" },
      { indexed: true, name: "sweeper", type: "address" },
    ],
    name: "FeesSwept",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "poolId", type: "bytes32" },
      { indexed: true, name: "owner", type: "address" },
      { indexed: false, name: "amount0", type: "uint256" },
      { indexed: false, name: "amount1", type: "uint256" },
      { indexed: false, name: "sharesBurned", type: "uint256" },
    ],
    name: "YieldWithdrawn",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, name: "strategy", type: "address" },
      { indexed: false, name: "amount0", type: "uint256" },
      { indexed: false, name: "amount1", type: "uint256" },
    ],
    name: "StrategyDeposit",
    type: "event",
  },
  // Constants
  {
    inputs: [],
    name: "SWEEPER_REWARD_BPS",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "MIN_SWEEP_THRESHOLD",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

// Contract addresses - update with deployed addresses
export const CONTRACT_ADDRESSES = {
  // Mainnet
  1: {
    yieldForgeHook: "0x0000000000000000000000000000000000000000", // TODO: Deploy
    strategyRegistry: "0x0000000000000000000000000000000000000000",
  },
  // Sepolia Testnet
  11155111: {
    yieldForgeHook: "0x0000000000000000000000000000000000000000", // TODO: Deploy
    strategyRegistry: "0x0000000000000000000000000000000000000000",
  },
  // Base Sepolia
  84532: {
    yieldForgeHook: "0x0000000000000000000000000000000000000000",
    strategyRegistry: "0x0000000000000000000000000000000000000000",
  },
} as const;

// Default pool for demo (ETH-USDC 0.3%)
export const DEMO_POOL = {
  poolId: "0x0000000000000000000000000000000000000000000000000000000000000000",
  currency0: "0x0000000000000000000000000000000000000000", // ETH
  currency1: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
  fee: 3000,
  tickSpacing: 60,
  token0Symbol: "ETH",
  token1Symbol: "USDC",
};
