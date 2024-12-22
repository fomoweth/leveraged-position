// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

import {Configured} from "config/Configured.sol";

import {AaveV3Config, AaveMarket, CometConfig, CometMarket} from "test/shared/Protocols.sol";
import {Common} from "./Common.sol";

abstract contract Fork is Configured, Common {
	uint256 internal forkId;

	modifier onlyEthereum() {
		vm.skip(block.chainid != ETHEREUM_CHAIN_ID);
		_;
	}

	modifier onlyOptimism() {
		vm.skip(block.chainid != OPTIMISM_CHAIN_ID);
		_;
	}

	modifier onlyPolygon() {
		vm.skip(block.chainid != POLYGON_CHAIN_ID);
		_;
	}

	modifier onlyArbitrum() {
		vm.skip(block.chainid != ARBITRUM_CHAIN_ID);
		_;
	}

	function configure() internal virtual override {
		if (block.chainid == 31337) vm.chainId(ETHEREUM_CHAIN_ID);

		super.configure();
		fork();
	}

	function fork() internal virtual {
		uint256 forkBlockNumber = getForkBlockNumber();

		if (forkBlockNumber != 0) {
			forkId = vm.createSelectFork(vm.rpcUrl(network), forkBlockNumber);
		} else {
			forkId = vm.createSelectFork(vm.rpcUrl(network));
		}

		vm.chainId(getChainId());
	}

	function labelAll() internal virtual {
		label(address(V3_FACTORY), "Uniswap V3 Factory");
		label(address(V3_QUOTER), "Uniswap V3 Quoter");
		label(address(PERMIT2), "Permit2");
		labelAaveV3();
		labelComet();
	}

	function labelAaveV3() internal virtual {
		if (bytes(aaveV3.context.network).length == 0) return;

		string memory prefix = string.concat("Aave V3 ", aaveV3.context.protocol, ": ");

		label(aaveV3.aclAdmin, string.concat(prefix, "ACLAdmin"));
		label(address(aaveV3.aclManager), string.concat(prefix, "ACLManager"));
		label(address(aaveV3.addressesProvider), string.concat(prefix, "PoolAddressesProvider"));
		label(address(aaveV3.dataProvider), string.concat(prefix, "PoolDataProvider"));
		label(address(aaveV3.pool), string.concat(prefix, "Pool"));
		label(address(aaveV3.oracle), string.concat(prefix, "PriceOracle"));
		label(address(aaveV3.rewardsController), string.concat(prefix, "RewardsController"));
		label(address(aaveV3.emissionManager), string.concat(prefix, "EmissionManager"));
		label(address(aaveV3.collector), string.concat(prefix, "Collector"));
	}

	function labelAaveMarket(AaveMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		string memory prefix = string.concat(aaveV3.context.abbreviation, market.symbol);

		label(market.underlying.toAddress(), market.symbol);
		label(address(market.aToken), string.concat("a", prefix));
		label(address(market.vdToken), string.concat("variableDebt", prefix));
	}

	function labelComet() internal virtual {
		if (compV3.governor == address(0)) return;

		label(compV3.governor, "CometGovernor");
		label(address(compV3.configurator), "CometConfigurator");
		label(address(compV3.rewards), "CometRewards");
	}

	function labelCometMarket(CometMarket memory market) internal virtual {
		if (bytes(market.symbol).length == 0) return;

		label(market.underlying.toAddress(), market.base);
		label(address(market.comet), market.symbol);

		for (uint256 i; i < market.assets.length; ++i) {
			label(market.assets[i].underlying.toAddress(), market.assets[i].symbol);
		}
	}
}
