// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";
import {IERC20} from "@openzeppelin/contracts@4.9.0/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts@4.9.0/access/Ownable2Step.sol";

/// @title An ERC777 Token that has a bonding curve (x=y)
/// @author Yves
/// @notice Payment Token is an ERC20 contract
contract ERC777Bonding is ERC777, Ownable2Step {
    // _totalSupply
    IERC20 public paymentToken;

    // events
    event Bought(address indexed buyer, uint256 indexed paid, uint256 indexed supply);
    event Sold(address indexed seller, uint256 indexed received, uint256 indexed supply);

    // errors
    error NotLiquidEnough(uint256 price);
    error TransferringPaymentTokenFailed();

    constructor(string memory name_, string memory symbol_, address[] memory defaultOperators_, address paymentToken_)
        ERC777(name_, symbol_, defaultOperators_)
    {
        paymentToken = IERC20(paymentToken_);
    }

    /// @notice Buys Tokens from the BondingERC777 contract via a bonding curve
    /// @notice Requires the user to approve first (payment token is ERC20)
    /// @dev bonding curve x = y
    /// @param amount specifying the amount that the user wants to buy
    function buy(uint256 amount) external {
        // convert
        uint256 price = convert(amount, true);

        uint256 availableCustomerTokens = paymentToken.balanceOf(msg.sender);
        if (price > availableCustomerTokens) {
            // custom error
            // is this really needed to check twice
            revert NotLiquidEnough(price);
        }
        bool success = paymentToken.transferFrom(msg.sender, address(this), price);
        if (!success) {
            // revert
            revert TransferringPaymentTokenFailed();
        }
        // mint to the user
        _mint(msg.sender, amount, "", "", false); // can re-enter, but no danger

        emit Bought(msg.sender, price, amount);
    }

    /// @notice Sells Tokens back to the contract via a bonding curve
    /// @notice Requires the user to approve first (payment token is ERC20)
    /// @dev bonding curve x = y
    /// @param amount specifying the amount that the user wants to buy
    function sell(uint256 amount) external {
        // convert
        uint256 price = convert(amount, false);

        _burn(msg.sender, amount, "", ""); // can user re-enter with beforeTokenTransfer?

        bool success = paymentToken.transfer(msg.sender, price);
        if (!success) {
            // revert
            revert TransferringPaymentTokenFailed();
        }

        emit Sold(msg.sender, price, amount);
    }

    /// @notice Computes the bonding curve
    /// @dev Based on the requested amount, a price is calculated and returned
    /// @param amount the amount the user wants to buy/sell
    /// @param isGrowing whether the user buys(true)/sells(false) from the contract
    /// @return Documents the return variables of a contract’s function state variable
    function convert(uint256 amount, bool isGrowing) internal view returns (uint256) {
        uint256 precision = decimals();
        uint256 cachedTotalSupply = totalSupply();
        uint256 cachedPrice = cachedTotalSupply; // not reading from storage again
        uint256 newAmount = isGrowing ? cachedTotalSupply + amount : cachedTotalSupply - amount;
        uint256 newPrice = newAmount; // x = y
        if (isGrowing) {
            return (newPrice * newAmount - cachedPrice * cachedTotalSupply) / (2 * 10 ** precision);
        } else {
            return (cachedPrice * cachedTotalSupply - newPrice * newAmount) / (2 * 10 ** precision);
        }
    }
}
