// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../src/GameItems.sol";
import {CraftingShop} from "../src/CraftingShop.sol";
import {CodeConstants, HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";

contract DeployGameItems is Script, CodeConstants {
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function run() public returns (GameItems) {
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
        string memory gameItemsUri = vm.envOr("GAME_ITEMS_URI", GAME_ITEMS_URI);
        vm.startBroadcast(networkConfig.deployerAccount);
        gameItems = new GameItems(
            networkConfig.defaultAdmin,
            networkConfig.minter,
            networkConfig.uriSetter,
            networkConfig.burner,
            GAME_ITEMS_ADMIN_DELAY,
            gameItemsUri
        );
        craftingShop = new CraftingShop(networkConfig.defaultAdmin, gameItems);
        gameItems.grantRole(gameItems.MINTER_ROLE(), address(craftingShop));
        gameItems.grantRole(gameItems.BURNER_ROLE(), address(craftingShop));
        vm.stopBroadcast();

        return gameItems;
    }
}
