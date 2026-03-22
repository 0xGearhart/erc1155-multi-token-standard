// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {CraftingShop} from "../../src/CraftingShop.sol";
import {GameItems} from "../../src/GameItems.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Test} from "forge-std/Test.sol";

contract CraftingShopTest is Test {
    GameItems internal gameItems;
    CraftingShop internal craftingShop;

    address internal defaultAdmin = makeAddr("defaultAdmin");
    address internal minter = makeAddr("minter");
    address internal uriSetter = makeAddr("uriSetter");
    address internal burner = makeAddr("burner");
    address internal user = makeAddr("user");

    uint48 internal constant INITIAL_DELAY = 1;
    string internal constant INITIAL_URI = "ipfs://mock/{id}.json";

    event RecipeSet(uint256 indexed recipeId, uint256 outputId, uint256 outputAmount, bool enabled);
    event RecipeStatusUpdated(uint256 indexed recipeId, bool enabled);
    event Crafted(address indexed account, uint256 indexed recipeId, uint256 times, uint256 outputId, uint256 outputAmount);

    function setUp() public {
        gameItems = new GameItems(defaultAdmin, minter, uriSetter, burner, INITIAL_DELAY, INITIAL_URI);
        craftingShop = new CraftingShop(defaultAdmin, gameItems);

        vm.startPrank(defaultAdmin);
        gameItems.grantRole(gameItems.MINTER_ROLE(), address(craftingShop));
        gameItems.grantRole(gameItems.BURNER_ROLE(), address(craftingShop));
        vm.stopPrank();
    }

    function testConstructorSetsRolesAndGameItemsReference() public view {
        assertEq(address(craftingShop.GAME_ITEMS()), address(gameItems));
        assertTrue(craftingShop.hasRole(craftingShop.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(craftingShop.hasRole(craftingShop.RECIPE_ADMIN_ROLE(), defaultAdmin));
    }

    function testConstructorRevertsOnZeroGameItemsAddress() public {
        vm.expectRevert(CraftingShop.CraftingShop__InvalidGameItemsAddress.selector);
        new CraftingShop(defaultAdmin, GameItems(address(0)));
    }

    function testSetRecipeRevertsForNonRecipeAdmin() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 2;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, craftingShop.RECIPE_ADMIN_ROLE()
            )
        );
        vm.prank(user);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);
    }

    function testSetRecipeStoresRecipeAndEmitsEvent() public {
        uint256[] memory inputIds = new uint256[](2);
        inputIds[0] = 1;
        inputIds[1] = 2;
        uint256[] memory inputAmounts = new uint256[](2);
        inputAmounts[0] = 3;
        inputAmounts[1] = 4;

        vm.expectEmit(true, true, true, true, address(craftingShop));
        emit RecipeSet(7, 99, 1, true);

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(7, inputIds, inputAmounts, 99, 1, true);

        (
            uint256[] memory storedInputIds,
            uint256[] memory storedInputAmounts,
            uint256 outputId,
            uint256 outputAmount,
            bool enabled,
            bool exists
        ) = craftingShop.getRecipe(7);

        assertEq(storedInputIds.length, 2);
        assertEq(storedInputIds[0], 1);
        assertEq(storedInputIds[1], 2);
        assertEq(storedInputAmounts.length, 2);
        assertEq(storedInputAmounts[0], 3);
        assertEq(storedInputAmounts[1], 4);
        assertEq(outputId, 99);
        assertEq(outputAmount, 1);
        assertTrue(enabled);
        assertTrue(exists);
    }

    function testSetRecipeRevertsOnArrayLengthMismatch() public {
        uint256[] memory inputIds = new uint256[](2);
        inputIds[0] = 1;
        inputIds[1] = 2;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 3;

        vm.prank(defaultAdmin);
        vm.expectRevert(CraftingShop.CraftingShop__InvalidArrayLength.selector);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);
    }

    function testSetRecipeRevertsOnEmptyInputs() public {
        uint256[] memory inputIds = new uint256[](0);
        uint256[] memory inputAmounts = new uint256[](0);

        vm.prank(defaultAdmin);
        vm.expectRevert(CraftingShop.CraftingShop__EmptyInputs.selector);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);
    }

    function testSetRecipeRevertsOnZeroOutputAmount() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 3;

        vm.prank(defaultAdmin);
        vm.expectRevert(CraftingShop.CraftingShop__ZeroAmount.selector);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 0, true);
    }

    function testSetRecipeRevertsOnZeroInputAmount() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 0;

        vm.prank(defaultAdmin);
        vm.expectRevert(CraftingShop.CraftingShop__ZeroAmount.selector);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);
    }

    function testSetRecipeEnabledUpdatesStatusAndEmitsEvent() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 3;

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);

        vm.expectEmit(true, true, true, true, address(craftingShop));
        emit RecipeStatusUpdated(1, false);

        vm.prank(defaultAdmin);
        craftingShop.setRecipeEnabled(1, false);

        (, , , , bool enabled, bool exists) = craftingShop.getRecipe(1);
        assertFalse(enabled);
        assertTrue(exists);
    }

    function testSetRecipeEnabledRevertsForUnknownRecipe() public {
        vm.prank(defaultAdmin);
        vm.expectRevert(abi.encodeWithSelector(CraftingShop.CraftingShop__UnknownRecipe.selector, 42));
        craftingShop.setRecipeEnabled(42, true);
    }

    function testCraftRevertsForUnknownRecipe() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(CraftingShop.CraftingShop__UnknownRecipe.selector, 77));
        craftingShop.craft(77, 1);
    }

    function testCraftRevertsForZeroTimes() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 2;

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);

        vm.prank(user);
        vm.expectRevert(CraftingShop.CraftingShop__InvalidTimes.selector);
        craftingShop.craft(1, 0);
    }

    function testCraftRevertsForDisabledRecipe() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 2;

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, false);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(CraftingShop.CraftingShop__RecipeDisabled.selector, 1));
        craftingShop.craft(1, 1);
    }

    function testCraftRevertsWithoutApproval() public {
        uint256[] memory inputIds = new uint256[](1);
        inputIds[0] = 1;
        uint256[] memory inputAmounts = new uint256[](1);
        inputAmounts[0] = 2;

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(1, inputIds, inputAmounts, 10, 1, true);

        vm.prank(minter);
        gameItems.mint(user, 1, 2, "");

        vm.prank(user);
        vm.expectRevert();
        craftingShop.craft(1, 1);
    }

    function testCraftTransfersBurnsAndMintsOutput() public {
        uint256[] memory inputIds = new uint256[](2);
        inputIds[0] = 1;
        inputIds[1] = 2;
        uint256[] memory inputAmounts = new uint256[](2);
        inputAmounts[0] = 2;
        inputAmounts[1] = 1;

        vm.prank(defaultAdmin);
        craftingShop.setRecipe(7, inputIds, inputAmounts, 99, 1, true);

        vm.startPrank(minter);
        gameItems.mint(user, 1, 10, "");
        gameItems.mint(user, 2, 5, "");
        vm.stopPrank();

        vm.prank(user);
        gameItems.setApprovalForAll(address(craftingShop), true);

        vm.expectEmit(true, true, true, true, address(craftingShop));
        emit Crafted(user, 7, 3, 99, 3);

        vm.prank(user);
        craftingShop.craft(7, 3);

        assertEq(gameItems.balanceOf(user, 1), 4);
        assertEq(gameItems.balanceOf(user, 2), 2);
        assertEq(gameItems.balanceOf(user, 99), 3);

        assertEq(gameItems.balanceOf(address(craftingShop), 1), 0);
        assertEq(gameItems.balanceOf(address(craftingShop), 2), 0);

        assertEq(gameItems.totalSupply(1), 4);
        assertEq(gameItems.totalSupply(2), 2);
        assertEq(gameItems.totalSupply(99), 3);
    }
}
