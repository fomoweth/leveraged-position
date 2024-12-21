// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";
import {IAddressesProvider} from "./IAddressesProvider.sol";

interface ILendingPool {
	event Deposit(
		Currency indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint16 indexed referral
	);

	event Withdraw(Currency indexed reserve, address indexed user, address indexed to, uint256 amount);

	event Borrow(
		Currency indexed reserve,
		address user,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 borrowRateMode,
		uint256 borrowRate,
		uint16 indexed referral
	);

	event Repay(Currency indexed reserve, address indexed user, address indexed repayer, uint256 amount);

	event Swap(Currency indexed reserve, address indexed user, uint256 rateMode);

	event ReserveUsedAsCollateralEnabled(Currency indexed reserve, address indexed user);

	event ReserveUsedAsCollateralDisabled(Currency indexed reserve, address indexed user);

	event RebalanceStableBorrowRate(Currency indexed reserve, address indexed user);

	event FlashLoan(
		address indexed target,
		address indexed initiator,
		Currency indexed asset,
		uint256 amount,
		uint256 premium,
		uint16 referralCode
	);

	event Paused();

	event Unpaused();

	event LiquidationCall(
		Currency indexed collateralAsset,
		Currency indexed debtAsset,
		address indexed user,
		uint256 debtToCover,
		uint256 liquidatedCollateralAmount,
		address liquidator,
		bool receiveAToken
	);

	event ReserveDataUpdated(
		Currency indexed reserve,
		uint256 liquidityRate,
		uint256 stableBorrowRate,
		uint256 variableBorrowRate,
		uint256 liquidityIndex,
		uint256 variableBorrowIndex
	);

	struct ReserveData {
		ReserveConfigurationMap configuration;
		uint128 liquidityIndex;
		uint128 variableBorrowIndex;
		uint128 currentLiquidityRate;
		uint128 currentVariableBorrowRate;
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		Currency aTokenAddress;
		Currency stableDebtTokenAddress;
		Currency variableDebtTokenAddress;
		address interestRateStrategyAddress;
		uint8 id;
	}

	struct ReserveConfigurationMap {
		uint256 data;
	}

	struct UserConfigurationMap {
		uint256 data;
	}

	function deposit(Currency asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

	function withdraw(Currency asset, uint256 amount, address to) external returns (uint256);

	function borrow(
		Currency asset,
		uint256 amount,
		uint256 interestRateMode,
		uint16 referralCode,
		address onBehalfOf
	) external;

	function repay(Currency asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);

	function swapBorrowRateMode(Currency asset, uint256 rateMode) external;

	function rebalanceStableBorrowRate(Currency asset, address user) external;

	function setUserUseReserveAsCollateral(Currency asset, bool useAsCollateral) external;

	function liquidationCall(
		Currency collateralAsset,
		Currency debtAsset,
		address user,
		uint256 debtToCover,
		bool receiveAToken
	) external;

	function flashLoan(
		address receiverAddress,
		Currency[] calldata assets,
		uint256[] calldata amounts,
		uint256[] calldata modes,
		address onBehalfOf,
		bytes calldata params,
		uint16 referralCode
	) external;

	function getUserAccountData(
		address user
	)
		external
		view
		returns (
			uint256 totalCollateralETH,
			uint256 totalDebtETH,
			uint256 availableBorrowsETH,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	function initReserve(
		Currency reserve,
		Currency aTokenAddress,
		Currency stableDebtAddress,
		Currency variableDebtAddress,
		address interestRateStrategyAddress
	) external;

	function setReserveInterestRateStrategyAddress(Currency reserve, address rateStrategyAddress) external;

	function setConfiguration(Currency reserve, uint256 configuration) external;

	function getConfiguration(Currency asset) external view returns (ReserveConfigurationMap memory);

	function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);

	function getReserveNormalizedIncome(Currency asset) external view returns (uint256);

	function getReserveNormalizedVariableDebt(Currency asset) external view returns (uint256);

	function getReserveData(Currency asset) external view returns (ReserveData memory);

	function finalizeTransfer(
		Currency asset,
		address from,
		address to,
		uint256 amount,
		uint256 balanceFromAfter,
		uint256 balanceToBefore
	) external;

	function getReservesList() external view returns (Currency[] memory);

	function getAddressesProvider() external view returns (IAddressesProvider);

	function setPause(bool val) external;

	function paused() external view returns (bool);

	function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

	function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

	function MAX_NUMBER_RESERVES() external view returns (uint256);

	function LENDINGPOOL_REVISION() external view returns (uint256);
}
