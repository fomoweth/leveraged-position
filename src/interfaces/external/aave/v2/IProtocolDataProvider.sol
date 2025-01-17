// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IProtocolDataProvider {
	struct TokenData {
		string symbol;
		Currency tokenAddress;
	}

	function getAllReservesTokens() external view returns (TokenData[] memory);

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

	function getReserveData(
		Currency asset
	)
		external
		view
		returns (
			uint256 availableLiquidity,
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
}
