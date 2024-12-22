// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {ICometExt} from "./ICometExt.sol";
import {ICometPriceFeed} from "./ICometPriceFeed.sol";

interface IComet is ICometExt {
	struct AssetInfo {
		uint8 offset;
		Currency asset;
		ICometPriceFeed priceFeed;
		uint64 scale;
		uint64 borrowCollateralFactor;
		uint64 liquidateCollateralFactor;
		uint64 liquidationFactor;
		uint128 supplyCap;
	}

	event Supply(address indexed from, address indexed dst, uint256 amount);
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Withdraw(address indexed src, address indexed to, uint256 amount);

	event SupplyCollateral(address indexed from, address indexed dst, Currency indexed asset, uint256 amount);
	event TransferCollateral(address indexed from, address indexed to, Currency indexed asset, uint256 amount);
	event WithdrawCollateral(address indexed src, address indexed to, Currency indexed asset, uint256 amount);

	event AbsorbDebt(address indexed absorber, address indexed borrower, uint256 basePaidOut, uint256 usdValue);

	event AbsorbCollateral(
		address indexed absorber,
		address indexed borrower,
		Currency indexed asset,
		uint256 collateralAbsorbed,
		uint256 usdValue
	);

	event BuyCollateral(address indexed buyer, Currency indexed asset, uint256 baseAmount, uint256 collateralAmount);

	event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);

	event WithdrawReserves(address indexed to, uint256 amount);

	function supply(Currency asset, uint256 amount) external;

	function supplyTo(address dst, Currency asset, uint256 amount) external;

	function supplyFrom(address from, address dst, Currency asset, uint256 amount) external;

	function transfer(address dst, uint256 amount) external returns (bool);

	function transferFrom(address src, address dst, uint256 amount) external returns (bool);

	function transferAsset(address dst, Currency asset, uint256 amount) external;

	function transferAssetFrom(address src, address dst, Currency asset, uint256 amount) external;

	function withdraw(Currency asset, uint256 amount) external;

	function withdrawTo(address to, Currency asset, uint256 amount) external;

	function withdrawFrom(address src, address to, Currency asset, uint256 amount) external;

	function withdrawReserves(address to, uint256 amount) external;

	function approveThis(address manager, Currency asset, uint256 amount) external;

	function absorb(address absorber, address[] calldata accounts) external;

	function buyCollateral(Currency asset, uint256 minAmount, uint256 baseAmount, address recipient) external;

	function quoteCollateral(Currency asset, uint256 baseAmount) external view returns (uint256);

	function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

	function getAssetInfoByAddress(Currency asset) external view returns (AssetInfo memory);

	function getCollateralReserves(Currency asset) external view returns (uint256);

	function getReserves() external view returns (int256);

	function getPrice(ICometPriceFeed priceFeed) external view returns (uint256);

	function hasPermission(address owner, address manager) external view returns (bool);

	function isAllowed(address owner, address manager) external view returns (bool);

	function isBorrowCollateralized(address account) external view returns (bool);

	function isLiquidatable(address account) external view returns (bool);

	function totalSupply() external view returns (uint256);

	function totalBorrow() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function borrowBalanceOf(address account) external view returns (uint256);

	function pause(
		bool supplyPaused,
		bool transferPaused,
		bool withdrawPaused,
		bool absorbPaused,
		bool buyPaused
	) external;

	function isSupplyPaused() external view returns (bool);

	function isTransferPaused() external view returns (bool);

	function isWithdrawPaused() external view returns (bool);

	function isAbsorbPaused() external view returns (bool);

	function isBuyPaused() external view returns (bool);

	function accrueAccount(address account) external;

	function getSupplyRate(uint256 utilization) external view returns (uint64);

	function getBorrowRate(uint256 utilization) external view returns (uint64);

	function getUtilization() external view returns (uint256);

	function governor() external view returns (address);

	function pauseGuardian() external view returns (address);

	function baseToken() external view returns (Currency);

	function baseTokenPriceFeed() external view returns (ICometPriceFeed);

	function extensionDelegate() external view returns (ICometExt);

	function supplyKink() external view returns (uint64);

	function supplyPerSecondInterestRateSlopeLow() external view returns (uint64);

	function supplyPerSecondInterestRateSlopeHigh() external view returns (uint64);

	function supplyPerSecondInterestRateBase() external view returns (uint64);

	function borrowKink() external view returns (uint64);

	function borrowPerSecondInterestRateSlopeLow() external view returns (uint64);

	function borrowPerSecondInterestRateSlopeHigh() external view returns (uint64);

	function borrowPerSecondInterestRateBase() external view returns (uint64);

	function storeFrontPriceFactor() external view returns (uint64);

	function baseScale() external view returns (uint64);

	function trackingIndexScale() external view returns (uint64);

	function baseTrackingSupplySpeed() external view returns (uint64);

	function baseTrackingBorrowSpeed() external view returns (uint64);

	function baseMinForRewards() external view returns (uint104);

	function baseBorrowMin() external view returns (uint104);

	function targetReserves() external view returns (uint104);

	function numAssets() external view returns (uint8);

	function decimals() external view returns (uint8);

	function initializeStorage() external;

	function userNonce(address account) external view returns (uint256);
}
