// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount, CompatibleSmartAccountWithHooks} from "../src/Accounts.sol";
import {ERC777Bonding} from "../src/ERC777Bonding.sol";
import {PaymentTokenERC20} from "../src/PaymentTokenERC20.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";
import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";
import {IERC20} from "@openzeppelin/contracts@4.9.0/token/ERC20/IERC20.sol";

contract ERC777Test is Test {
    // EOAs
    address owner = address(99);
    address user1 = address(101);
    address user2 = address(102);
    address user3 = address(103);

    ERC777Bonding public bondingToken;
    PaymentTokenERC20 public paymentTokenERC20;

    // Smart Accounts
    CompatibleSmartAccount public compatibleAccount;
    IncompatibleSmartAccount public incompatibleAccount;
    CompatibleSmartAccountWithHooks public compatibleAccountWithHooks;

    // ERC1820
    IERC1820Registry internal constant ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    // interface hashes
    bytes32 public constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 public constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    function setUp() public {
        string memory mainnetRPCUrl = vm.envString("MAINNET_RPC_URL");

        // Fork mainnet
        vm.createSelectFork(mainnetRPCUrl);

        // Verify ERC1820Registry exists at the expected address
        require(address(ERC1820_REGISTRY).code.length > 0, "ERC1820Registry not found");

        address[] memory benefeciaries = new address[](3);
        benefeciaries[0] = user1;
        benefeciaries[1] = user2;
        benefeciaries[2] = user3;
        benefeciaries[3] = owner;

        paymentTokenERC20 = new PaymentTokenERC20(benefeciaries);

        // owner
        vm.startPrank(owner);
        // address 99 is owner of a smart account and the erc777
        compatibleAccount = new CompatibleSmartAccount();
        address[] memory defaultOperators = new address[](0);
        bondingToken = new ERC777Bonding("BondingToken", "BT", defaultOperators, address(paymentTokenERC20));
        vm.stopPrank();
        // someone else
        vm.prank(user1);
        incompatibleAccount = new IncompatibleSmartAccount();

        vm.prank(user2);
        // make user3 recipient of donations
        compatibleAccountWithHooks = new CompatibleSmartAccountWithHooks(user3, address(bondingToken));
        // erc1820 related
        registerOwnRecipient(address(compatibleAccount));
        registerOwnRecipient(address(compatibleAccountWithHooks));
    }

    function test_buyBonding() public {
        vm.startPrank(user1); // owns 100 payment tokens
        paymentTokenERC20.approve(address(bondingToken), 100e18); // allowance needed
        bondingToken.buy(10e18); // buy 10 tokens, pay 50
            // check if the user has 50 payment tokens
            // check if the user has received 10 bonding token
    }

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/

    // assume smart accounts can call this function themselves (ie prank)
    function registerOwnRecipient(address user) public {
        vm.prank(user);
        ERC1820_REGISTRY.setInterfaceImplementer(user, TOKENS_RECIPIENT_INTERFACE_HASH, user);
    }
}
