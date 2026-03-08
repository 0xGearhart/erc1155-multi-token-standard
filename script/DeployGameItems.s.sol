// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../src/GameItems.sol";
import {CodeConstants, HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployGameItems is Script, CodeConstants {
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    function run() public returns (GameItems) {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
        vm.startBroadcast(networkConfig.deployerAccount);
        GameItems gameItems = new GameItems(
            networkConfig.defaultAdmin,
            networkConfig.minter,
            networkConfig.uriSetter,
            networkConfig.burner,
            GAME_ITEMS_ADMIN_DELAY,
            GAME_ITEMS_URI
        );
        vm.stopBroadcast();

        return gameItems;
    }
}
