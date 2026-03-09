// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../../src/GameItems.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Test} from "forge-std/Test.sol";

contract Handler is Test {
    GameItems public immutable gameItems;
    address public immutable defaultAdmin;
    address public immutable minter;
    address public immutable uriSetter;
    address public immutable burner;
    address public immutable unauthorized;

    uint256 public constant MAX_TRACKED_ID = 8;

    mapping(uint256 id => uint256 amount) public mintedById;
    mapping(uint256 id => uint256 amount) public burnedById;
    mapping(address actor => mapping(uint256 id => uint256 amount)) public burnedByActor;

    constructor(
        GameItems gameItems_,
        address defaultAdmin_,
        address minter_,
        address uriSetter_,
        address burner_,
        address unauthorized_
    ) {
        gameItems = gameItems_;
        defaultAdmin = defaultAdmin_;
        minter = minter_;
        uriSetter = uriSetter_;
        burner = burner_;
        unauthorized = unauthorized_;
    }

    function mintAsMinter(uint256 id, uint256 amount) external {
        id = bound(id, 1, MAX_TRACKED_ID);
        amount = bound(amount, 1, type(uint96).max);

        vm.prank(minter);
        gameItems.mint(burner, id, amount, "");
        mintedById[id] += amount;
    }

    function mintAsUnauthorized(uint256 id, uint256 amount) external {
        id = bound(id, 1, MAX_TRACKED_ID);
        amount = bound(amount, 1, type(uint96).max);

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, gameItems.MINTER_ROLE())
        );
        vm.prank(unauthorized);
        gameItems.mint(unauthorized, id, amount, "");
    }

    function burnAsBurner(uint256 id, uint256 amount) external {
        id = bound(id, 1, MAX_TRACKED_ID);

        uint256 balance = gameItems.balanceOf(burner, id);
        if (balance == 0) {
            vm.prank(minter);
            gameItems.mint(burner, id, 1, "");
            mintedById[id] += 1;
            balance = 1;
        }

        amount = bound(amount, 1, balance);

        vm.prank(burner);
        gameItems.burn(id, amount);
        burnedById[id] += amount;
        burnedByActor[burner][id] += amount;
    }

    function burnAsUnauthorized(uint256 id, uint256 amount) external {
        id = bound(id, 1, MAX_TRACKED_ID);
        amount = bound(amount, 1, type(uint96).max);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, gameItems.BURNER_ROLE()
            )
        );
        vm.prank(unauthorized);
        gameItems.burn(id, amount);
    }

    function setUriAsSetter(uint256 salt) external {
        string memory newUri = string.concat("ipfs://invariant/", vm.toString(salt), "/{id}.json");
        vm.prank(uriSetter);
        gameItems.setURI(newUri);
    }

    function setUriAsUnauthorized(uint256 salt) external {
        string memory newUri = string.concat("ipfs://unauthorized/", vm.toString(salt), "/{id}.json");
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, unauthorized, gameItems.URI_SETTER_ROLE()
            )
        );
        vm.prank(unauthorized);
        gameItems.setURI(newUri);
    }

    function burnByRandomActor(uint256 actorSeed, uint256 id, uint256 amount) external {
        id = bound(id, 1, MAX_TRACKED_ID);
        address actor = _pickActor(actorSeed);

        if (actor == burner) {
            uint256 balance = gameItems.balanceOf(burner, id);
            if (balance == 0) {
                vm.prank(minter);
                gameItems.mint(burner, id, 1, "");
                mintedById[id] += 1;
                balance = 1;
            }
            amount = bound(amount, 1, balance);

            vm.prank(burner);
            gameItems.burn(id, amount);
            burnedById[id] += amount;
            burnedByActor[burner][id] += amount;
            return;
        }

        amount = bound(amount, 1, type(uint96).max);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, actor, gameItems.BURNER_ROLE())
        );
        vm.prank(actor);
        gameItems.burn(id, amount);
    }

    function _pickActor(uint256 seed) internal view returns (address) {
        uint256 choice = seed % 5;
        if (choice == 0) return defaultAdmin;
        if (choice == 1) return minter;
        if (choice == 2) return uriSetter;
        if (choice == 3) return burner;
        return unauthorized;
    }
}
