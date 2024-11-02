// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";
import {Ownable2Step} from "@openzeppelin/contracts@4.9.0/access/Ownable2Step.sol";

/// @title A contract that explores ERC777
/// @author Yves
/// @notice Owner allowed to mint, no further customisation
/// @dev no further detail
contract SimpleERC777 is ERC777, Ownable2Step {
    constructor(string memory name_, string memory symbol_, address[] memory defaultOperators_)
        ERC777(name_, symbol_, defaultOperators_)
    {}

    /// @notice Mint new tokens to the owner
    /// @dev make sure the owner is a contract satisfying the IERC777Recipient interface
    /// @dev See {IERC777-mint}.
    function mint(
        address beneficiary,
        uint256 amount_,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) external onlyOwner {
        _mint(beneficiary, amount_, userData, operatorData, requireReceptionAck);
    }
}
