// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ILeveragedPosition {
	event CheckpointSet(Currency indexed currency, uint256 indexed index, uint256 indexed state);

	event CheckpointUpdated(Currency indexed currency, uint256 indexed index, uint256 indexed state);

	event LiquidityUpdated(Currency indexed currency, int256 indexed delta, uint8 indexed side);

	event PrincipalUpdated(Currency indexed currency, int256 indexed delta);

	event LtvBoundsSet(uint256 indexed upperBound, uint256 indexed lowerBound, uint256 indexed medianBound);
	event LtvBoundsUpdated(uint256 indexed upperBound, uint256 indexed lowerBound, uint256 indexed medianBound);

	struct IncreaseLiquidityParams {
		uint256 amountToDeposit;
		bytes path;
	}

	function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable;

	struct DecreaseLiquidityParams {
		uint256 amountToWithdraw;
		bool shouldClaim;
		bytes path;
	}

	function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable;

	struct ModifyLiquidityParams {
		uint256 amountPrincipal;
		bool shouldClaim;
		bytes path;
	}

	function modifyLiquidity(ModifyLiquidityParams calldata params) external payable;

	function checkpointsLengthOf(Currency currency) external view returns (uint256);

	function checkpointOf(
		Currency currency,
		uint256 index
	) external view returns (uint128 ratio, uint80 roundId, uint40 updatedAt);

	function liquidityOf(
		Currency currency
	) external view returns (int104 liquidity, uint104 reserveIndex, uint40 accrualTime, uint8 side);

	function ltvBounds() external view returns (uint16 upperBound, uint16 lowerBound, uint16 medianBound);

	// function principalOf(Currency currency) external view returns (int256);

	// function principal() external view returns (int256);

	function lender() external view returns (address);

	function collateralAsset() external view returns (Currency);

	function liabilityAsset() external view returns (Currency);
}
