// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface ILender {
	function supply(Currency currency, uint256 amount) external payable returns (int256);

	function borrow(Currency currency, uint256 amount) external payable returns (int256);

	function repay(Currency currency, uint256 amount) external payable returns (int256);

	function redeem(Currency currency, uint256 amount) external payable returns (int256);

	function claim(address recipient) external payable;

	function getReservesIn(address account) external view returns (Currency[] memory);

	function getReservesList() external view returns (Currency[] memory);

	function getRewardsList() external view returns (Currency[] memory);

	function getAccountLiquidity(
		address account
	)
		external
		view
		returns (
			uint256 totalCollateralInBase,
			uint256 totalDebtInBase,
			uint256 availableBorrowsInBase,
			uint256 collateralUsage,
			uint256 healthFactor
		);

	function getAccountCollateral(Currency currency, address account) external view returns (uint256);

	function getAccountLiability(Currency currency, address account) external view returns (uint256);

	function getAccruedRewards(address account) external view returns (Currency[] memory, uint256[] memory);

	function getAvailableLiquidity(Currency currency) external view returns (uint256);

	function getCollateralFactor(Currency currency) external view returns (uint256);

	function getLiquidationFactor(Currency currency) external view returns (uint256);

	function getRatio(Currency currency) external view returns (uint256);

	function getPrice(Currency currency) external view returns (uint256);

	function PROTOCOL() external view returns (bytes32);
}
