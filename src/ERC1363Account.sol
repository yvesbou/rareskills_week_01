// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC1363Receiver} from "@openzeppelin/contracts@5.1.0/interfaces/IERC1363Receiver.sol";
import {IERC1363Spender} from "@openzeppelin/contracts@5.1.0/interfaces/IERC1363Spender.sol";
import {IERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/IERC20.sol";

/// @title ERC1363CompatibleAccount that filters approvals and receiving tokens
/// @author Yves
/// @notice Improves UX by allowing to call code before receiving allowance or receiving tokens
/// @dev TODO: Contract requires a way to use the tokens (currently they are stuck)
contract ERC1363CompatibleAccount is IERC1363Receiver, IERC1363Spender {
    mapping(address user => bool listed) isUserBlacklisted;
    mapping(address token => bool listed) isTokenBlacklisted;

    error RejectApproval(address user);
    error RejectToken(address token);

    constructor() {}

    // TODO Protect with ownable
    function addToUserBlackList(address user_) public {
        isUserBlacklisted[user_] = true;
    }

    // TODO Protect with ownable
    function addToTokenBlackList(address token_) public {
        isUserBlacklisted[token_] = true;
    }

    /// @notice Whenever ERC-1363 tokens are transferred to this contract via `transferAndCall`
    /// or `transferFromAndCall` by `operator` from `from`, this function is called.
    /// @inheritdoc	IERC1363Receiver
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        returns (bytes4)
    {
        // The ERC-1363 contract is always the caller.
        address token = msg.sender;
        if (isTokenBlacklisted[token]) revert RejectToken(token);

        // do stuff with the token, e.g put it somewhere
        token;

        this.onTransferReceived.selector; // accept the transaction
    }

    /// @notice Whenever an ERC-1363 token `owner` approves this contract via `approveAndCall`
    /// to spend their tokens, this function is called.
    /// @inheritdoc	IERC1363Spender
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4) {
        // The ERC-1363 contract is always the caller.
        address token = msg.sender;
        if (isUserBlacklisted[owner]) revert RejectApproval(owner);

        // do stuff

        // e.g directly take the tokens in the same tx
        IERC20(token).transferFrom(owner, address(this), value);

        this.onApprovalReceived.selector; // accept the approval
    }
}
