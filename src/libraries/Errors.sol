// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Errors
/// @notice Provides assertions and custom errors used in multiple contracts

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

	function required(bytes4 selector, bool condition) internal pure {
		assembly ("memory-safe") {
			if iszero(condition) {
				mstore(0x00, selector)
				revert(0x00, 0x04)
			}
		}
	}

	function verifyAddress(address target) internal pure returns (address) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xd92e233d) // ZeroAddress()
				revert(0x00, 0x04)
			}
		}

		return target;
	}

	function verifyBytes32(bytes32 target) internal pure returns (bytes32) {
		assembly ("memory-safe") {
			if iszero(target) {
				mstore(0x00, 0xdff66326) // ZeroBytes32()
				revert(0x00, 0x04)
			}
		}

		return target;
	}

	function verifyContract(address target) internal view returns (address) {
		assembly ("memory-safe") {
			if iszero(extcodesize(target)) {
				mstore(0x00, 0x1858b10b) // EmptyCode()
				revert(0x00, 0x04)
			}
		}

		return target;
	}
}
