// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {DeployGameItems} from "../../script/DeployGameItems.s.sol";
import {CodeConstants, HelperConfig} from "../../script/HelperConfig.s.sol";
import {GameItems} from "../../src/GameItems.sol";
import {Test} from "forge-std/Test.sol";

contract DeployGameItemsTest_local is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testRunDeploysContractWithConfiguredInitialization() external view {
        assertEq(block.chainid, LOCAL_CHAIN_ID);
        assertTrue(address(gameItems) != address(0));

        assertEq(networkConfig.deployerAccount, ANVIL_DEFAULT_ACCOUNT);
        assertEq(networkConfig.defaultAdmin, ANVIL_DEFAULT_ACCOUNT);
        assertEq(networkConfig.minter, ANVIL_DEFAULT_ACCOUNT);
        assertEq(networkConfig.uriSetter, ANVIL_DEFAULT_ACCOUNT);
        assertEq(networkConfig.burner, ANVIL_DEFAULT_ACCOUNT);

        assertEq(gameItems.defaultAdmin(), ANVIL_DEFAULT_ACCOUNT);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
        assertTrue(gameItems.hasRole(gameItems.DEFAULT_ADMIN_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.URI_SETTER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
    }
}

contract DeployGameItemsTest_ethMainnet is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, ETH_MAINNET_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_ethSepolia is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("ETH_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, ETH_SEPOLIA_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_arbMainnet is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("ARB_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, ARB_MAINNET_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_arbSepolia is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("ARB_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, ARB_SEPOLIA_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_baseMainnet is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, BASE_MAINNET_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_baseSepolia is Test, CodeConstants {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASE_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        helperConfig = new HelperConfig();
        networkConfig = helperConfig.getNetworkConfig();
    }

    function testForkDeploymentUsesConfiguredState() external view {
        address expected = vm.envAddress("DEFAULT_KEY_ADDRESS");
        assertEq(block.chainid, BASE_SEPOLIA_CHAIN_ID);
        assertEq(networkConfig.deployerAccount, expected);
        assertEq(networkConfig.defaultAdmin, expected);
        assertEq(networkConfig.minter, expected);
        assertEq(networkConfig.uriSetter, expected);
        assertEq(networkConfig.burner, expected);
        assertEq(gameItems.defaultAdmin(), expected);
        assertEq(gameItems.defaultAdminDelay(), GAME_ITEMS_ADMIN_DELAY);
        assertEq(gameItems.uri(0), GAME_ITEMS_URI);
    }
}

contract DeployGameItemsTest_unsupportedChain is Test, CodeConstants {
    DeployGameItems public deployer;

    function setUp() external {
        vm.createSelectFork(vm.envString("LINEA_SEPOLIA_RPC_URL"));
    }

    function testDeploymentFailsForUnsupportedChain() external {
        deployer = new DeployGameItems();
        vm.expectRevert(abi.encodeWithSelector(HelperConfig.HelperConfig__InvalidNetwork.selector, block.chainid));
        deployer.run();
    }
}
