// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AaveV3Strategy} from "../src/strategies/AaveV3Strategy.sol";
import {CompoundV3Strategy} from "../src/strategies/CompoundV3Strategy.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

/**
 * @title DeployStrategies
 * @notice Deployment script for Aave V3 and Compound V3 strategies
 * @dev Run with: forge script script/DeployStrategies.s.sol --rpc-url <RPC_URL> --broadcast
 */
contract DeployStrategies is Script {
    // Mainnet addresses
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address constant aUSDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address constant aWETH = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address constant aDAI = 0x018008bfb33d285247A21d44E50697654f754e63;

    address constant USDC_COMET = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Aave V3 Strategy
        console2.log("Deploying Aave V3 Strategy...");
        AaveV3Strategy aaveStrategy = new AaveV3Strategy(AAVE_POOL);
        console2.log("Aave V3 Strategy deployed at:", address(aaveStrategy));

        // Configure Aave currencies
        console2.log("Configuring Aave currencies...");
        aaveStrategy.configureCurrency(Currency.wrap(USDC), aUSDC);
        console2.log("  - USDC configured");

        aaveStrategy.configureCurrency(Currency.wrap(WETH), aWETH);
        console2.log("  - WETH configured");

        aaveStrategy.configureCurrency(Currency.wrap(DAI), aDAI);
        console2.log("  - DAI configured");

        // Deploy Compound V3 Strategy
        console2.log("\nDeploying Compound V3 Strategy...");
        CompoundV3Strategy compoundStrategy = new CompoundV3Strategy(
            USDC_COMET
        );
        console2.log(
            "Compound V3 Strategy deployed at:",
            address(compoundStrategy)
        );

        // Configure Compound currency
        console2.log("Configuring Compound currency...");
        compoundStrategy.configureCurrency(Currency.wrap(USDC));
        console2.log("  - USDC configured");

        vm.stopBroadcast();

        // Print summary
        console2.log("\n=== Deployment Summary ===");
        console2.log("Aave V3 Strategy:", address(aaveStrategy));
        console2.log("  Supported: USDC, WETH, DAI");
        console2.log("\nCompound V3 Strategy:", address(compoundStrategy));
        console2.log("  Supported: USDC");
        console2.log("\nNext steps:");
        console2.log("1. Register strategies in StrategyRegistry");
        console2.log("2. Set default strategy or assign strategy IDs");
        console2.log("3. Update frontend with strategy addresses");
    }
}

/**
 * @title DeployStrategiesBase
 * @notice Deployment script for Base network
 */
contract DeployStrategiesBase is Script {
    // Base addresses
    address constant AAVE_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH = 0x4200000000000000000000000000000000000006;

    // Base aTokens (you'll need to find these)
    address constant aUSDC = address(0); // TODO: Find Base aUSDC
    address constant aWETH = address(0); // TODO: Find Base aWETH

    address constant USDC_COMET = 0xb125E6687d4313864e53df431d5425969c15Eb2F;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Deploying to Base...");

        // Deploy Aave V3 Strategy
        AaveV3Strategy aaveStrategy = new AaveV3Strategy(AAVE_POOL);
        console2.log("Aave V3 Strategy deployed at:", address(aaveStrategy));

        // Deploy Compound V3 Strategy
        CompoundV3Strategy compoundStrategy = new CompoundV3Strategy(
            USDC_COMET
        );
        console2.log(
            "Compound V3 Strategy deployed at:",
            address(compoundStrategy)
        );

        // Configure Compound
        compoundStrategy.configureCurrency(Currency.wrap(USDC));
        console2.log("Compound configured for USDC");

        vm.stopBroadcast();

        console2.log("\n=== Base Deployment Complete ===");
        console2.log("Aave V3 Strategy:", address(aaveStrategy));
        console2.log("Compound V3 Strategy:", address(compoundStrategy));
    }
}

/**
 * @title DeployStrategiesArbitrum
 * @notice Deployment script for Arbitrum network
 */
contract DeployStrategiesArbitrum is Script {
    // Arbitrum addresses
    address constant AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
    address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    address constant USDC_COMET = 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console2.log("Deploying to Arbitrum...");

        // Deploy Aave V3 Strategy
        AaveV3Strategy aaveStrategy = new AaveV3Strategy(AAVE_POOL);
        console2.log("Aave V3 Strategy deployed at:", address(aaveStrategy));

        // Deploy Compound V3 Strategy
        CompoundV3Strategy compoundStrategy = new CompoundV3Strategy(
            USDC_COMET
        );
        console2.log(
            "Compound V3 Strategy deployed at:",
            address(compoundStrategy)
        );

        // Configure Compound
        compoundStrategy.configureCurrency(Currency.wrap(USDC));
        console2.log("Compound configured for USDC");

        vm.stopBroadcast();

        console2.log("\n=== Arbitrum Deployment Complete ===");
        console2.log("Aave V3 Strategy:", address(aaveStrategy));
        console2.log("Compound V3 Strategy:", address(compoundStrategy));
    }
}
