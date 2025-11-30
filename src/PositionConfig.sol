// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {PoolId} from "v4-core/types/PoolId.sol";

struct PositionInfo {
    uint8 strategyId;
    uint128 minSweepAmount; // in token0 units
    uint64 lastSweepBlock;
}

contract PositionConfig {
    mapping(PoolId => mapping(address => PositionInfo)) public positionInfo;

    function setPositionConfig(
        PoolId poolId,
        address owner,
        PositionInfo memory info
    ) external {
        positionInfo[poolId][owner] = info;
    }

    function getPositionConfig(
        PoolId poolId,
        address owner
    ) external view returns (PositionInfo memory) {
        return positionInfo[poolId][owner];
    }
}
