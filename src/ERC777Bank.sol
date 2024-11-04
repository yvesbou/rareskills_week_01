// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Sender.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";

/// @title An ERC777 Bank that demonstrates ERC777 re-entrancy vulnerability
/// @author Yves
/// @notice Savings Token is an ERC777 contract
/// @notice user can send ERC777 directly to this contract (uses IERC777Recipient)
/// or user can use the function deposit which is exposed by this contract.
contract ERC777Bank is IERC777Recipient, IERC777Sender {
    IERC1820Registry internal constant ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    IERC777 public savingsToken;

    mapping(address accountHolder => uint256 amount) public accountBalances;

    // events
    event Deposited(address indexed saver, uint256 indexed amount);
    event Withdrawn(address indexed saver, uint256 indexed amount);

    // errors
    error NotEnoughSavings(uint256 savings, uint256 request);
    error TokenReferenceAlreadySet();

    constructor() {
        ERC1820_REGISTRY.setInterfaceImplementer(address(0), keccak256("ERC777TokensRecipient"), address(this));
    }

    function setSavingsToken(address savingsToken_) external {
        if (address(savingsToken) != address(0)) revert TokenReferenceAlreadySet();
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
    /// @param recipient specifying the receiver of the withdrawn amount
    function withdraw(address recipient) external {
        bytes memory data = "";
        uint256 amount = accountBalances[msg.sender];

        // send erc777 tokens to user
        savingsToken.send(recipient, amount, data);

        // change internal balance (accountBalances)
        accountBalances[msg.sender] = 0;
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

        // emit event
        emit Deposited(from, amount);
    }
}
