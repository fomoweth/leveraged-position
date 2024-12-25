// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "src/types/Currency.sol";

interface IPoolConfigurator {
	event ReserveInitialized(
		address indexed asset,
		address indexed aToken,
		address stableDebtToken,
		address variableDebtToken,
		address interestRateStrategyAddress
	);

	event ReserveBorrowing(address indexed asset, bool enabled);

	event ReserveFlashLoaning(address indexed asset, bool enabled);

	event CollateralConfigurationChanged(
		address indexed asset,
		uint256 ltv,
		uint256 liquidationThreshold,
		uint256 liquidationBonus
	);

	event ReserveStableRateBorrowing(address indexed asset, bool enabled);

	event ReserveActive(address indexed asset, bool active);

	event ReserveFrozen(address indexed asset, bool frozen);

	event ReservePaused(address indexed asset, bool paused);

	event ReserveDropped(address indexed asset);

	event ReserveFactorChanged(address indexed asset, uint256 oldReserveFactor, uint256 newReserveFactor);

	event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

	event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

	event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

	event UnbackedMintCapChanged(address indexed asset, uint256 oldUnbackedMintCap, uint256 newUnbackedMintCap);

	event AssetCollateralInEModeChanged(address indexed asset, uint8 categoryId, bool collateral);

	event AssetBorrowableInEModeChanged(address indexed asset, uint8 categoryId, bool borrowable);

	event EModeCategoryAdded(
		uint8 indexed categoryId,
		uint256 ltv,
		uint256 liquidationThreshold,
		uint256 liquidationBonus,
		string label
	);

	event ReserveInterestRateStrategyChanged(address indexed asset, address oldStrategy, address newStrategy);

	event ATokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

	event VariableDebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

	event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);

	event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);

	event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);

	event FlashloanPremiumTotalUpdated(uint128 oldFlashloanPremiumTotal, uint128 newFlashloanPremiumTotal);

	event FlashloanPremiumToProtocolUpdated(
		uint128 oldFlashloanPremiumToProtocol,
		uint128 newFlashloanPremiumToProtocol
	);

	event BorrowableInIsolationChanged(address asset, bool borrowable);

	function setReserveBorrowing(Currency asset, bool enabled) external;

	function configureReserveAsCollateral(
		Currency asset,
		uint256 ltv,
		uint256 liquidationThreshold,
		uint256 liquidationBonus
	) external;

	function setReserveFlashLoaning(Currency asset, bool enabled) external;

	function setReserveActive(Currency asset, bool active) external;

	function setReserveFreeze(Currency asset, bool freeze) external;

	function setBorrowableInIsolation(Currency asset, bool borrowable) external;

	function setReservePause(Currency asset, bool paused) external;

	function setReserveFactor(Currency asset, uint256 newReserveFactor) external;

	function setReserveInterestRateStrategyAddress(Currency asset, address newRateStrategyAddress) external;

	function setPoolPause(bool paused) external;

	function setBorrowCap(Currency asset, uint256 newBorrowCap) external;

	function setSupplyCap(Currency asset, uint256 newSupplyCap) external;

	function setLiquidationProtocolFee(Currency asset, uint256 newFee) external;

	function setUnbackedMintCap(Currency asset, uint256 newUnbackedMintCap) external;

	function setAssetBorrowableInEMode(Currency asset, uint8 categoryId, bool borrowable) external;

	function setAssetCollateralInEMode(Currency asset, uint8 categoryId, bool collateral) external;

	function setEModeCategory(
		uint8 categoryId,
		uint16 ltv,
		uint16 liquidationThreshold,
		uint16 liquidationBonus,
		string calldata label
	) external;

	function dropReserve(Currency asset) external;

	function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

	function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

	function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

	function setDebtCeiling(Currency asset, uint256 newDebtCeiling) external;

	function setSiloedBorrowing(Currency asset, bool siloed) external;
}
