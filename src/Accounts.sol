// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC777Recipient} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Sender.sol";

contract CompatibleSmartAccount is IERC777Recipient, IERC777Sender {
    /// @notice conforming to standard
    /// @dev do nothing
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        // if a revert is included receiving the token is disabled
        // but with mint?
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {}
}

contract IncompatibleSmartAccount {
    constructor() {}
}
