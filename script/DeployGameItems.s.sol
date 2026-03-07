// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../src/GameItems.sol";
import {CodeConstants, HelperConfig} from "./HelperConfig.s.sol";
import {Script, console2} from "forge-std/Script.sol";

contract DeployGameItems is Script, CodeConstants {
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    function run() public {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
        vm.startBroadcast(networkConfig.account);
        new GameItems(msg.sender, msg.sender, msg.sender, msg.sender, GAME_ITEMS_ADMIN_DELAY, GAME_ITEMS_URI);
        vm.stopBroadcast();
    }
}
