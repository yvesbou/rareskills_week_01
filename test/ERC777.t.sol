// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount, CompatibleSmartAccountWithHooks} from "../src/Accounts.sol";
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

        vm.prank(user2);
        // make user3 recipient of donations
        compatibleAccountWithHooks = new CompatibleSmartAccountWithHooks(user3, address(myToken));
        // erc1820 related
        registerOwnRecipient(address(compatibleAccount));
        registerOwnRecipient(address(compatibleAccountWithHooks));
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

    function test_sendToCorrectImplementorWithHook() public {
        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 amountForBeneficiary = 1e18;
        address addrBeneficiary = address(compatibleAccountWithHooks);
        bytes memory data = "";
        vm.prank(owner);
        myToken.send(addrBeneficiary, amountForBeneficiary, data);

        uint256 compatibleAccountBalance = myToken.balanceOf(addrBeneficiary);
        uint256 balanceDonationReceiver = myToken.balanceOf(user3); // receiver of donation

        uint256 remainingAfterDonation = 99 * amountForBeneficiary / 100;
        uint256 amountForDonationReceiver = amountForBeneficiary - remainingAfterDonation;
        assertEq(compatibleAccountBalance, remainingAfterDonation);
        assertEq(balanceDonationReceiver, amountForDonationReceiver);
    }

    function test_tryToSendToCorrectImplementorNot1820Registered() public {
        vm.prank(user3);
        CompatibleSmartAccount compatibleAccountNotRegisted = new CompatibleSmartAccount();

        uint256 amountToBeMinted = 100 * 1e18;
        mintForOwner(amountToBeMinted);

        uint256 amountForBeneficiary = 1e18;
        address addrBeneficiary = address(compatibleAccountNotRegisted);
        bytes memory data = "";
        vm.prank(owner); // owner trying to send to *un*registered compatible account
        vm.expectRevert("ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        myToken.send(addrBeneficiary, amountForBeneficiary, data);
    }

    // it is possible to mint to incompatible, if the mint function is set up this way
    function test_mintToIncompatible() public {
        bytes memory userData = "";
        bytes memory operatorData = "";
        address addrIncompatible = address(incompatibleAccount);
        uint256 amount = 2e18;
        vm.prank(owner);
        myToken.mint(addrIncompatible, amount, userData, operatorData, false);
    }

    function test_operatorWithEOA() public {
        uint256 amount = 1000e18;

        mintForUser(user2, amount);
        // authorize operator
        vm.prank(user2);
        myToken.authorizeOperator(user3);

        // operator sends somewhere
        bytes memory data = "";
        bytes memory operatorData = "";
        uint256 halfAmount = amount / 2;
        vm.prank(user3, user3); // user3 is the operator and thus needs to be msg.sender
        myToken.operatorSend(user2, user3, halfAmount, data, operatorData);
        // 50% with transferFrom and 50% with operatorSend

        // operator and allowance concepts are orthogonal: operators cannot
        // call `transferFrom` (unless they have allowance)
        vm.prank(user3, user3); // being operator not equal to allowance
        vm.expectRevert("ERC777: insufficient allowance");
        myToken.transferFrom(user2, user3, halfAmount);

        // try operatorBurn
        vm.prank(user3, user3); // user3 is the operator and thus needs to be msg.sender
        myToken.operatorBurn(user2, halfAmount, data, operatorData);

        uint256 endBalance = myToken.balanceOf(user2);
        assertEq(endBalance, 0);
    }

    /*════════════════════════════════════════════════════════════*\
    ║                                                            ║
    ║                     HELPER FUNCTIONS                       ║
    ║                                                            ║
    \*════════════════════════════════════════════════════════════*/
    function mintForOwner(uint256 amount) public {
        bytes memory userData = "";
        bytes memory operatorData = "";
        vm.prank(owner);
        myToken.mint(owner, amount, userData, operatorData, false);
    }

    function mintForUser(address user, uint256 amount) public {
        bytes memory userData = "";
        bytes memory operatorData = "";
        vm.prank(owner);
        myToken.mint(user, amount, userData, operatorData, false);
    }

    // assume smart accounts can call this function themselves (ie prank)
    function registerOwnRecipient(address user) public {
        vm.prank(user);
        ERC1820_REGISTRY.setInterfaceImplementer(user, TOKENS_RECIPIENT_INTERFACE_HASH, user);
    }
}
