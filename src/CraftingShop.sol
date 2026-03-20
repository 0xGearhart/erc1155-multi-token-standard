// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {GameItems} from "./GameItems.sol";

/**
 * @title CraftingShop
 * @author 0xGearhart
 * @notice Admin-managed recipe registry for GameItems crafting logic.
 * @dev This first scaffold stage only manages recipe configuration and events.
 */
contract CraftingShop is AccessControl, ERC1155Holder {
    /**
     * @notice Role allowed to create/update/toggle recipes.
     */
    bytes32 public constant RECIPE_ADMIN_ROLE = keccak256("RECIPE_ADMIN_ROLE");

    /**
     * @notice Linked GameItems token contract.
     */
    GameItems public immutable GAME_ITEMS;

    /**
     * @dev Core recipe storage object.
     * @param outputId Token ID produced by recipe.
     * @param outputAmount Token quantity produced by recipe.
     * @param enabled Whether recipe can be used.
     * @param exists Whether recipe has been initialized.
     */
    struct Recipe {
        uint256 outputId;
        uint256 outputAmount;
        bool enabled;
        bool exists;
    }

    /**
     * @notice Error for mismatched input ID and amount arrays.
     */
    error CraftingShop__InvalidArrayLength();
    /**
     * @notice Error when a recipe is configured without any inputs.
     */
    error CraftingShop__EmptyInputs();
    /**
     * @notice Error when an amount value is zero.
     */
    error CraftingShop__ZeroAmount();
    /**
     * @notice Error when toggling a recipe that does not exist.
     * @param recipeId Recipe identifier.
     */
    error CraftingShop__UnknownRecipe(uint256 recipeId);
    /**
     * @notice Error when trying to craft with a disabled recipe.
     * @param recipeId Recipe identifier.
     */
    error CraftingShop__RecipeDisabled(uint256 recipeId);
    /**
     * @notice Error when craft multiplier is zero.
     */
    error CraftingShop__InvalidTimes();
    /**
     * @notice Error when constructor receives an invalid GameItems address.
     */
    error CraftingShop__InvalidGameItemsAddress();

    /**
     * @notice Recipe metadata keyed by recipe ID.
     */
    mapping(uint256 recipeId => Recipe recipe) public recipes;
    /**
     * @notice Input token IDs per recipe.
     */
    mapping(uint256 recipeId => uint256[] inputIds) internal recipeInputIds;
    /**
     * @notice Input token amounts per recipe.
     */
    mapping(uint256 recipeId => uint256[] inputAmounts) internal recipeInputAmounts;

    /**
     * @notice Emitted when a recipe is created or updated.
     * @param recipeId Recipe identifier.
     * @param outputId Output token ID.
     * @param outputAmount Output token amount.
     * @param enabled Recipe enabled flag.
     */
    event RecipeSet(uint256 indexed recipeId, uint256 outputId, uint256 outputAmount, bool enabled);

    /**
     * @notice Emitted when recipe enabled state is toggled.
     * @param recipeId Recipe identifier.
     * @param enabled New enabled value.
     */
    event RecipeStatusUpdated(uint256 indexed recipeId, bool enabled);
    /**
     * @notice Emitted when a craft is successfully executed.
     * @param account Crafter address.
     * @param recipeId Recipe identifier.
     * @param times Craft multiplier used.
     * @param outputId Output token ID.
     * @param outputAmount Crafted output amount.
     */
    event Crafted(
        address indexed account, uint256 indexed recipeId, uint256 times, uint256 outputId, uint256 outputAmount
    );

    /**
     * @notice Initializes role assignments and linked GameItems address.
     * @param initialAdmin Address receiving default admin and recipe admin roles.
     * @param gameItems Address of deployed GameItems contract.
     */
    constructor(address initialAdmin, GameItems gameItems) {
        if (address(gameItems) == address(0)) revert CraftingShop__InvalidGameItemsAddress();
        GAME_ITEMS = gameItems;
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(RECIPE_ADMIN_ROLE, initialAdmin);
    }

    /**
     * @notice Creates or updates a recipe.
     * @param recipeId Recipe identifier.
     * @param inputIds Required input token IDs.
     * @param inputAmounts Required input token amounts.
     * @param outputId Crafted output token ID.
     * @param outputAmount Crafted output token amount.
     * @param enabled Enabled state for recipe.
     */
    function setRecipe(
        uint256 recipeId,
        uint256[] calldata inputIds,
        uint256[] calldata inputAmounts,
        uint256 outputId,
        uint256 outputAmount,
        bool enabled
    )
        external
        onlyRole(RECIPE_ADMIN_ROLE)
    {
        if (inputIds.length != inputAmounts.length) revert CraftingShop__InvalidArrayLength();
        if (inputIds.length == 0) revert CraftingShop__EmptyInputs();
        if (outputAmount == 0) revert CraftingShop__ZeroAmount();

        for (uint256 i = 0; i < inputAmounts.length; i++) {
            if (inputAmounts[i] == 0) revert CraftingShop__ZeroAmount();
        }

        recipeInputIds[recipeId] = inputIds;
        recipeInputAmounts[recipeId] = inputAmounts;
        recipes[recipeId] = Recipe({outputId: outputId, outputAmount: outputAmount, enabled: enabled, exists: true});

        emit RecipeSet(recipeId, outputId, outputAmount, enabled);
    }

    /**
     * @notice Toggles recipe enabled state.
     * @param recipeId Recipe identifier.
     * @param enabled New enabled value.
     */
    function setRecipeEnabled(uint256 recipeId, bool enabled) external onlyRole(RECIPE_ADMIN_ROLE) {
        if (!recipes[recipeId].exists) revert CraftingShop__UnknownRecipe(recipeId);
        recipes[recipeId].enabled = enabled;
        emit RecipeStatusUpdated(recipeId, enabled);
    }

    /**
     * @notice Executes a crafting recipe atomically.
     * @dev Transfers required inputs from user to this contract, burns them, then mints output to user.
     * @param recipeId Recipe identifier.
     * @param times Craft multiplier.
     */
    function craft(uint256 recipeId, uint256 times) external {
        if (times == 0) revert CraftingShop__InvalidTimes();

        Recipe memory recipe = recipes[recipeId];
        if (!recipe.exists) revert CraftingShop__UnknownRecipe(recipeId);
        if (!recipe.enabled) revert CraftingShop__RecipeDisabled(recipeId);

        uint256[] memory inputIds = recipeInputIds[recipeId];
        uint256[] memory requiredInputAmounts = _requiredInputAmounts(recipeId, times);
        uint256 outputAmount = recipe.outputAmount * times;

        GAME_ITEMS.safeBatchTransferFrom(msg.sender, address(this), inputIds, requiredInputAmounts, "");
        GAME_ITEMS.burnBatch(inputIds, requiredInputAmounts);
        GAME_ITEMS.mint(msg.sender, recipe.outputId, outputAmount, "");

        emit Crafted(msg.sender, recipeId, times, recipe.outputId, outputAmount);
    }

    /**
     * @notice Returns complete recipe data including inputs.
     * @param recipeId Recipe identifier.
     * @return inputIds Input token IDs.
     * @return inputAmounts Input token amounts.
     * @return outputId Output token ID.
     * @return outputAmount Output token amount.
     * @return enabled Recipe enabled state.
     * @return exists True if recipe exists.
     */
    function getRecipe(uint256 recipeId)
        external
        view
        returns (
            uint256[] memory inputIds,
            uint256[] memory inputAmounts,
            uint256 outputId,
            uint256 outputAmount,
            bool enabled,
            bool exists
        )
    {
        Recipe memory recipe = recipes[recipeId];
        return (
            recipeInputIds[recipeId],
            recipeInputAmounts[recipeId],
            recipe.outputId,
            recipe.outputAmount,
            recipe.enabled,
            recipe.exists
        );
    }

    /**
     * @dev Computes required inputs for a recipe at a given craft multiplier.
     */
    function _requiredInputAmounts(uint256 recipeId, uint256 times) internal view returns (uint256[] memory) {
        uint256[] memory baseInputAmounts = recipeInputAmounts[recipeId];
        uint256[] memory multipliedInputAmounts = new uint256[](baseInputAmounts.length);

        for (uint256 i = 0; i < baseInputAmounts.length; i++) {
            multipliedInputAmounts[i] = baseInputAmounts[i] * times;
        }
        return multipliedInputAmounts;
    }

    /**
     * @notice Returns true if this contract implements the queried interface.
     * @param interfaceId Interface identifier.
     * @return True if supported.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
