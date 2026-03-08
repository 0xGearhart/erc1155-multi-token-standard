// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../../src/GameItems.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlDefaultAdminRules} from
    "@openzeppelin/contracts/access/extensions/IAccessControlDefaultAdminRules.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Test} from "forge-std/Test.sol";

contract GameItemsTest is Test {
    GameItems internal gameItems;

    address internal defaultAdmin = makeAddr("defaultAdmin");
    address internal minter = makeAddr("minter");
    address internal uriSetter = makeAddr("uriSetter");
    address internal burner = makeAddr("burner");
    address internal user = makeAddr("user");
    address internal newDefaultAdmin = makeAddr("newDefaultAdmin");

    uint48 internal constant INITIAL_DELAY = 1;
    string internal constant INITIAL_URI = "ipfs://mock/{id}.json";

    uint256 internal constant FIRST_ID = 1;
    uint256 internal constant SECOND_ID = 2;
    uint256 internal constant AMOUNT = 10;

    function setUp() public {
        gameItems = new GameItems(defaultAdmin, minter, uriSetter, burner, INITIAL_DELAY, INITIAL_URI);
    }

    function testConstructorSetsRolesAndInitialDelay() public view {
        assertEq(gameItems.defaultAdmin(), defaultAdmin);
        assertEq(gameItems.defaultAdminDelay(), INITIAL_DELAY);
        assertEq(gameItems.uri(0), INITIAL_URI);

        assertTrue(gameItems.hasRole(gameItems.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), minter));
        assertTrue(gameItems.hasRole(gameItems.URI_SETTER_ROLE(), uriSetter));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), burner));
        assertFalse(gameItems.hasRole(gameItems.MINTER_ROLE(), user));
    }

    function testRoleAdminsAreDefaultAdminRole() public view {
        bytes32 defaultAdminRole = gameItems.DEFAULT_ADMIN_ROLE();

        assertEq(gameItems.getRoleAdmin(gameItems.MINTER_ROLE()), defaultAdminRole);
        assertEq(gameItems.getRoleAdmin(gameItems.URI_SETTER_ROLE()), defaultAdminRole);
        assertEq(gameItems.getRoleAdmin(gameItems.BURNER_ROLE()), defaultAdminRole);
    }

    function testCannotGrantDefaultAdminRoleDirectly() public {
        bytes32 defaultAdminRole = gameItems.DEFAULT_ADMIN_ROLE();

        vm.expectRevert(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminRules.selector);
        vm.prank(defaultAdmin);
        gameItems.grantRole(defaultAdminRole, newDefaultAdmin);
    }

    function testSetURIRevertsForNonUriSetter() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, gameItems.URI_SETTER_ROLE()
            )
        );
        vm.prank(user);
        gameItems.setURI("ipfs://new-uri/{id}.json");
    }

    function testSetURIUpdatesForUriSetter() public {
        string memory updatedUri = "ipfs://updated/{id}.json";
        vm.prank(uriSetter);
        gameItems.setURI(updatedUri);
        assertEq(gameItems.uri(123), updatedUri);
    }

    function testMintRevertsForNonMinter() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, gameItems.MINTER_ROLE()
            )
        );
        vm.prank(user);
        gameItems.mint(user, FIRST_ID, AMOUNT, "");
    }

    function testMintUpdatesBalanceAndSupply() public {
        vm.prank(minter);
        gameItems.mint(user, FIRST_ID, AMOUNT, "");

        assertEq(gameItems.balanceOf(user, FIRST_ID), AMOUNT);
        assertEq(gameItems.totalSupply(FIRST_ID), AMOUNT);
        assertTrue(gameItems.exists(FIRST_ID));
    }

    function testMintBatchUpdatesBalancesAndSupply() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = FIRST_ID;
        ids[1] = SECOND_ID;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = AMOUNT;
        amounts[1] = AMOUNT * 2;

        vm.prank(minter);
        gameItems.mintBatch(user, ids, amounts, "");

        assertEq(gameItems.balanceOf(user, FIRST_ID), AMOUNT);
        assertEq(gameItems.balanceOf(user, SECOND_ID), AMOUNT * 2);
        assertEq(gameItems.totalSupply(FIRST_ID), AMOUNT);
        assertEq(gameItems.totalSupply(SECOND_ID), AMOUNT * 2);
    }

    function testMintBatchRevertsOnArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = FIRST_ID;
        ids[1] = SECOND_ID;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = AMOUNT;

        vm.prank(minter);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidArrayLength.selector, 2, 1));
        gameItems.mintBatch(user, ids, amounts, "");
    }

    function testBurnRevertsForNonBurner() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, user, gameItems.BURNER_ROLE()
            )
        );
        vm.prank(user);
        gameItems.burn(FIRST_ID, 1);
    }

    function testBurnRevertsWhenBurnerHasNoBalance() public {
        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InsufficientBalance.selector, burner, 0, 1, FIRST_ID));
        gameItems.burn(FIRST_ID, 1);
    }

    function testBurnBurnsFromBurnerBalanceAndUpdatesSupply() public {
        vm.prank(minter);
        gameItems.mint(burner, FIRST_ID, AMOUNT, "");

        vm.prank(burner);
        gameItems.burn(FIRST_ID, 4);

        assertEq(gameItems.balanceOf(burner, FIRST_ID), 6);
        assertEq(gameItems.totalSupply(FIRST_ID), 6);
    }

    function testBurnBatchBurnsFromBurnerBalanceAndUpdatesSupply() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = FIRST_ID;
        ids[1] = SECOND_ID;

        uint256[] memory mintedAmounts = new uint256[](2);
        mintedAmounts[0] = 10;
        mintedAmounts[1] = 20;

        vm.prank(minter);
        gameItems.mintBatch(burner, ids, mintedAmounts, "");

        uint256[] memory burnAmounts = new uint256[](2);
        burnAmounts[0] = 3;
        burnAmounts[1] = 5;

        vm.prank(burner);
        gameItems.burnBatch(ids, burnAmounts);

        assertEq(gameItems.balanceOf(burner, FIRST_ID), 7);
        assertEq(gameItems.balanceOf(burner, SECOND_ID), 15);
        assertEq(gameItems.totalSupply(FIRST_ID), 7);
        assertEq(gameItems.totalSupply(SECOND_ID), 15);
    }

    function testBurnBatchRevertsOnArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = FIRST_ID;
        ids[1] = SECOND_ID;

        uint256[] memory mintedAmounts = new uint256[](2);
        mintedAmounts[0] = 10;
        mintedAmounts[1] = 20;

        vm.prank(minter);
        gameItems.mintBatch(burner, ids, mintedAmounts, "");

        uint256[] memory burnAmounts = new uint256[](1);
        burnAmounts[0] = 1;

        vm.prank(burner);
        vm.expectRevert(abi.encodeWithSelector(IERC1155Errors.ERC1155InvalidArrayLength.selector, 2, 1));
        gameItems.burnBatch(ids, burnAmounts);
    }

    function testSupportsInterfaceReturnsExpectedValues() public view {
        assertTrue(gameItems.supportsInterface(type(IERC165).interfaceId));
        assertTrue(gameItems.supportsInterface(type(IERC1155).interfaceId));
        assertTrue(gameItems.supportsInterface(type(IAccessControl).interfaceId));
        assertTrue(gameItems.supportsInterface(type(IAccessControlDefaultAdminRules).interfaceId));
        assertFalse(gameItems.supportsInterface(bytes4(0xffffffff)));
    }

    function testDefaultAdminTransferFlowRespectsDelay() public {
        vm.prank(defaultAdmin);
        gameItems.beginDefaultAdminTransfer(newDefaultAdmin);

        (address pendingAdmin, uint48 schedule) = gameItems.pendingDefaultAdmin();
        assertEq(pendingAdmin, newDefaultAdmin);
        assertEq(schedule, uint48(block.timestamp + INITIAL_DELAY));

        vm.prank(newDefaultAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControlDefaultAdminRules.AccessControlEnforcedDefaultAdminDelay.selector, schedule)
        );
        gameItems.acceptDefaultAdminTransfer();

        vm.warp(uint256(schedule) + 1);
        vm.prank(newDefaultAdmin);
        gameItems.acceptDefaultAdminTransfer();
        assertEq(gameItems.defaultAdmin(), newDefaultAdmin);
    }
}
