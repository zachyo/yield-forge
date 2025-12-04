// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AaveV3Strategy} from "../src/strategies/AaveV3Strategy.sol";
import {CompoundV3Strategy} from "../src/strategies/CompoundV3Strategy.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title StrategyIntegrationTest
 * @notice Fork tests for Aave V3 and Compound V3 strategy integrations
 * @dev These tests require forking mainnet to interact with real protocols
 */
contract StrategyIntegrationTest is Test {
    using CurrencyLibrary for Currency;

    // Mainnet addresses
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant aUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address constant aWETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

    // Compound V3 addresses
    address constant USDC_COMET = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

    // Whale addresses for testing (addresses with large balances)
    address constant USDC_WHALE = 0xf584F8728B874a6a5c7A8d4d387C9aae9172D621;
    address constant WETH_WHALE = 0x8EB8a3b98659Cce290402893d0123abb75E3ab28;

    AaveV3Strategy aaveStrategy;
    CompoundV3Strategy compoundStrategy;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        // Fork mainnet at a recent block
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // Deploy strategies
        aaveStrategy = new AaveV3Strategy(AAVE_POOL);
        compoundStrategy = new CompoundV3Strategy(USDC_COMET);

        // Configure Aave strategy
        aaveStrategy.configureCurrency(Currency.wrap(USDC), aUSDC);
        aaveStrategy.configureCurrency(Currency.wrap(WETH), aWETH);

        // Configure Compound strategy
        compoundStrategy.configureCurrency(Currency.wrap(USDC));

        console2.log("Aave strategy deployed at:", address(aaveStrategy));
        console2.log(
            "Compound strategy deployed at:",
            address(compoundStrategy)
        );
    }

    // ============ Aave V3 Strategy Tests ============

    function testAaveDepositUSDC() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Get USDC from whale
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, depositAmount);

        // Alice deposits into Aave strategy
        vm.startPrank(alice);
        IERC20(USDC).approve(address(aaveStrategy), depositAmount);

        uint256 sharesBefore = aaveStrategy.shares(alice);
        uint256 totalSharesBefore = aaveStrategy.totalShares();

        aaveStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );

        uint256 sharesAfter = aaveStrategy.shares(alice);
        uint256 totalSharesAfter = aaveStrategy.totalShares();

        vm.stopPrank();

        // Verify shares were minted
        assertGt(sharesAfter, sharesBefore, "Shares should increase");
        assertGt(
            totalSharesAfter,
            totalSharesBefore,
            "Total shares should increase"
        );

        // Verify aTokens were received (allow for small rounding)
        uint256 aTokenBalance = aaveStrategy.getATokenBalance(
            Currency.wrap(USDC)
        );
        assertApproxEqAbs(
            aTokenBalance,
            depositAmount,
            10,
            "Should receive aTokens"
        );

        console2.log("Alice shares:", sharesAfter);
        console2.log("aUSDC balance:", aTokenBalance);
    }

    function testAaveDepositMultipleCurrencies() public {
        uint256 usdcAmount = 1000e6; // 1000 USDC
        uint256 wethAmount = 1e18; // 1 WETH

        // Get tokens from whales
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, usdcAmount);

        vm.prank(WETH_WHALE);
        IERC20(WETH).transfer(alice, wethAmount);

        // Alice deposits both tokens
        vm.startPrank(alice);
        IERC20(USDC).approve(address(aaveStrategy), usdcAmount);
        IERC20(WETH).approve(address(aaveStrategy), wethAmount);

        aaveStrategy.deposit(
            Currency.wrap(USDC),
            usdcAmount,
            Currency.wrap(WETH),
            wethAmount
        );

        vm.stopPrank();

        // Verify both aTokens were received
        uint256 aUSDCBalance = aaveStrategy.getATokenBalance(
            Currency.wrap(USDC)
        );
        uint256 aWETHBalance = aaveStrategy.getATokenBalance(
            Currency.wrap(WETH)
        );

        // Allow for small rounding differences (up to 10 wei)
        assertApproxEqAbs(aUSDCBalance, usdcAmount, 10, "Should receive aUSDC");
        assertApproxEqAbs(aWETHBalance, wethAmount, 10, "Should receive aWETH");

        console2.log("aUSDC balance:", aUSDCBalance);
        console2.log("aWETH balance:", aWETHBalance);
    }

    function testAaveMultipleDepositors() public {
        uint256 depositAmount = 1000e6; // 1000 USDC each

        // Setup Alice
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, depositAmount);

        vm.startPrank(alice);
        IERC20(USDC).approve(address(aaveStrategy), depositAmount);
        aaveStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );
        vm.stopPrank();

        // Setup Bob
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(bob, depositAmount);

        vm.startPrank(bob);
        IERC20(USDC).approve(address(aaveStrategy), depositAmount);
        aaveStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );
        vm.stopPrank();

        // Verify both have shares
        assertGt(aaveStrategy.shares(alice), 0, "Alice should have shares");
        assertGt(aaveStrategy.shares(bob), 0, "Bob should have shares");

        // Total shares should be sum of individual shares
        assertEq(
            aaveStrategy.totalShares(),
            aaveStrategy.shares(alice) + aaveStrategy.shares(bob),
            "Total shares mismatch"
        );

        console2.log("Alice shares:", aaveStrategy.shares(alice));
        console2.log("Bob shares:", aaveStrategy.shares(bob));
        console2.log("Total shares:", aaveStrategy.totalShares());
    }

    // ============ Compound V3 Strategy Tests ============

    function testCompoundDepositUSDC() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Get USDC from whale
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, depositAmount);

        // Alice deposits into Compound strategy
        vm.startPrank(alice);
        IERC20(USDC).approve(address(compoundStrategy), depositAmount);

        uint256 sharesBefore = compoundStrategy.shares(alice);
        uint256 balanceBefore = compoundStrategy.getBalance();

        compoundStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );

        uint256 sharesAfter = compoundStrategy.shares(alice);
        uint256 balanceAfter = compoundStrategy.getBalance();

        vm.stopPrank();

        // Verify shares were minted
        assertGt(sharesAfter, sharesBefore, "Shares should increase");

        // Verify Compound balance increased (allow for small rounding)
        assertApproxEqAbs(
            balanceAfter,
            balanceBefore + depositAmount,
            10,
            "Compound balance should increase"
        );

        console2.log("Alice shares:", sharesAfter);
        console2.log("Compound balance:", balanceAfter);
    }

    function testCompoundMultipleDepositors() public {
        uint256 depositAmount = 1000e6; // 1000 USDC each

        // Setup Alice
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, depositAmount);

        vm.startPrank(alice);
        IERC20(USDC).approve(address(compoundStrategy), depositAmount);
        compoundStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );
        vm.stopPrank();

        // Setup Bob
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(bob, depositAmount);

        vm.startPrank(bob);
        IERC20(USDC).approve(address(compoundStrategy), depositAmount);
        compoundStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );
        vm.stopPrank();

        // Verify both have shares
        assertGt(compoundStrategy.shares(alice), 0, "Alice should have shares");
        assertGt(compoundStrategy.shares(bob), 0, "Bob should have shares");

        console2.log("Alice shares:", compoundStrategy.shares(alice));
        console2.log("Bob shares:", compoundStrategy.shares(bob));
        console2.log("Total shares:", compoundStrategy.totalShares());
    }

    function testCompoundWithdraw() public {
        uint256 depositAmount = 1000e6; // 1000 USDC

        // Get USDC and deposit
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(alice, depositAmount);

        vm.startPrank(alice);
        IERC20(USDC).approve(address(compoundStrategy), depositAmount);
        compoundStrategy.deposit(
            Currency.wrap(USDC),
            depositAmount,
            Currency.wrap(address(0)),
            0
        );

        uint256 shares = compoundStrategy.shares(alice);
        uint256 usdcBefore = IERC20(USDC).balanceOf(alice);

        // Withdraw half
        uint256 sharesToBurn = shares / 2;
        (uint256 amount0, ) = compoundStrategy.withdraw(alice, sharesToBurn);

        uint256 usdcAfter = IERC20(USDC).balanceOf(alice);

        vm.stopPrank();

        // Verify withdrawal
        assertGt(amount0, 0, "Should withdraw some USDC");
        assertGt(usdcAfter, usdcBefore, "USDC balance should increase");
        assertEq(
            compoundStrategy.shares(alice),
            shares - sharesToBurn,
            "Shares should decrease"
        );

        console2.log("Withdrawn amount:", amount0);
        console2.log("Remaining shares:", compoundStrategy.shares(alice));
    }

    // ============ Error Cases ============

    function testAaveRevertUnsupportedCurrency() public {
        address unsupportedToken = makeAddr("unsupported");

        // Expect UnsupportedCurrency when trying to deposit unsupported token with amount > 0
        vm.expectRevert(AaveV3Strategy.UnsupportedCurrency.selector);
        aaveStrategy.deposit(
            Currency.wrap(unsupportedToken),
            1000e6,
            Currency.wrap(USDC), // Use supported currency for currency1
            0
        );
    }

    function testCompoundRevertUnsupportedCurrency() public {
        address unsupportedToken = makeAddr("unsupported");

        // Expect UnsupportedCurrency when trying to deposit unsupported token with amount > 0
        vm.expectRevert(CompoundV3Strategy.UnsupportedCurrency.selector);
        compoundStrategy.deposit(
            Currency.wrap(unsupportedToken),
            1000e6,
            Currency.wrap(USDC), // Use supported currency for currency1
            0
        );
    }

    function testCompoundRevertInsufficientShares() public {
        vm.expectRevert(CompoundV3Strategy.InsufficientShares.selector);
        vm.prank(alice);
        compoundStrategy.withdraw(alice, 1000);
    }
}
