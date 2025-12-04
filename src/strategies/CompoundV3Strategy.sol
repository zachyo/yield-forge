// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IYieldForgeStrategy} from "../interfaces/IYieldForgeStrategy.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Compound V3 (Comet) interfaces
interface IComet {
    function supply(address asset, uint256 amount) external;

    function withdraw(address asset, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function baseToken() external view returns (address);
}

/// @title CompoundV3Strategy
/// @notice Strategy that deposits tokens into Compound V3 (Comet) to earn yield
/// @dev This strategy wraps deposits into Compound's lending markets
contract CompoundV3Strategy is IYieldForgeStrategy {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    // Compound V3 Comet address (e.g., USDC market on mainnet)
    IComet public immutable comet;

    // The base token for this Comet instance (e.g., USDC)
    address public immutable baseToken;

    // Track shares per depositor
    mapping(address => uint256) public shares;
    uint256 public totalShares;

    // Track supported currencies
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
    event CurrencyConfigured(Currency indexed currency);

    error UnsupportedCurrency();
    error InsufficientShares();
    error NativeTokenNotSupported();

    constructor(address _comet) {
        comet = IComet(_comet);
        baseToken = comet.baseToken();

        // Approve Comet to spend base token
        IERC20(baseToken).forceApprove(address(comet), type(uint256).max);
    }

    /// @notice Configure a currency to use with this strategy
    /// @param currency The currency to configure
    function configureCurrency(Currency currency) external {
        require(!currency.isAddressZero(), "Native token not supported");
        require(
            Currency.unwrap(currency) == baseToken,
            "Only base token supported"
        );

        supportedCurrencies[currency] = true;

        emit CurrencyConfigured(currency);
    }

    /// @notice Deposit tokens into Compound V3
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

        // Deposit currency0 to Compound
        if (amount0 > 0) {
            if (!supportedCurrencies[currency0]) revert UnsupportedCurrency();

            // Transfer tokens from sender
            IERC20(Currency.unwrap(currency0)).safeTransferFrom(
                msg.sender,
                address(this),
                amount0
            );

            // Supply to Compound
            comet.supply(Currency.unwrap(currency0), amount0);

            totalValue += amount0;
        }

        // Deposit currency1 to Compound
        if (amount1 > 0) {
            if (!supportedCurrencies[currency1]) revert UnsupportedCurrency();

            // Transfer tokens from sender
            IERC20(Currency.unwrap(currency1)).safeTransferFrom(
                msg.sender,
                address(this),
                amount1
            );

            // Supply to Compound
            comet.supply(Currency.unwrap(currency1), amount1);

            totalValue += amount1;
        }

        // Mint shares based on total value deposited
        uint256 newShares = totalValue;
        if (totalShares > 0) {
            // Calculate shares based on current pool value
            uint256 poolValue = comet.balanceOf(address(this));
            newShares = (totalValue * totalShares) / (poolValue - totalValue);
        }

        shares[msg.sender] += newShares;
        totalShares += newShares;

        emit Deposited(currency0, amount0, currency1, amount1, msg.sender);
    }

    /// @notice Withdraw tokens from Compound V3
    /// @param to Address to send withdrawn tokens
    /// @param sharesToBurn Amount of shares to burn
    /// @return amount0 Amount of first currency withdrawn
    /// @return amount1 Amount of second currency withdrawn
    function withdraw(
        address to,
        uint256 sharesToBurn
    ) external override returns (uint256 amount0, uint256 amount1) {
        if (shares[msg.sender] < sharesToBurn) revert InsufficientShares();

        // Calculate proportional amount to withdraw
        uint256 totalBalance = comet.balanceOf(address(this));
        uint256 withdrawAmount = (sharesToBurn * totalBalance) / totalShares;

        shares[msg.sender] -= sharesToBurn;
        totalShares -= sharesToBurn;

        // Withdraw from Compound
        comet.withdraw(baseToken, withdrawAmount);

        // Transfer to recipient
        IERC20(baseToken).safeTransfer(to, withdrawAmount);

        // For simplicity, return as amount0
        amount0 = withdrawAmount;
        amount1 = 0;

        emit Withdrawn(to, sharesToBurn, amount0, amount1);
    }

    /// @notice Get current balance in Compound
    function getBalance() external view returns (uint256) {
        return comet.balanceOf(address(this));
    }
}
