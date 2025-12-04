# YieldForge Strategy Integration Guide

This guide explains how to integrate and use the Aave V3 and Compound V3 strategies with YieldForge.

## Overview

YieldForge now supports two real DeFi yield strategies:

1. **AaveV3Strategy** - Deposits tokens into Aave V3 lending pools
2. **CompoundV3Strategy** - Deposits tokens into Compound V3 (Comet) markets

These strategies replace the mock strategy and enable real yield generation on LP fees.

## Strategy Implementations

### Aave V3 Strategy

Located at: `src/strategies/AaveV3Strategy.sol`

**Features:**

- Deposits tokens into Aave V3 lending pools
- Earns interest on supplied assets
- Receives aTokens as receipt tokens
- Supports multiple currencies per strategy instance

**Key Functions:**

```solidity
// Configure a currency to use with Aave
function configureCurrency(Currency currency, address aToken) external

// Deposit tokens into Aave
function deposit(
    Currency currency0,
    uint256 amount0,
    Currency currency1,
    uint256 amount1
) external payable

// Withdraw tokens from Aave
function withdraw(
    address to,
    uint256 sharesToBurn
) external returns (uint256 amount0, uint256 amount1)
```

**Deployment:**

```solidity
// Deploy with Aave V3 Pool address
// Mainnet: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2
AaveV3Strategy strategy = new AaveV3Strategy(aavePoolAddress);

// Configure supported currencies
strategy.configureCurrency(usdcCurrency, aUSDC_address);
strategy.configureCurrency(wethCurrency, aWETH_address);
```

### Compound V3 Strategy

Located at: `src/strategies/CompoundV3Strategy.sol`

**Features:**

- Deposits tokens into Compound V3 (Comet) markets
- Earns interest on supplied base assets
- Simpler than Aave - focuses on single base token per market
- Gas-efficient design

**Key Functions:**

```solidity
// Configure a currency (must be the base token)
function configureCurrency(Currency currency) external

// Deposit tokens into Compound
function deposit(
    Currency currency0,
    uint256 amount0,
    Currency currency1,
    uint256 amount1
) external payable

// Withdraw tokens from Compound
function withdraw(
    address to,
    uint256 sharesToBurn
) external returns (uint256 amount0, uint256 amount1)
```

**Deployment:**

```solidity
// Deploy with Compound V3 Comet address
// USDC market on mainnet: 0xc3d688B66703497DAA19211EEdff47f25384cdc3
CompoundV3Strategy strategy = new CompoundV3Strategy(cometAddress);

// Configure the base token
strategy.configureCurrency(usdcCurrency);
```

## Integration with YieldForge

### 1. Deploy Strategy

Choose either Aave or Compound (or deploy both):

```solidity
// Example: Deploy Aave V3 Strategy
AaveV3Strategy aaveStrategy = new AaveV3Strategy(
    0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2 // Aave Pool
);

// Configure currencies
aaveStrategy.configureCurrency(
    Currency.wrap(USDC),
    0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c // aUSDC
);
```

### 2. Register Strategy

```solidity
// Set as default strategy in StrategyRegistry
strategyRegistry.setDefaultStrategy(aaveStrategy);

// Or register as a specific strategy ID
strategyRegistry.registerStrategy(1, aaveStrategy);
```

### 3. Use Strategy in Positions

When adding liquidity, specify the strategy in hookData:

```solidity
// Encode: owner address, strategyId, minSweepAmount
bytes memory hookData = abi.encode(
    msg.sender,      // Position owner
    uint8(0),        // Strategy ID (0 = default)
    uint128(1e18)    // Minimum sweep threshold
);

// Add liquidity with strategy config
modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);
```

### 4. Automatic Yield Generation

Once configured:

1. Trading fees accumulate in the pool
2. When threshold is reached, anyone can call `sweep()`
3. Fees are automatically deposited into the configured strategy
4. Strategy earns yield on the deposited tokens
5. Sweeper receives 0.2% reward for triggering the sweep

## Network Deployments

### Ethereum Mainnet

**Aave V3:**

- Pool: `0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2`
- aUSDC: `0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c`
- aWETH: `0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8`
- aDAI: `0x018008bfb33d285247A21d44E50697654f754e63`

**Compound V3:**

- USDC Comet: `0xc3d688B66703497DAA19211EEdff47f25384cdc3`
- ETH Comet: `0xA17581A9E3356d9A858b789D68B4d866e593aE94`

### Base

**Aave V3:**

- Pool: `0xA238Dd80C259a72e81d7e4664a9801593F98d1c5`

**Compound V3:**

- USDC Comet: `0xb125E6687d4313864e53df431d5425969c15Eb2F`

### Arbitrum

**Aave V3:**

- Pool: `0x794a61358D6845594F94dc1DB02A252b5b4814aD`

**Compound V3:**

- USDC Comet: `0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf`

## Testing

Run the test suite:

```bash
forge test --match-path test/YieldForgeHook.t.sol -vv
```

All tests should pass, including:

- ✅ Position tracking with multiple users
- ✅ Strategy configuration
- ✅ Fee accumulation
- ✅ Sweep functionality

## Security Considerations

### Strategy Risks

1. **Smart Contract Risk**: Aave and Compound are battle-tested but not risk-free
2. **Liquidity Risk**: Strategies may not have instant liquidity for withdrawals
3. **Oracle Risk**: Compound relies on price oracles
4. **Governance Risk**: Protocol parameters can change

### Mitigation Strategies

1. **Diversification**: Support multiple strategies
2. **Circuit Breakers**: Implement emergency pause functionality
3. **Gradual Rollout**: Start with conservative limits
4. **Monitoring**: Track strategy performance and health
5. **Upgradability**: Use registry pattern for strategy updates

## Advanced Usage

### Multiple Strategies

```solidity
// Register multiple strategies
strategyRegistry.registerStrategy(0, aaveStrategy);
strategyRegistry.registerStrategy(1, compoundStrategy);
strategyRegistry.registerStrategy(2, conservativeStrategy);

// Users choose their preferred strategy
bytes memory hookData = abi.encode(
    msg.sender,
    uint8(1),        // Use Compound (strategy ID 1)
    uint128(1e18)
);
```

### Custom Strategy Implementation

To create a custom strategy:

1. Implement `IYieldForgeStrategy` interface
2. Implement `deposit()` and `withdraw()` functions
3. Handle share accounting properly
4. Test thoroughly
5. Register with StrategyRegistry

Example skeleton:

```solidity
contract CustomStrategy is IYieldForgeStrategy {
    function deposit(
        Currency currency0,
        uint256 amount0,
        Currency currency1,
        uint256 amount1
    ) external payable override {
        // Your deposit logic
    }

    function withdraw(
        address to,
        uint256 sharesToBurn
    ) external override returns (uint256 amount0, uint256 amount1) {
        // Your withdrawal logic
    }
}
```

## Roadmap

Future enhancements:

- [ ] Yearn vault integration
- [ ] Pendle PT/YT strategies
- [ ] EigenLayer LST strategies
- [ ] Multi-strategy auto-rebalancing
- [ ] Risk-adjusted strategy selection
- [ ] Gas optimization for batch sweeps
- [ ] Emergency withdrawal mechanisms

## Support

For issues or questions:

- GitHub Issues: [Create an issue](https://github.com/your-repo/issues)
- Documentation: See PRD.md and IMPLEMENTATION_SUMMARY.md
- Tests: See `test/YieldForgeHook.t.sol` for usage examples
