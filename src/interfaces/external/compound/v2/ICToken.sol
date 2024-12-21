// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20Metadata} from "@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {Currency} from "src/types/Currency.sol";
import {IComptroller} from "./IComptroller.sol";
import {IInterestRateModel} from "./IInterestRateModel.sol";

interface ICToken is IERC20Metadata {
	event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

	event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
	event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
	event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);
	event RepayBorrow(
		address payer,
		address borrower,
		uint256 repayAmount,
		uint256 accountBorrows,
		uint256 totalBorrows
	);
	event LiquidateBorrow(
		address liquidator,
		address borrower,
		uint256 repayAmount,
		address cTokenCollateral,
		uint256 seizeTokens
	);

	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewComptroller(address oldComptroller, address newComptroller);
	event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);
	event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

	event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);
	event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

	function implementation() external view returns (address);

	function comptroller() external view returns (IComptroller);

	function interestRateModel() external view returns (IInterestRateModel);

	function accrualBlockNumber() external view returns (uint256);

	function borrowIndex() external view returns (uint256);

	function supplyRatePerBlock() external view returns (uint256);

	function borrowRatePerBlock() external view returns (uint256);

	function getCash() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function totalReserves() external view returns (uint256);

	function reserveFactorMantissa() external view returns (uint256);

	function initialExchangeRateMantissa() external view returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function accrueInterest() external returns (uint256);

	function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);

	function balanceOfUnderlying(address account) external returns (uint256);

	function borrowBalanceCurrent(address account) external returns (uint256);

	function borrowBalanceStored(address account) external view returns (uint256);

	function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

	function redeem(uint256 amount) external returns (uint256);

	function redeemUnderlying(uint256 amount) external returns (uint256);

	function borrow(uint256 amount) external returns (uint256);

	// ICERC20

	function underlying() external view returns (Currency);

	function mint(uint256 amount) external returns (uint256);

	function repayBorrow(uint256 amount) external returns (uint256);

	function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

	function liquidateBorrow(address borrower, uint256 amount, address collateral) external returns (uint256);

	// ICETH

	function mint() external payable;

	function repayBorrow() external payable;

	function repayBorrowBehalf(address borrower) external payable;

	function liquidateBorrow(address borrower, address collateral) external payable;

	function sweepToken(Currency token) external;

	// Admin Functions

	function admin() external view returns (address);

	function pendingAdmin() external view returns (address);

	function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

	function _acceptAdmin() external returns (uint256);

	function _setComptroller(IComptroller newComptroller) external returns (uint256);

	function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

	function _reduceReserves(uint256 reduceAmount) external returns (uint256);

	function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint256);

	function _addReserves(uint256 addAmount) external returns (uint256);
}
