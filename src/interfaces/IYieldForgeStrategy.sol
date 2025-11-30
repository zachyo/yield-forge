// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Currency} from "v4-core/types/Currency.sol";

interface IYieldForgeStrategy {
    function deposit(
        Currency currency0,
        uint256 amount0,
        Currency currency1,
        uint256 amount1
    ) external payable;

    function withdraw(
        address to,
        uint256 shares
    ) external returns (uint256 amount0, uint256 amount1);
}
