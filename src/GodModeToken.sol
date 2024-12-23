// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC1363} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC1363.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable2Step.sol";
import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";

/// @title A contract that explores ERC777
/// @author Yves
/// @notice Owner allowed to mint, no further customisation
/// @dev no further detail
contract ERC1363WithGodmode is ERC1363, Ownable2Step {
    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {}

    /// @notice This allows the owner to move tokens between users at free will
    /// @dev Direct use of _update function without any approval checks
    /// @param from if 0-address it's equal to a mint
    function godMode(address from, address to, uint256 value) public onlyOwner {
        _update(from, to, value);
    }

    /// @notice Mint new tokens to the owner
    /// @dev make sure the owner is a contract satisfying the IERC777Recipient interface
    /// @dev See {IERC777-mint}.
    function mint(address beneficiary, uint256 amount_) external onlyOwner {
        _mint(beneficiary, amount_);
    }
}
