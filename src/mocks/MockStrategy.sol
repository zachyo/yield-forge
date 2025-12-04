// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IYieldForgeStrategy} from "../interfaces/IYieldForgeStrategy.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";

/// @title MockStrategy
/// @notice A simple mock strategy for testing that just holds the deposited tokens
contract MockStrategy is IYieldForgeStrategy {
    using CurrencyLibrary for Currency;

    // Track total deposits
    mapping(Currency => uint256) public totalDeposits;

    // Track shares per depositor (simplified - not a real vault)
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    event Deposited(
        Currency currency0,
        uint256 amount0,
        Currency currency1,
        uint256 amount1,
        address indexed depositor
    );
    event Withdrawn(
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    function deposit(
        Currency currency0,
        uint256 amount0,
        Currency currency1,
        uint256 amount1
    ) external payable override {
        // Accept native ETH if currency0 is address(0)
        if (currency0.isAddressZero()) {
            require(msg.value == amount0, "MockStrategy: incorrect ETH amount");
        }

        // Track deposits
        totalDeposits[currency0] += amount0;
        totalDeposits[currency1] += amount1;

        // Mint shares (simplified 1:1 for testing)
        uint256 newShares = amount0 + amount1;
        shares[msg.sender] += newShares;
        totalShares += newShares;

        emit Deposited(currency0, amount0, currency1, amount1, msg.sender);
    }

    function withdraw(
        address to,
        uint256 sharesToBurn
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(
            shares[msg.sender] >= sharesToBurn,
            "MockStrategy: insufficient shares"
        );

        // Simplified withdrawal - return proportional amounts
        // In a real strategy, this would redeem from the underlying protocol
        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // For testing, just return the shares as amounts
        amount0 = sharesToBurn / 2;
        amount1 = sharesToBurn / 2;

        emit Withdrawn(to, sharesToBurn, amount0, amount1);
    }

    // Helper function to check balance
    function getBalance(Currency currency) external view returns (uint256) {
        return totalDeposits[currency];
    }

    // Allow contract to receive ETH
    receive() external payable {}
}
