// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Errors
/// @notice Collection of custom errors used in multiple contracts

library Errors {
	error Unauthorized();
	error InvalidNewOwner();

	error ZeroAddress();
	error ZeroBytes32();

	error EmptyCode();
	error EmptyCreationCode();
	error EmptyConstructor();

	error CalldataEmpty();
	error CalldataNotEmpty();

	error SlotEmpty();
	error SlotNotEmpty();

	error ProxyCreationFailed();
	error ContractCreationFailed();
	error InitializationFailed();
	error InvalidInitialization();

	error AddressNotSet();

	error ExistsAlready();
	error NotExists();

	error NoDelegateCall();
	error NotDelegateCall();

	error IdenticalAssets();
	error InvalidAction();
	error InvalidCurrency();
	error InvalidCollateralAsset();
	error InvalidLiabilityAsset();
	error InvalidUpperBound();
	error InvalidLowerBound();
	error ExceededMaxLimit();
	error InsufficientPrincipalAmount();
	error InsufficientCollateral();
	error InsufficientLiquidity();
	error InsufficientPoolLiquidity();

	error InvalidSwap();
	error InsufficientAmountIn();
	error InsufficientAmountOut();

	error InvalidFeed();
	error InvalidPrice();
}
