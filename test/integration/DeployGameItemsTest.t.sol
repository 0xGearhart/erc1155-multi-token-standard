// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {DeployGameItems} from "../../script/DeployGameItems.s.sol";
import {CodeConstants, HelperConfig} from "../../script/HelperConfig.s.sol";
import {CraftingShop} from "../../src/CraftingShop.sol";
import {GameItems} from "../../src/GameItems.sol";
import {Test} from "forge-std/Test.sol";

contract DeployGameItemsTestBase is Test, CodeConstants {
    function _expectedUri() internal view returns (string memory) {
        return vm.envOr("GAME_ITEMS_URI", GAME_ITEMS_URI);
    }

    function _assertUriTemplate(string memory uri) internal pure {
        assertTrue(bytes(uri).length > 0, "uri should not be empty");
        assertTrue(_contains(uri, "{id}.json"), "uri must include {id}.json");
    }

    function _contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0 || n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool match_ = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) return true;
        }
        return false;
    }
}

contract DeployGameItemsTest_local is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.DEFAULT_ADMIN_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.URI_SETTER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), ANVIL_DEFAULT_ACCOUNT));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }

    function testGetOrCreateLocalConfigCanBeCalledDirectly() external {
        HelperConfig.NetworkConfig memory first = helperConfig._getOrCreateLocalConfig();
        HelperConfig.NetworkConfig memory second = helperConfig._getOrCreateLocalConfig();

        assertEq(first.deployerAccount, ANVIL_DEFAULT_ACCOUNT);
        assertEq(first.defaultAdmin, ANVIL_DEFAULT_ACCOUNT);
        assertEq(first.minter, ANVIL_DEFAULT_ACCOUNT);
        assertEq(first.uriSetter, ANVIL_DEFAULT_ACCOUNT);
        assertEq(first.burner, ANVIL_DEFAULT_ACCOUNT);

        assertEq(second.deployerAccount, first.deployerAccount);
        assertEq(second.defaultAdmin, first.defaultAdmin);
        assertEq(second.minter, first.minter);
        assertEq(second.uriSetter, first.uriSetter);
        assertEq(second.burner, first.burner);
    }

    function testCraftingShopCanCraftEndToEnd() external {
        uint256[] memory inputIds = new uint256[](2);
        inputIds[0] = 1;
        inputIds[1] = 2;
        uint256[] memory inputAmounts = new uint256[](2);
        inputAmounts[0] = 2;
        inputAmounts[1] = 1;

        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 99, 1, true);

        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        gameItems.mint(ANVIL_DEFAULT_ACCOUNT, 1, 10, "");
        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        gameItems.mint(ANVIL_DEFAULT_ACCOUNT, 2, 5, "");

        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        gameItems.setApprovalForAll(address(craftingShop), true);
        vm.prank(ANVIL_DEFAULT_ACCOUNT);
        craftingShop.craft(1, 3);

        assertEq(gameItems.balanceOf(ANVIL_DEFAULT_ACCOUNT, 1), 4);
        assertEq(gameItems.balanceOf(ANVIL_DEFAULT_ACCOUNT, 2), 2);
        assertEq(gameItems.balanceOf(ANVIL_DEFAULT_ACCOUNT, 99), 3);
        assertEq(gameItems.balanceOf(address(craftingShop), 1), 0);
        assertEq(gameItems.balanceOf(address(craftingShop), 2), 0);
    }
}

contract DeployGameItemsTest_ethMainnet is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("ETH_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_ethSepolia is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("ETH_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_arbMainnet is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("ARB_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_arbSepolia is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("ARB_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_baseMainnet is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASE_MAINNET_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_baseSepolia is DeployGameItemsTestBase {
    DeployGameItems public deployer;
    HelperConfig public helperConfig;
    HelperConfig.NetworkConfig public networkConfig;
    GameItems public gameItems;
    CraftingShop public craftingShop;

    function setUp() external {
        vm.createSelectFork(vm.envString("BASE_SEPOLIA_RPC_URL"));
        deployer = new DeployGameItems();
        gameItems = deployer.run();
        craftingShop = deployer.craftingShop();
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
        assertEq(gameItems.uri(0), _expectedUri());
        _assertUriTemplate(gameItems.uri(0));
        assertTrue(address(craftingShop) != address(0));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), address(craftingShop)));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), address(craftingShop)));
    }
}

contract DeployGameItemsTest_unsupportedChain is DeployGameItemsTestBase {
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
