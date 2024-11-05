// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC1363} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC1363.sol";
import {IERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable2Step.sol";

/// @title A contract that explores ERC777
/// @author Yves
/// @notice Owner allowed to mint, no further customisation
/// @dev no further detail
contract ERC1363WithSanctions is ERC1363, Ownable2Step {
    mapping(address => bool) public sanctioned;

    error Sanctioned();

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {}

    /// @notice Mint new tokens to the owner
    /// @dev make sure the owner is a contract satisfying the IERC777Recipient interface
    /// @dev See {IERC777-mint}.
    function mint(address beneficiary, uint256 amount_) external onlyOwner {
        _mint(beneficiary, amount_);
    }

    /// @notice Transfers amount "value" tokens from "msg.sender" to "to"
    /// @dev This function is overriding transferFrom
    /// @dev after a check if whether sender or recipient are sanctioned
    /// @dev call the standard transferFrom after sanction check
    /// @inheritdoc	IERC20
    function transfer(address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        // sanctions
        if (sanctioned[msg.sender] || sanctioned[to]) revert Sanctioned();
        super.transfer(to, value);
    }

    /// @notice Transfers amount "value" tokens from "from" to "to"
    /// @dev This function is overriding transferFrom
    /// @dev after a check if whether sender or recipient are sanctioned
    /// @dev call the standard transferFrom after sanction check
    /// @inheritdoc	IERC20
    function transferFrom(address from, address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        // sanctions
        if (sanctioned[from] || sanctioned[to]) revert Sanctioned();
        super.transferFrom(from, to, value);
    }

    /// @notice add a user to the sanctioned list
    /// @dev Only callable by the owner
    /// @param sanctionedUser user that is prohibited to send or receive tokens
    function addSanctioned(address sanctionedUser) public onlyOwner {
        sanctioned[sanctionedUser] = true;
    }

    /// @notice remove a user from the sanctioned list
    /// @dev Only callable by the owner
    /// @param sanctionedUser user that is prohibited to send or receive tokens
    function removeSanctioned(address sanctionedUser) public onlyOwner {
        sanctioned[sanctionedUser] = false;
    }
}
