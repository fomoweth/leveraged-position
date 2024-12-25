// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ILender} from "src/interfaces/ILender.sol";
import {PositionMath} from "src/libraries/PositionMath.sol";
import {Currency} from "src/types/Currency.sol";
import {LeveragedPosition} from "src/LeveragedPosition.sol";

library PositionUtils {
	using PositionMath for uint256;
	using PositionUtils for LeveragedPosition;

	function getPrincipal(LeveragedPosition position) internal view returns (uint256) {
		ILender lender = position.getLender();
		Currency collateralAsset = position.COLLATERAL_ASSET();
		Currency liabilityAsset = position.LIABILITY_ASSET();

		return
			PositionMath.computePrincipal(
				lender.getAccountCollateral(collateralAsset, address(position)),
				lender.getAccountLiability(liabilityAsset, address(position)),
				lender.getPrice(collateralAsset),
				lender.getPrice(liabilityAsset),
				10 ** collateralAsset.decimals(),
				10 ** liabilityAsset.decimals()
			);
	}

	function getLeverage(LeveragedPosition position) internal view returns (uint256) {
		ILender lender = position.getLender();
		Currency collateralAsset = position.COLLATERAL_ASSET();
		Currency liabilityAsset = position.LIABILITY_ASSET();

		return
			PositionMath.computeLeverage(
				lender.getAccountCollateral(collateralAsset, address(position)),
				lender.getAccountLiability(liabilityAsset, address(position)),
				lender.getPrice(collateralAsset),
				lender.getPrice(liabilityAsset),
				10 ** collateralAsset.decimals(),
				10 ** liabilityAsset.decimals()
			);
	}

	function getCollateralUsage(LeveragedPosition position) internal view returns (uint256) {
		ILender lender = position.getLender();
		Currency collateralAsset = position.COLLATERAL_ASSET();
		Currency liabilityAsset = position.LIABILITY_ASSET();

		return
			PositionMath.computeCollateralUsage(
				lender.getAccountCollateral(collateralAsset, address(position)),
				lender.getAccountLiability(liabilityAsset, address(position)),
				lender.getPrice(collateralAsset),
				lender.getPrice(liabilityAsset),
				10 ** collateralAsset.decimals(),
				10 ** liabilityAsset.decimals(),
				lender.getCollateralFactor(collateralAsset)
			);
	}

	function getHealthFactor(LeveragedPosition position) internal view returns (uint256 healthFactor) {
		ILender lender = position.getLender();
		Currency collateralAsset = position.COLLATERAL_ASSET();
		Currency liabilityAsset = position.LIABILITY_ASSET();

		return
			PositionMath.computeHealthFactor(
				lender.getAccountCollateral(collateralAsset, address(position)),
				lender.getAccountLiability(liabilityAsset, address(position)),
				lender.getPrice(collateralAsset),
				lender.getPrice(liabilityAsset),
				10 ** collateralAsset.decimals(),
				10 ** liabilityAsset.decimals(),
				lender.getLiquidationFactor(collateralAsset)
			);
	}

	function getCollateralBalance(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getAccountCollateral(position.COLLATERAL_ASSET(), address(position));
	}

	function getLiabilityBalance(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getAccountLiability(position.LIABILITY_ASSET(), address(position));
	}

	function getCollateralFactor(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getCollateralFactor(position.COLLATERAL_ASSET());
	}

	function getLiquidationFactor(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getLiquidationFactor(position.COLLATERAL_ASSET());
	}

	function getPrice(LeveragedPosition position, Currency currency) internal view returns (uint256) {
		return position.getLender().getPrice(currency);
	}

	function getCollateralPrice(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getPrice(position.COLLATERAL_ASSET());
	}

	function getLiabilityPrice(LeveragedPosition position) internal view returns (uint256) {
		return position.getLender().getPrice(position.LIABILITY_ASSET());
	}

	function getLender(LeveragedPosition position) internal view returns (ILender) {
		return ILender(position.LENDER());
	}
}
