// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity 0.8.33;

import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract GameItems is ERC1155, AccessControlDefaultAdminRules, ERC1155Supply {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor(
        address defaultAdmin,
        address minter,
        address uriSetter,
        address burner,
        uint48 initialDelay,
        string memory gameItemsUri
    )
        ERC1155(gameItemsUri)
        AccessControlDefaultAdminRules(initialDelay, defaultAdmin)
    {
        _grantRole(MINTER_ROLE, minter);
        _grantRole(URI_SETTER_ROLE, uriSetter);
        _grantRole(BURNER_ROLE, burner);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(uint256 id, uint256 value) public onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), id, value);
    }

    function burnBatch(uint256[] memory ids, uint256[] memory values) public onlyRole(BURNER_ROLE) {
        _burnBatch(_msgSender(), ids, values);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    )
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlDefaultAdminRules)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
