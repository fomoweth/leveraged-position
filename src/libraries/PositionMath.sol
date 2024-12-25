// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Math} from "./Math.sol";
import {PercentageMath} from "./PercentageMath.sol";
import {WadRayMath} from "./WadRayMath.sol";

/// @title PositionMath
/// @notice Provides functions to perform position's liquidity calculations

library PositionMath {
	using Math for uint256;
	using PercentageMath for uint256;
	using WadRayMath for uint256;

	function computePositionLiquidity(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale,
		uint256 collateralFactor,
		uint256 liquidationFactor
	)
		internal
		pure
		returns (
			uint256 totalCollateralInBase,
			uint256 totalDebtInBase,
			uint256 availableBorrowsInBase,
			uint256 principalInBase,
			uint256 collateralUsage,
			uint256 healthFactor
		)
	{
		if (totalCollateral != 0 && collateralFactor != 0 && liquidationFactor != 0) {
			totalCollateralInBase = convertToBase(totalCollateral, collateralPrice, collateralScale);

			uint256 availableLiquidityInBase = totalCollateralInBase.percentMul(collateralFactor);

			totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

			availableBorrowsInBase = availableLiquidityInBase.zeroFloorSub(totalDebtInBase);

			principalInBase = totalCollateralInBase - totalDebtInBase;

			(collateralUsage, healthFactor) = totalDebtInBase != 0
				? (
					totalDebtInBase.percentDiv(availableLiquidityInBase),
					totalCollateralInBase.percentMul(liquidationFactor).wadDiv(totalDebtInBase)
				)
				: (0, Math.MAX_UINT256);
		}
	}

	function computePrincipal(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale
	) internal pure returns (uint256) {
		if (totalCollateral == 0) return 0;

		uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

		return totalCollateral.zeroFloorSub(convertFromBase(totalDebtInBase, collateralPrice, collateralScale));
	}

	function computeLeverage(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale
	) internal pure returns (uint256) {
		if (totalCollateral == 0 || totalDebt == 0) return 0;

		uint256 totalCollateralInBase = convertToBase(totalCollateral, collateralPrice, collateralScale);

		uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

		return totalCollateralInBase.percentDiv(totalCollateralInBase.sub(totalDebtInBase));
	}

	function computeCollateralUsage(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale,
		uint256 collateralFactor
	) internal pure returns (uint256) {
		require(collateralFactor != 0);

		if (totalCollateral == 0 || totalDebt == 0) return 0;

		uint256 totalCollateralInBase = convertToBase(totalCollateral, collateralPrice, collateralScale);

		uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

		return totalDebtInBase.percentDiv(totalCollateralInBase.percentMul(collateralFactor));
	}

	function computeHealthFactor(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale,
		uint256 liquidationFactor
	) internal pure returns (uint256) {
		require(liquidationFactor != 0);

		if (totalCollateral == 0) return 0;
		if (totalDebt == 0) return Math.MAX_UINT256;

		uint256 totalCollateralInBase = convertToBase(totalCollateral, collateralPrice, collateralScale);

		uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

		return totalCollateralInBase.percentMul(liquidationFactor).wadDiv(totalDebtInBase);
	}

	function computeAvailableBorrows(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale,
		uint256 collateralFactor
	) internal pure returns (uint256) {
		if (totalCollateral != 0 && collateralFactor != 0) {
			uint256 availableLiquidityInBase = convertToBase(
				totalCollateral.percentMul(collateralFactor),
				collateralPrice,
				collateralScale
			);

			uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

			if (availableLiquidityInBase > totalDebtInBase) {
				return convertFromBase(availableLiquidityInBase.sub(totalDebtInBase), liabilityPrice, liabilityScale);
			}
		}

		return 0;
	}

	function computeLiability(
		uint256 totalCollateral,
		uint256 totalDebt,
		uint256 collateralPrice,
		uint256 liabilityPrice,
		uint256 collateralScale,
		uint256 liabilityScale,
		uint256 collateralFactor,
		uint256 ltvUpperBound,
		uint256 ltvLowerBound
	) internal pure returns (uint256 amountToBorrow, uint256 amountToRepay) {
		if (totalCollateral == 0 || collateralFactor == 0 || ltvUpperBound == 0) return (0, totalDebt);

		uint256 availableLiquidityInBase = convertToBase(
			totalCollateral.percentMul(collateralFactor),
			collateralPrice,
			collateralScale
		);

		uint256 totalDebtInBase = convertToBase(totalDebt, liabilityPrice, liabilityScale);

		if (availableLiquidityInBase <= totalDebtInBase) return (0, totalDebt);

		uint256 availableBorrows = convertFromBase(
			availableLiquidityInBase.sub(totalDebtInBase),
			liabilityPrice,
			liabilityScale
		);

		uint256 maxBorrowLimit = availableBorrows.percentMul(ltvUpperBound);
		uint256 minBorrowLimit = availableBorrows.percentMul(ltvLowerBound);

		if (totalDebt > maxBorrowLimit) {
			amountToRepay = totalDebt.sub(minBorrowLimit);
		} else if (totalDebt < minBorrowLimit) {
			amountToBorrow = minBorrowLimit.sub(totalDebt);
		}
	}

	function convertToBase(uint256 amount, uint256 price, uint256 scale) internal pure returns (uint256) {
		if (amount == 0) return 0;
		return amount.mulDiv(price, scale);
	}

	function convertFromBase(uint256 amount, uint256 price, uint256 scale) internal pure returns (uint256) {
		if (amount == 0) return 0;
		return amount.mulDiv(scale, price);
	}
}
