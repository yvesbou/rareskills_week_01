// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount} from "../src/Accounts.sol";
import {MyERC777} from "../src/ERC777.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";
import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";

contract ERC777Test is Test {
    // EOAs
    address owner = address(99);
    address user1 = address(101);
    address user2 = address(102);
    address user3 = address(103);

    MyERC777 public myToken;

    // Smart Accounts
    CompatibleSmartAccount public compatibleAccount;
    IncompatibleSmartAccount public incompatibleAccount;

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

        // erc1820 related
        registerOwnRecipient(address(compatibleAccount));
    }

    function test_mint() public {
        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 ownerBalance = myToken.balanceOf(owner);
        uint256 totalSupply = myToken.totalSupply();

        assertEq(ownerBalance, amountToBeMinted);
        assertEq(totalSupply, amountToBeMinted);
    }

    function test_sendToEOA() public {
        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 amountForBeneficiary = 1e18;
        address addrBeneficiary = user1;
        bytes memory data = "";
        vm.prank(owner);
        myToken.send(addrBeneficiary, amountForBeneficiary, data);

        uint256 compatibleAccountBalance = myToken.balanceOf(addrBeneficiary);

        assertEq(compatibleAccountBalance, amountForBeneficiary);
    }

    function test_sendToCorrectImplementor() public {
        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 amountForBeneficiary = 1e18;
        address addrBeneficiary = address(compatibleAccount);
        bytes memory data = "";
        vm.prank(owner);
        myToken.send(addrBeneficiary, amountForBeneficiary, data);

        uint256 compatibleAccountBalance = myToken.balanceOf(addrBeneficiary);

        assertEq(compatibleAccountBalance, amountForBeneficiary);
    }

    function test_tryToSendToCorrectImplementorNot1820Registered() public {
        vm.prank(user3);
        CompatibleSmartAccount compatibleAccountNotRegisted = new CompatibleSmartAccount();

        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 amountForBeneficiary = 1e18;
        address addrBeneficiary = address(compatibleAccountNotRegisted);
        bytes memory data = "";
        vm.prank(owner); // owner trying to send to not registered compatible account
        vm.expectRevert("ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        myToken.send(addrBeneficiary, amountForBeneficiary, data);
    }

    /**
     * todo
     * - test operator
     * - test erc20
     * - test minting
     */

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/
    function mintForOwner(uint256 amount) public {
        bytes memory userData = "";
        bytes memory oepratorData = "";
        vm.prank(owner);
        myToken.mint(owner, amount, userData, oepratorData, false);
    }

    function registerOwnRecipient(address user) public {
        vm.prank(user);
        ERC1820_REGISTRY.setInterfaceImplementer(user, TOKENS_RECIPIENT_INTERFACE_HASH, user);
    }
}
