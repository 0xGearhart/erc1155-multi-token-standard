// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {DeployGameItems} from "../../script/DeployGameItems.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {GameItems} from "../../src/GameItems.sol";
import {Handler} from "./Handeler.t.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console2} from "forge-std/Test.sol";

contract Invariants is StdInvariant, Test {}
