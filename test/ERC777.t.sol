// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount} from "../src/Accounts.sol";
import {MyERC777} from "../src/ERC777.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";
import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";

contract ERC777Test is Test {
    address owner = address(99);
    address user1 = address(101);
    address user2 = address(102);
    address user3 = address(103);

    MyERC777 public myToken;
    CompatibleSmartAccount public compatibleAccount;
    IncompatibleSmartAccount public incompatibleAccount;
    // not sure if I'm going to use this
    IERC1820Registry internal constant ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setUp() public {
        string memory mainnetRPCUrl = vm.envString("MAINNET_RPC_URL");

        // Fork mainnet
        vm.createSelectFork(mainnetRPCUrl);

        // Verify ERC1820Registry exists at the expected address
        require(address(ERC1820_REGISTRY).code.length > 0, "ERC1820Registry not found");

        // owner
        vm.startPrank(owner);
        // address 99 is owner of a smart account and the erc777
        compatibleAccount = new CompatibleSmartAccount();
        address[] memory defaultOperators = new address[](0);
        myToken = new MyERC777("MyTokenName", "MTN", defaultOperators);
        vm.stopPrank();
        // someone else
        vm.prank(user1);
        incompatibleAccount = new IncompatibleSmartAccount();
    }

    function test_mint() public {
        uint256 amountToBeMinted = 100 * 1e18;
        bytes memory userData = "";
        bytes memory oepratorData = "";
        vm.prank(owner);
        myToken.mint(amountToBeMinted, userData, oepratorData, false);
        uint256 ownerBalance = myToken.balanceOf(owner);
        uint256 totalSupply = myToken.totalSupply();

        assertEq(ownerBalance, amountToBeMinted);
        assertEq(totalSupply, amountToBeMinted);
    }

    /**
     * todo
     * - test operator
     * - test erc20
     * - test minting
     */
}
