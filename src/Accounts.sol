// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC777Recipient} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Recipient.sol";
import {IERC777Sender} from "@openzeppelin/contracts@4.9.0/token/ERC777/IERC777Sender.sol";
import {IERC20} from "@openzeppelin/contracts@4.9.0/token/ERC20/ERC20.sol";

/// @title A smart account that adheres to ERC777
/// @author Yves
/// @dev The contract does implement IERC777Recipient, IERC777Sender
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

    /// @notice conforming to standard
    /// @dev do nothing
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        /**
         * potential ideas
         *      - only whitelisted addresses
         *      - pay tax
         *      - save to another account
         */
    }
}

contract CompatibleSmartAccountWithHooks is IERC777Recipient, IERC777Sender {
    address public donatingBeneficiary;
    IERC20 public token; // showing backward compatibility

    constructor(address bene, address token_) {
        donatingBeneficiary = bene;
        token = IERC20(token_);
    }

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
        // un-used
        operator;
        from;
        to;
        userData;
        operatorData;
        // neglect if the recipient implements erc777recipient
        // donate 1% of every receiving amount, to immutable beneficiary
        if (amount > 100) {
            uint256 donatingAmount = amount / 100;
            token.transfer(donatingBeneficiary, donatingAmount);
        }
    }

    /// @notice conforming to standard
    /// @dev do nothing
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {}
}

/// @title A smart account that doesnt adhere to ERC777
/// @author Yves
/// @dev The contract doesnt implement IERC777Recipient, IERC777Sender
contract IncompatibleSmartAccount {
    constructor() {}
}
