// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {YieldForgeHook} from "./YieldForgeHook.sol";
import {StrategyRegistry} from "./StrategyRegistry.sol";
import {PositionConfig} from "./PositionConfig.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

contract YieldForgeFactory {
    event HookDeployed(address hook, bytes32 salt);

    IPoolManager public immutable poolManager;
    StrategyRegistry public immutable strategyRegistry;
    PositionConfig public immutable positionConfig;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
        strategyRegistry = new StrategyRegistry();
        positionConfig = new PositionConfig();
        // Optional: pre-whitelist Aave, Compound, Yearn here
    }

    function deployHook(bytes32 salt) external returns (address) {
        YieldForgeHook hook = new YieldForgeHook{salt: salt}(
            poolManager,
            strategyRegistry,
            positionConfig
        );
        emit HookDeployed(address(hook), salt);
        return address(hook);
    }

    // Helper for deterministic address
    function getPrecomputedHookAddress(
        bytes32 salt
    ) external view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(YieldForgeHook).creationCode,
                                        abi.encode(
                                            poolManager,
                                            strategyRegistry,
                                            positionConfig
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}
