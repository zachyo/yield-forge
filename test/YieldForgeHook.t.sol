// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {BalanceDelta, BalanceDeltaLibrary, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {YieldForgeHook} from "../src/YieldForgeHook.sol";
import {StrategyRegistry} from "../src/StrategyRegistry.sol";
import {PositionConfig, PositionInfo} from "../src/PositionConfig.sol";
import {MockStrategy} from "../src/mocks/MockStrategy.sol";

contract YieldForgeHookForkTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    YieldForgeHook hook;
    StrategyRegistry strategyRegistry;
    PositionConfig positionConfig;
    MockStrategy mockStrategy;

    PoolKey poolKey;
    PoolId poolId;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address sweeper = makeAddr("sweeper");

    function setUp() public {
        // Deploy v4-core contracts
        deployFreshManagerAndRouters();

        // Deploy mock tokens
        (currency0, currency1) = deployMintAndApprove2Currencies();

        // Deploy supporting contracts
        strategyRegistry = new StrategyRegistry();
        positionConfig = new PositionConfig();

        // Deploy mock strategy
        mockStrategy = new MockStrategy();

        // Set default strategy
        strategyRegistry.setDefaultStrategy(mockStrategy);

        // Mine for valid hook address
        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
                Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
                Hooks.AFTER_SWAP_FLAG
        );

        // Find salt for valid hook address
        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(this),
            flags,
            type(YieldForgeHook).creationCode,
            abi.encode(
                address(manager),
                address(strategyRegistry),
                address(positionConfig)
            )
        );

        // Deploy hook with mined salt
        hook = new YieldForgeHook{salt: salt}(
            IPoolManager(manager),
            strategyRegistry,
            positionConfig
        );

        // Verify hook address matches
        require(address(hook) == hookAddress, "Hook address mismatch");

        console2.log("Hook deployed at:", address(hook));
        console2.log(
            "Hook flags match:",
            uint160(address(hook)) & Hooks.ALL_HOOK_MASK == flags
        );

        // Initialize pool with hook
        (poolKey, poolId) = initPool(
            currency0,
            currency1,
            hook,
            3000, // 0.3% fee
            SQRT_PRICE_1_1
        );

        // Approve tokens for test users
        MockERC20(Currency.unwrap(currency0)).approve(
            address(swapRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency1)).approve(
            address(swapRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency0)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency1)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );
    }

    function testSetup() public view {
        assertEq(address(hook.strategyRegistry()), address(strategyRegistry));
        assertEq(address(hook.positionConfig()), address(positionConfig));
        assertEq(
            address(strategyRegistry.getDefaultStrategy()),
            address(mockStrategy)
        );

        console2.log("Setup test passed");
    }

    function testAddLiquidityWithStrategy() public {
        // Encode strategy config: owner, strategyId = 0, minSweepAmount = 1e18
        bytes memory hookData = abi.encode(
            address(this),
            uint8(0),
            uint128(1e18)
        );

        // Add liquidity
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });

        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);

        // Check position config was set
        PositionInfo memory info = positionConfig.getPositionConfig(
            poolId,
            address(this)
        );
        assertEq(info.strategyId, 0);
        assertEq(info.minSweepAmount, 1e18);

        // Check position was added to active positions
        assertEq(hook.getActivePositionsCount(poolId), 1);
        address[] memory positions = hook.getActivePositions(poolId);
        assertEq(positions[0], address(this));

        console2.log("Add liquidity with strategy test passed");
    }

    function testMultiplePositions() public {
        // Setup: Add liquidity from multiple users
        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).mint(alice, 10000e18);
        MockERC20(Currency.unwrap(currency1)).mint(alice, 10000e18);
        MockERC20(Currency.unwrap(currency0)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency1)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );

        bytes memory hookData = abi.encode(alice, uint8(0), uint128(1e18));
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });
        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);
        vm.stopPrank();

        vm.startPrank(bob);
        MockERC20(Currency.unwrap(currency0)).mint(bob, 10000e18);
        MockERC20(Currency.unwrap(currency1)).mint(bob, 10000e18);
        MockERC20(Currency.unwrap(currency0)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency1)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );

        hookData = abi.encode(bob, uint8(0), uint128(1e18)); // Update hookData for bob
        params.salt = bytes32(uint256(1)); // Different salt for different position
        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);
        vm.stopPrank();

        // Verify multiple positions
        assertEq(hook.getActivePositionsCount(poolId), 2);

        address[] memory positions = hook.getActivePositions(poolId);
        assertEq(positions.length, 2);
        assertEq(positions[0], alice);
        assertEq(positions[1], bob);

        console2.log("Multiple positions test passed");
    }

    function testFeeTracking() public {
        // Add liquidity first
        bytes memory hookData = abi.encode(
            address(this),
            uint8(0),
            uint128(1e18)
        );
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });

        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);

        // Check initial fees are zero
        (int256 fees0, int256 fees1) = hook.getAccumulatedFees(
            poolId,
            address(this)
        );
        assertEq(fees0, 0);
        assertEq(fees1, 0);

        (int256 poolFees0, int256 poolFees1) = hook.getTotalPoolFees(poolId);
        assertEq(poolFees0, 0);
        assertEq(poolFees1, 0);

        console2.log("Fee tracking test passed");
    }

    function testGetAccumulatedFees() public view {
        // Test view function
        (int256 amount0, int256 amount1) = hook.getAccumulatedFees(
            poolId,
            address(this)
        );
        assertEq(amount0, 0);
        assertEq(amount1, 0);

        console2.log("Get accumulated fees test passed");
    }

    function testGetTotalPoolFees() public view {
        // Test view function
        (int256 amount0, int256 amount1) = hook.getTotalPoolFees(poolId);
        assertEq(amount0, 0);
        assertEq(amount1, 0);

        console2.log("Get total pool fees test passed");
    }

    function testHookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        assertFalse(permissions.beforeInitialize);
        assertTrue(permissions.afterInitialize);
        assertFalse(permissions.beforeAddLiquidity);
        assertTrue(permissions.afterAddLiquidity);
        assertFalse(permissions.beforeRemoveLiquidity);
        assertTrue(permissions.afterRemoveLiquidity);
        assertFalse(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
        assertFalse(permissions.beforeDonate);
        assertFalse(permissions.afterDonate);

        console2.log("Hook permissions test passed");
    }

    function testStrategyIntegration() public view {
        // Verify strategy is set correctly
        assertEq(
            address(strategyRegistry.getDefaultStrategy()),
            address(mockStrategy)
        );

        console2.log(" Strategy integration test passed");
    }

    function testSweepRevertWithNoPositions() public {
        // Create a new pool with no positions
        PoolKey memory emptyPoolKey;
        (emptyPoolKey, ) = initPool(
            currency0,
            currency1,
            hook,
            500, // 0.05% fee
            SQRT_PRICE_1_1
        );

        // Try to sweep (should revert with NoActivePositions)
        vm.expectRevert(YieldForgeHook.NoActivePositions.selector);
        hook.sweep(emptyPoolKey);

        console2.log(" Sweep revert test passed");
    }

    function testActivePositionsTracking() public {
        // Initially no positions
        assertEq(hook.getActivePositionsCount(poolId), 0);

        // Add first position
        bytes memory hookData = abi.encode(
            address(this),
            uint8(0),
            uint128(1e18)
        );
        ModifyLiquidityParams memory params = ModifyLiquidityParams({
            tickLower: -60,
            tickUpper: 60,
            liquidityDelta: 1000e18,
            salt: bytes32(0)
        });
        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);

        assertEq(hook.getActivePositionsCount(poolId), 1);

        // Add second position from different user
        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).mint(alice, 10000e18);
        MockERC20(Currency.unwrap(currency1)).mint(alice, 10000e18);
        MockERC20(Currency.unwrap(currency0)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );
        MockERC20(Currency.unwrap(currency1)).approve(
            address(modifyLiquidityRouter),
            type(uint256).max
        );

        hookData = abi.encode(alice, uint8(0), uint128(1e18)); // Update hookData for alice
        params.salt = bytes32(uint256(1));
        modifyLiquidityRouter.modifyLiquidity(poolKey, params, hookData);
        vm.stopPrank();

        assertEq(hook.getActivePositionsCount(poolId), 2);

        console2.log(" Active positions tracking test passed");
    }
}
