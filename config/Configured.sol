// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "lib/forge-std/src/Vm.sol";

import {Currency} from "src/types/Currency.sol";

import {AaveV3Config, AaveMarket, CometConfig, CometMarket} from "test/shared/Protocols.sol";

import {Config} from "./Config.sol";

contract Configured {
	Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

	uint256 private constant ETHEREUM_CHAIN_ID = 1;
	uint256 private constant OPTIMISM_CHAIN_ID = 10;
	uint256 private constant POLYGON_CHAIN_ID = 137;
	uint256 private constant ARBITRUM_CHAIN_ID = 42161;

	string internal constant ETHEREUM_NETWORK = "ethereum";
	string internal constant OPTIMISM_NETWORK = "optimism";
	string internal constant POLYGON_NETWORK = "polygon";
	string internal constant ARBITRUM_NETWORK = "arbitrum";

	Config internal config;

	string internal network;

	Currency internal WNATIVE;
	Currency internal WETH;
	Currency internal STETH;
	Currency internal WSTETH;
	Currency internal WBTC;

	Currency internal DAI;
	Currency internal USDC;
	Currency internal USDCe;
	Currency internal USDT;

	Currency internal AAVE;
	Currency internal COMP;
	Currency internal LINK;
	Currency internal UNI;

	Currency[] internal allAssets;
	Currency[] internal intermediateCurrencies;
	Currency[] internal stablecoins;

	AaveV3Config internal aaveV3;
	CometConfig internal compV3;

	function configure() internal virtual {
		uint256 chainId = block.chainid;

		if (chainId == 0) {
			revert("chain id must be specified (`--chain <chainid>`)");
		} else if (chainId == ETHEREUM_CHAIN_ID) {
			network = ETHEREUM_NETWORK;
		} else if (chainId == OPTIMISM_CHAIN_ID) {
			network = OPTIMISM_NETWORK;
		} else if (chainId == POLYGON_CHAIN_ID) {
			network = POLYGON_NETWORK;
		} else if (chainId == ARBITRUM_CHAIN_ID) {
			network = ARBITRUM_NETWORK;
		} else {
			revert(string.concat("Unsupported chain: ", vm.toString(chainId)));
		}

		if (bytes(config.json).length == 0) {
			string memory root = vm.projectRoot();
			string memory path = string.concat(root, "/config/", network, ".json");

			config.json = vm.readFile(path);
		}

		configureAssets();
	}

	function configureAssets() internal virtual {
		WNATIVE = config.getWrappedNative();
		WETH = config.getCurrency("WETH");
		STETH = config.getCurrency("stETH");
		WSTETH = config.getCurrency("wstETH");
		WBTC = config.getCurrency("WBTC");

		DAI = config.getCurrency("DAI");
		USDC = config.getCurrency("USDC");
		USDCe = config.getCurrency("USDCe");
		USDT = config.getCurrency("USDT");

		AAVE = config.getCurrency("AAVE");
		COMP = config.getCurrency("COMP");
		LINK = config.getCurrency("LINK");
		UNI = config.getCurrency("UNI");

		intermediateCurrencies = config.getIntermediateCurrencies();
		stablecoins = config.getStablecoins();
	}

	function configureAaveV3(string memory key) internal virtual {
		aaveV3 = config.getAaveV3Config(vm.toLowercase(key));
	}

	function configureCompoundV3() internal virtual {
		compV3 = config.getCompoundV3Config();
	}

	function getAaveV3Markets(string memory key) internal view virtual returns (AaveMarket[] memory) {
		return config.getAaveV3Markets(vm.toLowercase(key));
	}

	function getCometMarkets() internal view virtual returns (CometMarket[] memory) {
		return config.getCometMarkets();
	}

	function getChainId() internal view virtual returns (uint256) {
		return config.getChainId();
	}

	function getForkBlockNumber() internal view virtual returns (uint256) {
		return config.getForkBlockNumber();
	}

	function rpcAlias() internal view virtual returns (string memory) {
		return config.getRpcAlias();
	}
}
