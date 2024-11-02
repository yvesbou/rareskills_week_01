// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts@4.9.0/token/ERC20/ERC20.sol";

/// @title An ERC20 token that can be used as payment token for the bonding contract
/// @author Yves
/// @notice Mints to the initial users each 100 tokens (denominated in 1e18)
/// @dev No further permissions
contract PaymentTokenERC20 is ERC20 {
    constructor(address[] memory beneficiaries) ERC20("PaymentToken", "PT") {
        uint256 countBeneficiaries = beneficiaries.length;
        for (uint256 index = 0; index < countBeneficiaries; index++) {
            _mint(beneficiaries[index], 100e18);
        }
    }
}
