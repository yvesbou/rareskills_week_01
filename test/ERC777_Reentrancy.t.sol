// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std-1.9.2/src/Test.sol";
import {CompatibleSmartAccount, IncompatibleSmartAccount, CompatibleSmartAccountWithHooks} from "../src/Accounts.sol";
import {SimpleERC777} from "../src/SimpleERC777.sol";
import {IERC1820Registry} from "@openzeppelin/contracts@4.9.0/utils/introspection/IERC1820Registry.sol";
import {ERC777} from "@openzeppelin/contracts@4.9.0/token/ERC777/ERC777.sol";

/**
 * - create savings token (MyERC777)
 * - create bank account
 * - let multiple owners save
 * - exploit
 */
