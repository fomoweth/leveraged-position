// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title Dispatcher
/// @notice Provides functions for forwarding calls to the target contract

abstract contract Dispatcher {
	function dispatch(address target, bytes memory data) internal virtual returns (bytes memory returndata) {
		assembly ("memory-safe") {
			if iszero(delegatecall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x00)) {
				let ptr := mload(0x40)
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(returndata, add(returndatasize(), 0x20)))
			mstore(returndata, returndatasize())
			returndatacopy(add(returndata, 0x20), 0x00, returndatasize())
		}
	}

	function fetch(address target, bytes memory data) internal view virtual returns (bytes memory returndata) {
		assembly ("memory-safe") {
			if iszero(staticcall(gas(), target, add(data, 0x20), mload(data), 0x00, 0x00)) {
				let ptr := mload(0x40)
				returndatacopy(ptr, 0x00, returndatasize())
				revert(ptr, returndatasize())
			}

			mstore(0x40, add(returndata, add(returndatasize(), 0x20)))
			mstore(returndata, returndatasize())
			returndatacopy(add(returndata, 0x20), 0x00, returndatasize())
		}
	}
}
