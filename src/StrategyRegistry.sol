// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IYieldForgeStrategy} from "./interfaces/IYieldForgeStrategy.sol";

contract StrategyRegistry {
    address public governance;
    IYieldForgeStrategy public defaultStrategy;

    mapping(uint8 => IYieldForgeStrategy) public strategies;
    uint8 public strategyCount;

    constructor() {
        governance = msg.sender;
    }

    function setDefaultStrategy(IYieldForgeStrategy strategy) external {
        require(msg.sender == governance);
        defaultStrategy = strategy;
    }

    function addStrategy(uint8 id, IYieldForgeStrategy strategy) external {
        require(msg.sender == governance);
        strategies[id] = strategy;
        if (strategyCount < id + 1) strategyCount = id + 1;
    }

    function getDefaultStrategy() external view returns (IYieldForgeStrategy) {
        return
            defaultStrategy != IYieldForgeStrategy(address(0))
                ? defaultStrategy
                : strategies[0];
    }
}
