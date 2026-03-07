// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.6.0
pragma solidity 0.8.33;

import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title GameItems
 * @author 0xGearhart
 * @notice Role-gated ERC-1155 token contract for game item minting, URI management, and burner-owned burns.
 * @dev Uses AccessControlDefaultAdminRules for delayed default-admin transfers and ERC1155Supply for per-id supply tracking.
 */
contract GameItems is ERC1155, AccessControlDefaultAdminRules, ERC1155Supply {
    /**
     * @notice Role allowed to update the base metadata URI.
     */
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    /**
     * @notice Role allowed to mint single and batch tokens.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /**
     * @notice Role allowed to burn only its own token balances.
     */
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice Initializes role assignments and ERC-1155 base URI.
     * @param defaultAdmin Initial default admin managed by AccessControlDefaultAdminRules.
     * @param minter Address granted MINTER_ROLE.
     * @param uriSetter Address granted URI_SETTER_ROLE.
     * @param burner Address granted BURNER_ROLE.
     * @param initialDelay Delay in seconds required for default-admin transfer acceptance.
     * @param gameItemsUri Initial base URI used by ERC-1155 metadata.
     */
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

    /**
     * @notice Updates the base URI for all token IDs.
     * @param newUri New base URI string.
     */
    function setURI(string memory newUri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newUri);
    }

    /**
     * @notice Mints tokens of a single ID to an account.
     * @param account Recipient of minted tokens.
     * @param id Token ID to mint.
     * @param amount Quantity to mint.
     * @param data Additional data passed to receiver hooks.
     */
    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    /**
     * @notice Mints multiple token IDs to an account.
     * @param to Recipient of minted tokens.
     * @param ids Token IDs to mint.
     * @param amounts Quantities per token ID.
     * @param data Additional data passed to receiver hooks.
     */
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

    /**
     * @notice Burns caller-owned balance for a single token ID.
     * @param id Token ID to burn.
     * @param value Quantity to burn.
     */
    function burn(uint256 id, uint256 value) public onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), id, value);
    }

    /**
     * @notice Burns caller-owned balances for multiple token IDs.
     * @param ids Token IDs to burn.
     * @param values Quantities per token ID.
     */
    function burnBatch(uint256[] memory ids, uint256[] memory values) public onlyRole(BURNER_ROLE) {
        _burnBatch(_msgSender(), ids, values);
    }

    /**
     * @dev Internal transfer/burn/mint hook override required by ERC1155Supply.
     */
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

    /**
     * @notice Returns true if this contract implements the queried interface.
     * @param interfaceId Interface identifier, as specified in ERC-165.
     * @return True if the interface is supported.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlDefaultAdminRules)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
