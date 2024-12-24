// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "lib/forge-std/src/Vm.sol";

import {Currency} from "src/types/Currency.sol";

import {Configured} from "config/Configured.sol";

import {AaveV3Config, AaveMarket, CometConfig, CometMarket} from "test/shared/Protocols.sol";
import {Constants} from "./Constants.sol";

abstract contract Fork is Configured, Constants {
	Vm private constant vm = Vm(VM);

	uint256 internal forkId;

	function fork() internal virtual {
		uint256 forkBlockNumber = getForkBlockNumber();

		if (forkBlockNumber != 0) {
			forkId = vm.createSelectFork(vm.rpcUrl(network), forkBlockNumber);
		} else {
			forkId = vm.createSelectFork(vm.rpcUrl(network));
		}

		vm.chainId(getChainId());
	}

	function forward(uint256 numberOfDays) internal virtual {
		vm.roll(vm.getBlockNumber() + numberOfDays * blocksPerDay());
		vm.warp(vm.getBlockTimestamp() + numberOfDays * SECONDS_PER_DAY);
	}

	function blocksPerDay() internal view returns (uint256) {
		uint256 chainId = getChainId();

		if (chainId == OPTIMISM_CHAIN_ID) {
			return OPTIMISM_BLOCKS_PER_DAY;
		} else if (chainId == POLYGON_CHAIN_ID) {
			return POLYGON_BLOCKS_PER_DAY;
		} else if (chainId == ARBITRUM_CHAIN_ID) {
			return ARBITRUM_BLOCKS_PER_DAY;
		} else return ETHEREUM_BLOCKS_PER_DAY;
	}

	function randomIntermediateCurrency() internal virtual returns (Currency) {
		return randomAsset(intermediateCurrencies);
	}

	function randomStablecoin() internal virtual returns (Currency) {
		return randomAsset(stablecoins);
	}

	function randomAsset() internal virtual returns (Currency) {
		return randomAsset(allAssets);
	}

	function randomAsset(Currency[] memory assets) internal virtual returns (Currency) {
		vm.assume(assets.length != 0);
		return assets[vm.randomUint(0, assets.length - 1)];
	}

	function labelAll() internal virtual {
		vm.label(address(UNISWAP_V3_FACTORY), "Uniswap V3 Factory");
		vm.label(address(UNISWAP_V3_QUOTER), "Uniswap V3 Quoter");
		vm.label(address(PERMIT2), "Permit2");
		labelAaveV3();
		labelComet();
	}

	function labelAaveV3() internal virtual {
		if (bytes(aaveV3.context.network).length == 0) return;

		string memory prefix = string.concat("Aave V3 ", aaveV3.context.protocol, ": ");

		vm.label(aaveV3.aclAdmin, string.concat(prefix, "ACLAdmin"));
		vm.label(address(aaveV3.aclManager), string.concat(prefix, "ACLManager"));
		vm.label(address(aaveV3.addressesProvider), string.concat(prefix, "PoolAddressesProvider"));
		vm.label(address(aaveV3.dataProvider), string.concat(prefix, "PoolDataProvider"));
		vm.label(address(aaveV3.pool), string.concat(prefix, "Pool"));
		vm.label(address(aaveV3.oracle), string.concat(prefix, "PriceOracle"));
		vm.label(address(aaveV3.rewardsController), string.concat(prefix, "RewardsController"));
		vm.label(address(aaveV3.emissionManager), string.concat(prefix, "EmissionManager"));
		vm.label(address(aaveV3.collector), string.concat(prefix, "Collector"));
	}

	function labelAaveMarket(AaveMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		string memory prefix = string.concat(aaveV3.context.abbreviation, market.symbol);

		vm.label(market.underlying.toAddress(), market.symbol);
		vm.label(address(market.aToken), string.concat("a", prefix));
		vm.label(address(market.vdToken), string.concat("variableDebt", prefix));
	}

	function labelComet() internal virtual {
		if (compV3.governor == address(0)) return;

		vm.label(compV3.governor, "CometGovernor");
		vm.label(address(compV3.configurator), "CometConfigurator");
		vm.label(address(compV3.rewards), "CometRewards");
	}

	function labelCometMarket(CometMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		vm.label(market.underlying.toAddress(), market.base);
		vm.label(address(market.comet), market.symbol);

		for (uint256 i; i < market.assets.length; ++i) {
			vm.label(market.assets[i].underlying.toAddress(), market.assets[i].symbol);
		}
	}
}
