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

    // ──────────────────────────────────────────────────────────────────────────────
    // Yield Share Tracking (for withdrawals)
    // ──────────────────────────────────────────────────────────────────────────────

    // Track yield shares per position per pool
    // poolId => owner => shares (represents proportional claim to strategy deposits)
    mapping(PoolId => mapping(address => uint256)) public yieldShares;

    // Total shares per pool (for calculating proportional withdrawals)
    mapping(PoolId => uint256) public totalYieldShares;

    // Track total deposits per pool to strategies (for yield calculation)
    mapping(PoolId => uint256) public totalDeposited0;
    mapping(PoolId => uint256) public totalDeposited1;

    // Track deposits per position (for share calculation)
    mapping(PoolId => mapping(address => uint256)) public positionDeposited0;
    mapping(PoolId => mapping(address => uint256)) public positionDeposited1;

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
    event YieldWithdrawn(
        PoolId indexed poolId,
        address indexed owner,
        uint256 amount0,
        uint256 amount1,
        uint256 sharesBurned
    );
    event YieldSharesUpdated(
        PoolId indexed poolId,
        address indexed owner,
        uint256 newShares,
        uint256 totalShares
    );

    error SweepThresholdNotReached();
    error NoFeesToSweep();
    error NoActivePositions();
    error NoYieldToWithdraw();
    error InsufficientShares();

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

        // Collect fees from all positions and calculate totals
        (
            uint256 totalFees0,
            uint256 totalFees1,
            uint256[] memory positionFees0,
            uint256[] memory positionFees1
        ) = _collectPositionFees(poolId, positions);

        if (totalFees0 == 0 && totalFees1 == 0) revert NoFeesToSweep();

        // Calculate sweeper reward and deposit amounts
        uint256 reward0 = (totalFees0 * SWEEPER_REWARD_BPS) / 10_000;
        uint256 reward1 = (totalFees1 * SWEEPER_REWARD_BPS) / 10_000;
        uint256 depositAmount0 = totalFees0 - reward0;
        uint256 depositAmount1 = totalFees1 - reward1;

        // Update yield shares for each position
        _updateAllPositionShares(
            poolId,
            positions,
            positionFees0,
            positionFees1,
            totalFees0,
            totalFees1,
            depositAmount0,
            depositAmount1
        );

        // Transfer rewards to sweeper
        if (reward0 > 0) {
            key.currency0.transfer(msg.sender, reward0);
        }
        if (reward1 > 0) {
            key.currency1.transfer(msg.sender, reward1);
        }

        // Deposit remaining fees to default strategy
        _depositToStrategy(key, depositAmount0, depositAmount1);

        // Clear total pool fees
        totalPoolFees[poolId] = BalanceDeltaLibrary.ZERO_DELTA;

        emit FeesSwept(poolId, totalFees0, totalFees1, msg.sender);
    }

    /// @notice Collect and aggregate fees from all positions
    function _collectPositionFees(
        PoolId poolId,
        address[] memory positions
    )
        internal
        returns (
            uint256 totalFees0,
            uint256 totalFees1,
            uint256[] memory positionFees0,
            uint256[] memory positionFees1
        )
    {
        positionFees0 = new uint256[](positions.length);
        positionFees1 = new uint256[](positions.length);

        for (uint256 i = 0; i < positions.length; i++) {
            BalanceDelta fees = accumulatedFees[poolId][positions[i]];

            if (fees == BalanceDeltaLibrary.ZERO_DELTA) continue;

            // Convert to absolute values
            int128 amt0 = fees.amount0();
            int128 amt1 = fees.amount1();
            uint256 fees0 = uint256(amt0 > 0 ? int256(amt0) : -int256(amt0));
            uint256 fees1 = uint256(amt1 > 0 ? int256(amt1) : -int256(amt1));

            positionFees0[i] = fees0;
            positionFees1[i] = fees1;
            totalFees0 += fees0;
            totalFees1 += fees1;

            // Clear accumulated fees
            accumulatedFees[poolId][positions[i]] = BalanceDeltaLibrary
                .ZERO_DELTA;
        }
    }

    /// @notice Update yield shares for a single position
    function _updatePositionShares(
        PoolId poolId,
        address owner,
        uint256 share0,
        uint256 share1
    ) internal {
        uint256 depositValue = share0 + share1;
        if (depositValue == 0) return;

        yieldShares[poolId][owner] += depositValue;
        totalYieldShares[poolId] += depositValue;
        positionDeposited0[poolId][owner] += share0;
        positionDeposited1[poolId][owner] += share1;
    }

    /// @notice Calculate and update shares for all positions
    function _updateAllPositionShares(
        PoolId poolId,
        address[] memory positions,
        uint256[] memory positionFees0,
        uint256[] memory positionFees1,
        uint256 totalFees0,
        uint256 totalFees1,
        uint256 depositAmount0,
        uint256 depositAmount1
    ) internal {
        for (uint256 i = 0; i < positions.length; i++) {
            if (positionFees0[i] == 0 && positionFees1[i] == 0) continue;

            uint256 share0 = totalFees0 > 0
                ? (positionFees0[i] * depositAmount0) / totalFees0
                : 0;
            uint256 share1 = totalFees1 > 0
                ? (positionFees1[i] * depositAmount1) / totalFees1
                : 0;

            _updatePositionShares(poolId, positions[i], share0, share1);
        }

        // Track total deposits
        totalDeposited0[poolId] += depositAmount0;
        totalDeposited1[poolId] += depositAmount1;
    }

    /// @notice Deposit fees to strategy
    function _depositToStrategy(
        PoolKey calldata key,
        uint256 depositAmount0,
        uint256 depositAmount1
    ) internal {
        if (depositAmount0 == 0 && depositAmount1 == 0) return;

        IYieldForgeStrategy strategy = strategyRegistry.getDefaultStrategy();
        strategy.deposit{
            value: key.currency0.isAddressZero() ? depositAmount0 : 0
        }(key.currency0, depositAmount0, key.currency1, depositAmount1);

        emit StrategyDeposit(address(strategy), depositAmount0, depositAmount1);
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

    // ──────────────────────────────────────────────────────────────────────────────
    // Yield Withdrawal Functions
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Withdraw yield from the strategy for a specific position
    /// @param key The pool key
    /// @param sharesToWithdraw Amount of shares to burn (use 0 for all shares)
    /// @return amount0 Amount of token0 withdrawn
    /// @return amount1 Amount of token1 withdrawn
    function withdrawYield(
        PoolKey calldata key,
        uint256 sharesToWithdraw
    ) external returns (uint256 amount0, uint256 amount1) {
        PoolId poolId = key.toId();

        uint256 userShares = yieldShares[poolId][msg.sender];
        if (userShares == 0) revert NoYieldToWithdraw();

        // Use all shares if 0 is specified
        uint256 actualSharesToWithdraw = sharesToWithdraw == 0
            ? userShares
            : sharesToWithdraw;
        if (actualSharesToWithdraw > userShares) revert InsufficientShares();

        // Get claimable amounts based on share proportion
        (uint256 claimable0, uint256 claimable1) = _calculateClaimableYield(
            poolId,
            msg.sender,
            actualSharesToWithdraw
        );

        // CEI: Update state before external calls
        yieldShares[poolId][msg.sender] -= actualSharesToWithdraw;
        totalYieldShares[poolId] -= actualSharesToWithdraw;

        // Update deposit tracking
        if (
            claimable0 > 0 &&
            positionDeposited0[poolId][msg.sender] >= claimable0
        ) {
            positionDeposited0[poolId][msg.sender] -= claimable0;
            totalDeposited0[poolId] -= claimable0;
        }
        if (
            claimable1 > 0 &&
            positionDeposited1[poolId][msg.sender] >= claimable1
        ) {
            positionDeposited1[poolId][msg.sender] -= claimable1;
            totalDeposited1[poolId] -= claimable1;
        }

        // Withdraw from strategy
        IYieldForgeStrategy strategy = strategyRegistry.getDefaultStrategy();
        (amount0, amount1) = strategy.withdraw(
            msg.sender,
            actualSharesToWithdraw
        );

        emit YieldWithdrawn(
            poolId,
            msg.sender,
            amount0,
            amount1,
            actualSharesToWithdraw
        );

        return (amount0, amount1);
    }

    /// @notice Get claimable yield for a position
    /// @param poolId The pool ID
    /// @param owner The position owner
    /// @return claimable0 Claimable amount of token0
    /// @return claimable1 Claimable amount of token1
    function getClaimableYield(
        PoolId poolId,
        address owner
    ) external view returns (uint256 claimable0, uint256 claimable1) {
        uint256 userShares = yieldShares[poolId][owner];
        if (userShares == 0) return (0, 0);

        return _calculateClaimableYield(poolId, owner, userShares);
    }

    /// @notice Get yield shares for a position
    /// @param poolId The pool ID
    /// @param owner The position owner
    /// @return shares The position's yield shares
    /// @return totalShares The total yield shares in the pool
    function getYieldShares(
        PoolId poolId,
        address owner
    ) external view returns (uint256 shares, uint256 totalShares) {
        return (yieldShares[poolId][owner], totalYieldShares[poolId]);
    }

    /// @notice Get deposit tracking for a position
    /// @param poolId The pool ID
    /// @param owner The position owner
    /// @return deposited0 Amount of token0 deposited to strategy
    /// @return deposited1 Amount of token1 deposited to strategy
    function getPositionDeposits(
        PoolId poolId,
        address owner
    ) external view returns (uint256 deposited0, uint256 deposited1) {
        return (
            positionDeposited0[poolId][owner],
            positionDeposited1[poolId][owner]
        );
    }

    /// @notice Get total deposits for a pool
    /// @param poolId The pool ID
    /// @return total0 Total token0 deposited to strategy
    /// @return total1 Total token1 deposited to strategy
    function getTotalDeposits(
        PoolId poolId
    ) external view returns (uint256 total0, uint256 total1) {
        return (totalDeposited0[poolId], totalDeposited1[poolId]);
    }

    /// @notice Get comprehensive position info for dashboard display
    /// @param poolId The pool ID
    /// @param owner The position owner
    /// @return pendingFees0 Pending fees token0 (not yet swept)
    /// @return pendingFees1 Pending fees token1 (not yet swept)
    /// @return yieldShares_ Yield shares in strategy
    /// @return claimable0 Claimable yield token0
    /// @return claimable1 Claimable yield token1
    function getPositionInfo(
        PoolId poolId,
        address owner
    )
        external
        view
        returns (
            int256 pendingFees0,
            int256 pendingFees1,
            uint256 yieldShares_,
            uint256 claimable0,
            uint256 claimable1
        )
    {
        BalanceDelta fees = accumulatedFees[poolId][owner];
        pendingFees0 = fees.amount0();
        pendingFees1 = fees.amount1();

        yieldShares_ = yieldShares[poolId][owner];

        if (yieldShares_ > 0) {
            (claimable0, claimable1) = _calculateClaimableYield(
                poolId,
                owner,
                yieldShares_
            );
        }
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // Internal functions
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Calculate claimable yield based on shares
    function _calculateClaimableYield(
        PoolId poolId,
        address owner,
        uint256 sharesToClaim
    ) internal view returns (uint256 claimable0, uint256 claimable1) {
        uint256 userShares = yieldShares[poolId][owner];
        if (userShares == 0 || sharesToClaim == 0) return (0, 0);

        uint256 totalShares = totalYieldShares[poolId];
        if (totalShares == 0) return (0, 0);

        // Calculate proportional share of deposits
        // Note: In production, this would query actual strategy value for yield accrual
        uint256 userDeposit0 = positionDeposited0[poolId][owner];
        uint256 userDeposit1 = positionDeposited1[poolId][owner];

        // Proportional to shares being claimed
        claimable0 = (userDeposit0 * sharesToClaim) / userShares;
        claimable1 = (userDeposit1 * sharesToClaim) / userShares;
    }
}
