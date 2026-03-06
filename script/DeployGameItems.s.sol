// SPDX-License-Identifier: MIT

import {GameItems} from "../src/GameItems.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script, console2} from "forge-std/Script.sol";

pragma solidity 0.8.33;

contract DeployGameItems is Script {
    function run() public {
        vm.startBroadcast();
        new GameItems(msg.sender, msg.sender);
        vm.stopBroadcast();
    }
}
