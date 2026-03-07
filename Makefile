-include .env

.PHONY: all reset clean remove install build test coverage coverage-report stage-coverage stage-check snapshot gas-report anvil deploy

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# Keep CI artifacts grouped for stage-by-stage review evidence.
REPORTS_DIR := reports
# Stage label is used in coverage artifact filenames (e.g., stage-0-coverage.txt).
STAGE ?= local
# Ignore noisy dependency-only warnings during coverage runs.
COVERAGE_IGNORED_CODES ?= 2424 4591
# Hide Foundry internal WARN spam while keeping real errors visible.
RUST_LOG_COVERAGE ?= error

all: install build

reset: clean remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install dependencies
install :; forge install cyfrin/foundry-devops@0.4.0 && forge install foundry-rs/forge-std@v1.13.0 && forge install openzeppelin/openzeppelin-contracts@v5.6.0

# Build contracts
build:; forge build

# Run test suite
test :; forge test 

# Run forge coverage with minimal fuzz/invariant runs to save time
coverage:
	@RUST_LOG=$(RUST_LOG_COVERAGE) FOUNDRY_PROFILE=coverage forge coverage $(foreach code,$(COVERAGE_IGNORED_CODES),--ignored-error-codes $(code))

# Create test coverage report and save to .txt file
# Use "coverage" foundry profile to prevent crashes due to excessive fuzz and invariant runs
coverage-report:
	@mkdir -p $(REPORTS_DIR)
	@RUST_LOG=$(RUST_LOG_COVERAGE) FOUNDRY_PROFILE=coverage forge coverage $(foreach code,$(COVERAGE_IGNORED_CODES),--ignored-error-codes $(code)) --report debug > $(REPORTS_DIR)/coverage-debug.txt

# Stage coverage artifact expected by plan.md
stage-coverage:
	@mkdir -p $(REPORTS_DIR)
	# Keep the report in reports/ so each stage review has a fixed artifact path.
	@RUST_LOG=$(RUST_LOG_COVERAGE) FOUNDRY_PROFILE=coverage forge coverage $(foreach code,$(COVERAGE_IGNORED_CODES),--ignored-error-codes $(code)) | tee $(REPORTS_DIR)/stage-$(STAGE)-coverage.txt

# Baseline stage check flow
# Single command to run the minimum gate checks before stage sign-off.
stage-check: build test stage-coverage

# Generate Gas Snapshot
snapshot :; forge snapshot

# Generate table showing gas cost for each function
gas-report:
	@mkdir -p $(REPORTS_DIR)
	@FOUNDRY_PROFILE=coverage forge test --gas-report > $(REPORTS_DIR)/gas.txt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network eth-MAINNET,$(ARGS)),--network eth-MAINNET)
	NETWORK_ARGS := --rpc-url $(ETH_MAINNET_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network eth-sepolia,$(ARGS)),--network eth-sepolia)
	NETWORK_ARGS := --rpc-url $(ETH_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network arb-MAINNET,$(ARGS)),--network arb-MAINNET)
	NETWORK_ARGS := --rpc-url $(ARB_MAINNET_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network arb-sepolia,$(ARGS)),--network arb-sepolia)
	NETWORK_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network base-MAINNET,$(ARGS)),--network base-MAINNET)
	NETWORK_ARGS := --rpc-url $(BASE_MAINNET_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network base-sepolia,$(ARGS)),--network base-sepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# deploy contracts with script
deploy:
	@forge script script/DeployGameItems.s.sol:DeployGameItems $(NETWORK_ARGS)
