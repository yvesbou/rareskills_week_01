// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Sender.sol";

/// @title An ERC777 Bank that demonstrates ERC777 re-entrancy vulnerability
/// @author Yves
/// @notice Savings Token is an ERC777 contract
contract ERC777Bank is IERC777Recipient, IERC777Sender {
    IERC777 public savingsToken;
    mapping(address accountHolder => uint256 amount) accountBalances;

    // events
    event Deposited(address indexed saver, uint256 indexed amount);
    event Withdrawn(address indexed saver, uint256 indexed amount);

    // errors
    error NotLiquidEnough(uint256 price);
    error TransferringPaymentTokenFailed();

    constructor(string memory name_, string memory symbol_, address[] memory defaultOperators_, address savingsToken_) {
        savingsToken = IERC777(savingsToken_);
    }

    /// @notice User can deposit ERC777 into this bank in his/her account
    /// @notice user can send ERC777 directly to this contract (uses IERC777Recipient)
    /// @notice user can give Bank operator rights can then call this function
    /// @dev uses `ERC777.operatorSend`
    /// @dev requires ERC777.isOperatorFor(address(this), msg.sender) to be true
    /// @param amount specifying the amount that the user wants to deposit
    function deposit(uint256 amount) external {
        //
    }

    /// @notice Sells Tokens back to the contract via a bonding curve
    /// @notice Requires the user to approve first (payment token is ERC20)
    /// @dev bonding curve x = y
    /// @param amount specifying the amount that the user wants to buy
    function withdraw(uint256 amount) external {
        // send erc777 tokens to user

        // change internal balance (accountBalances)
    }
}
