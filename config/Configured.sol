// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Vm} from "lib/forge-std/src/Vm.sol";

import {Currency} from "src/types/Currency.sol";

import {AaveV3Config, AaveMarket, CometConfig, CometMarket} from "test/shared/Protocols.sol";

import {Config} from "./Config.sol";

contract Configured {
	Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

	Config internal config;

	Currency internal WETH;
	Currency internal STETH;
	Currency internal WSTETH;
	Currency internal WEETH;

	Currency internal DAI;
	Currency internal FRAX;
	Currency internal USDC;
	Currency internal USDT;

	Currency internal WBTC;
	Currency internal AAVE;
	Currency internal COMP;
	Currency internal LINK;
	Currency internal UNI;

	Currency[] internal allAssets;
	Currency[] internal intermediateCurrencies;

	AaveV3Config internal aaveV3;
	CometConfig internal compV3;

	function configure() internal virtual {
		if (bytes(config.json).length == 0) {
			string memory root = vm.projectRoot();
			string memory path = string.concat(root, "/config/ethereum.json");

			config.json = vm.readFile(path);
		}

		configureAssets();
	}

	function configureAssets() internal virtual {
		WETH = config.getCurrency("WETH");
		STETH = config.getCurrency("stETH");
		WSTETH = config.getCurrency("wstETH");
		WEETH = config.getCurrency("weETH");

		DAI = config.getCurrency("DAI");
		FRAX = config.getCurrency("FRAX");
		USDC = config.getCurrency("USDC");
		USDT = config.getCurrency("USDT");

		WBTC = config.getCurrency("WBTC");
		AAVE = config.getCurrency("AAVE");
		COMP = config.getCurrency("COMP");
		LINK = config.getCurrency("LINK");
		UNI = config.getCurrency("UNI");

		intermediateCurrencies = config.getIntermediateCurrencies();
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

	function getCometMarket(string memory key) internal view virtual returns (CometMarket memory) {
		return config.getCometMarket(key);
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
