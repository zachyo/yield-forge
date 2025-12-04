// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {IYieldForgeStrategy} from "./interfaces/IYieldForgeStrategy.sol";
import {StrategyRegistry} from "./StrategyRegistry.sol";
import {PositionConfig, PositionInfo} from "./PositionConfig.sol";

contract YieldForgeHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    // Immutable references
    StrategyRegistry public immutable strategyRegistry;
    PositionConfig public immutable positionConfig;

    // Fee tracking per position
    // poolId => owner => (accumulatedFees0, accumulatedFees1)
    mapping(PoolId => mapping(address => BalanceDelta)) public accumulatedFees;

    // Total fees accumulated per pool (for sweep threshold checking)
    mapping(PoolId => BalanceDelta) public totalPoolFees;

    // Active positions per pool (for iteration during sweep)
    mapping(PoolId => address[]) public activePositions;
    mapping(PoolId => mapping(address => uint256)) public positionIndex; // 1-indexed, 0 means not active

    // Anyone can trigger a sweep → incentivised
    uint256 public constant SWEEPER_REWARD_BPS = 20; // 0.2%
    uint256 public constant MIN_SWEEP_THRESHOLD = 1e18; // 1 token minimum

    event FeesAccrued(
        PoolId indexed poolId,
        address indexed owner,
        int256 amount0,
        int256 amount1
    );
    event FeesSwept(
        PoolId indexed poolId,
        uint256 totalFees0,
        uint256 totalFees1,
        address indexed sweeper
    );
    event StrategyDeposit(
        address indexed strategy,
        uint256 amount0,
        uint256 amount1
    );

    error SweepThresholdNotReached();
    error NoFeesToSweep();
    error NoActivePositions();

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
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();

        // Determine the actual position owner
        address owner = sender;

        // Set position config if provided
        if (hookData.length > 0) {
            // Decode: owner address, strategyId, minSweepAmount
            (address hookOwner, uint8 strategyId, uint128 minSweepAmount) = abi
                .decode(hookData, (address, uint8, uint128));

            // Use the owner from hookData if provided
            if (hookOwner != address(0)) {
                owner = hookOwner;
            }

            PositionInfo memory info = PositionInfo({
                strategyId: strategyId,
                minSweepAmount: minSweepAmount,
                lastSweepBlock: uint64(block.number)
            });
            positionConfig.setPositionConfig(poolId, owner, info);
        }

        // Track fees accrued for this position
        if (feesAccrued != BalanceDeltaLibrary.ZERO_DELTA) {
            _trackFees(poolId, owner, feesAccrued);
        }

        // Add to active positions if not already tracked
        if (positionIndex[poolId][owner] == 0) {
            activePositions[poolId].push(owner);
            positionIndex[poolId][owner] = activePositions[poolId].length; // 1-indexed
        }

        return (BaseHook.afterAddLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _afterRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta feesAccrued,
        bytes calldata
    ) internal override returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();

        // Track fees accrued for this position
        if (feesAccrued != BalanceDeltaLibrary.ZERO_DELTA) {
            _trackFees(poolId, sender, feesAccrued);
        }

        return (BaseHook.afterRemoveLiquidity.selector, BalanceDelta.wrap(0));
    }

    function _afterSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        // Check if sweep threshold is met and attempt sweep
        PoolId poolId = key.toId();
        BalanceDelta poolFees = totalPoolFees[poolId];

        // Check if either token has accumulated enough fees
        int128 amount0 = poolFees.amount0();
        int128 amount1 = poolFees.amount1();
        uint256 absFees0 = uint256(
            amount0 > 0 ? int256(amount0) : -int256(amount0)
        );
        uint256 absFees1 = uint256(
            amount1 > 0 ? int256(amount1) : -int256(amount1)
        );

        if (
            absFees0 >= MIN_SWEEP_THRESHOLD || absFees1 >= MIN_SWEEP_THRESHOLD
        ) {
            _attemptSweep(key);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Fee tracking
    // ──────────────────────────────────────────────────────────────────────────────

    function _trackFees(
        PoolId poolId,
        address owner,
        BalanceDelta feesAccrued
    ) internal {
        // Accumulate fees for this position
        BalanceDelta currentFees = accumulatedFees[poolId][owner];
        accumulatedFees[poolId][owner] = currentFees + feesAccrued;

        // Accumulate total pool fees
        totalPoolFees[poolId] = totalPoolFees[poolId] + feesAccrued;

        emit FeesAccrued(
            poolId,
            owner,
            feesAccrued.amount0(),
            feesAccrued.amount1()
        );
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Sweep logic
    // ──────────────────────────────────────────────────────────────────────────────

    // Public sweep entrypoint (permissionless)
    function sweep(PoolKey calldata key) external {
        _attemptSweep(key);
    }

    function _attemptSweep(PoolKey calldata key) internal {
        PoolId poolId = key.toId();

        // Get all active positions for this pool
        address[] memory positions = activePositions[poolId];
        if (positions.length == 0) revert NoActivePositions();

        // Aggregate fees from all positions
        uint256 totalFees0;
        uint256 totalFees1;

        for (uint256 i = 0; i < positions.length; i++) {
            address owner = positions[i];
            BalanceDelta fees = accumulatedFees[poolId][owner];

            if (fees == BalanceDeltaLibrary.ZERO_DELTA) continue;

            // Accumulate fees (convert to absolute values)
            int128 amount0 = fees.amount0();
            int128 amount1 = fees.amount1();
            uint256 fees0 = uint256(
                amount0 > 0 ? int256(amount0) : -int256(amount0)
            );
            uint256 fees1 = uint256(
                amount1 > 0 ? int256(amount1) : -int256(amount1)
            );

            totalFees0 += fees0;
            totalFees1 += fees1;

            // Clear accumulated fees for this position
            accumulatedFees[poolId][owner] = BalanceDeltaLibrary.ZERO_DELTA;
        }

        if (totalFees0 == 0 && totalFees1 == 0) revert NoFeesToSweep();

        // Calculate sweeper reward (CEI pattern)
        uint256 reward0 = (totalFees0 * SWEEPER_REWARD_BPS) / 10_000;
        uint256 reward1 = (totalFees1 * SWEEPER_REWARD_BPS) / 10_000;

        // Transfer rewards to sweeper
        if (reward0 > 0) {
            key.currency0.transfer(msg.sender, reward0);
        }
        if (reward1 > 0) {
            key.currency1.transfer(msg.sender, reward1);
        }

        // Deposit remaining fees to default strategy (MVP - single strategy for all)
        IYieldForgeStrategy strategy = strategyRegistry.getDefaultStrategy();
        uint256 depositAmount0 = totalFees0 - reward0;
        uint256 depositAmount1 = totalFees1 - reward1;

        if (depositAmount0 > 0 || depositAmount1 > 0) {
            strategy.deposit{
                value: key.currency0.isAddressZero() ? depositAmount0 : 0
            }(key.currency0, depositAmount0, key.currency1, depositAmount1);
            emit StrategyDeposit(
                address(strategy),
                depositAmount0,
                depositAmount1
            );
        }

        // Clear total pool fees
        totalPoolFees[poolId] = BalanceDeltaLibrary.ZERO_DELTA;

        emit FeesSwept(poolId, totalFees0, totalFees1, msg.sender);
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // View functions
    // ──────────────────────────────────────────────────────────────────────────────

    function getAccumulatedFees(
        PoolId poolId,
        address owner
    ) external view returns (int256 amount0, int256 amount1) {
        BalanceDelta fees = accumulatedFees[poolId][owner];
        return (fees.amount0(), fees.amount1());
    }

    function getTotalPoolFees(
        PoolId poolId
    ) external view returns (int256 amount0, int256 amount1) {
        BalanceDelta fees = totalPoolFees[poolId];
        return (fees.amount0(), fees.amount1());
    }

    function getActivePositionsCount(
        PoolId poolId
    ) external view returns (uint256) {
        return activePositions[poolId].length;
    }

    function getActivePositions(
        PoolId poolId
    ) external view returns (address[] memory) {
        return activePositions[poolId];
    }
}
