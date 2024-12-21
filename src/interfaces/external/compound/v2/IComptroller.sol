// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {ICToken} from "./ICToken.sol";
import {IPriceOracle} from "./IPriceOracle.sol";

interface IComptroller {
	function oracle() external view returns (IPriceOracle);

	function getAllMarkets() external view returns (ICToken[] memory);

	function markets(
		ICToken cToken
	) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped);

	function closeFactorMantissa() external view returns (uint256);

	function liquidationIncentiveMantissa() external view returns (uint256);

	function maxAssets() external view returns (uint256);

	function isDeprecated(ICToken cToken) external view returns (bool);

	function pauseGuardian() external view returns (address);

	function transferGuardianPaused() external view returns (bool);

	function seizeGuardianPaused() external view returns (bool);

	function mintGuardianPaused(ICToken cToken) external view returns (bool);

	function borrowGuardianPaused(ICToken cToken) external view returns (bool);

	function borrowCapGuardian() external view returns (address);

	function borrowCaps(ICToken cToken) external view returns (uint256);

	function enterMarkets(ICToken[] memory cTokens) external returns (uint256[] memory);

	function exitMarket(ICToken cToken) external returns (uint256);

	function getAssetsIn(address account) external view returns (ICToken[] memory);

	function checkMembership(address account, ICToken cToken) external view returns (bool);

	function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

	function getHypotheticalAccountLiquidity(
		address account,
		ICToken cTokenModify,
		uint256 redeemTokens,
		uint256 borrowAmount
	) external view returns (uint256, uint256, uint256);

	function claimComp(address holder) external;

	function claimComp(address holder, ICToken[] memory cTokens) external;

	function compAccrued(address holder) external view returns (uint256);

	function getCompAddress() external view returns (Currency);

	function compRate() external view returns (uint256);

	function compSpeeds(ICToken cToken) external view returns (uint256);

	function compSupplySpeeds(ICToken cToken) external view returns (uint256);

	function compBorrowSpeeds(ICToken cToken) external view returns (uint256);

	function compSupplyState(ICToken cToken) external view returns (uint224, uint32);

	function compBorrowState(ICToken cToken) external view returns (uint224, uint32);

	function compSupplierIndex(ICToken cToken, address supplier) external view returns (uint256);

	function compBorrowerIndex(ICToken cToken, address borrower) external view returns (uint256);

	function compContributorSpeeds(address holder) external view returns (uint256);

	function lastContributorBlock(address holder) external view returns (uint256);

	// Admin Functions

	function admin() external view returns (address);

	function pendingAdmin() external view returns (address);

	function _setPendingAdmin(address newPendingAdmin) external returns (uint256);

	function _acceptAdmin() external returns (uint256);

	function comptrollerImplementation() external view returns (address);

	function pendingComptrollerImplementation() external view returns (address);

	function _setPendingImplementation(address newPendingImplementation) external returns (uint256);

	function _acceptImplementation() external returns (uint256);
}
