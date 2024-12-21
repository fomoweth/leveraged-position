// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IConfigurator {
	struct Configuration {
		address governor;
		address pauseGuardian;
		Currency baseToken;
		address baseTokenPriceFeed;
		address extensionDelegate;
		uint64 supplyKink;
		uint64 supplyPerYearInterestRateSlopeLow;
		uint64 supplyPerYearInterestRateSlopeHigh;
		uint64 supplyPerYearInterestRateBase;
		uint64 borrowKink;
		uint64 borrowPerYearInterestRateSlopeLow;
		uint64 borrowPerYearInterestRateSlopeHigh;
		uint64 borrowPerYearInterestRateBase;
		uint64 storeFrontPriceFactor;
		uint64 trackingIndexScale;
		uint64 baseTrackingSupplySpeed;
		uint64 baseTrackingBorrowSpeed;
		uint104 baseMinForRewards;
		uint104 baseBorrowMin;
		uint104 targetReserves;
		AssetConfig[] assetConfigs;
	}

	struct AssetConfig {
		Currency asset;
		address priceFeed;
		uint8 decimals;
		uint64 borrowCollateralFactor;
		uint64 liquidateCollateralFactor;
		uint64 liquidationFactor;
		uint128 supplyCap;
	}

	// events

	event AddAsset(address indexed cometProxy, AssetConfig assetConfig);

	event CometDeployed(address indexed cometProxy, address indexed newComet);

	event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);

	event SetFactory(address indexed cometProxy, address indexed oldFactory, address indexed newFactory);

	event SetGovernor(address indexed cometProxy, address indexed oldGovernor, address indexed newGovernor);

	event SetConfiguration(address indexed cometProxy, Configuration oldConfiguration, Configuration newConfiguration);

	event SetPauseGuardian(
		address indexed cometProxy,
		address indexed oldPauseGuardian,
		address indexed newPauseGuardian
	);

	event SetBaseTokenPriceFeed(
		address indexed cometProxy,
		address indexed oldBaseTokenPriceFeed,
		address indexed newBaseTokenPriceFeed
	);

	event SetExtensionDelegate(address indexed cometProxy, address indexed oldExt, address indexed newExt);

	event SetSupplyKink(address indexed cometProxy, uint64 oldKink, uint64 newKink);

	event SetSupplyPerYearInterestRateSlopeLow(address indexed cometProxy, uint64 oldIRSlopeLow, uint64 newIRSlopeLow);

	event SetSupplyPerYearInterestRateSlopeHigh(
		address indexed cometProxy,
		uint64 oldIRSlopeHigh,
		uint64 newIRSlopeHigh
	);

	event SetSupplyPerYearInterestRateBase(address indexed cometProxy, uint64 oldIRBase, uint64 newIRBase);

	event SetBorrowKink(address indexed cometProxy, uint64 oldKink, uint64 newKink);

	event SetBorrowPerYearInterestRateSlopeLow(address indexed cometProxy, uint64 oldIRSlopeLow, uint64 newIRSlopeLow);

	event SetBorrowPerYearInterestRateSlopeHigh(
		address indexed cometProxy,
		uint64 oldIRSlopeHigh,
		uint64 newIRSlopeHigh
	);

	event SetBorrowPerYearInterestRateBase(address indexed cometProxy, uint64 oldIRBase, uint64 newIRBase);

	event SetStoreFrontPriceFactor(
		address indexed cometProxy,
		uint64 oldStoreFrontPriceFactor,
		uint64 newStoreFrontPriceFactor
	);

	event SetBaseTrackingSupplySpeed(
		address indexed cometProxy,
		uint64 oldBaseTrackingSupplySpeed,
		uint64 newBaseTrackingSupplySpeed
	);

	event SetBaseTrackingBorrowSpeed(
		address indexed cometProxy,
		uint64 oldBaseTrackingBorrowSpeed,
		uint64 newBaseTrackingBorrowSpeed
	);

	event SetBaseMinForRewards(address indexed cometProxy, uint104 oldBaseMinForRewards, uint104 newBaseMinForRewards);

	event SetBaseBorrowMin(address indexed cometProxy, uint104 oldBaseBorrowMin, uint104 newBaseBorrowMin);

	event SetTargetReserves(address indexed cometProxy, uint104 oldTargetReserves, uint104 newTargetReserves);

	event UpdateAsset(address indexed cometProxy, AssetConfig oldAssetConfig, AssetConfig newAssetConfig);

	event UpdateAssetPriceFeed(
		address indexed cometProxy,
		Currency indexed asset,
		address oldPriceFeed,
		address newPriceFeed
	);

	event UpdateAssetBorrowCollateralFactor(
		address indexed cometProxy,
		Currency indexed asset,
		uint64 oldBorrowCF,
		uint64 newBorrowCF
	);

	event UpdateAssetLiquidateCollateralFactor(
		address indexed cometProxy,
		Currency indexed asset,
		uint64 oldLiquidateCF,
		uint64 newLiquidateCF
	);

	event UpdateAssetLiquidationFactor(
		address indexed cometProxy,
		Currency indexed asset,
		uint64 oldLiquidationFactor,
		uint64 newLiquidationFactor
	);

	event UpdateAssetSupplyCap(
		address indexed cometProxy,
		Currency indexed asset,
		uint128 oldSupplyCap,
		uint128 newSupplyCap
	);

	function initialize(address governor) external;

	function setFactory(address cometProxy, address newFactory) external;

	function setConfiguration(address cometProxy, Configuration calldata newConfiguration) external;

	function setGovernor(address cometProxy, address newGovernor) external;

	function setBaseTokenPriceFeed(address cometProxy, address newBaseTokenPriceFeed) external;

	function setExtensionDelegate(address cometProxy, address newExtensionDelegate) external;

	function setSupplyKink(address cometProxy, uint64 newSupplyKink) external;

	function setSupplyPerYearInterestRateSlopeLow(address cometProxy, uint64 newSlope) external;

	function setSupplyPerYearInterestRateSlopeHigh(address cometProxy, uint64 newSlope) external;

	function setSupplyPerYearInterestRateBase(address cometProxy, uint64 newBase) external;

	function setBorrowKink(address cometProxy, uint64 newBorrowKink) external;

	function setBorrowPerYearInterestRateSlopeLow(address cometProxy, uint64 newSlope) external;

	function setBorrowPerYearInterestRateSlopeHigh(address cometProxy, uint64 newSlope) external;

	function setBorrowPerYearInterestRateBase(address cometProxy, uint64 newBase) external;

	function setStoreFrontPriceFactor(address cometProxy, uint64 newStoreFrontPriceFactor) external;

	function setBaseTrackingSupplySpeed(address cometProxy, uint64 newBaseTrackingSupplySpeed) external;

	function setBaseTrackingBorrowSpeed(address cometProxy, uint64 newBaseTrackingBorrowSpeed) external;

	function setBaseMinForRewards(address cometProxy, uint104 newBaseMinForRewards) external;

	function setBaseBorrowMin(address cometProxy, uint104 newBaseBorrowMin) external;

	function setTargetReserves(address cometProxy, uint104 newTargetReserves) external;

	function addAsset(address cometProxy, AssetConfig calldata assetConfig) external;

	function updateAsset(address cometProxy, AssetConfig calldata newAssetConfig) external;

	function updateAssetPriceFeed(address cometProxy, Currency asset, address newPriceFeed) external;

	function updateAssetBorrowCollateralFactor(address cometProxy, Currency asset, uint64 newBorrowCF) external;

	function updateAssetLiquidateCollateralFactor(address cometProxy, Currency asset, uint64 newLiquidateCF) external;

	function updateAssetLiquidationFactor(address cometProxy, Currency asset, uint64 newLiquidationFactor) external;

	function updateAssetSupplyCap(address cometProxy, Currency asset, uint128 newSupplyCap) external;

	function getAssetIndex(address cometProxy, Currency asset) external view returns (uint8);

	function getConfiguration(address cometProxy) external view returns (Configuration memory);

	function deploy(address cometProxy) external returns (address);

	function transferGovernor(address newGovernor) external;

	function version() external view returns (uint256);

	function governor() external view returns (address);

	function factory(address cometProxy) external view returns (address);
}
