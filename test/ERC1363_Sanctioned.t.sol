// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {ERC1363WithSanctions} from "../src/SanctionsToken.sol";
import {ERC1363CompatibleAccount} from "../src/ERC1363Account.sol";

/**
 *  - test basic erc1363
 *  - test a transfer between two users, ban one, try again ✅
 *  - transferFrom ban from, ban to ✅
 *  - transfer ban sender, ban to ✅
 */
contract SanctionsTokenTest is Test {
    // EOAs
    address owner = address(99);

    address user1 = address(101);
    address user2 = address(102);
    address user3 = address(103);

    ERC1363WithSanctions public sanctionsToken;
    ERC1363WithSanctions public evilToken; // for simplicity same token
    ERC1363CompatibleAccount public erc1363SmartAccount;

    function setUp() public {
        vm.startPrank(owner);
        sanctionsToken = new ERC1363WithSanctions("MyToken", "MT");
        erc1363SmartAccount = new ERC1363CompatibleAccount();
        sanctionsToken.mint(user1, 100e18);
        sanctionsToken.mint(user2, 100e18);
        sanctionsToken.mint(user3, 100e18);
        vm.stopPrank();

        vm.startPrank(user3);
        evilToken = new ERC1363WithSanctions("EvilToken", "ET");
        evilToken.mint(user3, 100e18);
        vm.stopPrank();

        vm.prank(owner); // wants to protect his account
        erc1363SmartAccount.addToTokenBlackList(address(evilToken));
    }

    function test_rejectedTransfer() public {
        vm.prank(user1);
        sanctionsToken.transfer(user2, 50e18);

        uint256 user1Balance = sanctionsToken.balanceOf(user1);
        uint256 user2Balance = sanctionsToken.balanceOf(user2);

        assertEq(user1Balance, 50e18);
        assertEq(user2Balance, 150e18);

        vm.prank(owner);
        sanctionsToken.addSanctioned(user1);

        vm.expectRevert();
        vm.prank(user1);
        sanctionsToken.transfer(user2, 50e18);

        vm.expectRevert();
        vm.prank(user2);
        sanctionsToken.transfer(user1, 50e18);

        // allow transfers again

        vm.prank(owner);
        sanctionsToken.removeSanctioned(user1);

        vm.prank(user2);
        sanctionsToken.transfer(user1, 50e18);

        user1Balance = sanctionsToken.balanceOf(user1);
        user2Balance = sanctionsToken.balanceOf(user2);

        assertEq(user1Balance, 100e18);
        assertEq(user2Balance, 100e18);
    }

    function test_rejectedTransferFrom() public {
        vm.prank(user1);
        sanctionsToken.approve(user2, 100e18);
        vm.prank(user2);
        sanctionsToken.transferFrom(user1, user2, 50e18);

        uint256 user1Balance = sanctionsToken.balanceOf(user1);
        uint256 user2Balance = sanctionsToken.balanceOf(user2);

        assertEq(user1Balance, 50e18);
        assertEq(user2Balance, 150e18);

        vm.prank(owner);
        sanctionsToken.addSanctioned(user1);

        vm.expectRevert();
        vm.prank(user1);
        sanctionsToken.transferFrom(user1, user2, 50e18);

        vm.expectRevert();
        vm.prank(user2);
        sanctionsToken.transferFrom(user1, user2, 50e18);
    }

    function test_receivingOnERC1363Compatible() public {
        vm.prank(user3);
        vm.expectRevert();
        // erc1363 smart account did blacklist evilToken
        // not going through
        evilToken.transferAndCall(address(erc1363SmartAccount), 100e18);

        vm.prank(user3);
        // can go through, if using erc20 transfer
        // DISCUSS
        evilToken.transfer(address(erc1363SmartAccount), 100e18);

        vm.prank(user2);
        sanctionsToken.transfer(address(erc1363SmartAccount), 100e18);
        uint256 smartAccountBalance = sanctionsToken.balanceOf(address(erc1363SmartAccount));
        assertEq(smartAccountBalance, 100e18);
    }

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/
}
