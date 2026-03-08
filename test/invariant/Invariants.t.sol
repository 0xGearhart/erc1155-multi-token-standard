// SPDX-License-Identifier: MIT

pragma solidity 0.8.33;

import {GameItems} from "../../src/GameItems.sol";
import {Handler} from "./Handeler.t.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";

contract Invariants is StdInvariant, Test {
    GameItems internal gameItems;
    Handler internal handler;

    address internal defaultAdmin = makeAddr("defaultAdmin");
    address internal minter = makeAddr("minter");
    address internal uriSetter = makeAddr("uriSetter");
    address internal burner = makeAddr("burner");
    address internal unauthorized = makeAddr("unauthorized");

    uint48 internal constant INITIAL_DELAY = 1;
    string internal constant INITIAL_URI = "ipfs://mock/{id}.json";

    function setUp() external {
        gameItems = new GameItems(defaultAdmin, minter, uriSetter, burner, INITIAL_DELAY, INITIAL_URI);
        handler = new Handler(gameItems, minter, uriSetter, burner, unauthorized);
        targetContract(address(handler));
    }

    function invariant_SupplyConservationForTrackedIds() external view {
        for (uint256 id = 1; id <= handler.MAX_TRACKED_ID(); id++) {
            uint256 expectedSupply = handler.mintedById(id) - handler.burnedById(id);
            assertEq(gameItems.totalSupply(id), expectedSupply, "tracked supply mismatch");
        }
    }

    function invariant_RoleBoundariesRemainIntact() external view {
        assertTrue(gameItems.hasRole(gameItems.DEFAULT_ADMIN_ROLE(), defaultAdmin));
        assertTrue(gameItems.hasRole(gameItems.MINTER_ROLE(), minter));
        assertTrue(gameItems.hasRole(gameItems.URI_SETTER_ROLE(), uriSetter));
        assertTrue(gameItems.hasRole(gameItems.BURNER_ROLE(), burner));

        assertFalse(gameItems.hasRole(gameItems.MINTER_ROLE(), unauthorized));
        assertFalse(gameItems.hasRole(gameItems.URI_SETTER_ROLE(), unauthorized));
        assertFalse(gameItems.hasRole(gameItems.BURNER_ROLE(), unauthorized));
    }
}
