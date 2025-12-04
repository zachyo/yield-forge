// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IYieldForgeStrategy} from "../interfaces/IYieldForgeStrategy.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Aave V3 interfaces
interface IPool {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IAToken is IERC20 {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/// @title AaveV3Strategy
/// @notice Strategy that deposits tokens into Aave V3 to earn yield
/// @dev This strategy wraps deposits into Aave's lending pools
contract AaveV3Strategy is IYieldForgeStrategy {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    // Aave V3 Pool address (mainnet: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2)
    IPool public immutable aavePool;

    // Track aToken addresses for each currency
    mapping(Currency => IAToken) public aTokens;

    // Track shares per depositor
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    // Track which currencies are supported
    mapping(Currency => bool) public supportedCurrencies;

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
    event CurrencyConfigured(Currency indexed currency, address indexed aToken);

    error UnsupportedCurrency();
    error InsufficientShares();
    error NativeTokenNotSupported();

    constructor(address _aavePool) {
        aavePool = IPool(_aavePool);
    }

    /// @notice Configure a currency to use with this strategy
    /// @param currency The currency to configure
    /// @param aToken The corresponding aToken address
    function configureCurrency(Currency currency, address aToken) external {
        require(aToken != address(0), "Invalid aToken");
        require(!currency.isAddressZero(), "Native token not supported");

        aTokens[currency] = IAToken(aToken);
        supportedCurrencies[currency] = true;

        // Approve Aave pool to spend underlying tokens
        IERC20(Currency.unwrap(currency)).forceApprove(
            address(aavePool),
            type(uint256).max
        );

        emit CurrencyConfigured(currency, aToken);
    }

    /// @notice Deposit tokens into Aave V3
    /// @param currency0 First currency to deposit
    /// @param amount0 Amount of first currency
    /// @param currency1 Second currency to deposit
    /// @param amount1 Amount of second currency
    function deposit(
        Currency currency0,
        uint256 amount0,
        Currency currency1,
        uint256 amount1
    ) external payable override {
        // Native ETH not supported in this strategy - only check if amount > 0
        if (amount0 > 0 && currency0.isAddressZero()) {
            revert NativeTokenNotSupported();
        }
        if (amount1 > 0 && currency1.isAddressZero()) {
            revert NativeTokenNotSupported();
        }

        uint256 totalValue = 0;

        // Deposit currency0 to Aave
        if (amount0 > 0) {
            if (!supportedCurrencies[currency0]) revert UnsupportedCurrency();

            // Transfer tokens from sender
            IERC20(Currency.unwrap(currency0)).safeTransferFrom(
                msg.sender,
                address(this),
                amount0
            );

            // Supply to Aave
            aavePool.supply(
                Currency.unwrap(currency0),
                amount0,
                address(this),
                0 // referral code
            );

            totalValue += amount0;
        }

        // Deposit currency1 to Aave
        if (amount1 > 0) {
            if (!supportedCurrencies[currency1]) revert UnsupportedCurrency();

            // Transfer tokens from sender
            IERC20(Currency.unwrap(currency1)).safeTransferFrom(
                msg.sender,
                address(this),
                amount1
            );

            // Supply to Aave
            aavePool.supply(
                Currency.unwrap(currency1),
                amount1,
                address(this),
                0 // referral code
            );

            totalValue += amount1;
        }

        // Mint shares based on total value deposited
        // In a production system, you'd want to normalize by token prices
        uint256 newShares = totalValue;
        if (totalShares > 0) {
            // Calculate shares based on current pool value
            uint256 poolValue = _getTotalValue(currency0, currency1);
            newShares = (totalValue * totalShares) / (poolValue - totalValue);
        }

        shares[msg.sender] += newShares;
        totalShares += newShares;

        emit Deposited(currency0, amount0, currency1, amount1, msg.sender);
    }

    /// @notice Withdraw tokens from Aave V3
    /// @param to Address to send withdrawn tokens
    /// @param sharesToBurn Amount of shares to burn
    /// @return amount0 Amount of first currency withdrawn
    /// @return amount1 Amount of second currency withdrawn
    function withdraw(
        address to,
        uint256 sharesToBurn
    ) external override returns (uint256 amount0, uint256 amount1) {
        if (shares[msg.sender] < sharesToBurn) revert InsufficientShares();

        // Calculate proportional withdrawal
        // Note: In production, you'd need to specify which currencies to withdraw
        // For now, this is a simplified version

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // This is a simplified implementation
        // In production, you'd track which currencies each depositor has
        // and withdraw proportionally

        emit Withdrawn(to, sharesToBurn, amount0, amount1);
    }

    /// @notice Get total value of deposits in Aave
    /// @dev Simplified - assumes both currencies have same value
    function _getTotalValue(
        Currency currency0,
        Currency currency1
    ) internal view returns (uint256) {
        uint256 total = 0;

        if (supportedCurrencies[currency0]) {
            IAToken aToken0 = aTokens[currency0];
            total += aToken0.balanceOf(address(this));
        }

        if (supportedCurrencies[currency1]) {
            IAToken aToken1 = aTokens[currency1];
            total += aToken1.balanceOf(address(this));
        }

        return total;
    }

    /// @notice Get aToken balance for a currency
    function getATokenBalance(
        Currency currency
    ) external view returns (uint256) {
        if (!supportedCurrencies[currency]) return 0;
        return aTokens[currency].balanceOf(address(this));
    }
}
