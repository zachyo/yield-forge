// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {IYieldForgeStrategy} from "./interfaces/IYieldForgeStrategy.sol";
import {StrategyRegistry} from "./StrategyRegistry.sol";
import {PositionConfig, PositionInfo} from "./PositionConfig.sol";

contract YieldForgeHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Immutable references
    StrategyRegistry public immutable strategyRegistry;
    PositionConfig public immutable positionConfig;

    // Anyone can trigger a sweep → incentivised
    uint256 public constant SWEEPER_REWARD_BPS = 20; // 0.2%

    error SweepThresholdNotReached();
    error NoFeesToSweep();

    constructor(
        IPoolManager _poolManager,
        StrategyRegistry _strategyRegistry,
        PositionConfig _positionConfig
    ) BaseHook(_poolManager) {
        strategyRegistry = _strategyRegistry;
        positionConfig = _positionConfig;
    }

    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        Hooks.Permissions memory permissions;
        permissions.beforeInitialize = false;
        permissions.afterInitialize = true;
        permissions.beforeAddLiquidity = false;
        permissions.afterAddLiquidity = true;
        permissions.beforeRemoveLiquidity = false;
        permissions.afterRemoveLiquidity = true;
        permissions.beforeSwap = false;
        permissions.afterSwap = true;
        permissions.beforeDonate = false;
        permissions.afterDonate = false;
        permissions.beforeSwapReturnDelta = false;
        permissions.afterSwapReturnDelta = false;
        permissions.afterAddLiquidityReturnDelta = false;
        permissions.afterRemoveLiquidityReturnDelta = false;
        return permissions;
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Core logic
    // ──────────────────────────────────────────────────────────────────────────────

    function _afterInitialize(
        address,
        PoolKey calldata,
        uint160,
        int24
    ) internal override returns (bytes4) {
        // Optional: register pool-specific config here
        return BaseHook.afterInitialize.selector;
    }

    function _afterAddLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        if (hookData.length > 0) {
            (uint8 strategyId, uint128 minSweepAmount) = abi.decode(
                hookData,
                (uint8, uint128)
            );
            PositionInfo memory info = PositionInfo({
                strategyId: strategyId,
                minSweepAmount: minSweepAmount,
                lastSweepBlock: uint64(block.number)
            });
            positionConfig.setPositionConfig(key.toId(), msg.sender, info);
        }
        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        _attemptSweep(key);
        return (BaseHook.afterSwap.selector, 0);
    }

    // Public sweep entrypoint (permissionless)
    function sweep(PoolKey calldata key) external {
        _attemptSweep(key);
    }

    function _attemptSweep(PoolKey calldata key) internal {
        // 1. Collect all accrued fees for token0 & token1
        (uint256 fees0, uint256 fees1) = _collectAllFees(key);

        if (fees0 == 0 && fees1 == 0) revert NoFeesToSweep();

        // 2. Calculate rewards (CEI pattern - calculate before external calls)
        uint256 reward0 = (fees0 * SWEEPER_REWARD_BPS) / 10_000;
        uint256 reward1 = (fees1 * SWEEPER_REWARD_BPS) / 10_000;
        uint256 depositAmount0 = fees0 - reward0;
        uint256 depositAmount1 = fees1 - reward1;

        // 3. Get strategy
        IYieldForgeStrategy strategy = strategyRegistry.getDefaultStrategy();

        // 4. Transfer rewards to sweeper (external calls)
        if (reward0 > 0) {
            key.currency0.transfer(msg.sender, reward0);
        }
        if (reward1 > 0) {
            key.currency1.transfer(msg.sender, reward1);
        }

        // 5. Deposit remaining fees to strategy
        strategy.deposit{
            value: key.currency0.isAddressZero() ? depositAmount0 : 0
        }(key.currency0, depositAmount0, key.currency1, depositAmount1);
    }

    function _collectAllFees(
        PoolKey calldata key
    ) internal returns (uint256 fees0, uint256 fees1) {
        // TODO: Implement proper fee collection using PoolManager's accounting
        // For now, return the balance held by this hook
        fees0 = key.currency0.balanceOf(address(this));
        fees1 = key.currency1.balanceOf(address(this));
    }
}
