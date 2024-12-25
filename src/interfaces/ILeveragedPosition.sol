// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ILeveragedPosition {
	event CheckpointSet(Currency indexed currency, uint256 indexed index, uint256 indexed state);

	event LiquidityUpdated(Currency indexed currency, int256 indexed delta, uint8 indexed side);

	event PrincipalUpdated(int256 indexed principal, int256 indexed delta);

	event LtvBoundsSet(uint256 indexed upperBound, uint256 indexed lowerBound, uint256 indexed medianBound);

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

	function addCollateral(uint256 amount) external payable;

	function repayDebt(uint256 amount) external payable;

	function claimRewards(address recipient) external payable;

	function checkpointsLengthOf(Currency currency) external view returns (uint256);

	function checkpointOf(
		Currency currency,
		uint256 index
	) external view returns (uint128 ratio, uint80 roundId, uint40 updatedAt);

	function liquidityOf(
		Currency currency
	) external view returns (int104 liquidity, uint104 reserveIndex, uint40 accrualTime, uint8 side);

	function ltvBounds() external view returns (uint16 upperBound, uint16 lowerBound, uint16 medianBound);

	function principal() external view returns (int256);

	function LENDER() external view returns (address);

	function OWNER() external view returns (address);

	function COLLATERAL_ASSET() external view returns (Currency);

	function LIABILITY_ASSET() external view returns (Currency);

	function REVISION() external view returns (uint256);
}
