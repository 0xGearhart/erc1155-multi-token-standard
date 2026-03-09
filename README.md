# ERC-1155 GameItems

## Table of Contents

- [ERC-1155 GameItems](#erc-1155-gameitems)
  - [Table of Contents](#table-of-contents)
  - [About](#about)
    - [Key Features](#key-features)
    - [Architecture](#architecture)
  - [Getting Started](#getting-started)
    - [Requirements](#requirements)
    - [Quickstart](#quickstart)
    - [Environment Setup](#environment-setup)
  - [Usage](#usage)
    - [Build](#build)
    - [Testing](#testing)
    - [Test Coverage](#test-coverage)
    - [Deploy Locally](#deploy-locally)
    - [Interact with Contract](#interact-with-contract)
  - [Deployment](#deployment)
    - [Deploy to Testnet](#deploy-to-testnet)
    - [Verify Contract](#verify-contract)
    - [Deployment Addresses](#deployment-addresses)
  - [Security](#security)
    - [Audit Status](#audit-status)
    - [Access Control (Roles \& Permissions)](#access-control-roles--permissions)
    - [Known Limitations](#known-limitations)
  - [Gas Optimization](#gas-optimization)
  - [Contributing](#contributing)
  - [License](#license)

## About

`GameItems` is a role-gated ERC-1155 contract for game item minting, role-restricted burns, and base URI management. This repository includes deployment scripts, multi-chain integration tests, invariants, and stage-gated quality checks.

### Key Features

- OpenZeppelin-based ERC-1155 token with per-ID total supply tracking.
- Role-based minting, burning, and URI control.
- Delayed default-admin handoff using `AccessControlDefaultAdminRules`.
- Integration tests across local + supported forked networks.
- Invariant and fuzz testing for role boundaries and supply correctness.

**Tech Stack:**
- Solidity `0.8.33`
- Foundry (`forge`, `cast`, `anvil`)
- OpenZeppelin Contracts `v5.6.0`
- Slither + Aderyn static analysis

### Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                        Player / Admin EOAs                  │
└───────────────┬───────────────────────────┬─────────────────┘
                │                           │
                │ role-gated calls          │ governance actions
                ▼                           ▼
┌──────────────────────────────────────────────────────────────┐
│                           GameItems                          │
│  ERC1155 + ERC1155Supply + AccessControlDefaultAdminRules    │
│                                                              │
│  - mint/mintBatch   -> MINTER_ROLE                           │
│  - setURI           -> URI_SETTER_ROLE                       │
│  - burn/burnBatch   -> BURNER_ROLE (caller balance only)     │
│  - delayed admin transfer -> DEFAULT_ADMIN_ROLE lifecycle    │
└──────────────────────────────────────────────────────────────┘

```

**Repository Structure:**
```text
erc1155-multi-token-standard/
├── src/
│   └── GameItems.sol                    # Core ERC-1155 contract, roles, burn policy, URI updates
├── script/
│   ├── HelperConfig.s.sol               # Chain IDs, deployment constants, and per-network role config
│   └── DeployGameItems.s.sol            # Broadcast deployment entrypoint that instantiates GameItems
├── test/
│   ├── unit/
│   │   └── GameItemsTest.t.sol          # Unit + fuzz tests for contract behavior and event/revert coverage
│   ├── integration/
│   │   └── DeployGameItemsTest.t.sol    # Deployment script tests on local + forked chains
│   └── invariant/
│       ├── Handeler.t.sol               # Stateful handler actions (authorized and unauthorized actors)
│       └── Invariants.t.sol             # Protocol invariants for supply and role safety boundaries
├── Makefile                             # Standardized build/test/coverage/slither/deploy commands
├── foundry.toml                         # Foundry profiles, remappings, fuzz/invariant config
├── .env.example                         # Required environment variable template for setup
├── plan.md                              # Stage-by-stage execution plan and gate checklist
└── README.md                            # Project documentation and operator runbook
```

## Getting Started

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Verify installation: `git --version`
- [Foundry](https://getfoundry.sh/)
  - Verify installation: `forge --version`
- Optional but recommended: [Slither](https://github.com/crytic/slither)

### Quickstart

```bash
git clone https://github.com/0xGearhart/erc1155-multi-token-standard
cd erc1155-multi-token-standard
make
```

### Environment Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure your `.env` file:**
   ```bash
   MAINNET_RPC_URL=your_mainnet_rpc_url
   SEPOLIA_RPC_URL=your_sepolia_rpc_url
   ARB_MAINNET_RPC_URL=your_mainnet_rpc_url
   ARB_SEPOLIA_RPC_URL=your_sepolia_rpc_url
   BASE_MAINNET_RPC_URL=your_mainnet_rpc_url
   BASE_SEPOLIA_RPC_URL=your_sepolia_rpc_url
   LINEA_SEPOLIA_RPC_URL=your_sepolia_rpc_url
   ETHERSCAN_API_KEY=your_etherscan_api_key
   DEFAULT_KEY_ADDRESS=public_address_of_your_encrypted_private_key
   ```

3. **Get testnet ETH:**
   - Sepolia Faucet: [cloud.google.com/application/web3/faucet/ethereum/sepolia](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)

4. **Configure Makefile**
- Change account name in Makefile to the name of your desired encrypted key 
  - change "--account defaultKey" to "--account <YOUR_ENCRYPTED_KEY_NAME>"
  - check encrypted key names stored locally with:

```bash
cast wallet list
```
- **If no encrypted keys found**
  - Encrypt private key to be used securely within foundry:

```bash
cast wallet import <account_name> --interactive
```

**⚠️ Security Warning:**
- Never commit your `.env` file
- Never use your mainnet private key for testing
- Use a separate wallet with only testnet funds for development

## Usage

### Build

Compile contracts:

```bash
forge build
```

### Testing

Run the test suite:

```bash
forge test
```

Run tests with verbosity:

```bash
forge test -vvv
```

Run specific test targets:

```bash
forge test --match-path test/unit/GameItemsTest.t.sol
forge test --match-path test/integration/DeployGameItemsTest.t.sol
forge test --match-contract Invariants
```

### Test Coverage

Generate coverage report:

```bash
make coverage
```

Create test coverage report and save to `.txt` file:

```bash
make coverage-report
```

### Deploy Locally

Start a local Anvil node:

```bash
make anvil
```

Deploy to local node (in another terminal):

```bash
make deploy
```

### Interact with Contract

[Examples of how to interact with your contract using cast or scripts]

```bash
# Grant MINTER_ROLE (caller must be default admin)
cast send <GAME_ITEMS_ADDRESS> \
  "grantRole(bytes32,address)" \
  $(cast keccak "MINTER_ROLE") <MINTER_ADDRESS> \
  --rpc-url <RPC_URL> --account defaultKey

# Mint token ID 1 amount 10
cast send <GAME_ITEMS_ADDRESS> \
  "mint(address,uint256,uint256,bytes)" \
  <TO_ADDRESS> 1 10 0x \
  --rpc-url <RPC_URL> --account defaultKey

# Update base URI
cast send <GAME_ITEMS_ADDRESS> \
  "setURI(string)" "ipfs://<CID>/{id}.json" \
  --rpc-url <RPC_URL> --account defaultKey
```

## Deployment

### Deploy to Testnet

Deploy using Makefile network args:

```bash
make deploy ARGS="--network eth-sepolia"
make deploy ARGS="--network arb-sepolia"
make deploy ARGS="--network base-sepolia"
```

Or using forge directly:

```bash
forge script script/DeployGameItems.s.sol:DeployGameItems \
  --rpc-url $ETH_SEPOLIA_RPC_URL \
  --account defaultKey \
  --broadcast --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
```

### Verify Contract

If automatic verification fails:

```bash
forge verify-contract <CONTRACT_ADDRESS> src/GameItems.sol:GameItems \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Deployment Addresses

| Network          | Contract Address | Explorer                                             |
| ---------------- | ---------------- | ---------------------------------------------------- |
| Ethereum Mainnet | `TBD`            | [etherscan.io](https://etherscan.io)                 |
| Ethereum Sepolia | `TBD`            | [sepolia.etherscan.io](https://sepolia.etherscan.io) |
| Arbitrum Mainnet | `TBD`            | [arbiscan.io](https://arbiscan.io)                   |
| Arbitrum Sepolia | `TBD`            | [sepolia.arbiscan.io](https://sepolia.arbiscan.io)   |
| Base Mainnet     | `TBD`            | [basescan.org](https://basescan.org)                 |
| Base Sepolia     | `TBD`            | [sepolia.basescan.org](https://sepolia.basescan.org) |

## Security

### Audit Status

⚠️ **This contract has not been audited.** Use at your own risk.

For production use, consider:
- Professional security audit
- Bug bounty program
- Gradual rollout with monitoring

### Access Control (Roles & Permissions)

The protocol uses OpenZeppelin `AccessControlDefaultAdminRules` with delayed admin transfer.

**Roles:**
- **`DEFAULT_ADMIN_ROLE`**
  - Admin of `MINTER_ROLE`, `URI_SETTER_ROLE`, and `BURNER_ROLE`.
  - Transferred using delayed `beginDefaultAdminTransfer` / `acceptDefaultAdminTransfer` flow.
- **`MINTER_ROLE`**
  - Can call `mint` and `mintBatch`.
- **`URI_SETTER_ROLE`**
  - Can call `setURI`.
- **`BURNER_ROLE`**
  - Can call `burn` and `burnBatch`.
  - Burns from caller-owned balances only.

**Access Control Vulnerabilities & Mitigations:**
- ⚠️ **Risk**: Centralized key controls all roles in default setup.
  - **Mitigation**: Move admin to multisig and split operational roles across dedicated addresses/contracts.
- ⚠️ **Risk**: Incorrect role assignment during deployment.
  - **Mitigation**: Verify role state in integration tests and post-deploy scripts.

### Known Limitations

- Current deployment defaults grant all roles to deployer/default key.
- Placeholder URI remains until metadata/IPFS stage is finalized.
- Shop/crafting contract integration is planned but not yet implemented.

**Centralization Risks:**
- Admin can grant/revoke non-admin roles.
- Operational mistakes in key management can impact mint/burn/URI authority.

## Gas Optimization

| Function    | Gas Cost |
| ----------- | -------- |
| `function1` | ~XXX,XXX |
| `function2` | ~XXX,XXX |
| `function3` | ~XXX,XXX |

Generate gas report and save to `.txt` file:

```bash
make gas-report
```

Generate gas snapshot:

```bash
forge snapshot
```

Compare gas changes:

```bash
forge snapshot --diff
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Disclaimer:** This software is provided "as is", without warranty of any kind. Use at your own risk.

**Built with [Foundry](https://getfoundry.sh/)**
