// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {ERC1363WithGodmode} from "../src/GodModeToken.sol";
import {ERC1363CompatibleAccount} from "../src/ERC1363Account.sol";

/**
 *  - test basic erc1363
 *  - test a transfer between two users, ban one, try again ✅
 *  - transferFrom ban from, ban to ✅
 *  - transfer ban sender, ban to ✅
 */
contract godModeTokenTest is Test {
    // EOAs
    address owner = address(99);

    address user1 = address(101);
    address user2 = address(102);
    address user3 = address(103);

    ERC1363WithGodmode public godModeToken;
    ERC1363CompatibleAccount public erc1363SmartAccount;

    function setUp() public {
        vm.startPrank(owner);
        godModeToken = new ERC1363WithGodmode("MyToken", "MT");
        erc1363SmartAccount = new ERC1363CompatibleAccount();
        godModeToken.mint(user1, 100e18);
        godModeToken.mint(user2, 100e18);
        godModeToken.mint(user3, 100e18);
        vm.stopPrank();
    }

    function test_godMode() public {
        // check on-chain balance of user1 and user2
        uint256 user1Balance = godModeToken.balanceOf(user1);
        uint256 user2Balance = godModeToken.balanceOf(user2);
        assertEq(user1Balance, 100e18);
        assertEq(user2Balance, 100e18);
        // do a godmode transfer between the two
        vm.prank(owner);
        godModeToken.godMode(user1, user2, 100e18);
        // check on-chain balance again
        user1Balance = godModeToken.balanceOf(user1);
        user2Balance = godModeToken.balanceOf(user2);
    }

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/
}
