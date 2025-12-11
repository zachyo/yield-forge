// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {YieldForgeHook} from "../src/YieldForgeHook.sol";
import {YieldForgeFactory} from "../src/YieldForgeFactory.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

contract DeployHook is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Sepolia PoolManager
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Factory
        console.log("Deploying YieldForgeFactory...");
        YieldForgeFactory factory = new YieldForgeFactory(
            IPoolManager(poolManager)
        );
        console.log("YieldForgeFactory deployed at:", address(factory));

        // 2. Mine Salt for Hook
        console.log("Mining salt for Hook...");

        uint160 flags = uint160(
            Hooks.AFTER_INITIALIZE_FLAG |
                Hooks.AFTER_ADD_LIQUIDITY_FLAG |
                Hooks.AFTER_REMOVE_LIQUIDITY_FLAG |
                Hooks.AFTER_SWAP_FLAG
        );

        // Prepare constructor arguments for the hook
        bytes memory constructorArgs = abi.encode(
            factory.poolManager(),
            factory.strategyRegistry(),
            factory.positionConfig()
        );

        // Use HookMiner to find a salt
        (address expectedHookAddress, bytes32 salt) = HookMiner.find(
            address(factory),
            flags,
            type(YieldForgeHook).creationCode,
            constructorArgs
        );

        console.log("Expected Hook Address:", expectedHookAddress);
        console.logBytes32(salt);

        // 3. Deploy Hook
        console.log("Deploying YieldForgeHook...");
        address hookAddress = factory.deployHook(salt);
        console.log("YieldForgeHook deployed at:", hookAddress);

        require(hookAddress == expectedHookAddress, "Hook address mismatch");

        require(
            uint160(hookAddress) & flags == flags,
            "Hook address does not have correct flags"
        );

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("Factory:", address(factory));
        console.log("Hook:", hookAddress);
        console.log("StrategyRegistry:", address(factory.strategyRegistry()));
        console.log("PositionConfig:", address(factory.positionConfig()));
    }
}
