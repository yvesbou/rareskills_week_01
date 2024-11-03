// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Sender.sol";

/// @title An ERC777 Bank that demonstrates ERC777 re-entrancy vulnerability
/// @author Yves
/// @notice Savings Token is an ERC777 contract
/// @notice user can send ERC777 directly to this contract (uses IERC777Recipient)
/// or user can use the function deposit which is exposed by this contract.
contract ERC777Bank is IERC777Recipient, IERC777Sender {
    IERC777 public savingsToken;
    address[] public holders; // allows exploiter to look up other bank accounts
    uint256 public numClients;
    mapping(address accountHolder => uint256 amount) accountBalances;

    // events
    event Deposited(address indexed saver, uint256 indexed amount);
    event Withdrawn(address indexed saver, uint256 indexed amount);

    // errors
    error NotLiquidEnough(uint256 price);
    error TransferringPaymentTokenFailed();

    constructor(address savingsToken_) {
        savingsToken = IERC777(savingsToken_);
    }

    /// @notice User can deposit ERC777 into this bank in his/her account
    /// @notice user can give Bank operator rights can then call this function
    /// @dev uses `ERC777.operatorSend`
    /// @dev requires ERC777.isOperatorFor(address(this), msg.sender) to be true
    /// @param amount specifying the amount that the user wants to deposit
    function deposit(uint256 amount) external {
        bytes memory data = "";
        bytes memory operatorData = "";
        // this will trigger tokensReceived as well
        savingsToken.operatorSend(msg.sender, address(this), amount, data, operatorData);
    }

    /// @notice Required for IERC777-Recipient
    /// @inheritdoc	IERC777Recipient
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        // do I need sanity checks?
        // checks for userData?
        // how does it react on other erc777 tokens?
        // if a revert is included receiving the token is disabled
        // but with mint?
        _deposit(from, amount);
    }

    /// @notice Allows users to get back their deposit
    /// @dev token transfer before state change to introduce re-entrancy
    /// @param amount specifying the amount that the user wants to withdraw
    function withdraw(address recipient, uint256 amount) external {
        bytes memory data = "";
        // send erc777 tokens to user
        savingsToken.send(recipient, amount, data);
        // change internal balance (accountBalances)
        accountBalances[recipient] -= amount; // no vulnerability if msg.sender
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        // would be safer if the accountBalances update was here before token transfer
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param from the owner of the deposit
    /// @param amount the amount of the deposit
    function _deposit(address from, uint256 amount) internal {
        // increase internal balance
        accountBalances[from] += amount;
        holders.push(from);
        // emit event
        emit Deposited(from, amount);
    }
}
