-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

all: clean remove install update build

build :; forge build

clean :; forge clean

test :; forge test -vvvv

coverage :; forge coverage

install :; forge install smartcontractkit/chainlink-brownie-contracts@1.3.0

deploy-anvil :
	@forge script script/DeployPriceLockedEthVault.s.sol:DeployPriceLockedEthVault --rpc-url $(ANVIL_RPC_URL) --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv

deploy-sepolia :
	@forge script script/DeployPriceLockedEthVault.s.sol:DeployPriceLockedEthVault --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaTestnetKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv