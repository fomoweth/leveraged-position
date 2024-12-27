// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IACLManager} from "src/interfaces/external/aave/v3/IACLManager.sol";
import {IPoolAddressesProvider} from "src/interfaces/external/aave/v3/IPoolAddressesProvider.sol";
import {IPoolDataProvider} from "src/interfaces/external/aave/v3/IPoolDataProvider.sol";
import {IPoolConfigurator} from "src/interfaces/external/aave/v3/IPoolConfigurator.sol";
import {IPool} from "src/interfaces/external/aave/v3/IPool.sol";
import {IRewardsController} from "src/interfaces/external/Aave/V3/IRewardsController.sol";

import {IAaveOracle} from "src/interfaces/external/aave/IAaveOracle.sol";
import {IAToken} from "src/interfaces/external/aave/IAToken.sol";
import {IStableDebtToken} from "src/interfaces/external/aave/IStableDebtToken.sol";
import {IVariableDebtToken} from "src/interfaces/external/aave/IVariableDebtToken.sol";
import {IEmissionManager} from "src/interfaces/external/aave/IEmissionManager.sol";
import {ICollector} from "src/interfaces/external/aave/ICollector.sol";

import {IAggregator} from "src/interfaces/external/chainlink/IAggregator.sol";

import {IComet} from "src/interfaces/external/compound/v3/IComet.sol";
import {ICometPriceFeed} from "src/interfaces/external/compound/v3/ICometPriceFeed.sol";
import {ICometRewards} from "src/interfaces/external/compound/v3/ICometRewards.sol";
import {IConfigurator} from "src/interfaces/external/compound/v3/IConfigurator.sol";

import {Currency} from "src/types/Currency.sol";

struct Context {
	string abbreviation;
	string network;
	string protocol;
}

struct AaveV3Config {
	bytes32 id;
	Context context;
	address aclAdmin;
	IACLManager aclManager;
	IPoolAddressesProvider addressesProvider;
	IPoolDataProvider dataProvider;
	IPool pool;
	IPoolConfigurator poolConfigurator;
	IAaveOracle oracle;
	IRewardsController rewardsController;
	IEmissionManager emissionManager;
	ICollector collector;
}

struct AaveMarket {
	string symbol;
	Currency underlying;
	IAToken aToken;
	IVariableDebtToken vdToken;
	IAggregator oracle;
	uint16 ltv;
	bool isCollateral;
	bool isBorrowable;
	bool isIsolated;
}

struct AaveV3ConfigRaw {
	address aclAdmin;
	address aclManager;
	address addressesProvider;
	address collector;
	Context context;
	address dataProvider;
	address emissionManager;
	address oracle;
	address pool;
	address poolConfigurator;
	address rewardsController;
}

struct AaveMarketRaw {
	address aToken;
	bool isBorrowable;
	bool isCollateral;
	bool isIsolated;
	uint16 ltv;
	address oracle;
	string symbol;
	address underlying;
	address vdToken;
}

function parseAaveV3(bytes memory data) pure returns (AaveV3Config memory) {
	AaveV3ConfigRaw memory raw = abi.decode(data, (AaveV3ConfigRaw));

	return
		AaveV3Config({
			id: bytes32(bytes(string.concat("Aave V3 ", raw.context.protocol))),
			context: raw.context,
			aclAdmin: raw.aclAdmin,
			aclManager: IACLManager(raw.aclManager),
			addressesProvider: IPoolAddressesProvider(raw.addressesProvider),
			dataProvider: IPoolDataProvider(raw.dataProvider),
			pool: IPool(raw.pool),
			poolConfigurator: IPoolConfigurator(raw.poolConfigurator),
			oracle: IAaveOracle(raw.oracle),
			rewardsController: IRewardsController(raw.rewardsController),
			emissionManager: IEmissionManager(raw.emissionManager),
			collector: ICollector(raw.collector)
		});
}

function parseAaveMarkets(bytes memory data) pure returns (AaveMarket[] memory markets) {
	AaveMarketRaw[] memory rawMarkets = abi.decode(data, (AaveMarketRaw[]));

	uint256 length = rawMarkets.length;
	uint256 count;

	markets = new AaveMarket[](length);

	for (uint256 i; i < length; ++i) {
		if (!rawMarkets[i].isCollateral && !rawMarkets[i].isBorrowable) continue;

		markets[i] = AaveMarket({
			symbol: rawMarkets[i].symbol,
			underlying: Currency.wrap(rawMarkets[i].underlying),
			aToken: IAToken(rawMarkets[i].aToken),
			vdToken: IVariableDebtToken(rawMarkets[i].vdToken),
			oracle: IAggregator(rawMarkets[i].oracle),
			ltv: rawMarkets[i].ltv,
			isCollateral: rawMarkets[i].isCollateral,
			isBorrowable: rawMarkets[i].isBorrowable,
			isIsolated: rawMarkets[i].isIsolated
		});

		++count;
	}

	assembly ("memory-safe") {
		if xor(length, count) {
			mstore(markets, count)
		}
	}
}

struct CometConfig {
	address governor;
	IConfigurator configurator;
	ICometRewards rewards;
}

struct CometConfigRaw {
	address configurator;
	address governor;
	address rewards;
}

struct CometMarket {
	bytes32 id;
	string symbol;
	IComet comet;
	string base;
	Currency underlying;
	ICometPriceFeed feed;
	CometAsset[] assets;
}

struct CometMarketRaw {
	CometAssetRaw[] assets;
	string base;
	address comet;
	address feed;
	string symbol;
	address underlying;
}

struct CometAsset {
	string symbol;
	Currency underlying;
	ICometPriceFeed feed;
	uint16 ltv;
}

struct CometAssetRaw {
	address feed;
	uint16 ltv;
	string symbol;
	address underlying;
}

function parseComet(bytes memory data) pure returns (CometConfig memory) {
	CometConfigRaw memory raw = abi.decode(data, (CometConfigRaw));

	return
		CometConfig({
			governor: raw.governor,
			configurator: IConfigurator(raw.configurator),
			rewards: ICometRewards(raw.rewards)
		});
}

function parseCometMarket(bytes memory data) pure returns (CometMarket memory) {
	CometMarketRaw memory rawMarket = abi.decode(data, (CometMarketRaw));

	CometAsset[] memory assets = new CometAsset[](rawMarket.assets.length);

	for (uint256 i; i < rawMarket.assets.length; ++i) {
		assets[i] = CometAsset({
			symbol: rawMarket.assets[i].symbol,
			underlying: Currency.wrap(rawMarket.assets[i].underlying),
			feed: ICometPriceFeed(rawMarket.assets[i].feed),
			ltv: rawMarket.assets[i].ltv
		});
	}

	return
		CometMarket({
			id: bytes32(bytes(string.concat("Comet ", rawMarket.base))),
			symbol: rawMarket.symbol,
			comet: IComet(rawMarket.comet),
			base: rawMarket.base,
			underlying: Currency.wrap(rawMarket.underlying),
			feed: ICometPriceFeed(rawMarket.feed),
			assets: assets
		});
}

function parseCometMarkets(bytes memory data) pure returns (CometMarket[] memory markets) {
	CometMarketRaw[] memory rawMarkets = abi.decode(data, (CometMarketRaw[]));

	markets = new CometMarket[](rawMarkets.length);

	for (uint256 i; i < rawMarkets.length; ++i) {
		CometAsset[] memory assets = new CometAsset[](rawMarkets[i].assets.length);

		for (uint256 j; j < assets.length; ++j) {
			assets[j] = CometAsset({
				symbol: rawMarkets[i].assets[j].symbol,
				underlying: Currency.wrap(rawMarkets[i].assets[j].underlying),
				feed: ICometPriceFeed(rawMarkets[i].assets[j].feed),
				ltv: rawMarkets[i].assets[j].ltv
			});
		}

		markets[i] = CometMarket({
			id: bytes32(bytes(string.concat("Comet ", rawMarkets[i].base))),
			symbol: rawMarkets[i].symbol,
			comet: IComet(rawMarkets[i].comet),
			base: rawMarkets[i].base,
			underlying: Currency.wrap(rawMarkets[i].underlying),
			feed: ICometPriceFeed(rawMarkets[i].feed),
			assets: assets
		});
	}
}
