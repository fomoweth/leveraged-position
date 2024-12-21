// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

interface IPoolDataProvider {
	struct TokenData {
		string symbol;
		Currency tokenAddress;
	}

	function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

	function getAllReservesTokens() external view returns (TokenData[] memory);

	function getAllATokens() external view returns (TokenData[] memory);

	function getReserveConfigurationData(
		Currency asset
	)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool usageAsCollateralEnabled,
			bool borrowingEnabled,
			bool stableBorrowRateEnabled,
			bool isActive,
			bool isFrozen
		);

	function getReserveEModeCategory(Currency asset) external view returns (uint256);

	function getReserveCaps(Currency asset) external view returns (uint256 borrowCap, uint256 supplyCap);

	function getPaused(Currency asset) external view returns (bool isPaused);

	function getSiloedBorrowing(Currency asset) external view returns (bool);

	function getLiquidationProtocolFee(Currency asset) external view returns (uint256);

	function getUnbackedMintCap(Currency asset) external view returns (uint256);

	function getDebtCeiling(Currency asset) external view returns (uint256);

	function getDebtCeilingDecimals() external pure returns (uint256);

	function getReserveData(
		Currency asset
	)
		external
		view
		returns (
			uint256 unbacked,
			uint256 accruedToTreasuryScaled,
			uint256 totalAToken,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableBorrowRate,
			uint256 stableBorrowRate,
			uint256 averageStableBorrowRate,
			uint256 liquidityIndex,
			uint256 variableBorrowIndex,
			uint40 lastUpdateTimestamp
		);

	function getATokenTotalSupply(Currency asset) external view returns (uint256);

	function getTotalDebt(Currency asset) external view returns (uint256);

	function getUserReserveData(
		Currency asset,
		address user
	)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);

	function getReserveTokensAddresses(
		Currency asset
	)
		external
		view
		returns (Currency aTokenAddress, Currency stableDebtTokenAddress, Currency variableDebtTokenAddress);

	function getInterestRateStrategyAddress(Currency asset) external view returns (address irStrategyAddress);

	function getFlashLoanEnabled(Currency asset) external view returns (bool);

	function getIsVirtualAccActive(Currency asset) external view returns (bool);

	function getVirtualUnderlyingBalance(Currency asset) external view returns (uint256);
}
